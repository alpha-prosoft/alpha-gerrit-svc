#!/bin/bash

set -e 

echo "Building ${BUILD_ID}"

IMAGE_ID=$(aws ec2 describe-images --filters "Name=name,Values=build-alpha-scm-svc.b${BUILD_ID}" --query 'Images[0].ImageId' --output text)
echo "Image id ${IMAGE_ID}"
aws ec2 deregister-image --image-id ${IMAGE_ID} 2> /dev/null | echo "No image existing"

docker build --progress=plain \
	     --no-cache \
	     --build-arg BUILD_ID="${BUILD_ID}" \
	     -t alpha-scm-svc:b${BUILD_ID} \
	     -f Dockerfile .
