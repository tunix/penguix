#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -ouex pipefail

### Configuring desktop environment
echo "::group:: Configuring desktop environment..."

cp -r /ctx/custom/etc /
cp -r /ctx/custom/var /
# Ships gschema overrides, GNOME extensions, image artwork
cp -r /ctx/custom/usr /

# Recompile GSettings schemas (bluefin zz0/zz1 overrides) and rebuild the
# dconf system database so our distro.d keyfiles are compiled into the image
glib-compile-schemas /usr/share/glib-2.0/schemas/
dconf update

systemctl mask systemd-remount-fs.service
systemctl mask zfs-import-cache.service
systemctl mask systemd-udev-settle.service
systemctl mask NetworkManager-wait-online.service

echo "Desktop environment configured successfully"
echo "::endgroup::"
