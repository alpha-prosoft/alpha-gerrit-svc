#!/bin/bash

set -e 

echo "Going to deploy me some stuff"

export TARGET_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')"
export DOCKER_BUILDKIT=0
export DOCKER_BUILDKIT=1

export LATEST_IMAGE="$(aws ec2 describe-images \
                          --owners self --no-paginate  \
			  | jq -r '.Images[].Name' \
			  | grep build-alpha-gerrit  \
			  | sort | tail -1)"
echo "Last image found: $LATEST_IMAGE"
export BUILD_ID="${LATEST_IMAGE##*.b}"
echo "Deploy build id: $BUILD_ID"

export AWS_DEFAULT_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)


curl https://raw.githubusercontent.com/raiffeisenbankinternational/cbd-jenkins-pipeline/master/ext/deploy.sh > deploy.sh
chmod +x deploy.sh

docker run -it -v /var/run/docker.sock:/var/run/docker.sock \
	  -e TargetAccountId="${TARGET_ACCOUNT_ID}" \
	  -e EnvironmentNameUpper="PIPELINE" \
	  -e ServiceName="alpha-gerrit-svc" \
	  -e BUILD_ID="${BUILD_ID}" \
	  -v $PWD/deploy.sh:/dist/deploy.sh \
	  alpha-gerrit-svc:b${BUILD_ID} /dist/deploy.sh

