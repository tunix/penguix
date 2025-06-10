#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

/ctx/system76.sh
/ctx/1password.sh
/ctx/devops.sh
/ctx/openvpn.sh
/ctx/akmod-intel-ipu6.sh

systemctl enable podman.socket
systemctl disable pcscd.socket
