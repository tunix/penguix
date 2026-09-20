# vim: set ft=just :
#######################
### penguix-desktop.just
#######################

# Enables touchpad history navigation scroll & wayland support for Brave Browser
[group('Fixes')]
brave-wayland-fixes:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.var/app/com.brave.Browser/config"
    cat <<'EOF' >"${HOME}/.var/app/com.brave.Browser/config/brave-flags.conf"
    --enable-features=UseOzonePlatform,TouchpadOverscrollHistoryNavigation
    --ozone-platform=wayland
    EOF

# Enables 1Password desktop app integration for Brave Browser (flatpak)
[group('Fixes')]
brave-1password-fix:
    #!/usr/bin/env bash
    set -euo pipefail
    SRC="${HOME}/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    DEST="${HOME}/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    if [ ! -f "${SRC}/1PasswordWrapper.sh" ] || [ ! -f "${SRC}/com.1password.1password.json" ]; then
    	echo "1Password native messaging files not found in ${SRC}." >&2
    	echo "Install the GUI first: brew install --cask ublue-os/tap/1password-gui-linux" >&2
    	exit 1
    fi
    # Allow Brave to spawn host processes via flatpak-spawn --host (sandbox escape for this app)
    flatpak override --user --talk-name=org.freedesktop.Flatpak com.brave.Browser
    # Copy wrapper + manifest into the flatpak's own NMH dir; point manifest at the sandbox-readable path
    mkdir -p "${DEST}"
    install -m 755 "${SRC}/1PasswordWrapper.sh" "${DEST}/1PasswordWrapper.sh"
    sed -E "s|\"path\": \".*\"|\"path\": \"${DEST}/1PasswordWrapper.sh\"|" \
    	"${SRC}/com.1password.1password.json" >"${DEST}/com.1password.1password.json"
    chmod 644 "${DEST}/com.1password.1password.json"
    echo "Done. Restart Brave completely (flatpak kill com.brave.Browser) to activate."

# Syncs dconf settings for local user
[group('Desktop')]
sync-dconf:
    dconf reset -f /

# Recompiles GSettings schemas so zz9-penguix-modifications.gschema.override takes effect
# without reinstalling the image
[group('Desktop')]
sync-schemas:
    #!/usr/bin/env bash
    set -euo pipefail

    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
    echo "GSettings defaults recompiled. Keys you explicitly set still win;"
    echo "run 'gsettings reset <schema> <key>' to fall back to the new default."

# One-shot: recompiles GSettings schemas and resets user dconf so every key
# falls back to the image default. WARNING: 'dconf reset -f /' wipes ALL
# user-level settings (not just desktop ones) — this mirrors sync-dconf.
[group('Desktop')]
desktop-defaults-apply:
    #!/usr/bin/env bash
    set -euo pipefail

    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
    dconf reset -f /
    echo "Image desktop defaults applied: schemas recompiled, user dconf reset."
    echo "Log out/in (or restart apps) so everything picks up the new values."

# Syncs skel for local user
[group('Desktop')]
sync-skel:
    #!/usr/bin/env bash

    set -euo pipefail

    SRC=/etc/skel
    DEST=$HOME

    if [ ! -d "$SRC" ]; then
    	echo "$SRC not found" >&2
    	exit 1
    fi

    rsync -avz "$SRC/" "$DEST/"
