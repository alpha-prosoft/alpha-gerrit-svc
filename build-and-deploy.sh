#!/bin/bash

set -euo pipefail

export RESOURCE_NAME=${1:-gerrit}
export ENV_NAME_UPPER=${2:-PIPELINE}

target_dir=${PWD}/target
mkdir -p $target_dir

for script in build.sh run.sh; do
  curl -fsS -H 'Cache-Control: no-cache' \
    https://raw.githubusercontent.com/alpha-prosoft/cbd-jenkins-pipeline/master/ext/${script} \
    >${target_dir}/${script}
  chmod +x ${target_dir}/${script}
done

source ${target_dir}/build.sh "${RESOURCE_NAME}" "${ENV_NAME_UPPER}"

source ${target_dir}/run.sh "${RESOURCE_NAME}" "${ENV_NAME_UPPER}"
