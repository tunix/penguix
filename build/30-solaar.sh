#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

### Install solaar from Official Repository
echo "::group:: Installing solaar..."

dnf install -y solaar solaar-udev
pip3 install --target "$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')" hid-parser

echo "solaar installed successfully"
echo "::endgroup::"
