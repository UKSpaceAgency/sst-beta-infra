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

# Uploading a copy of a real analysis onto its own event, with the event's stored UKSA probability, leaves
# that event, its CDM's analyst-queue entry and its collision_probability_uksa as they were. Analysts
# only upload before TCA, so a past-TCA event cannot receive a real upload that this run would overwrite.
now=$(date -u +%Y-%m-%dT%H:%M:%S)
analyses=$(api "/v1/analyses/?sort_by=tca_time&sort_order=desc&limit=1000")
analysis=$(jq -e --arg now "$now" 'map(select(.tca_time < $now)) | .[0]' <<<"$analyses") ||
  fail "no active analysis with a past TCA on dev"
analysed_short_id=$(jq -r .event_short_id <<<"$analysis")
analysed_events=$(api "/v1/conjunction-events/list?search_like=$analysed_short_id&epoch=past")
stored_uksa=$(jq -e --arg short_id "$analysed_short_id" \
  'map(select(.short_id == $short_id)) | .[0].collision_probability_uksa // empty' <<<"$analysed_events") ||
  fail "analysed event $analysed_short_id has no stored UKSA probability"

jq --argjson analysis "$analysis" --argjson uksa "$stored_uksa" --arg update_time "$now" '
  .event_id = $analysis.event_short_id
  | .cdm_id = $analysis.cdm_external_id
  | .collision_probability = $uksa
  | .collision_probability_method = $analysis.collision_probability_method
  | .tca = $analysis.tca_time + "Z"
  | .update_time = $update_time + ".000Z"
  | .miss_distance.total_value = $analysis.miss_distance
  | .miss_distance.mean_radial_value = $analysis.radial_miss_distance
  | .miss_distance.in_track_value = $analysis.intrack_miss_distance
  | .miss_distance.cross_track_value = $analysis.crosstrack_miss_distance
  | .altitude = $analysis.altitude
  | .latitude = $analysis.latitude
  | .longitude = $analysis.longitude
  | .relative_velocity = $analysis.relative_velocity
  | .estimated_combined_mass = $analysis.combined_mass
  | .estimated_fragments = $analysis.possible_fragments
  | .primary_object.norad_id = $analysis.primary_object_norad_id
  | .secondary_object.norad_id = $analysis.secondary_object_norad_id
' analysis_template.json >analysis_upload.json

jq --argjson event "$event" --arg cdm_id "$cdm_id" --argjson analysis "$analysis" --arg update_time "$now" '
  .values += [
    {key: "testEventShortId", value: $event.short_id},
    {key: "testCDMId", value: $cdm_id},
    {key: "testSatelliteSecondaryNorad", value: $event.secondary_object_norad_id},
    {key: "testAnalysisEventShortId", value: $analysis.event_short_id},
    {key: "testAnalysisTcaTime", value: $analysis.tca_time},
    {key: "testAnalysisUpdateTime", value: $update_time}
  ]
' postman_environment.json >run.postman_environment.json

echo "event $(jq -r .short_id <<<"$event") (CDM $cdm_id), analysis upload onto $analysed_short_id (CDM $(jq -r .cdm_external_id <<<"$analysis"), TCA $(jq -r .tca_time <<<"$analysis"))"
