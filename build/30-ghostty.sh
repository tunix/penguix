#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

source /ctx/build/copr-helpers.sh

echo "::group:: Installing Ghostty..."

copr_install_isolated "scottames/ghostty" ghostty

echo "Ghostty installed successfully"
echo "::endgroup::"
