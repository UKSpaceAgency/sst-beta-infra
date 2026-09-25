# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "httpx>=0.28,<1",
# ]
# ///
# Dev retention deletes events and analyses after 180 days, so every run targets data that exists now.
import json
import os
import sys
import time
from collections.abc import Mapping
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

import httpx

PAGE_SIZE = 200
MAX_PAGES = 20
CANDIDATE_EVENTS = 5
# A day past TCA leaves no room for a late real upload to land between the read and the E2E upload.
TCA_MARGIN = timedelta(days=1)
TIMEOUT_SECONDS = 60
RETRIES = 2
RETRYABLE_STATUSES = {408, 429, 500, 502, 503, 504}
TIMESTAMP_FORMAT = "%Y-%m-%dT%H:%M:%S"
EXPECTED_FIELDS = (
    "collision_probability_method",
    "miss_distance",
    "radial_miss_distance",
    "intrack_miss_distance",
    "crosstrack_miss_distance",
    "miss_distance_uncertainty",
    "altitude",
    "latitude",
    "longitude",
    "relative_velocity",
    "combined_mass",
    "possible_fragments",
    "primary_object_norad_id",
    "secondary_object_norad_id",
    "primary_object_observations_data",
    "secondary_object_observations_data",
)


class FixtureError(Exception):
    pass


def request_json(client: httpx.Client, method: str, url: str, **kwargs: Any) -> Any:
    for attempt in range(RETRIES + 1):
        try:
            response = client.request(method, url, **kwargs)
        except httpx.TransportError:
            if attempt == RETRIES:
                raise
        else:
            if response.status_code not in RETRYABLE_STATUSES or attempt == RETRIES:
                return response.raise_for_status().json()
        time.sleep(2**attempt)
    raise AssertionError("unreachable")


def fetch_token(client: httpx.Client, env: Mapping[str, str]) -> str:
    response = request_json(
        client,
        "POST",
        f"{env['E2E_AUTH_BASE_URL']}/oauth/token",
        json={
            "grant_type": "client_credentials",
            "client_id": env["E2E_CLIENT_ID"],
            "client_secret": env["E2E_CLIENT_SECRET"],
            "audience": env["E2E_AUTH0_AUDIENCE"],
        },
    )
    token: str | None = response.get("access_token")
    if not token:
        raise FixtureError("Auth0 returned no access token")
    return token


def pick_event(client: httpx.Client, norad_id: str) -> dict[str, Any]:
    params = {"norad_id": norad_id, "epoch": "past", "sort_by": "tca_time", "sort_order": "desc", "limit": 1}
    events = request_json(client, "GET", "/v1/events/", params=params)
    if not events:
        raise FixtureError(f"no past event for NORAD {norad_id} on dev")
    event: dict[str, Any] = events[0]
    if not event.get("cdm_external_id"):
        raise FixtureError(f"event {event['short_id']} has no CDM id")
    return event


def past_tca_candidates(client: httpx.Client, cutoff: datetime) -> list[dict[str, Any]]:
    candidates: dict[str, dict[str, Any]] = {}
    scanned = 0
    for page in range(MAX_PAGES):
        params = {"sort_by": "tca_time", "sort_order": "desc", "limit": PAGE_SIZE, "offset": page * PAGE_SIZE}
        batch = request_json(client, "GET", "/v1/analyses/", params=params)
        if not batch:
            break
        scanned += len(batch)
        for analysis in batch:
            if datetime.fromisoformat(analysis["tca_time"]) < cutoff:
                candidates.setdefault(analysis["event_short_id"], analysis)
        if len(candidates) >= CANDIDATE_EVENTS:
            break
    if not candidates:
        raise FixtureError(
            f"none of the newest {scanned} active analyses on dev has a TCA before {cutoff:{TIMESTAMP_FORMAT}}"
        )
    return list(candidates.values())[:CANDIDATE_EVENTS]


def stored_uksa(client: httpx.Client, short_id: str) -> float | None:
    params = {"search_like": short_id, "epoch": "past"}
    for event in request_json(client, "GET", "/v1/conjunction-events/list", params=params):
        if event["short_id"] == short_id:
            probability: float | None = event["collision_probability_uksa"]
            return probability
    return None


def pick_analysis(client: httpx.Client, candidates: list[dict[str, Any]]) -> tuple[dict[str, Any], float]:
    # A copy of a past-TCA analysis, carrying its event's stored UKSA probability, changes nothing on that event.
    for analysis in candidates:
        probability = stored_uksa(client, analysis["event_short_id"])
        if probability is not None:
            return analysis, probability
    raise FixtureError(f"none of the {len(candidates)} analysed events picked has a stored UKSA probability")


