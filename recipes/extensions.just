# vim: set ft=just :
# GNOME Shell extensions, user-installed (Extension Manager equivalent).
# Image-shipped extensions (tilingshell, tailscale-qs, appindicator,
# blur-my-shell, gsconnect, caffeine, ...) are NOT listed here: they come
# with the base image on Dakota/Bluefin and stay image-owned.


# Extensions that must be installed at user level on a fresh system.
# Settings for these live in dconf/penguix.ini.
#
# Verified against extensions.gnome.org shell_version_map (2026-11):
# - theme-scheduler@lsbcodes: supports GNOME 50 — replaces the dead
#   nightthemeswitcher (upstream stopped at GNOME 3.38).
# - grand-theft-focus: supports GNOME 50 natively.
# - search-light: latest declares up to GNOME 49 — the installer fails
#   closed on GNOME 50; force it with PENGUIX_FORCE=1 if you want to try.
PENGUIX_USER_EXTENSIONS := "search-light@icedman.github.com theme-scheduler@lsbcodes grand-theft-focus@zalckos.github.com"

# Install + enable every user extension (idempotent). A per-extension
# failure warns and continues, so one dead extension cannot block setup.
[group('Desktop')]
penguix-extensions:
    #!/usr/bin/env bash
    set -euo pipefail
    status=0
    for uuid in {{PENGUIX_USER_EXTENSIONS}}; do
        if ! just penguix-extension-install "$uuid"; then
            echo "WARN: $uuid not installed — setup continues." >&2
            status=1
        fi
    done
    exit $status

# Install one extension from extensions.gnome.org for the running GNOME
# Shell version, into ~/.local/share/gnome-shell/extensions/, then enable it.
[group('Desktop')]
penguix-extension-install UUID:
    #!/usr/bin/env bash
    set -euo pipefail
    exec bash "{{repo_root}}/scripts/install-gnome-extension.sh" "{{UUID}}"

# Disable a user extension without uninstalling it.
[group('Desktop')]
penguix-extension-disable UUID:
    #!/usr/bin/env bash
    gnome-extensions disable "{{UUID}}" && echo "Disabled {{UUID}}"

# Uninstall a user extension entirely.
[group('Desktop')]
penguix-extension-uninstall UUID:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf "$HOME/.local/share/gnome-shell/extensions/{{UUID}}"
    echo "Removed {{UUID}} (log out/in for the shell to forget it)."

# List installed extensions and their enabled state.
[group('Desktop')]
penguix-extensions-list:
    #!/usr/bin/env bash
    gnome-extensions list --enabled | sed 's/^/enabled:  /'
    gnome-extensions list --disabled | sed 's/^/disabled: /'
