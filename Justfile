# vim: set ft=just :
# penguix — userspace personalization entry point.
# Conventions mirror /usr/share/ublue-os/just (ujust) so the recipes read the
# same as upstream ones; invoked via this justfile or `just -g` after
# `just penguix-install-global-justfile`.

set allow-duplicate-recipes := true
set ignore-comments := true

repo_root := justfile_directory()

_default:
    #!/usr/bin/env bash
    echo "penguix — userspace personalization (no image layering)"
    just --list --list-heading $'Available commands:\n' --list-prefix $' - '

import "recipes/brew.just"
import "recipes/dconf.just"
import "recipes/extensions.just"
import "recipes/home.just"
import "recipes/system.just"
import? "recipes/work.just"

# One-shot: bring a fresh system to the penguix state. Each step is
# idempotent and asks for confirmation, so this is safe to re-run.
[group('Penguix')]
penguix-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> penguix userspace setup"
    if gum confirm "1/5 Software (brew formulas + casks)?"; then
        just penguix-brew
    fi
    if gum confirm "2/5 Flatpaks (Brewfile DSL)?"; then
        just penguix-flatpaks
    fi
    if gum confirm "3/5 Desktop settings (per-user dconf)?"; then
        just penguix-dconf-apply
    fi
    if gum confirm "4/5 GNOME Shell extensions (user-installed)?"; then
        just penguix-extensions
    fi
    if gum confirm "5/5 Home fixes (Brave flags, autostart)?"; then
        just penguix-home
    fi
    echo "Done. Log out/in (or restart GNOME Shell) so extension and dconf changes fully apply."

# Install this Justfile as the global justfile (~/.config/just/justfile),
# so recipes run via `just -g <recipe>` from any directory.
[group('Penguix')]
penguix-install-global-justfile:
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{repo_root}}/Justfile"
    link="$HOME/.config/just/justfile"
    if [ -e "$link" ] && [ ! -L "$link" ]; then
        echo "$link exists and is not a symlink; refusing to overwrite." >&2
        exit 1
    fi
    mkdir -p "$HOME/.config/just"
    ln -sfn "$target" "$link"
    echo "Global justfile linked: $link -> $target"
    echo "Try: just -g penguix-setup"

# Show what of the penguix state is already applied.
[group('Penguix')]
penguix-status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "brew:"
    command -v brew >/dev/null && brew list --formula -1 | wc -l | xargs echo "  formulas:" || echo "  brew not installed yet"
    echo "flatpaks (user):"
    flatpak list --user --app --columns=application 2>/dev/null | sed 's/^/  /'
    echo "user shell extensions:"
    ls -1 "$HOME/.local/share/gnome-shell/extensions" 2>/dev/null | sed 's/^/  /'
    echo "dconf user settings: $([ -s "$HOME/.config/dconf/user" ] 2>/dev/null && echo present || echo empty)"
    echo "brave flags: $([ -f "$HOME/.var/app/com.brave.Browser/config/brave-flags.conf" ] && echo deployed || echo missing)"
