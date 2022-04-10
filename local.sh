#!/bin/bash

export TARGET_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')"
export DOCKER_BUILDKIT=0
export DOCKER_BUILDKIT=1

export TARGET=ubuntu@${1}
if [[ "${1:-}" != "" ]]; then
  export DOCKER_HOST=ssh://${TARGET}
fi
export BUILD_ID="7"

export AWS_DEFAULT_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
export TARGET_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')"

./build.sh && ./run.sh


