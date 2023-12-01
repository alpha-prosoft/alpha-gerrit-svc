ARG BUILD_ID
ARG PROJECT_NAME=alpha-gerrit-svc

FROM alphaprosoft/ansible-img:b373

COPY deploy.sh /dist/deploy.sh

ENV BUILD_ID ${BUILD_ID}


