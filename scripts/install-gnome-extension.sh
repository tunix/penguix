#!/usr/bin/env bash
# Install a GNOME Shell extension from extensions.gnome.org at user level,
# for the running GNOME Shell major version, into
# ~/.local/share/gnome-shell/extensions/ and enable it.
#
# Usage: install-gnome-extension.sh <uuid> [shell-major-version]
#
# Compat is resolved from the extension's shell_version_map; the exact
# compatible version is downloaded via its version_tag URL. If the extension
# has no version for the running shell the script fails closed; set
# PENGUIX_FORCE=1 to install the latest version anyway.
#
# Everything happens inside $HOME — nothing touches the OS image.

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <extension-uuid> [shell-major-version]" >&2
    exit 2
fi

UUID="$1"
EGO="https://extensions.gnome.org"
if [ $# -ge 2 ]; then
    GNOME_MAJOR="$2"
else
    GNOME_MAJOR="$(gnome-shell --version | awk '{print $NF}' | cut -d. -f1)"
fi
DEST="$HOME/.local/share/gnome-shell/extensions/${UUID}"

echo "==> ${UUID} (target GNOME Shell ${GNOME_MAJOR})"

if [ -d "${DEST}" ]; then
    echo "    already installed at ${DEST}"
else
    QUERY_JSON="$(curl -fsSL "${EGO}/extension-query/?search=${UUID}")"
    EXT_JSON="$(jq -c --arg uuid "${UUID}" \
        '.extensions[] | select(.uuid == $uuid)' <<<"${QUERY_JSON}" | head -n1)"
    if [ -z "${EXT_JSON}" ]; then
        echo "ERROR: ${UUID} not found on extensions.gnome.org" >&2
        exit 1
    fi

    VERSION_PK="$(jq -r --arg sv "${GNOME_MAJOR}" \
        '.shell_version_map[$sv].pk // empty' <<<"${EXT_JSON}")"
    if [ -z "${VERSION_PK}" ]; then
        MAX_SV="$(jq -r '.shell_version_map | keys | max' <<<"${EXT_JSON}")"
        if [ "${PENGUIX_FORCE:-0}" = "1" ]; then
            echo "WARN: ${UUID} declares support up to GNOME ${MAX_SV}, not ${GNOME_MAJOR}." >&2
            echo "      Installing the latest version anyway (PENGUIX_FORCE=1)." >&2
        else
            echo "ERROR: ${UUID} supports GNOME up to ${MAX_SV}; nothing for ${GNOME_MAJOR}." >&2
            echo "       To install anyway: PENGUIX_FORCE=1 $0 ${UUID}" >&2
            exit 1
        fi
    fi

    INFO_JSON="$(curl -fsSL "${EGO}/extension-info/?pk=$(jq -r '.pk' <<<"${EXT_JSON}")&shell_version=${GNOME_MAJOR}")"
    VERSION="$(jq -r '.version' <<<"${INFO_JSON}")"
    ZIP_URL="$(jq -r '.download_url' <<<"${INFO_JSON}")"
    if [ -z "${ZIP_URL}" ] || [ "${ZIP_URL}" = "null" ]; then
        echo "ERROR: no downloadable version of ${UUID} for GNOME ${GNOME_MAJOR}" >&2
        exit 1
    fi

    workdir="$(mktemp -d)"
    trap 'rm -rf -- "${workdir}"' EXIT
    curl -fsSL -o "${workdir}/ext.zip" "${EGO}${ZIP_URL}"
    mkdir -p "${DEST}"
    if command -v unzip >/dev/null; then
        unzip -qo "${workdir}/ext.zip" -d "${DEST}"
    elif command -v bsdtar >/dev/null; then
        bsdtar -xf "${workdir}/ext.zip" -C "${DEST}"
    else
        python3 -c 'import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' \
            "${workdir}/ext.zip" "${DEST}"
    fi
    if [ -d "${DEST}/schemas" ]; then
        glib-compile-schemas "${DEST}/schemas"
    fi
    echo "    installed version ${VERSION} -> ${DEST}"
fi

gnome-extensions enable "${UUID}" && echo "    enabled"
echo "    (On X11 the shell restarts on enable; on Wayland log out/in if it does not load.)"
