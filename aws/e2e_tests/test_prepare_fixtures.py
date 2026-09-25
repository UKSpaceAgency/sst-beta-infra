import json
from datetime import UTC, datetime
from pathlib import Path

import httpx
import pytest

import prepare_fixtures

NOW = datetime(2026, 9, 25, 12, 0, 0, tzinfo=UTC)
PAST_TCA = "2026-09-20T08:00:00.123000"
RECENT_TCA = "2026-09-25T02:00:00.000000"
FUTURE_TCA = "2026-10-01T00:00:00.000000"
ENV = {
    "E2E_AUTH_BASE_URL": "https://auth.example",
    "E2E_BASE_URL": "https://api.example",
    "E2E_CLIENT_ID": "client",
    "E2E_CLIENT_SECRET": "secret",
    "E2E_AUTH0_AUDIENCE": "audience",
}
OBSERVATIONS = {
    "data_received": None,
    "data_source": "US CDM, ESA DISCOS",
    "hbr": 2.5,
    "observations_number": 3,
    "observations_available": None,
    "observations_timespan": None,
    "od_quality": "good",
}


def analysis(short_id: str, tca_time: str = PAST_TCA) -> dict:
    return {
        "event_short_id": short_id,
        "cdm_external_id": "1707086436",
        "tca_time": tca_time,
        "collision_probability_method": "FOSTER",
        "miss_distance": 758.0,
        "radial_miss_distance": 12.5,
        "intrack_miss_distance": -700.1,
        "crosstrack_miss_distance": 280.4,
        "miss_distance_uncertainty": {
            "total_uncertainty": 1.5,
            "mean_radial_uncertainty": None,
            "in_track_uncertainty": None,
            "cross_track_uncertainty": None,
        },
        "altitude": 1200.5,
        "latitude": 14.37,
        "longitude": -3.2,
        "relative_velocity": 6.089,
        "combined_mass": None,
        "possible_fragments": None,
        "primary_object_norad_id": "61604",
        "secondary_object_norad_id": "21294",
        "primary_object_observations_data": OBSERVATIONS,
        "secondary_object_observations_data": {**OBSERVATIONS, "hbr": 1.35},
    }


class FakeDev:
    def __init__(self, *, events=None, analysis_pages=None, stored_uksa=None, token="token"):
        self.events = (
            events
            if events is not None
            else [
                {
                    "short_id": "zqlpbop-odzrgnn-abvzgd",
                    "cdm_external_id": "1713991513",
                    "secondary_object_norad_id": "2",
                }
            ]
        )
        self.analysis_pages = analysis_pages if analysis_pages is not None else [[analysis("kgpebal-vrddrbe-wrojld")]]
        self.stored_uksa = stored_uksa if stored_uksa is not None else {"kgpebal-vrddrbe-wrojld": 0.0000021}
        self.token = token
        self.uksa_lookups = []
        self.api_authorization = set()

    def __call__(self, request: httpx.Request) -> httpx.Response:
        path, params = request.url.path, request.url.params
        if path == "/oauth/token":
            return httpx.Response(200, json={"access_token": self.token} if self.token else {"error": "denied"})
        self.api_authorization.add(request.headers.get("Authorization"))
        if path == "/v1/events/":
            return httpx.Response(301, headers={"Location": str(request.url.copy_with(path="/v1/conjunction-events/"))})
        if path == "/v1/conjunction-events/":
            return httpx.Response(200, json=self.events)
        if path == "/v1/analyses/":
            page = int(params["offset"]) // prepare_fixtures.PAGE_SIZE
            return httpx.Response(200, json=self.analysis_pages[page] if page < len(self.analysis_pages) else [])
        if path == "/v1/conjunction-events/list":
            short_id = params["search_like"]
            self.uksa_lookups.append(short_id)
            rows = []
            if short_id in self.stored_uksa:
                rows = [{"short_id": short_id, "collision_probability_uksa": self.stored_uksa[short_id]}]
            return httpx.Response(200, json=rows)
        raise AssertionError(f"unexpected request {request.url}")


@pytest.fixture
def e2e_dir(tmp_path: Path) -> Path:
    source = Path(prepare_fixtures.__file__).parent
    (tmp_path / "postman_collection.json").write_text(
        json.dumps({"variable": [{"key": "testSatellitePrimaryNorad", "value": "61604"}]})
    )
    (tmp_path / "postman_environment.json").write_text((source / "postman_environment.json").read_text())
    return tmp_path


