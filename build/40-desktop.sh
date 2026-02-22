#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

### Configuring desktop environment
echo "::group:: Configuring desktop environment..."

cp -r /ctx/custom/etc /
cp -r /ctx/custom/usr /

echo "Desktop environment configured successfully"
echo "::endgroup::"
