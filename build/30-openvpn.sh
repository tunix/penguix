#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

source /ctx/build/copr-helpers.sh

### Install OpenVPN from Official Repository
echo "::group:: Installing OpenVPN client & indicator..."

copr_install_isolated "dsommers/openvpn3" openvpn3-client
copr_install_isolated "grzegorz-gutowski/openvpn3-indicator" openvpn3-indicator

# copy systemd service files for workarounds
cp -r /ctx/custom/openvpn/systemd/*.service /usr/lib/systemd/system/

# copy tmpfiles.d for workarounds
cp -r /ctx/custom/openvpn/tmpfiles.d/* /usr/lib/tmpfiles.d/

# Apply fixes according to my comment at below GitHub issue
# https://github.com/OpenVPN/openvpn3-linux/issues/229#issuecomment-2564890480

systemctl enable openvpn-selinux-workaround.service
systemctl enable openvpn-init-config.service

# no need to check as the command seems to be idempotent
setsebool -P dbus_access_tuntap_device=1

echo "OpenVPN installed successfully"
echo "::endgroup::"
