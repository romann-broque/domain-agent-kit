---
name: deps-harden-bun
description: >-
  Audit AND fix a Bun-managed JS/TS repo against the supply-chain hardening
  standard. Verifies every version against registry.npmjs.org before writing.
mode: subagent
---

# deps-harden-bun

Audit AND fix a Bun repo. Orchestrator passes the repo path and manifests.

## Three layers

1. **Lockfile** — text `bun.lock` committed (preferred over the binary `bun.lockb`).
2. **Strict CI** — `bun install --frozen-lockfile` on every install step.
3. **Cooldown** — `minimumReleaseAge = 86400` (seconds = 24h) in `bunfig.toml` at repo root. Requires Bun ≥ 1.3.4 (older field name `npmMinimalAgeGate` used days — flag for upgrade).

## Workflow

1. Read every `package.json` + `bunfig.toml`. Flag floating specifiers.
2. Resolve each floating dep against `https://registry.npmjs.org/<pkg>` (Bun resolves from npm). Apply 24h cooldown filter. Reject deprecated.

   Do it in Python using `uv` to fetch every package's metadata in parallel. If a package is not on the public registry, it's likely private (e.g. `@your-org/...`); try the GH CLI to query your organisation's GitHub Packages. If still not found or the call fails, stop and ask the operator.
3. Replace floating specifiers with the resolved version.
4. Lockfile: if missing, `bun install --frozen-lockfile=false --save-text-lockfile` then nothing else; if present, regenerate text lockfile and verify each changed integrity hash against the npm registry. Mismatch = STOP.
5. `bunfig.toml`:
   ```toml
   [install]
   minimumReleaseAge = 86400
   ```
6. Pin `packageManager` to an **exact** Bun version (e.g. `bun@1.3.4`). Corepack rejects ranges — `bun@>=1.3.4` is not a valid pin. Resolve the latest Bun release via `https://registry.npmjs.org/bun` (apply the 24h cooldown filter), pin that. Enforce a minimum separately via CI.
7. Workflows — rewrite every `bun install` lacking `--frozen-lockfile`.

## Checklist

| Control | Status | Evidence |
|---|---|---|
| `bun.lock` (text) committed | | path |
| No floating specifiers | | grep |
| CI uses `bun install --frozen-lockfile` | | workflow paths |
| `bunfig.toml` has `minimumReleaseAge >= 86400` | | path |
| `packageManager` pinned to an exact `bun@<x.y.z>` (≥ 1.3.4) | | manifest |

## Hard rules

- Never run `bun update`.
- Never write a hash you didn't verify against `registry.npmjs.org` in this run.
- Mismatch on lockfile regen = STOP.
