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
just penguix-setup          # chains: brew → flatpaks → dconf → extensions → home fixes
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
| `dconf/penguix.ini` | Per-user desktop settings, applied with `dconf load /` |
| `home/` | User-level file deployments (Brave flags, autostart) |
| `scripts/` | Extension installer, Brewfile validator |

## Recipes

```text
just penguix-setup              # one-shot full state (prompts per step)
just penguix-brew               # brew bundle all Brewfiles (install, not upgrade)
just penguix-flatpaks           # flatpaks from the Brewfile DSL
just penguix-dconf-apply        # dconf load / < dconf/penguix.ini
just penguix-dconf-backup       # dump current settings back into the repo
just penguix-extensions         # install + enable user GNOME Shell extensions
just penguix-home               # deploy ~/.var/app/Brave flags, autostart, etc.
just penguix-status             # show what is installed/applied
```

Granular variants (`penguix-brew-cli`, `penguix-brew-devops`,
`penguix-extension-install <uuid>`, `brave-1password-fix`, …) are listed by
`just --list`.

## sysctl

Kernel sysctls are system-global by definition — there is no userspace sysctl.
`kernel.yama.ptrace_scope=1` is already the Fedora default and was dropped.
The single remaining tweak (anti-fingerprinting `net.ipv4.ip_default_ttl=65`)
is opt-in and intentionally the only recipe that crosses into root territory:

```bash
just penguix-sysctl-ttl         # asks with gum confirm; writes /etc/sysctl.d/99-penguix-ttl.conf
```

## Fonts and cursor theme

- JetBrains Mono: already shipped by Bluefin as `jetbrains-mono-fonts-all`.
- Yaru cursor theme is not in the base images; install it into
  `~/.local/share/icons/` (userspace) or let GNOME use the default theme and
  delete the `cursor-theme` line from `dconf/penguix.ini`.