def observations(data: Mapping[str, Any], norad_id: str) -> dict[str, Any]:
    return {
        "norad_id": norad_id,
        "data_received": data["data_received"],
        "data_source": data["data_source"],
        "HBR": data["hbr"],
        "observations_number": data["observations_number"],
        "observations_available": data["observations_available"],
        "observations_timespan": data["observations_timespan"],
        "OD_Quality": data["od_quality"],
    }


def build_upload(analysis: Mapping[str, Any], uksa: float, update_time: str) -> dict[str, Any]:
    uncertainty = analysis["miss_distance_uncertainty"]
    return {
        "event_id": analysis["event_short_id"],
        # CDM id 0 matches no real CDM, so the events-list join and the analyst-queue delete both skip the copy.
        "cdm_id": "0",
        "collision_probability": uksa,
        "collision_probability_method": analysis["collision_probability_method"],
        "tca": f"{analysis['tca_time']}Z",
        "update_time": f"{update_time}.000Z",
        "miss_distance": {
            "total_value": analysis["miss_distance"],
            "total_uncertainty": uncertainty["total_uncertainty"],
            "mean_radial_value": analysis["radial_miss_distance"],
            "mean_radial_uncertainty": uncertainty["mean_radial_uncertainty"],
            "in_track_value": analysis["intrack_miss_distance"],
            "in_track_uncertainty": uncertainty["in_track_uncertainty"],
            "cross_track_value": analysis["crosstrack_miss_distance"],
            "cross_track_uncertainty": uncertainty["cross_track_uncertainty"],
        },
        "altitude": analysis["altitude"],
        "latitude": analysis["latitude"],
        "longitude": analysis["longitude"],
        "relative_velocity": analysis["relative_velocity"],
        "estimated_combined_mass": analysis["combined_mass"],
        "estimated_fragments": analysis["possible_fragments"],
        "primary_object": observations(
            analysis["primary_object_observations_data"], analysis["primary_object_norad_id"]
        ),
        "secondary_object": observations(
            analysis["secondary_object_observations_data"], analysis["secondary_object_norad_id"]
        ),
    }


def build_environment(
    base: Mapping[str, Any], event: Mapping[str, Any], analysis: Mapping[str, Any], update_time: str
) -> dict[str, Any]:
    values = {
        "testEventShortId": event["short_id"],
        "testCDMId": event["cdm_external_id"],
        "testSatelliteSecondaryNorad": event["secondary_object_norad_id"],
        "testAnalysisEventShortId": analysis["event_short_id"],
        "testAnalysisCDMId": analysis["cdm_external_id"],
        "testAnalysisPrimaryNorad": analysis["primary_object_norad_id"],
        "testAnalysisTcaTime": analysis["tca_time"],
        "testAnalysisUpdateTime": update_time,
        "testAnalysisExpectedFields": json.dumps({field: analysis[field] for field in EXPECTED_FIELDS}),
    }
    return {**base, "values": [*base["values"], *({"key": k, "value": v} for k, v in values.items())]}


def prepare(
    directory: Path, env: Mapping[str, str], now: datetime, transport: httpx.BaseTransport | None = None
) -> str:
    collection = json.loads((directory / "postman_collection.json").read_text())
    norad_id = next(v["value"] for v in collection["variable"] if v["key"] == "testSatellitePrimaryNorad")

    with httpx.Client(
        base_url=env["E2E_BASE_URL"], timeout=TIMEOUT_SECONDS, follow_redirects=True, transport=transport
    ) as client:
        client.headers["Authorization"] = f"Bearer {fetch_token(client, env)}"
        event = pick_event(client, norad_id)
        candidates = past_tca_candidates(client, now.replace(tzinfo=None) - TCA_MARGIN)
        analysis, uksa = pick_analysis(client, candidates)

    update_time = now.strftime(TIMESTAMP_FORMAT)
    base_environment = json.loads((directory / "postman_environment.json").read_text())
    (directory / "analysis_upload.json").write_text(json.dumps(build_upload(analysis, uksa, update_time)))
    (directory / "run.postman_environment.json").write_text(
        json.dumps(build_environment(base_environment, event, analysis, update_time))
    )
    return (
        f"event {event['short_id']} (CDM {event['cdm_external_id']}), "
        f"analysis copy onto {analysis['event_short_id']} (TCA {analysis['tca_time']})"
    )


def main() -> None:
    try:
        print(prepare(Path(__file__).parent, os.environ, datetime.now(UTC)))
    except FixtureError as error:
        sys.exit(f"prepare_fixtures: {error}")
    except httpx.HTTPStatusError as error:
        sys.exit(f"prepare_fixtures: {error.request.url} returned HTTP {error.response.status_code}")
    except httpx.RequestError as error:
        sys.exit(f"prepare_fixtures: request to {error.request.url} failed: {error!r}")


if __name__ == "__main__":
    main()
