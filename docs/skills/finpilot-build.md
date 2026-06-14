---
name: finpilot-build
description: >-
  Containerfile multi-stage build, image-versions.yml digest pinning,
  Justfile local build recipes, and build script conventions.
  Use when changing Containerfile, image-versions.yml, Justfile, or build/*.sh.
metadata:
  context7-sources: []
---

# finpilot Build System

## When to Use

- Editing `Containerfile` (ARGs, stages, base image, RUN directives)
- Editing `Justfile` (build recipe, tag strategy, digest resolution)
- Editing `image-versions.yml` (OCI image pins)
- Adding or modifying `build/*.sh` scripts
- Debugging why a local build fails differently from CI

## When NOT to Use

- CI workflow changes (`.github/workflows/`) — see `finpilot-ci.md`
- Runtime customizations (`custom/`) — use the README.md guides

## Core Process

1. **Identify which ARG drives your change** — image refs, version, identity
2. **Verify `image-versions.yml`** is the source of truth for OCI digests — do not hardcode them in `Containerfile`
3. **Use the `COMMON_IMAGE_REF` pattern** (single combined ref) — never separate `IMAGE`+`SHA` ARGs
4. **Run `just build`** locally before opening a PR; `just lint` to shellcheck
5. **Add `00-` prefix** for metadata scripts, `10-` for main packages, `20+` for extras

## Image Pinning Pattern

### image-versions.yml (source of truth)

```yaml
images:
  - name: common
    image: ghcr.io/projectbluefin/common
    tag: latest
    digest: sha256:<current>   # Renovate updates this
  - name: brew
    image: ghcr.io/ublue-os/brew
    tag: latest
    digest: sha256:<current>   # Renovate updates this
```

Renovate tracks this file with the custom `docker` datasource regex manager.
**Never update digests manually.** Let Renovate do it.

### Containerfile ARG pattern — ALWAYS use single ref ARGs

```dockerfile
# CORRECT — single ref, safe when digest is empty (local builds without yq)
ARG COMMON_IMAGE_REF="ghcr.io/projectbluefin/common:latest"
ARG BREW_IMAGE_REF="ghcr.io/ublue-os/brew:latest"
FROM ${COMMON_IMAGE_REF} AS common
FROM ${BREW_IMAGE_REF} AS brew
```

```dockerfile
# WRONG — empty COMMON_IMAGE_SHA produces "FROM image:tag@" which is invalid syntax
ARG COMMON_IMAGE="ghcr.io/projectbluefin/common:latest"
ARG COMMON_IMAGE_SHA=""
FROM ${COMMON_IMAGE}@${COMMON_IMAGE_SHA} AS common   # ← BREAKS on local builds
```

### Justfile — constructing the ref

```bash
# Combine image + digest only when digest is non-empty (bash :+ expansion)
COMMON_IMAGE_REF="${common_image}${common_image_sha:+@${common_image_sha}}"
BREW_IMAGE_REF="${brew_image}${brew_image_sha:+@${brew_image_sha}}"
BUILD_ARGS+=("--build-arg" "COMMON_IMAGE_REF=${COMMON_IMAGE_REF}")
BUILD_ARGS+=("--build-arg" "BREW_IMAGE_REF=${BREW_IMAGE_REF}")
```

When `yq` is not installed, the Justfile falls back to Containerfile defaults
(plain `image:tag` without digest) — the `:+` guard ensures the `@` separator
only appears when there is actually a digest to append.

## Build Script Conventions

### Numbering

| Prefix | Purpose |
|---|---|
| `00-image-info.sh` | Metadata only: writes `image-info.json`, customises `os-release` |
| `10-build.sh` | Main script: copies custom files, `dnf5 install` |
| `20-*.sh` | Optional extras: third-party repos, COPR packages |
| `30-*.sh` | Optional desktop swaps |
| `clean-stage.sh` | Always runs last: reverts `keepcache`, disables fedora flatpak repo, clears artefacts |

### Template build script rules

- **Default packages**: build scripts in the template must have **no packages installed by default** — only commented examples. Users add their own.
- **Exception**: `dnf5 install -y tmux` is intentionally present as a minimal smoke-test that the DNF cache is warm. Do not remove it.
- Always use `dnf5` — never `dnf`, `yum`, or `rpm-ostree`
- Always use `dnf5 install -y` (non-interactive)
- COPR: enable → install → `copr_install_isolated` (auto-disables); never leave a repo enabled

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

Default: `quay.io/fedora-ostree-desktops/silverblue:44`

The major version is controlled by `FEDORA_MAJOR_VERSION` ARG. To bump Fedora releases:
1. Update `FEDORA_MAJOR_VERSION` in `Containerfile` and `Justfile`
2. Update the Renovate rule that blocks major updates for the base image
3. Test with `just build` — expect `bootc container lint --fatal-warnings` to catch regressions

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll just hardcode the digest in FROM for now." | Renovate can only update what it tracks in `image-versions.yml`. Hardcoded digests go stale silently. |
| "yq is always available in CI so the empty-SHA case never matters." | Local contributors don't have yq. The `FROM image:tag@` syntax breaks their builds. |
| "I'll add `dnf` as a fallback since dnf5 might not be installed." | Never. `dnf5` is the canonical tool. Using `dnf` or `rpm-ostree` diverges from Bluefin. |

## Red Flags

- `FROM ${FOO}@${BAR}` where `BAR` could be empty
- `ARG COMMON_IMAGE_SHA=""` without a single-ref fallback
- Digests hardcoded in `Containerfile` instead of read from `image-versions.yml`
- `dnf`, `yum`, or `rpm-ostree` in any build script
- COPR left enabled after package install (missing `dnf5 copr disable`)
- `# finpilot image identity` hardcoded instead of `# ${IMAGE_NAME} image identity`

## Verification

- [ ] Do all `FROM stage@digest` lines use a single combined ref ARG?
- [ ] Does `image-versions.yml` have the current digests (or will Renovate update them)?
- [ ] Does `build/00-image-info.sh` use `${IMAGE_NAME}` in the os-release comment?
- [ ] Does `just build` succeed locally (with and without yq installed)?
- [ ] Does `just lint` pass clean (shellcheck)?
- [ ] Does `bootc container lint --fatal-warnings` pass in CI?
