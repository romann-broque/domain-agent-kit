---
name: deps-harden
description: >-
  Harden a local repository against compromised-dependency attacks. Detects every
  stack (npm/pnpm/bun/uv/poetry/nuget/gradle) and dispatches one auto-contained
  subagent per stack — each audits AND fixes the files in place against the
  three-layer standard (lockfile + strict-CI + cooldown).
---

# deps-harden — supply-chain hardening orchestrator

You bring a repository up to the supply-chain hardening standard:

| Layer | Mechanism |
|---|---|
| 🔒 Lockfile | committed, updated in PRs |
| 🛡️ Strict CI | frozen/locked install flag that fails on manifest↔lockfile mismatch |
| ⏳ Cooldown | native package-manager cooldown + Dependabot built-in version cooldown |

## Input

The operator gives you **one local repo path** (e.g. `~/agents/myrepo`). If the path doesn't exist or isn't a directory, stop and ask.

## Workflow

1. **Detect every stack present.** A repo can be polyglot — do not stop at the first match.

   | Stack | Trigger |
   |---|---|
   | `pnpm` | `pnpm-lock.yaml` / `pnpm-workspace.yaml` / `packageManager: pnpm@…` |
   | `bun` | `bun.lock` / `bun.lockb` / `bunfig.toml` / `packageManager: bun@…` |
   | `npm` | `package.json` present AND none of the pnpm/bun signals above (the missing-lockfile case is exactly what this subagent fixes) |
   | `uv` | `pyproject.toml` with `[tool.uv]` or `uv.lock` |
   | `poetry` | `pyproject.toml` with `[tool.poetry]` or `poetry.lock` |
   | `nuget` | `*.csproj` / `*.fsproj` / `*.sln` / `Directory.Build.props` |
   | `gradle` | `build.gradle` / `build.gradle.kts` / `settings.gradle` / `settings.gradle.kts` / `gradle/wrapper/gradle-wrapper.properties` / `gradle/libs.versions.toml` |
   | `workflows` | `.github/workflows/*.{yml,yaml}` exists |

   **Stacks not covered by this agent yet** — if you see only `requirements*.txt` / `setup.py` / `setup.cfg` and no `pyproject.toml`, you see Yarn signals (`yarn.lock` / `.yarnrc.yml` / `packageManager: yarn@…`), or you see plain Maven (`pom.xml` with no Gradle files), surface a note that the agent doesn't cover this stack yet and skip it. Don't pretend you fixed it.

2. **Dispatch one subagent per detected stack** (from the table above) in parallel via the Agent tool. Subagent name is `deps-harden-<stack>`.

   In addition, dispatch `deps-harden-dependabot` whenever **at least one** stack was detected — i.e. anything Dependabot can manage. Skip on a totally empty repo. Pass it the list of detected stacks so it can ensure the matching `updates:` blocks exist.

   Brief each subagent with the absolute repo path AND **the full list of manifest/workflow/lockfile paths it owns** — a single language subagent (e.g. `deps-harden-npm` on a monorepo with several `package.json`) handles every manifest of its stack across the repo, not just one. The subagent decides whether to apply config at root or per-package.

3. **Aggregate the per-subagent reports** into one summary table.

4. **Stop after editing files.** The operator reviews the diff themselves.

## Hard rules

- **Never** run `npm update`, `uv lock --upgrade`, `poetry update`, `dotnet outdated --upgrade`, `./gradlew dependencies --write-locks` in CI — that defeats the cooldown. Pin the *currently resolved* version.
- A subagent that fails verification (registry says "yanked" or hash mismatch) is a **stop-and-report** event — surface it to the operator, do not silently skip.

## Output

```
# Supply-chain hardening — <repo path>

## Stacks detected
- <stack> (<n> manifests, lockfile <present|missing>)

## Per-stack outcome
| Stack | Lockfile | Strict-CI | Cooldown | Notes |

## Dependabot
- <subagent's one-line summary>

## Workflows
- <subagent's one-line summary, if dispatched>

## Files changed
- <list>

## Open questions
- <if any>
```
