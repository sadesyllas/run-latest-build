#!/bin/bash

set -eEuo pipefail

BUILD_TAG="${1}"
VERBOSE=${VERBOSE:-0}

if [[ -z "${BUILD_TAG}" ]]; then
  echo "The \"BUILD_TAG\" argument is required" > /dev/stderr

  exit 1
fi

cd "$(dirname "$0")"

. /etc/run-latest-build-${BUILD_TAG}.env

while true; do
  if [[ ! -d "${BUILD_DIR}" ]]; then
    sleep 5

    continue
  fi

  # Keep only two most recent builds.
  ls "${BUILD_DIR}" | sort -r | sed -n '3,$p' | xargs -I{} rm -rf "${BUILD_DIR}/{}"

  LATEST_BUILD_NAME="$(ls "${BUILD_DIR}" | sort -r | head -n 1)"

  if [[ -z "${LATEST_BUILD_NAME}" ]]; then
    sleep 5

    continue
  fi

  LATEST_BUILD="${BUILD_DIR}/${LATEST_BUILD_NAME}"

  [[ $VERBOSE -eq 1 ]] && echo "Running latest build: ${LATEST_BUILD_NAME}."

  bash -c "${COMMAND_ENVIRONMENT} ${COMMAND} \"${LATEST_BUILD}\""

  sleep 5
done
