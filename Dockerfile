ARG BUILD_ID

ARG PROJECT_NAME
ARG SERVICE_NAME=gerrit

ARG AWS_REGION
ARG AWS_DEFAULT_REGION
ARG DOCKER_REGISTRY_URL=docker.io
ARG ANSIBLE_LOG_LEVEL="-v"
FROM ${DOCKER_REGISTRY_URL}/alphaprosoft/ansible-img:latest

ENV BUILD_ID ${BUILD_ID}


