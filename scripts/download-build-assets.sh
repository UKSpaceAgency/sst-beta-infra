#!/bin/bash
set -eou pipefail

export GITHUB_BE_OWNER="the-psc"
export GITHUB_BE_REPO="sst-beta-python-backend"
export GITHUB_RELEASE_TAG="latest"
export GITHUB_BE_ASSET="be.zip"
export GITHUB_OWNER="UKSpaceAgency"
export GITHUB_FE_REPO="sst-beta"
export GITHUB_FE_APP_ASSET="app.zip"
export GITHUB_FE_API_ASSET="api.zip"

# BE Asset
echo "$(date '+%d/%m/%Y %H:%M:%S') Downloading BE Asset..."
. ./scripts/download-private-release.sh $GITHUB_BE_OWNER $GITHUB_BE_REPO $GITHUB_RELEASE_TAG $GITHUB_BE_ASSET $GITHUB_BE_ASSET
echo "$(date '+%d/%m/%Y %H:%M:%S') Downloaded"

# FE APP Asset
echo "$(date '+%d/%m/%Y %H:%M:%S') Downloading FE APP Asset"
. ./scripts/download-private-release.sh $GITHUB_OWNER $GITHUB_FE_REPO $GITHUB_RELEASE_TAG $GITHUB_FE_APP_ASSET $GITHUB_FE_APP_ASSET
echo "$(date '+%d/%m/%Y %H:%M:%S') Downloaded"

# FE API Asset
echo "$(date '+%d/%m/%Y %H:%M:%S') Downloading FE API Asset"
. ./scripts/download-private-release.sh $GITHUB_OWNER $GITHUB_FE_REPO $GITHUB_RELEASE_TAG $GITHUB_FE_API_ASSET $GITHUB_FE_API_ASSET
echo "$(date '+%d/%m/%Y %H:%M:%S') Downloaded"
