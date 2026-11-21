# vim: set ft=just :
# User-level file deployments — the old /etc/skel content, applied to $HOME.


# Deploy every home/ file into its $HOME-relative location (idempotent).
[group('Fixes')]
penguix-home:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v rsync >/dev/null; then
        rsync -rcv "{{repo_root}}/home/" "$HOME/"
    else
        # rsync is not guaranteed on bootc images; cp is fine for a one-shot deploy
        cp -Rv "{{repo_root}}/home/." "$HOME/"
    fi
    echo "Home files deployed (brave-flags, autostart entries)."

# Deploy Brave flatpak flags (Wayland + PipeWire camera etc.).
# Fast-exits when the deployed file already matches.
[group('Fixes')]
brave-wayland-fixes:
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{repo_root}}/home/.var/app/com.brave.Browser/config/brave-flags.conf"
    dest="$HOME/.var/app/com.brave.Browser/config/brave-flags.conf"
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        echo "Brave flags already deployed; nothing to do."
        exit 0
    fi
    install -D -m 644 "$src" "$dest"

# Enable 1Password desktop integration for the Brave flatpak. Requires the
# 1Password GUI installed via brew cask first.
[group('Fixes')]
brave-1password-fix:
    #!/usr/bin/env bash
    set -euo pipefail
    SRC="$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    DEST="$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    if [ ! -f "${SRC}/1PasswordWrapper.sh" ] || [ ! -f "${SRC}/com.1password.1password.json" ]; then
        echo "1Password native messaging files not found in ${SRC}." >&2
        echo "Install the GUI first: just penguix-brew-gui" >&2
        exit 1
    fi
    flatpak override --user --talk-name=org.freedesktop.Flatpak com.brave.Browser
    mkdir -p "${DEST}"
    install -m 755 "${SRC}/1PasswordWrapper.sh" "${DEST}/1PasswordWrapper.sh"
    sed -E "s|\"path\": \".*\"|\"path\": \"${DEST}/1PasswordWrapper.sh\"|" \
        "${SRC}/com.1password.1password.json" >"${DEST}/com.1password.1password.json"
    chmod 644 "${DEST}/com.1password.1password.json"
    echo "Done. Restart Brave completely (flatpak kill com.brave.Browser) to activate."
