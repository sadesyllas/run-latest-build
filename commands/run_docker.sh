#!/bin/bash

set -eEuo pipefail

BUILD_DIR="${1}"
REPLICAS=${REPLICAS:-1}
MY_NAME="$(basename "$0")"
MY_PID=$$
VERBOSE=${VERBOSE:-0}

if [[ -z "${BUILD_DIR}" ]]; then
  echo "No build specified." > /dev/stderr

  exit 1
fi

function count_replicas {
  local BUILD_TAG="$1"

  echo -n $(docker ps -q --filter label="build-tag=${BUILD_TAG}" | wc -l)
}

function is_running {
  local BUILD_TAG="$1"
  local PORT="$2"

  [[ -n "$(docker ps -lq --filter label="build-tag=${BUILD_TAG}" --filter label="port=${PORT}")" ]]
}

function is_active_port {
  local SOCKET=$1

  netstat -ntl | awk '{print $4}' | sed -E 's/.*:([0-9]+)$/\1/' | grep $SOCKET &> /dev/null
}

BUILD_TAG="$(basename "${BUILD_DIR}")"

RUNNING_REPLICAS=$[$(count_replicas "${BUILD_TAG}")]

if [[ $RUNNING_REPLICAS -ge $REPLICAS ]]; then
  [[ $VERBOSE -eq 1 ]] && \
    echo \
      "Build ${BUILD_TAG} already has ${RUNNING_REPLICAS} running replicas(s)" \
      "(requested ${REPLICAS} running replica(s))."

  exit 0
fi

if [[ -z "$(docker images -q --filter label="build-needle=${BUILD_NEEDLE}" --filter label="build-tag=${BUILD_TAG}")" ]]; then
  echo "Image ${BUILD_NEEDLE}:${BUILD_TAG} does not exist."

  exit 0
fi

REMAINING_REPLICAS=$[$REPLICAS - $RUNNING_REPLICAS]
REMAINING_REPLICA=0

while [[ $REMAINING_REPLICA -lt $REMAINING_REPLICAS ]]; do
  echo "Running $[$REMAINING_REPLICAS - $REMAINING_REPLICA] remaining build replicas."

  REMAINING_REPLICA=$[$REMAINING_REPLICA + 1]

  PORT=${BASE_PORT}

  while is_active_port $PORT; do
    PORT=$[${PORT}+1]
  done

  echo "Running remaining build ${BUILD_TAG} replica ${REMAINING_REPLICA} on port ${PORT}."

  while ! is_running "${BUILD_TAG}" "${PORT}"; do
    nohup bash -i -c \
      "docker run --rm -d --name=${BUILD_NEEDLE}-${BUILD_TAG}-${PORT} --label port=${PORT} -p ${PORT}:${CONTAINER_PORT} ${BUILD_NEEDLE}:${BUILD_TAG} &> \"/tmp/${MY_NAME}_${BUILD_TAG}.log\"" \
      &> /dev/null & disown

    echo \
      "Waiting for 5 seconds until build ${BUILD_TAG} remaining" \
      "replica ${REMAINING_REPLICA} has started running."

    sleep 5
  done

  echo "Build ${BUILD_TAG} remaining replica ${REMAINING_REPLICA} has started running."

  while ! is_active_port $PORT; do
    echo \
      "Waiting for 5 seconds until build ${BUILD_TAG} remaining" \
      "replica ${REMAINING_REPLICA} is listening on port ${PORT}."

    sleep 5
  done

  echo "Build ${BUILD_TAG} remaining replica ${REMAINING_REPLICA} is listening on port ${PORT}."
done

echo "Stopping all builds except for ${BUILD_TAG}."

docker ps --filter label="build-needle=${BUILD_NEEDLE}" --format 'id={{ .ID }} tag={{ .Label "build-tag" }}' \
  | (grep -v "tag=${BUILD_TAG}" || true) \
  | awk '{sub(/id=/, "", $1); print $1}' \
  | while read instance; do
    echo "Stopping container with id ${instance}."

    docker kill $instance
  done || true

echo "All builds except for ${BUILD_TAG} have been stopped."

echo "Pruning stopped containers and unused images."

sleep 2.5

docker container prune -f

sleep 2.5

docker image prune -af

echo "Stopped containers and unused images have been pruned."
