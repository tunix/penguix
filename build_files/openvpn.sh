#!/bin/bash

set -ouex pipefail

echo "Installing OpenVPN Client & Indicator..."

dnf5 -y copr enable \
    dsommers/openvpn3

dnf5 -y copr enable \
    grzegorz-gutowski/openvpn3-indicator

dnf5 install -y \
    openvpn3-client \
    openvpn3-indicator

systemctl enable openvpn-workaround.service
