# vim: set ft=just :
# User-level file deployments — the old /etc/skel content, applied to $HOME.


# Deploy every home/ file into its $HOME-relative location (idempotent).
[group('Fixes')]
penguix-home:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v rsync >/dev/null; then
        rsync -rcpv "{{repo_root}}/home/" "$HOME/"
    else
        # rsync is not guaranteed on bootc images; cp is fine for a one-shot deploy
        cp -Rv "{{repo_root}}/home/." "$HOME/"
    fi
    echo "Home files deployed (brave-flags, autostart entries, theme-sync watcher)."
    just --justfile "{{repo_root}}/Justfile" penguix-theme-sync
    just --justfile "{{repo_root}}/Justfile" penguix-sun-scheduler

# Re-evaluate color-scheme every minute from local sunrise/sunset. Location
# comes from night-light-last-coordinates (gsd writes it when Night Light
# follows the system location); fallback: fixed 09:00 light / 18:00 dark.
# Fast-exits when the timer is already enabled.
[group('Fixes')]
penguix-sun-scheduler:
    #!/usr/bin/env bash
    set -euo pipefail
    state="$(systemctl --user is-enabled penguix-sun-scheduler.timer 2>/dev/null || true)"
    if [ "$state" = "enabled" ]; then
        echo "penguix-sun-scheduler already enabled; nothing to do."
        exit 0
    fi
    if ! systemctl --user daemon-reload 2>/dev/null; then
        echo "WARN: no user systemd session available; run 'just penguix-sun-scheduler' from a desktop session later." >&2
        exit 0
    fi
    systemctl --user enable --now penguix-sun-scheduler.timer
    echo "penguix-sun-scheduler enabled (color-scheme follows local sunrise/sunset)."
    just --justfile "{{repo_root}}/Justfile" penguix-bibata

# Install a Bibata cursor theme variant into ~/.local/share/icons (userspace)
# and select it. Fast-exits when the variant is already installed.
# Variants: Modern/Original x Ice (white)/Classic (black)/Amber (yellow),
# optional -Right (right-pointing). Release pinned: ful1e5/Bibata_Cursor v2.0.7.
[group('Fixes')]
penguix-bibata variant='Bibata-Modern-Ice':
    #!/usr/bin/env bash
    set -euo pipefail
    dest="$HOME/.local/share/icons/{{variant}}"
    if [ -f "$dest/index.theme" ]; then
        echo "Bibata '{{variant}}' already installed; nothing to do."
    else
        ver="v2.0.7"
        url="https://github.com/ful1e5/Bibata_Cursor/releases/download/${ver}/{{variant}}.tar.xz"
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        echo "Downloading Bibata {{variant}} (${ver})..."
        curl -fsSL -o "$tmp/theme.tar.xz" "$url"
        mkdir -p "$HOME/.local/share/icons"
        tar -xf "$tmp/theme.tar.xz" -C "$HOME/.local/share/icons/"
        [ -f "$dest/index.theme" ] || {
            echo "ERROR: unexpected tarball layout (no $dest/index.theme)" >&2
            exit 1
        }
        echo "Installed -> $dest"
    fi
    current="$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || true)"
    if [ "$current" = "'{{variant}}'" ]; then
        echo "cursor-theme already {{variant}}; nothing to do."
    else
        gsettings set org.gnome.desktop.interface cursor-theme '{{variant}}'
        echo "cursor-theme -> {{variant}} (log out/in for every app to pick it up)"
    fi

# Keep CLI themes (zellij/k9s/bat/nvim) in sync with GNOME color-scheme.
# Deploys the watcher files (penguix-home does) and enables the systemd
# user unit. The dotfiles script it calls must exist and be executable;
# everything else degrades gracefully.
# Fast-exits when the unit is already enabled.
[group('Fixes')]
penguix-theme-sync:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! [ -x "$HOME/.local/bin/toggle-color-preferences.sh" ]; then
        echo "WARN: ~/.local/bin/toggle-color-preferences.sh missing (deploy from dotfiles);"
        echo "      theme-sync will start but only log until the script appears." >&2
    fi
    state="$(systemctl --user is-enabled penguix-theme-sync.service 2>/dev/null || true)"
    if [ "$state" = "enabled" ]; then
        echo "penguix-theme-sync already enabled; nothing to do."
        exit 0
    fi
    if ! systemctl --user daemon-reload 2>/dev/null; then
        echo "WARN: no user systemd session available; run 'just penguix-theme-sync' from a desktop session later." >&2
        exit 0
    fi
    systemctl --user enable --now penguix-theme-sync.service
    echo "penguix-theme-sync enabled (CLI themes now follow GNOME color-scheme)."

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
