#!/bin/bash

set -eEuo pipefail

NAME="${1}"

if [[ -z "${NAME}" ]]; then
  echo "The \"NAME\" argument is required" > /dev/stderr

  exit 1
fi

CONFIG_FILE="run-latest-build-${NAME}.env"

sudo rm -f /etc/run-latest-build-${NAME}.env
sudo systemctl stop run-latest-build-systemd@${NAME}.service
sudo systemctl disable run-latest-build-systemd@${NAME}.service
