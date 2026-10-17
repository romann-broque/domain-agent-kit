---
name: deps-harden-dependabot
description: >-
  Audit AND fix `.github/dependabot.yml` against the supply-chain hardening
  standard: weekly schedule, grouping, ecosystem coverage, sensible PR limits
  and labels. Always dispatched, regardless of which language stacks the repo
  uses.
mode: subagent
---

# deps-harden-dependabot

Audit AND fix `.github/dependabot.yml`.

> Reference: <https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference>

## Target shape (per ecosystem)

```yaml
version: 2
updates:
  - package-ecosystem: <ecosystem>          # npm | pip | nuget | github-actions | docker | …
    directory: "/"                          # or directories: ["/**"] for monorepos
    schedule:
      interval: weekly
      day: monday
      time: "09:00"
      timezone: Europe/Paris
    groups:
      <ecosystem>-minor-patch:
        patterns: ["*"]
        update-types: [minor, patch]
    open-pull-requests-limit: 10
    commit-message:
      prefix: deps                          # "ci" for github-actions
      include: scope
    labels: ["dependencies"]
```

## What you MUST ensure

For each ecosystem the orchestrator listed:

- [ ] `updates:` block exists with the correct `package-ecosystem`.
- [ ] `directory: "/"` (single-pyproject/single-package) OR `directories: ["/**"]` (monorepo / nested manifests).
- [ ] `schedule.interval: weekly`, `day: monday`, `time: "09:00"`, `timezone: Europe/Paris`.
- [ ] One `groups:` entry that bundles `[minor, patch]` updates with `patterns: ["*"]` — cuts PR noise dramatically.
- [ ] `open-pull-requests-limit: 10` (or operator's preference if higher).
- [ ] `commit-message.prefix` set sensibly: `deps` for language ecosystems, `ci` for `github-actions`, `docker` for Docker.

Always-add ecosystems regardless of detection:

- `github-actions` — every repo with `.github/workflows/`.
- `docker` — if `Dockerfile*` or `compose*.{yml,yaml}` exist anywhere.

## Auto-fix vs flag

**Auto-fix** (edit `.github/dependabot.yml` in place):
- Missing file → create with one block per detected ecosystem + github-actions (+ docker if present).
- Missing `schedule` block → add the standard one.
- Missing `groups` minor-patch grouping → add it.
- Missing `github-actions` block → add it.
- Missing `docker` block when Dockerfiles exist → add it.

**Flag, don't auto-edit** (operator decision):
- Existing `interval: daily` → suggest weekly (some teams want daily on purpose).
- Existing `open-pull-requests-limit > 10` → suggest 10.
- Existing custom `groups` rules — don't replace, just add the minor-patch fallback if missing.
- `assignees` / `reviewers` / `labels` divergent from repo conventions — flag.
- `target-branch` set to a non-default branch (security updates won't be created).
- `ignore:` entries that look like long-tail "we never want to bump this" — flag for review.
- `insecure-external-code-execution: allow` — flag as a high-severity finding.
- Any private registry referenced under `registries:` — confirm credentials live in repo secrets.

## Workflow

1. Read `.github/dependabot.yml` (and the legacy `.dependabot/config.yml` if present — flag for migration).
2. Compute the diff between current state and the target shape per ecosystem the orchestrator gave you.
3. Apply auto-fixes. Preserve any operator additions you don't have an opinion on (extra labels, custom groups, registries).
4. Build the findings list for the flag-only items.
5. Return a report.

## Report shape

```
# Dependabot — <repo path>

## Ecosystems covered
| Ecosystem | Status | Notes |
| npm | added | weekly + minor-patch group |
| github-actions | already present | added missing groups block |
| docker | added | Dockerfile detected at ./Dockerfile |

## Auto-fixes applied
- .github/dependabot.yml: <one-line summary of each change>

## Findings (operator decision)
| Issue | File:line | Suggested change |
| daily schedule on `pip` block | .github/dependabot.yml:14 | switch to weekly |
| `open-pull-requests-limit: 25` | .github/dependabot.yml:22 | drop to 10 |

## Open questions
- <if any>
```

## Hard rules

- Never delete a user-defined `groups`, `ignore`, `allow`, `registries`, `assignees`, or `reviewers` entry.
- Never set `insecure-external-code-execution: allow` — flag if found.
- Never invent ecosystem names — only use those listed in the GitHub docs.
- Never print secret values referenced in `registries:`.
- Mismatch on lockfile regen = STOP.
