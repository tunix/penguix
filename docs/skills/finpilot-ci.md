---
name: finpilot-ci
description: >-
  GitHub Actions workflows, projectbluefin/actions composite actions,
  Renovate configuration, and PR validation for finpilot.
  Use when changing .github/workflows/, renovate.json, or .hadolint.yaml.
metadata:
  context7-sources: []
---

# finpilot CI

## When to Use

- Editing any `.github/workflows/*.yml`
- Editing `renovate.json`
- Adding new tooling to `build-image.yml`
- Debugging CI failures
- Deciding what to automerge vs require review

## When NOT to Use

- Containerfile / Justfile / build script changes — see `finpilot-build.md`
- Runtime customisations — use README.md guides

## Core Process

1. **Identify the workflow responsible** for your change (see table below)
2. **Check `projectbluefin/actions`** to confirm the composite action exists and what inputs it takes
3. **Pin any new tool** with a specific version + Renovate tracking comment
4. **Validate** locally: `actionlint .github/workflows/*.yml`
5. **Do not widen automerge scope** beyond `digest/pin/pinDigest` for the broad rule

## Workflow Map

| File | Trigger | Purpose |
|---|---|---|
| `build-image.yml` | push main, schedule, manual | Build + push `:stable` via `projectbluefin/actions` |
| `pr-validation.yml` | PR → main | shellcheck + hadolint + pre-commit via `validate-pr` |
| `renovate.yml` | schedule 6h, push renovate config | Self-hosted Renovate runner |
| `clean.yml` | schedule weekly | Delete GHCR images older than 90 days |
| `validate-brewfiles.yml` | PR paths: `custom/brew/**` | Homebrew Brewfile syntax check |
| `validate-flatpaks.yml` | PR paths: `custom/flatpaks/**` | Flathub app ID existence check |
| `validate-justfiles.yml` | PR paths: `Justfile` | `just --list` syntax check |
| `validate-renovate.yml` | PR paths: `renovate.json` | `renovate-config-validator` |

## Composite Action Pins

All actions from `projectbluefin/actions` are pinned to a **commit SHA**:

```yaml
uses: projectbluefin/actions/bootc-build/setup-runner@<sha> # v1
```

**Never use a floating tag like `@v1` or `@main`.** Renovate updates the SHA automatically.

The SHA comment (`# v1`) is for human readability only — Renovate ignores it.

## Adding a New Tool (e.g., yq, jq, cosign)

Always pin to a specific version with a Renovate tracking comment:

```yaml
- name: Install yq
  env:
    # renovate: datasource=github-releases depName=mikefarah/yq
    YQ_VERSION: "v4.44.3"
  run: |
    sudo wget -qO /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
    sudo chmod +x /usr/local/bin/yq
```

The `renovate.json` custom manager tracks this pattern:
```json
{
  "customType": "regex",
  "description": "Track pinned tool versions in workflow env vars",
  "managerFilePatterns": ["/^\\.github\\/workflows\\/.+\\.yml$/"],
  "matchStrings": [
    "# renovate: datasource=(?<datasource>[^\\s]+) depName=(?<depName>[^\\s]+)\\n\\s+\\w+: \"(?<currentValue>[^\"]+)\""
  ]
}
```

Never use `/releases/latest/` — it is non-reproducible.

## Renovate Automerge Scope

### ✅ Safe to automerge broadly (digest/pin only)

```json
{
  "matchUpdateTypes": ["digest", "pin", "pinDigest"],
  "automerge": true
}
```

Digest-only updates are hash changes with no API surface change. Safe.

### ✅ Safe to automerge for trusted first-party actions

```json
{
  "matchPackageNames": ["projectbluefin/actions"],
  "matchUpdateTypes": ["digest", "pinDigest", "pin", "patch", "minor"],
  "automerge": true
}
```

`projectbluefin/actions` is controlled by the same factory — minor/patch bumps are safe.

### ❌ Do NOT automerge broadly for `minor`/`patch`

Minor and patch updates across all packages can change workflow behaviour or introduce
regressions. They require human review before merging to an OS image template that ships
to users' machines.

## Renovate OCI Digest Tracking

OCI image digests are tracked via `image-versions.yml`, not inline in `Containerfile`:

```json
{
  "customType": "regex",
  "description": "Track OCI image digests in image-versions.yml",
  "managerFilePatterns": ["/^image-versions\\.yml$/"],
  "matchStrings": [
    "image: (?<packageName>[^\\s]+)\\n\\s+tag: (?<currentValue>[^\\s]+)\\n\\s+digest: (?<currentDigest>sha256:[a-f0-9]+)"
  ],
  "datasourceTemplate": "docker",
  "versioningTemplate": "docker"
}
```

When Renovate updates a digest it opens a PR that changes only `image-versions.yml`.
The next CI build reads the new digest via `yq` and passes it as `COMMON_IMAGE_REF` / `BREW_IMAGE_REF`.

## Renovate Workflow Requirements

The self-hosted Renovate runner requires a `RENOVATE_TOKEN` secret:
- **Classic PAT** with `repo` + `workflow` scopes
- Set in repository secrets as `RENOVATE_TOKEN`
- The `check-token-health` composite action validates this at the start of the workflow

If `RENOVATE_TOKEN` is missing or expired, the workflow fails **before** running Renovate —
not midway through — thanks to the preflight check.

## hadolint Config (.hadolint.yaml)

Suppressions are documented with reasons:

```yaml
ignore:
  - DL3006  # Images use ARG for dynamic tags — cannot use explicit tags here
  - DL3059  # Multiple consecutive RUN — intentional design (cache layering)
  - SC2312  # Style preference — command substitution in conditions
```

Add suppressions sparingly. If you suppress a new rule, document the reason inline.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll use `/releases/latest/` for now and pin it later." | You won't. Non-reproducible builds silently fail months later. Pin immediately. |
| "Minor/patch automerge is fine — it's just a template." | Templates ship to users' machines. A bad automerge in a CI action can break all forks. |
| "I don't need Renovate tracking for this one tool." | Unpinned tools silently break when upstream releases a breaking change. |

## Red Flags

- Tool installed via `/releases/latest/` without version pin
- Automerge rule includes `minor` or `patch` for all packages (`matchPackageNames` not scoped)
- Composite action used with a floating tag (`@v1`, `@main`) instead of a commit SHA
- `GITHUB_TOKEN` used as the Renovate token (it cannot open PRs to other repos)
- `renovate.json` changed without running `renovate-config-validator`

## Verification

- [ ] Every `uses:` in workflows is pinned to a commit SHA with a version comment?
- [ ] Every new tool install has a pinned version + `# renovate: datasource=...` comment?
- [ ] Automerge broad rule is `digest/pin/pinDigest` only (not `minor`/`patch`)?
- [ ] `actionlint .github/workflows/*.yml` passes clean?
- [ ] `renovate-config-validator .github/renovate.json` passes clean?
- [ ] `RENOVATE_TOKEN` secret documented in SETUP_CHECKLIST.md?
