# AGENTS.md — penguix

Userspace-only personalization for Bluefin/Dakota. Repo state lives in
`recipes/`, `brew/`, `dconf/`, `home/`, `scripts/`. Read this file before
changing anything; the rules below are constraints, not suggestions.

## Red lines

1. **Nothing is layered into an OS image.** No Containerfile, no RPM/COPR
   packages, no rpm-ostree, no GNOME Shell extensions vendored for the image,
   no `/etc/skel` or `/etc/dconf` writes in this repo. If a change seems to
   need an image layer, stop and find the userspace path instead.
2. **Everything targets `$HOME`.** dconf goes through the user database
   (`dconf load /`), never the system db. Files deploy from `home/` into
   `$HOME`. Extensions install to `~/.local/share/gnome-shell/extensions/`.
3. **Software installs only via Homebrew (formula/cask/`flatpak` DSL) or
   Flatpak.** AppImage is the only other accepted fallback. No curl-piped
   installers, no deb/rpm installs, no copying binaries outside of these.
   User-level brew recipes only (`brew bundle` without `upgrade`).
4. **Root is allowed in exactly one place**: the opt-in
   `penguix-sysctl-ttl` recipe. Do not add a second one; if something seems
   to need root (sysctl, service masks, udev rules), it is either already
   in the base image or belongs to the OS, not this repo.

## Conventions

- The project name is always written lowercase: `penguix`. Never
  `Penguix`/`PENGUIX` in prose, code, group names or identifiers.
- Recipes follow ujust style: `[group(...)]` tags, `set
  allow-duplicate-recipes := true`, `set ignore-comments := true`, gum for
  prompts. They run via `just`/`just -g`, never via `ujust` (it has no
  userspace hook — see README).
- Brewfile changes must pass `just penguix-brew-check` (grep-only validator;
  never evaluate Brewfiles as Ruby). Third-party entries need `trusted: true`
  at item level.
- Before adding a GNOME Shell extension, verify its `shell_version_map` on
  extensions.gnome.org covers the target GNOME major. The installer fails
  closed on incompatible versions; do not weaken that without a comment
  explaining why.
- dconf edits: change `dconf/penguix.ini`, never dump raw user state into
  the repo (proposals go to `proposal-*.ini`, which is gitignored).
- Every recipe must be idempotent and safe to re-run: when the target state
  is already in place, fast-exit 0 with a clear "nothing to do" message
  before any prompt or privileged action (see change-shell, sysctl-ttl,
  brave-wayland-fixes).

## Verification expectations

- `just --justfile Justfile --list` must parse cleanly.
- Test scripts against a scratch `$HOME` (mktemp -d), never against a live
  session, and never run `penguix-sysctl-ttl` outside an explicit user
  request.
- Extension installer logic is verified against the live EGO API, not
  assumed from memory.
