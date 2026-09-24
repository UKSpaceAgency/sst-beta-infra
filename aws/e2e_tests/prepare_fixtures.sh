#!/usr/bin/env bash
# Dev retention deletes events and analyses after 180 days, so every run targets data that exists now.
set -euo pipefail
cd "$(dirname "$0")"

token=$(
  jq -n --arg id "$E2E_CLIENT_ID" --arg secret "$E2E_CLIENT_SECRET" --arg audience "$E2E_AUTH0_AUDIENCE" \
    '{grant_type: "client_credentials", client_id: $id, client_secret: $secret, audience: $audience}' |
    curl -sSf "$E2E_AUTH_BASE_URL/oauth/token" -H 'content-type: application/json' -d @- |
    jq -r .access_token
)

api() { curl -sSfL -H "Authorization: Bearer $token" "$E2E_BASE_URL$1"; }

norad=$(jq -r '.variable[] | select(.key == "testSatellitePrimaryNorad") | .value' postman_collection.json)
event=$(api "/v1/events/?norad_id=$norad&epoch=past&sort_by=tca_time&sort_order=desc&limit=1" | jq -e '.[0]')
short_id=$(jq -r .short_id <<<"$event")
cdm_id=$(api "/v1/events/$short_id/summary?limit=100" |
  jq -er 'map(select(.data_source == "Space-Track CDM")) | .[0].cdm_external_id')
analysed_short_id=$(api "/v1/analyses/?sort_by=tca_time&sort_order=desc&limit=1" | jq -er '.[0].event_short_id')
update_time=$(date -u +%Y-%m-%dT%H:%M:%S)

jq --argjson event "$event" --arg cdm_id "$cdm_id" --arg update_time "$update_time" '
  .event_id = $event.short_id
  | .cdm_id = $cdm_id
  | .tca = $event.tca_time + "Z"
  | .update_time = $update_time + ".000Z"
  | .primary_object.norad_id = $event.primary_object_norad_id
  | .secondary_object.norad_id = $event.secondary_object_norad_id
' analysis_template.json >analysis_upload.json

jq --argjson event "$event" --arg cdm_id "$cdm_id" --arg analysed "$analysed_short_id" --arg update_time "$update_time" '
  .values += [
    {key: "testEventShortId", value: $event.short_id},
    {key: "testCDMId", value: $cdm_id},
    {key: "testSatelliteSecondaryNorad", value: $event.secondary_object_norad_id},
    {key: "testAnalysedEventShortId", value: $analysed},
    {key: "testAnalysisEventShortId", value: $event.short_id},
    {key: "testAnalysisTcaTime", value: $event.tca_time},
    {key: "testAnalysisUpdateTime", value: $update_time}
  ]
' postman_environment.json >run.postman_environment.json

echo "event $short_id (CDM $cdm_id, TCA $(jq -r .tca_time <<<"$event")), analysed event $analysed_short_id"
