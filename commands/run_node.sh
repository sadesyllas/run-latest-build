#!/bin/bash

set -eEuo pipefail

BUILD_DIR="${1}"
MY_NAME="$(basename "$0")"
BUILD_NEEDLE="${BUILD_NEEDLE:-BUILD_NEEDLE}"
MY_PID=$$
VERBOSE=${VERBOSE:-0}

if [[ -z "${BUILD_DIR}" ]]; then
  echo "No build specified." > /dev/stderr

  exit 1
fi

function is_running {
  local PATTERN="$1"

  pgrep -f "${PATTERN}" | grep -v "${MY_PID}" &> /dev/null
}

function is_active_port {
  local SOCKET=$1

  netstat -ntl | awk '{print $4}' | sed -E 's/.*:([0-9]+)$/\1/' | grep $SOCKET &> /dev/null
}

BUILD_NAME="$(basename "${BUILD_DIR}")"

if is_running "${BUILD_NAME}"; then
  [[ $VERBOSE -eq 1 ]] && echo "${BUILD_NAME} is already running."

  exit 0
fi

PORT=${BASE_PORT:-8080}
NODE="${NODE:-node}"

while is_active_port $PORT; do
  PORT=$[${PORT}+1]
done

echo "Running build ${BUILD_NAME} at port ${PORT}."

cd "${BUILD_DIR}"

while ! is_running "${BUILD_NAME}"; do
  nohup bash -i -c "PORT=${PORT} nohup ${NODE} . -- ${BUILD_NEEDLE} ${BUILD_NAME} &> \"/tmp/${MY_NAME}_${BUILD_NAME}.log\" & disown" &> /dev/null & disown

  echo "Waiting for 5 seconds until ${BUILD_NAME} has started running."

  sleep 5
done

echo "${BUILD_NAME} has started running."

while ! is_active_port $PORT; do
  echo "Waiting for 5 seconds until ${BUILD_NAME} is listening on port ${PORT}."

  sleep 5
done

echo "${BUILD_NAME} is listening on port ${PORT}."

echo "Stopping all builds except for ${BUILD_NAME}."

pgrep -af ${BUILD_NEEDLE} | grep -v ${BUILD_NAME} | while read instance; do
  echo "Stopping ${instance}."

  kill -9 $(echo ${instance} | awk '{print $1}')
done || true

echo "All builds except for ${BUILD_NAME} have been stopped."
