#! /bin/bash

DOCKER_PATH=$(sed -e 's|^.*://||' <<< $DOCKER_HOST)
echo "DOCKER_PATH=${DOCKER_PATH}" > .env
