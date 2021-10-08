#!/bin/bash

set -eEuo pipefail

pushd "$(dirname "$0")"

sudo rm -f /bin/run-latest-build.sh
sudo rm -f /etc/systemd/system/run-latest-build-systemd@.service
sudo systemctl daemon-reload

popd
