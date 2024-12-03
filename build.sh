#!/bin/bash

set -e 

echo "Building ${BUILD_ID}"
set -e 

SESSION_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

ROLE_NAME=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
CREDENTIALS=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)

export AWS_DEFAULT_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" \
             http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')
export TARGET_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')"

export DOCKER_BUILDKIT=0
export DOCKER_BUILDKIT=1

export LATEST_IMAGE="$(aws ec2 describe-images \
                          --owners self --no-paginate  \
			  | jq -r '.Images[].Name' \
			  | grep build-alpha-gerrit  \
			  | sort | tail -1)"

echo "Last image found: $LATEST_IMAGE"

if [[ "$LATEST_IMAGE" == "" ]]; then
  export BUILD_ID="0"
else
  export BUILD_ID="${LATEST_IMAGE##*.b}"
fi
export BUILD_ID=$((BUILD_ID+1))
echo "New build id: $BUILD_ID"

      
docker build --progress=plain \
	     --no-cache \
	     --build-arg BUILD_ID="${BUILD_ID}" \
	     --build-arg BuildId="${BUILD_ID}" \
	     --build-arg AWS_REGION="${AWS_DEFAULT_REGION}" \
      	     --build-arg DOCKER_REGISTRY_URL="${DOCKER_REGISTRY_URL}" \
	     -t alpha-gerrit-svc:b${BUILD_ID} \
	     -f Dockerfile .
