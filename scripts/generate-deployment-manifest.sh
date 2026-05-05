#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/generate-deployment-manifest.sh [--bucket BUCKET] [--year YYYY] [--profile PROFILE] [--upload]

Generates a year-scoped deployment history manifest from existing .txt files in S3.

Examples:
  scripts/generate-deployment-manifest.sh --bucket mys-deployment-history-dev-00b8a
  scripts/generate-deployment-manifest.sh --bucket mys-deployment-history-dev-00b8a --year 2026 --upload

Options:
  --bucket BUCKET     S3 bucket containing deployment .txt files.
                      Can also be set with DEPLOYMENT_HISTORY_BUCKET.
  --year YYYY         Manifest year. Defaults to the current UTC year.
  --profile PROFILE   AWS CLI profile. Defaults to AWS_PROFILE, then uksa-mys-dev-env.
  --upload            Upload manifest-YYYY.json back to the bucket.
  -h, --help          Show this help.
USAGE
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

year="$(date -u +'%Y')"
bucket="${DEPLOYMENT_HISTORY_BUCKET:-}"
profile="${AWS_PROFILE:-uksa-mys-dev-env}"
upload=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bucket)
      bucket="${2:-}"
      shift 2
      ;;
    --year)
      year="${2:-}"
      shift 2
      ;;
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --upload)
      upload=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$bucket" ]]; then
  echo "Bucket is required. Pass --bucket or set DEPLOYMENT_HISTORY_BUCKET." >&2
  exit 1
fi

if [[ ! "$year" =~ ^[0-9]{4}$ ]]; then
  echo "Year must be a four digit value, got: $year" >&2
  exit 1
fi

require_command aws
require_command jq

aws_args=()
if [[ -n "$profile" ]]; then
  aws_args+=(--profile "$profile")
fi

manifest_file="manifest-${year}.json"
tmp_dir="$(mktemp -d)"
entries_file="${tmp_dir}/entries.jsonl"
keys_file="${tmp_dir}/keys.txt"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Listing .txt deployment records in s3://${bucket}"
aws "${aws_args[@]}" s3api list-objects-v2 \
  --bucket "$bucket" \
  --output json |
  jq -r '.Contents[]?.Key | select(endswith(".txt"))' > "$keys_file"

touch "$entries_file"

while IFS= read -r key; do
  [[ -n "$key" ]] || continue

  local_file="${tmp_dir}/objects/${key}"
  mkdir -p "$(dirname "$local_file")"
  aws "${aws_args[@]}" s3 cp "s3://${bucket}/${key}" "$local_file" >/dev/null

  display_date="$(sed -n '1p' "$local_file")"
  commit_id="$(sed -n '2p' "$local_file")"
  environment_name="$(sed -n '3p' "$local_file")"

  deployed_at="$(
    printf '%s\n' "$display_date" |
      sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})[ T]([0-9]{2}):([0-9]{2}):([0-9]{2}).*$/\1-\2-\3T\4:\5:\6Z/'
  )"

  if [[ ! "$deployed_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    echo "Skipping ${key}: unsupported date format '${display_date}'" >&2
    continue
  fi

  if [[ "${deployed_at:0:4}" != "$year" ]]; then
    continue
  fi

  jq -cn \
    --arg key "$key" \
    --arg deployedAt "$deployed_at" \
    --arg commitId "$commit_id" \
    --arg environmentName "$environment_name" \
    '{
      key: $key,
      deployedAt: $deployedAt,
      commitId: $commitId,
      environmentName: $environmentName
    }' >> "$entries_file"
done < "$keys_file"

if [[ -s "$entries_file" ]]; then
  jq -s 'unique_by(.key) | sort_by(.deployedAt) | reverse' "$entries_file" > "$manifest_file"
else
  printf '[]\n' > "$manifest_file"
fi

entry_count="$(jq 'length' "$manifest_file")"
echo "Wrote ${manifest_file} with ${entry_count} entries"

if [[ "$upload" == true ]]; then
  aws "${aws_args[@]}" s3 cp "$manifest_file" "s3://${bucket}/${manifest_file}" \
    --content-type "application/json" \
    --cache-control "max-age=60, must-revalidate"
  echo "Uploaded s3://${bucket}/${manifest_file}"
fi
