#!/bin/bash

set -eEuo pipefail

NAME="${1}"

if [[ -z "${NAME}" ]]; then
  echo "The \"NAME\" argument is required" > /dev/stderr

  exit 1
fi

sudo journalctl -f -u run-latest-build-systemd@${NAME}.service
