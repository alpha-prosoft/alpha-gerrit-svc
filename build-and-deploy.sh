#!/bin/bash

set -euo pipefail

export PROJECT_NAME=${1}
export ENV_NAME_UPPER=${2:-PIPELINE}

target_dir=${PWD}/target
mkdir -p $target_dir

curl -H 'Cache-Control: no-cache' \
  https://raw.githubusercontent.com/alpha-prosoft/cbd-jenkins-pipeline/master/ext/build.sh \
  >$target_dir/build.sh

chmod +x ${target_dir}/build.sh

source ${target_dir}/build.sh ${PROJECT_NAME} "gerrit" "${ENV_NAME_UPPER}"
