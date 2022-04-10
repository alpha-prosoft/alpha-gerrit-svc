#!/bin/bash

set -e 

echo "Building ${BUILD_ID}"

docker build --progress=plain \
	     --no-cache \
	     --build-arg BUILD_ID="${BUILD_ID}" \
	     --build-arg BuildId="${BUILD_ID}" \
	     --build-arg AWS_REGION="${AWS_DEFAULT_REGION}" \
	     -t alpha-gerrit-svc:b${BUILD_ID} \
	     -f Dockerfile .
