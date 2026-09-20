---
name: finpilot-build
description: >-
  Containerfile multi-stage build, image digest pinning in FROM lines,
  Justfile local build recipes, and build script conventions.
  Use when changing Containerfile, Justfile, or build/*.sh.
---

# finpilot Build System

## When to Use

- Editing `Containerfile` (ARGs, stages, base image, RUN directives)
- Editing `Justfile` (build recipe, tag strategy, version computation)
- Adding or modifying `build/*.sh` scripts
- Debugging why a local build fails differently from CI

## When NOT to Use

- CI workflow changes (`.github/workflows/`) — use `finpilot-ci`
- Runtime customizations (`custom/`) — use `finpilot-custom`

## Core Process

1. **Identify which `FROM` line or ARG drives your change**
2. **All image digests** are pinned directly in `Containerfile` `FROM` lines; Renovate updates them
3. **Run `just build`** locally before opening a PR; `just lint` to shellcheck
4. **Add `00-` prefix** for metadata scripts, `10-` for main packages, `20+` for extras

## Image Pinning Pattern

All OCI images are pinned directly in `Containerfile` `FROM` lines. Renovate's
built-in `dockerfile` manager updates every digest.

```dockerfile
# OCI context images
FROM ghcr.io/projectbluefin/common:latest@sha256:<current> AS common
FROM ghcr.io/ublue-os/brew:latest@sha256:<current> AS brew

# Base image — the only place the base is declared
FROM ghcr.io/ublue-os/bluefin-dx:stable@sha256:<current>
```

**Never update digests manually.** Let Renovate open PRs for digest bumps.

The base `FROM` line is the **single source of truth** for the base identity:
there is no `FEDORA_MAJOR_VERSION` or `BASE_IMAGE_NAME` ARG to keep in sync.
`just build` reads the base name and tag from the FROM line (the FROM with no
stage alias), the version string becomes `<base-tag>.<date>`, and
`00-image-info.sh` reads the Fedora major from the base's own `os-release` at
build time — so nothing can drift. A major bump is a one-line tag edit.

## Build Script Conventions

### Numbering

| Prefix             | Purpose                                                                               |
| ------------------ | ------------------------------------------------------------------------------------- |
| `00-image-info.sh` | Metadata only: writes `image-info.json`, customises `os-release`                      |
| `10-build.sh`      | Main script: copies custom files, `dnf5 install`                                      |
| `20-*.sh`          | Optional extras: third-party repos, COPR packages                                     |
| `30-*.sh`          | Optional desktop swaps                                                                |
| `clean-stage.sh`   | Always runs last: reverts `keepcache`, disables fedora flatpak repo, clears artefacts |

### Template build script rules

- **Default packages**: build scripts in the template must have **no extra packages installed by default** — only commented examples. Users add their own.
- **Exception**: `dnf5 install -y tmux gum` in `build/10-build.sh` is intentional: tmux smoke-tests that the DNF cache is warm, and gum is required by the ujust recipes' interactive prompts. Do not remove.
- Always use `dnf5` — never `dnf`, `yum`, or `rpm-ostree`
- Always use `dnf5 install -y` (non-interactive)
- COPR: enable → install → `copr_install_isolated` (auto-disables); never leave a repo enabled

### NVIDIA GPU support

NVIDIA support is a build-time option activated by renaming the example script and adding its explicit Containerfile `RUN` block:

```bash
mv build/40-nvidia.sh.example build/40-nvidia.sh
# Add the standard RUN block for /ctx/build/40-nvidia.sh after 10-build.sh.
# See build/README.md.
just build
```

All NVIDIA logic is self-contained in `40-nvidia.sh`. When both the script and its explicit Containerfile `RUN` block are activated, it provisions the NVIDIA driver, CDI container toolkit, Mutter kms-modifiers, and bootc kernel args directly into the base image — no separate image variant, no `IMAGE_NAME` gating.

Deactivate by removing its Containerfile `RUN` block and renaming the script back to `.example`. See `build/40-nvidia.sh.example` for the full implementation.

### 00-image-info.sh branding

The comment in the `os-release` append block must use `${IMAGE_NAME}`:

```bash
cat >> "${OS_RELEASE}" << EOF

# ${IMAGE_NAME} image identity   ← use variable, not literal "finpilot"
VARIANT_ID="${IMAGE_FLAVOR}"
...
EOF
```

## Base Image

Default: `ghcr.io/ublue-os/bluefin-dx:stable` (tracks Bluefin's weekly stable
stream; currently Fedora 44)

The `FROM` line in `Containerfile` is the single source of truth for the base
identity. Renovate bumps its digest; Fedora majors arrive when Bluefin repoints
`stable` (or you edit the tag deliberately). To change the base or its tag:

1. Edit the base `FROM` line in `Containerfile`
2. Test with `just build` — the version string and `image-info.json` derive
   themselves (`<base-tag>.<date>`; Fedora major read from the base's
   `os-release`), so no second edit exists to forget

## Common Rationalizations

| Rationalization                                                      | Reality                                                                                                |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| "I'll skip the digest pin and use a floating tag."                   | Non-reproducible builds and breaks supply-chain traceability. The `FROM` line should always be pinned. |
| "Renovate won't notice a manually pinned digest in `Containerfile`." | Renovate's dockerfile manager tracks `FROM image:tag@sha256:...` in `Containerfile` automatically.     |
| "I'll add `dnf` as a fallback since dnf5 might not be installed."    | Never. `dnf5` is the canonical tool. Using `dnf` or `rpm-ostree` diverges from Bluefin.                |

## Red Flags

- Floating tags (`FROM image:latest` without `@sha256:...`)
- `FROM ${FOO}@${BAR}` where `BAR` could be empty
- `dnf`, `yum`, or `rpm-ostree` in any build script
- COPR left enabled after package install (missing `dnf5 copr disable`)
- `# finpilot image identity` hardcoded instead of `# ${IMAGE_NAME} image identity`

## Verification

- [ ] Are all `FROM` lines pinned with `@sha256:...`?
- [ ] Does `build/00-image-info.sh` use `${IMAGE_NAME}` in the os-release comment?
- [ ] Does `just build` succeed locally?
- [ ] Does `just lint` pass clean (shellcheck)?
- [ ] Does `bootc container lint --fatal-warnings` pass in CI?
