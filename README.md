# penguix

Userspace-only personalization for [Bluefin](https://projectbluefin.io/) and
[Dakota](https://docs.projectbluefin.io/dakota/) — see AGENTS.md for the
project constraints. Nothing in this repo is layered into an OS image: no
RPMs, no COPR, no Containerfile, no fork of the base image.

- Software: Homebrew (formulas, casks, and Flatpaks via the `flatpak "…"`
  Brewfile directive) and Flathub
- Desktop: per-user dconf (`dconf load /`), never the system dconf database
- GNOME Shell extensions: user-installed into `~/.local/share/gnome-shell/extensions/`
- Home fixes: user-level copies of the old `/etc/skel` content

## Quickstart

```bash
git clone https://github.com/tunix/penguix.git
cd penguix
just penguix-setup          # chains: shell → sysctl → brew → flatpaks → dconf → extensions → home
```

Or install the recipes as your global justfile so they work from anywhere:

```bash
just penguix-install-global-justfile   # generates a delegating global justfile
cd $ANYWHERE
just -g penguix-setup
```

## Why not ujust?

`ujust` is `just --justfile /usr/share/ublue-os/just/00-entry.just`. Its entry
file imports only image-owned files (`apps.just`, `system.just`, …) plus an
optional image-owned `60-custom.just` — there is no userspace hook, and
`/usr` is immutable, so user recipes cannot be added to `ujust` without
layering an image. This repo therefore uses plain `just` with the same
conventions as upstream (`[group(...)]` tags, `set allow-duplicate-recipes`,
`set ignore-comments`, gum-based prompts) so the recipes read exactly like
ujust recipes; they are just invoked through the repo justfile or `just -g`.

## Layout

| Path | Purpose |
| --- | --- |
| `Justfile` | Entry point; chained `penguix-setup` recipe |
| `recipes/*.just` | Grouped recipes: Apps / Desktop / Fixes / System |
| `brew/*.Brewfile` | Software declarations (brew, casks, flatpak DSL) |
| `dconf/desktop.ini` | Desktop settings (fonts, peripherals, wm, power, media keys…) |
| `dconf/shell.ini` | GNOME Shell: app folders, favorites, enabled extensions, weather |
| `dconf/extensions.ini` | Shell extension settings (blur-my-shell, tilingshell, appindicator…) |
| `dconf/apps.ini` | App-specific settings (rtv, valhalla, firewall-config) |
| `dconf/proposals/` | gitignored output of `penguix-dconf-backup` |
| `home/` | User-level file deployments (Brave flags, autostart, Brave flatpak 1Password override) |
| `scripts/` | Extension installer, Brewfile validator |

## Recipes

Grouped as in ujust. The chained one-shot:

```text
just penguix-setup              # 7 steps, gum confirm each (see System note below)
just penguix-status             # show what is installed/applied
```

**Apps** — software via Homebrew and Flathub:

```text
just penguix-brew               # sync Brewfiles to ~/.config/homebrew + brew bundle all
just penguix-flatpaks           # flatpaks from the Brewfile DSL
just penguix-brew-cli           # per-category: also -coding, -devops, -gui
just penguix-brew-check         # validate Brewfiles without evaluating them
just install-jetbrains-toolbox  # user-level JetBrains Toolbox
```

**Desktop** — per-user GNOME settings and extensions:

```text
just penguix-dconf-apply        # dconf load / < every dconf/*.ini
just penguix-dconf-backup       # dump current settings to dconf/proposals/
just penguix-dconf-reset KEY    # reset one key to the factory default
just penguix-extensions         # install + enable user GNOME Shell extensions
just penguix-extension-install <uuid>   # one extension (also -disable/-uninstall/-list)
```

**Fixes** — user-level file deployments (old /etc/skel content):

```text
just penguix-home               # deploy all of home/ into $HOME (incl. the
                                # Brave↔1Password flatpak talk-name override)
just brave-wayland-fixes        # Brave flatpak flags only
just brave-1password-fix        # 1Password native messaging for the Brave flatpak
```

**System** — everything else; the shell change and the sysctl tweak run
FIRST in `penguix-setup` (steps 1/7 and 2/7), both behind a confirm:

```text
just change-shell               # login shell -> fish (sudo usermod; alias: chsh)
just penguix-sysctl-ttl         # opt-in TTL=65 sysctl (sudo; see sysctl section)
just update-and-reboot          # bootc upgrade + optional reboot
just clean-containers           # podman prune
just penguix-install-global-justfile   # generate the delegating `just -g` shim
```

Idempotency: `change-shell`, `penguix-sysctl-ttl`, `brave-wayland-fixes` and
`brave-1password-fix` fast-exit 0 when the target state is already in place;
the brew/flatpak bundles and the extension installer are naturally no-ops for
what is already installed. `penguix-setup` is safe to re-run end to end.

## sysctl

Kernel sysctls are system-global by definition — there is no userspace sysctl.
`kernel.yama.ptrace_scope=1` is already the Fedora default and was dropped.
The single remaining tweak (anti-fingerprinting `net.ipv4.ip_default_ttl=65`)
is opt-in and intentionally the only recipe that crosses into root territory:

```bash
just penguix-sysctl-ttl         # asks with gum confirm; writes /etc/sysctl.d/99-penguix-ttl.conf
```

## Fonts and cursor theme

- MonoLisa (Text/Code): the configured UI font. It is a commercial font and
  is not in Homebrew or Flathub — install it into `~/.local/share/fonts/`
  (userspace) on each machine. On fresh installs the font keys in
  `dconf/desktop.ini` fall back to the default typeface until the font is
  present.
- **Bibata** cursor theme: installed user-level by `just penguix-bibata`
  (downloads the pinned release `ful1e5/Bibata_Cursor v2.0.7` into
  `~/.local/share/icons/` and selects `Bibata-Modern-Ice`; pass another
  variant as an argument, e.g. `just penguix-bibata Bibata-Modern-Classic`).
  Yaru (the previous choice) is not installed on dakota and was replaced.

## Theme scheduling (replaces nightthemeswitcher)

nightthemeswitcher is dead upstream (last GNOME 3.38), and GNOME has NO
native automatic light/dark scheduling: the Settings Style panel is a plain
Default/Dark toggle (verified upstream), and Night Light only adjusts color
temperature. penguix therefore schedules it itself, all userspace:

1. `penguix-sun-scheduler` — a systemd **user** timer (every minute) running
   `~/.local/bin/penguix-sun-scheduler` (python3, stdlib only): reads the
   current location from `night-light-last-coordinates` (gnome-settings-daemon
   writes it when Night Light follows the system location), computes
   sunrise/sunset with the NOAA formulas, and flips `color-scheme` to
   prefer-light/prefer-dark accordingly. When no location is available the
   fallback is fixed 09:00 light / 18:00 dark. Idempotent: it writes only
   when the scheme actually flips.
2. `penguix-theme-sync` — the watcher from before: reacts to color-scheme
   changes and calls the dotfiles script
   (`~/.local/bin/toggle-color-preferences.sh`) so zellij/k9s/bat/nvim follow
   the GNOME style. The script stays in dotfiles; same-value rewrites are
   ignored so the chain cannot loop.

The theme-scheduler extension was dropped from this repo — the timer does
its job without a shell extension. Lost from nightthemeswitcher: the manual
toggle keybinding (`<Shift><Super>t`) — GNOME quick settings has a native
style toggle.
