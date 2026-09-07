#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -ouex pipefail

### Configuring desktop environment
echo "::group:: Configuring desktop environment..."

cp -r /ctx/custom/etc /
cp -r /ctx/custom/var /
# cp -r /ctx/custom/usr /

systemctl mask systemd-remount-fs.service
systemctl mask zfs-import-cache.service
systemctl mask systemd-udev-settle.service
systemctl mask NetworkManager-wait-online.service

echo "Desktop environment configured successfully"
echo "::endgroup::"
