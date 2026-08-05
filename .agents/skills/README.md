# finpilot Skills Router

## About

This directory contains discoverable Agent Skills for the finpilot bootc image
template. Each skill lives in a lowercase directory with a required `SKILL.md`
file whose frontmatter tells compatible agents when to load it.

## Skill Index

| Skill | What it covers |
|---|---|
| [`finpilot-overview`](finpilot-overview/SKILL.md) | Repository architecture, file layout, and the task router table. **Start here.** |
| [`finpilot-onboarding`](finpilot-onboarding/SKILL.md) | Bootstrap a new fork: rename, enable Actions, first green build, signing. |
| [`finpilot-templates`](finpilot-templates/SKILL.md) | The 7 rename locations and template-repo maintenance rules. |
| [`finpilot-packages`](finpilot-packages/SKILL.md) | Decision tree: where to add packages (dnf5, Brew, Flatpak). |
| [`finpilot-custom`](finpilot-custom/SKILL.md) | Runtime layer: Brewfiles, Flatpaks, ujust, and validation. |
| [`finpilot-build`](finpilot-build/SKILL.md) | Containerfile, Justfile, build scripts, image pinning, advanced topics. |
| [`finpilot-ci`](finpilot-ci/SKILL.md) | GitHub Actions, Renovate, composite actions, workflow pins. |
| [`finpilot-maintain`](finpilot-maintain/SKILL.md) | Ongoing work: Renovate PRs, README raptor updates, local test loops. |
| [`finpilot-troubleshooting`](finpilot-troubleshooting/SKILL.md) | Symptom → cause → fix tables for build, CI, and runtime issues. |
| [`finpilot-pr-checklist`](finpilot-pr-checklist/SKILL.md) | Pre-commit and per-change-type validation checklists. |
| [`finpilot-examples`](finpilot-examples/SKILL.md) | Runnable example scripts and the `.example` → `.sh` activation pattern. |

## Quick Router

| I need to… | Read this skill |
|---|---|
| Bootstrap a new fork from this template | `finpilot-onboarding` |
| Add/remove a package or app | `finpilot-packages` |
| Change Brewfiles, Flatpaks, or ujust | `finpilot-custom` |
| Change Containerfile, Justfile, or build scripts | `finpilot-build` |
| Fix CI or Renovate | `finpilot-ci` / `finpilot-maintain` |
| Open a PR | `finpilot-pr-checklist` |
| Debug a build or deploy failure | `finpilot-troubleshooting` |
| Follow a worked example | `finpilot-examples` |

## How to Extend Skills

When adding a new skill:

1. **Create a lowercase, hyphenated directory** under `.agents/skills/`
2. **Add `SKILL.md`** with `name` and `description` frontmatter; `name` must match the directory
3. **Describe when to use the skill** precisely so agents can select it automatically
4. **Include the standard sections**: When to Use, When NOT to Use, Core Process, Common Rationalizations, Red Flags, Verification
5. **Add the skill to this README** and the `finpilot-overview` task router

## References

- [Adding agent skills for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [Agent Skills specification](https://agentskills.io/specification)
- [AGENTS.md](../../AGENTS.md) — high-level copilot instructions and mandatory gates
