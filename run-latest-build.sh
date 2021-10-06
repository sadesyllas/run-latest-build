#!/bin/bash

set -eEuo pipefail

NAME="${1}"

if [[ -z "${NAME}" ]]; then
  echo "The \"NAME\" argument is required" > /dev/stderr

  exit 1
fi

CACHE_PATH="/tmp/$(basename "$0")"

cd "$(dirname "$0")"

. /etc/run-latest-build-${NAME}.env

FIRST_RUN=1

while true; do
  if [[ ! -d "${BUILD_DIR}" ]]; then
    sleep 5

    continue
  fi

  ls "${BUILD_DIR}" | sort -r | sed -n '3,$p' | xargs -I{} rm -rf "${BUILD_DIR}/{}"

  LATEST_BUILD_NAME="$(ls "${BUILD_DIR}" | sort -r | head -n 1)"

  if [[ -z "${LATEST_BUILD_NAME}" ]]; then
    sleep 5

    continue
  fi

  LATEST_BUILD_DIR="${BUILD_DIR}/${LATEST_BUILD_NAME}"

  RUNNING_BUILD="$(pgrep -f "${KILL_PATTERN}" || true)"

  if [[ -z "${RUNNING_BUILD}" ]] || [[ $FIRST_RUN -eq 1 ]] || [[ ! -f "${CACHE_PATH}/${LATEST_BUILD_NAME}" ]]; then
    FIRST_RUN=0

    echo "Running latest build: ${LATEST_BUILD_NAME}."

    rm -rf "${CACHE_PATH}/*"

    mkdir -p "${CACHE_PATH}"

    touch "${CACHE_PATH}/${LATEST_BUILD_NAME}"

    pushd "${LATEST_BUILD_DIR}"

    pkill -f "${KILL_PATTERN}" || true

    nohup bash -i -c "${COMMAND} &> /tmp/run-latest-build-systemd.log & disown" &> /dev/null &

    popd
  fi

  sleep 5
done

popd