#!/bin/bash
# shellcheck disable=SC2086
set -eou pipefail

_git_token="${GIT_TOKEN:-}"
repo_owner="${1:-}"
repo_name="${2:-}"
git_tag="${3:-}"
asset_filename="${4:-}"
output_filename_path="${5:-}"

usage="usage: ./download-private-release.sh [repo-owner] [repo-name] [git-tag] [asset-filename] [output-filename-path]"
if [[ -z "$_git_token" ]]; then
    echo "Missing environment variable: GIT_TOKEN"
    exit 1
fi
expected="repo_owner repo_name git_tag asset_filename output_filename_path"
for expect in $expected; do
    if [[ -z "${!expect}" ]]; then
      echo "Missing argument $expect"
      echo "$usage"
      exit 1
    fi
done

curl -sL -H "Authorization: token $_git_token" \
    "https://api.github.com/repos/$repo_owner/$repo_name/releases/tags/$git_tag" \
        | jq -r '.assets[] | select(.name == "'$asset_filename'").url' \
        | xargs -I {} curl -sL  -H "Authorization: token $_git_token" -H "Accept:application/octet-stream" -o $output_filename_path {}