#!/bin/bash


export TARGET=ubuntu@${1}
export DOCKER_HOST=ssh://${TARGET}
export BUILD_ID="3"

./build.sh && ./run.sh
