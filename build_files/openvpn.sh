#!/bin/bash

set -ouex pipefail

echo "Installing OpenVPN Client & Indicator..."

dnf -y copr enable \
    dsommers/openvpn3

dnf -y copr enable \
    grzegorz-gutowski/openvpn3-indicator

dnf install -y \
    openvpn3-client \
    openvpn3-indicator

# Apply fixes according to my comment at below GitHub issue
# https://github.com/OpenVPN/openvpn3-linux/issues/229#issuecomment-2564890480

systemctl enable openvpn-selinux-workaround.service
systemctl enable openvpn-init-config.service

# no need to check as the command seems to be idempotent
setsebool -P dbus_access_tuntap_device=1
