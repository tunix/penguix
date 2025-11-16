#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

### Install solaar from Official Repository
echo "::group:: Installing solaar..."

dnf5 install -y solaar solaar-udev

echo "solaar installed successfully"
echo "::endgroup::"
