#!/bin/bash

export BUILD_ID="6"

export TARGET_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')"

./build.sh && ./run.sh


