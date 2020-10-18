# syntax = docker/dockerfile:experimental
ARG BUILD_ID
ARG PROJECT_NAME=alpha-dynamodb-svc

FROM alphaprosoft/ansible-img:b93

ENV BUILD_ID ${BUILD_ID}


