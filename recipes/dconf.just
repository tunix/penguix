# vim: set ft=just :
# Per-user desktop settings. dconf load merges into the USER database
# (~/.config/dconf/user) — never the system db, so every setting stays
# user-level and survives OS rebases/switches.


# dconf/ holds one keyfile per topic: desktop.ini, shell.ini,
# extensions.ini, apps.ini. All are applied by penguix-dconf-apply.


# Apply every dconf/*.ini into the user database (idempotent).
[group('Desktop')]
penguix-dconf-apply:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in "{{repo_root}}"/dconf/*.ini; do
        echo "==> dconf load: $(basename "$f")"
        dconf load / < "$f"
    done
    echo "dconf user settings applied. Log out/in (or restart apps) for some keys to take effect."

# Write the keys that differ from factory defaults back into the repo, so
# manual GUI tweaks can be reviewed and committed (output is a proposal;
# nothing is overwritten automatically).
[group('Desktop')]
penguix-dconf-backup:
    #!/usr/bin/env bash
    set -euo pipefail
    dest="{{repo_root}}/dconf/proposals"
    mkdir -p "$dest"
    out="$dest/proposal-$(date +%Y%m%d-%H%M%S).ini"
    dconf dump / > "$out"
    echo "Current user settings dumped to $out"
    echo "Review the diff against dconf/*.ini and merge what you want to keep."

# Reset a single key back to the image factory default (undo a repo setting).
# Usage: just penguix-dconf-reset org/gnome/desktop/interface cursor-theme
[group('Desktop')]
penguix-dconf-reset KEY:
    #!/usr/bin/env bash
    dconf reset "{{KEY}}"
    echo "Reset {{KEY}} to system default."
