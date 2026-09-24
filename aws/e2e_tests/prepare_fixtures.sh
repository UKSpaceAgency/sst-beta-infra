#!/usr/bin/env bash
# Dev retention deletes events and analyses after 180 days, so every run targets data that exists now.
set -euo pipefail
cd "$(dirname "$0")"

fail() { echo "prepare_fixtures: $1" >&2; exit 1; }

token=$(
  jq -n '{grant_type: "client_credentials", client_id: $ENV.E2E_CLIENT_ID,
    client_secret: $ENV.E2E_CLIENT_SECRET, audience: $ENV.E2E_AUTH0_AUDIENCE}' |
    curl -sSf "$E2E_AUTH_BASE_URL/oauth/token" -H 'content-type: application/json' -d @- |
    jq -r .access_token
)
[[ -n $token && $token != null ]] || fail "Auth0 returned no access token"

api() { curl -sSfL -H "Authorization: Bearer $token" "$E2E_BASE_URL$1"; }

norad=$(jq -r '.variable[] | select(.key == "testSatellitePrimaryNorad") | .value' postman_collection.json)
events=$(api "/v1/events/?norad_id=$norad&epoch=past&sort_by=tca_time&sort_order=desc&limit=1")
event=$(jq -e '.[0]' <<<"$events") || fail "no past event for NORAD $norad on dev"
cdm_id=$(jq -er .cdm_external_id <<<"$event") || fail "event $(jq -r .short_id <<<"$event") has no CDM id"

now=$(date -u +%Y-%m-%dT%H:%M:%S)
candidates='[]'
for page in $(seq 0 19); do
  batch=$(api "/v1/analyses/?sort_by=tca_time&sort_order=desc&limit=200&offset=$((page * 200))")
  [[ $(jq length <<<"$batch") -gt 0 ]] || break
  candidates=$(printf '%s\n%s\n' "$candidates" "$batch" | jq -sc --arg now "$now" '
    .[0] + (.[1] | map(select(.tca_time < $now)))
    | reduce .[] as $a ([]; if any(.[]; .event_short_id == $a.event_short_id) then . else . + [$a] end)')
  [[ $(jq length <<<"$candidates") -ge 5 ]] && break
done
[[ $(jq length <<<"$candidates") -gt 0 ]] || fail "no active analysis with a past TCA in the newest 4000 on dev"

# A copy of a past-TCA analysis, carrying its event's stored UKSA probability, changes nothing on that event.
stored_uksa=""
for i in 0 1 2 3 4; do
  analysis=$(jq -e ".[$i]" <<<"$candidates") || break
  analysed_short_id=$(jq -r .event_short_id <<<"$analysis")
  analysed_events=$(api "/v1/conjunction-events/list?search_like=$analysed_short_id&epoch=past")
  stored_uksa=$(jq -e --arg short_id "$analysed_short_id" \
    'map(select(.short_id == $short_id)) | .[0].collision_probability_uksa // empty' <<<"$analysed_events") && break
done
[[ -n $stored_uksa ]] || fail "none of the newest 5 past-TCA analysed events has a stored UKSA probability"

# CDM id 0 matches no real CDM, so the events-list join and the analyst-queue delete both skip the copy.
jq -n --argjson analysis "$analysis" --argjson uksa "$stored_uksa" --arg update_time "$now" '
  def observations($data; $norad_id): {
    norad_id: $norad_id,
    data_received: $data.data_received,
    data_source: $data.data_source,
    HBR: $data.hbr,
    observations_number: $data.observations_number,
    observations_available: $data.observations_available,
    observations_timespan: $data.observations_timespan,
    OD_Quality: $data.od_quality
  };
  {
    event_id: $analysis.event_short_id,
    cdm_id: "0",
    collision_probability: $uksa,
    collision_probability_method: $analysis.collision_probability_method,
    tca: ($analysis.tca_time + "Z"),
    update_time: ($update_time + ".000Z"),
    miss_distance: {
      total_value: $analysis.miss_distance,
      total_uncertainty: $analysis.miss_distance_uncertainty.total_uncertainty,
      mean_radial_value: $analysis.radial_miss_distance,
      mean_radial_uncertainty: $analysis.miss_distance_uncertainty.mean_radial_uncertainty,
      in_track_value: $analysis.intrack_miss_distance,
      in_track_uncertainty: $analysis.miss_distance_uncertainty.in_track_uncertainty,
      cross_track_value: $analysis.crosstrack_miss_distance,
      cross_track_uncertainty: $analysis.miss_distance_uncertainty.cross_track_uncertainty
    },
    altitude: $analysis.altitude,
    latitude: $analysis.latitude,
    longitude: $analysis.longitude,
    relative_velocity: $analysis.relative_velocity,
    estimated_combined_mass: $analysis.combined_mass,
    estimated_fragments: $analysis.possible_fragments,
    primary_object: observations($analysis.primary_object_observations_data; $analysis.primary_object_norad_id),
    secondary_object: observations($analysis.secondary_object_observations_data; $analysis.secondary_object_norad_id)
  }' >analysis_upload.json

jq --argjson event "$event" --arg cdm_id "$cdm_id" --argjson analysis "$analysis" --arg update_time "$now" '
  .values += [
    {key: "testEventShortId", value: $event.short_id},
    {key: "testCDMId", value: $cdm_id},
    {key: "testSatelliteSecondaryNorad", value: $event.secondary_object_norad_id},
    {key: "testAnalysisEventShortId", value: $analysis.event_short_id},
    {key: "testAnalysisCDMId", value: $analysis.cdm_external_id},
    {key: "testAnalysisTcaTime", value: $analysis.tca_time},
    {key: "testAnalysisUpdateTime", value: $update_time}
  ]
' postman_environment.json >run.postman_environment.json

echo "event $(jq -r .short_id <<<"$event") (CDM $cdm_id), analysis copy onto $analysed_short_id (TCA $(jq -r .tca_time <<<"$analysis"))"