def run(e2e_dir: Path, dev: FakeDev) -> str:
    return prepare_fixtures.prepare(e2e_dir, ENV, NOW, transport=httpx.MockTransport(dev))


def environment_values(e2e_dir: Path) -> dict:
    environment = json.loads((e2e_dir / "run.postman_environment.json").read_text())
    return {value["key"]: value["value"] for value in environment["values"]}


def test_upload_is_a_copy_of_the_picked_analysis_with_cdm_zero_and_the_stored_probability(e2e_dir):
    # given
    dev = FakeDev()

    # when
    summary = run(e2e_dir, dev)

    # then
    upload = json.loads((e2e_dir / "analysis_upload.json").read_text())
    assert summary == (
        "event zqlpbop-odzrgnn-abvzgd (CDM 1713991513), "
        "analysis copy onto kgpebal-vrddrbe-wrojld (TCA 2026-09-20T08:00:00.123000)"
    )
    assert upload["event_id"] == "kgpebal-vrddrbe-wrojld"
    assert upload["cdm_id"] == "0"
    assert upload["collision_probability"] == 0.0000021
    assert upload["tca"] == "2026-09-20T08:00:00.123000Z"
    assert upload["update_time"] == "2026-09-25T12:00:00.000Z"
    assert upload["miss_distance"]["total_value"] == 758.0
    assert upload["miss_distance"]["total_uncertainty"] == 1.5
    assert upload["primary_object"] == {
        "norad_id": "61604",
        "data_received": None,
        "data_source": "US CDM, ESA DISCOS",
        "HBR": 2.5,
        "observations_number": 3,
        "observations_available": None,
        "observations_timespan": None,
        "OD_Quality": "good",
    }
    assert upload["secondary_object"]["HBR"] == 1.35


def test_api_requests_carry_the_fetched_token(e2e_dir):
    # given
    dev = FakeDev(token="dev-token")

    # when
    run(e2e_dir, dev)

    # then
    assert dev.api_authorization == {"Bearer dev-token"}


def test_environment_carries_both_picked_events_and_the_fields_the_round_trip_test_compares(e2e_dir):
    # given
    dev = FakeDev()

    # when
    run(e2e_dir, dev)

    # then
    values = environment_values(e2e_dir)
    assert values["testEventShortId"] == "zqlpbop-odzrgnn-abvzgd"
    assert values["testCDMId"] == "1713991513"
    assert values["testAnalysisEventShortId"] == "kgpebal-vrddrbe-wrojld"
    assert values["testAnalysisCDMId"] == "1707086436"
    assert values["testAnalysisPrimaryNorad"] == "61604"
    assert values["testAnalysisTcaTime"] == PAST_TCA
    assert values["testAnalysisUpdateTime"] == "2026-09-25T12:00:00"
    expected = json.loads(values["testAnalysisExpectedFields"])
    assert set(expected) == set(prepare_fixtures.EXPECTED_FIELDS)
    assert expected["secondary_object_observations_data"]["hbr"] == 1.35
    assert values["baseUrl"].startswith("<")


def test_analyses_less_than_a_day_past_tca_are_skipped(e2e_dir):
    # given
    dev = FakeDev(
        analysis_pages=[[analysis("future", FUTURE_TCA), analysis("recent", RECENT_TCA), analysis("old", PAST_TCA)]],
        stored_uksa={"future": 0.1, "recent": 0.2, "old": 0.3},
    )

    # when
    run(e2e_dir, dev)

    # then
    assert dev.uksa_lookups == ["old"]


def test_candidates_are_distinct_events_collected_across_pages(e2e_dir):
    # given
    dev = FakeDev(
        analysis_pages=[
            [analysis("future", FUTURE_TCA), analysis("pk"), analysis("pk"), analysis("pk"), analysis("q1")],
            [analysis("q1"), analysis("q2"), analysis("q3"), analysis("q4")],
        ],
        stored_uksa={"q4": 0.4},
    )

    # when
    run(e2e_dir, dev)

    # then
    assert dev.uksa_lookups == ["pk", "q1", "q2", "q3", "q4"]


def test_candidates_are_found_past_pages_of_future_analyses(e2e_dir):
    # given
    future_page = [analysis("future", FUTURE_TCA)] * 2
    dev = FakeDev(
        analysis_pages=[future_page, future_page, future_page, [analysis("deep")]],
        stored_uksa={"deep": 0.5},
    )

    # when
    run(e2e_dir, dev)

    # then
    assert environment_values(e2e_dir)["testAnalysisEventShortId"] == "deep"


