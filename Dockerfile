# syntax = docker/dockerfile:experimental
ARG BUILD_ID
ARG PROJECT_NAME=alpha-scm-svc

FROM ansible-img:b${BUILD_ID}

ENV BUILD_ID ${BUILD_ID}


