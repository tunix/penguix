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

# Vendored GNOME Shell extensions load their schemas from their own schemas/
# dir at runtime. Sources committed without a prebuilt gschemas.compiled
# (e.g. copied from a source checkout instead of an EGO zip) crash the
# extension on enable — compile any extension schemas dir that ships only
# XML sources.
for schema_dir in /usr/share/gnome-shell/extensions/*/schemas/; do
    [ -d "${schema_dir}" ] || continue
    if ! [ -f "${schema_dir}gschemas.compiled" ]; then
        glib-compile-schemas "${schema_dir}"
    fi
done

dconf update

systemctl mask systemd-remount-fs.service
systemctl mask zfs-import-cache.service
systemctl mask systemd-udev-settle.service
systemctl mask NetworkManager-wait-online.service

echo "Desktop environment configured successfully"
echo "::endgroup::"
