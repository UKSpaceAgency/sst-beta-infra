#!/usr/bin/env bash
# Dev retention deletes events and analyses after 180 days, so every run targets data that exists now.
set -euo pipefail
cd "$(dirname "$0")"

token=$(
  jq -n '{grant_type: "client_credentials", client_id: $ENV.E2E_CLIENT_ID,
    client_secret: $ENV.E2E_CLIENT_SECRET, audience: $ENV.E2E_AUTH0_AUDIENCE}' |
    curl -sSf "$E2E_AUTH_BASE_URL/oauth/token" -H 'content-type: application/json' -d @- |
    jq -r .access_token
)

api() { curl -sSfL -H "Authorization: Bearer $token" "$E2E_BASE_URL$1"; }
fail() { echo "prepare_fixtures: $1" >&2; exit 1; }

norad=$(jq -r '.variable[] | select(.key == "testSatellitePrimaryNorad") | .value' postman_collection.json)
event=$(api "/v1/events/?norad_id=$norad&epoch=past&sort_by=tca_time&sort_order=desc&limit=1" | jq -e '.[0]') ||
  fail "no past event for NORAD $norad on dev"
short_id=$(jq -r .short_id <<<"$event")
cdm_id=$(api "/v1/events/$short_id/summary?limit=100" |
  jq -er 'map(select(.data_source == "Space-Track CDM")) | .[0].cdm_external_id') ||
  fail "event $short_id has no Space-Track CDM"

# Uploading onto an already analysed event, with its CDM and its stored UKSA probability, leaves that
# event, its CDM's analyst-queue entry and its collision_probability_uksa exactly as they were.
analysis=$(api "/v1/analyses/?sort_by=tca_time&sort_order=desc&limit=1" | jq -e '.[0]') ||
  fail "no active analysis on dev"
analysed_short_id=$(jq -r .event_short_id <<<"$analysis")
stored_uksa=$(
  for epoch in future past; do api "/v1/conjunction-events/list?search_like=$analysed_short_id&epoch=$epoch"; done |
    jq -se --arg short_id "$analysed_short_id" \
      'add | map(select(.short_id == $short_id)) | .[0].collision_probability_uksa // empty'
) || fail "analysed event $analysed_short_id has no stored UKSA probability"
update_time=$(date -u +%Y-%m-%dT%H:%M:%S)

jq --argjson analysis "$analysis" --argjson uksa "$stored_uksa" --arg update_time "$update_time" '
  .event_id = $analysis.event_short_id
  | .cdm_id = $analysis.cdm_external_id
  | .collision_probability = $uksa
  | .tca = $analysis.tca_time + "Z"
  | .update_time = $update_time + ".000Z"
  | .primary_object.norad_id = $analysis.primary_object_norad_id
  | .secondary_object.norad_id = $analysis.secondary_object_norad_id
' analysis_template.json >analysis_upload.json

jq --argjson event "$event" --arg cdm_id "$cdm_id" --argjson analysis "$analysis" --arg update_time "$update_time" '
  .values += [
    {key: "testEventShortId", value: $event.short_id},
    {key: "testCDMId", value: $cdm_id},
    {key: "testSatelliteSecondaryNorad", value: $event.secondary_object_norad_id},
    {key: "testAnalysisEventShortId", value: $analysis.event_short_id},
    {key: "testAnalysisTcaTime", value: $analysis.tca_time},
    {key: "testAnalysisUpdateTime", value: $update_time}
  ]
' postman_environment.json >run.postman_environment.json

echo "event $short_id (CDM $cdm_id), analysis upload onto $analysed_short_id (CDM $(jq -r .cdm_external_id <<<"$analysis"))"
