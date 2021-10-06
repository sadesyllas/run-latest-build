#!/bin/bash

set -eEuo pipefail

pushd "$(dirname "$0")"

sudo cp -f ./run-latest-build.sh /bin/run-latest-build.sh
sudo chown root:root /bin/run-latest-build.sh
sudo chmod a+x /bin/run-latest-build.sh
sudo cp -f ./run-latest-build-systemd@.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/run-latest-build-systemd@.service
sudo systemctl daemon-reload

popd
