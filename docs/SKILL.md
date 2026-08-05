---
name: finpilot-skill-router
description: Route work in the finpilot bootc image template to its local skills.
---

# finpilot Skill Router

Read `AGENTS.md` first, then select the smallest relevant local skill before
making changes. `projectbluefin/common` supplies shared factory contracts; this
repository remains authoritative for its own implementation and validation.

| Task | Read |
|---|---|
| Container image, build scripts, or local build commands | [finpilot-build](../.agents/skills/finpilot-build.md) |
| GitHub Actions, Renovate, or validation workflows | [finpilot-ci](../.agents/skills/finpilot-ci.md) |
| Template initialization or contributor-facing documentation | [finpilot-templates](../.agents/skills/finpilot-templates.md) |
| Repository orientation and factory role | [finpilot-overview](../.agents/skills/finpilot-overview.md) |
| Capturing a durable lesson after work | [skill-improvement](../.agents/skills/skill-improvement.md) |
| Issue, PR, or Hive queue state | [common label workflow](https://github.com/projectbluefin/common/blob/main/docs/skills/label-workflow.md) |

For factory-managed work, verify the assigned issue, target branch, and current
GitHub state before editing. Work only on assigned or `3-clanker-queue` issues;
humans retain triage, review, and merge authority.