def test_first_candidate_without_stored_probability_falls_back_to_the_next(e2e_dir):
    # given
    dev = FakeDev(analysis_pages=[[analysis("no-uksa"), analysis("has-uksa")]], stored_uksa={"has-uksa": 0.6})

    # when
    run(e2e_dir, dev)

    # then
    assert dev.uksa_lookups == ["no-uksa", "has-uksa"]
    assert json.loads((e2e_dir / "analysis_upload.json").read_text())["event_id"] == "has-uksa"


def test_a_stored_probability_of_zero_counts_as_stored(e2e_dir):
    # given
    dev = FakeDev(analysis_pages=[[analysis("zero")]], stored_uksa={"zero": 0.0})

    # when
    run(e2e_dir, dev)

    # then
    assert json.loads((e2e_dir / "analysis_upload.json").read_text())["collision_probability"] == 0.0


@pytest.mark.parametrize(
    ("dev", "message"),
    [
        (FakeDev(token=None), "Auth0 returned no access token"),
        (FakeDev(events=[]), "no past event for NORAD 61604 on dev"),
        (FakeDev(events=[{"short_id": "ev-1", "cdm_external_id": None}]), "event ev-1 has no CDM id"),
        (
            FakeDev(analysis_pages=[[analysis("future", FUTURE_TCA)], [analysis("recent", RECENT_TCA)]]),
            "none of the newest 2 active analyses on dev has a TCA before 2026-09-24T12:00:00",
        ),
        (
            FakeDev(analysis_pages=[[analysis("a"), analysis("b")]], stored_uksa={"x": 0.1}),
            "none of the 2 analysed events picked has a stored UKSA probability",
        ),
    ],
)
def test_missing_data_fails_with_a_named_reason(e2e_dir, dev, message):
    # given
    transport = httpx.MockTransport(dev)

    # when
    with pytest.raises(prepare_fixtures.FixtureError) as error:
        prepare_fixtures.prepare(e2e_dir, ENV, NOW, transport=transport)

    # then
    assert str(error.value) == message
    assert not (e2e_dir / "analysis_upload.json").exists()


def replaying(*outcomes):
    calls = []

    def handler(request: httpx.Request) -> httpx.Response:
        outcome = outcomes[len(calls)]
        calls.append(request)
        if isinstance(outcome, Exception):
            raise outcome
        return outcome

    return httpx.Client(base_url="https://api.example", transport=httpx.MockTransport(handler)), calls


def test_transient_failures_are_retried(mocker):
    # given
    mocker.patch("prepare_fixtures.time.sleep")
    client, calls = replaying(httpx.Response(503), httpx.ConnectTimeout("slow"), httpx.Response(200, json={"ok": True}))

    # when
    result = prepare_fixtures.request_json(client, "GET", "/v1/events/")

    # then
    assert result == {"ok": True}
    assert len(calls) == 3


def test_client_errors_are_not_retried(mocker):
    # given
    mocker.patch("prepare_fixtures.time.sleep")
    client, calls = replaying(httpx.Response(401))

    # when
    with pytest.raises(httpx.HTTPStatusError) as error:
        prepare_fixtures.request_json(client, "GET", "/v1/events/")

    # then
    assert error.value.response.status_code == 401
    assert len(calls) == 1


def test_retries_give_up_after_the_limit(mocker):
    # given
    mocker.patch("prepare_fixtures.time.sleep")
    client, calls = replaying(*[httpx.Response(503)] * (prepare_fixtures.RETRIES + 1))

    # when
    with pytest.raises(httpx.HTTPStatusError):
        prepare_fixtures.request_json(client, "GET", "/v1/events/")

    # then
    assert len(calls) == prepare_fixtures.RETRIES + 1


def test_http_failures_exit_with_the_url_and_status(mocker):
    # given
    request = httpx.Request("GET", "https://api.example/v1/events/")
    error = httpx.HTTPStatusError("boom", request=request, response=httpx.Response(500, request=request))
    mocker.patch("prepare_fixtures.prepare", side_effect=error)

    # when
    with pytest.raises(SystemExit) as exit_:
        prepare_fixtures.main()

    # then
    assert exit_.value.code == "prepare_fixtures: https://api.example/v1/events/ returned HTTP 500"
