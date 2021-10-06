#!/bin/bash

set -eEuo pipefail

NAME="${1}"

if [[ -z "${NAME}" ]]; then
  echo "The \"NAME\" argument is required" > /dev/stderr

  exit 1
fi

CONFIG_FILE="run-latest-build-${NAME}.env"

pushd "$(dirname "$0")"

sudo cp -f ./${CONFIG_FILE} /etc/${CONFIG_FILE}
sudo chown root:root /etc/${CONFIG_FILE}
sudo systemctl enable run-latest-build-systemd@${NAME}.service
sudo systemctl start run-latest-build-systemd@${NAME}.service

popd
