---
name: deps-harden-npm
description: >-
  Audit AND fix an npm-managed JS/TS repo against the supply-chain hardening
  standard (lockfile + frozen-CI + cooldown). Verifies every version against
  registry.npmjs.org before writing.
mode: subagent
---

# deps-harden-npm

Audit AND fix an npm repo. The orchestrator gives you a repo path and the manifest list.

## Three layers (apply ALL)

1. **Lockfile** — `package-lock.json` committed.
2. **Strict CI** — `npm ci` (NOT `npm install`) on every install step in `.github/workflows/*.{yml,yaml}`.
3. **Cooldown** — `min-release-age=1` (days) in an `.npmrc` next to **every** `package.json` (npm walks up from CWD; a single root `.npmrc` gets missed in monorepo sub-packages or when the Docker build context is a subfolder). Requires npm ≥ 11.10.0 (recommended ≥ 11.15.0).

## Workflow

1. Read every `package.json`. Flag floating specifiers (`*`, `latest`, bare `>=`, missing version).
2. For each floating dep: query `https://registry.npmjs.org/<pkg>`. Pick the highest version where `time[<v>]` is **older than 24h** and `versions[<v>].deprecated` is unset/null (deprecation lives on the version object, not on `dist-tags`). Verify `versions[<v>].dist.tarball` resolves.

   Do it in Python using `uv` to fetch every package's metadata in parallel — much faster than a curl loop. If a package is not on the public registry, it's likely private (e.g. `@your-org/...`); try the GH CLI to query your organisation's GitHub Packages. If still not found or the call fails, stop and ask the operator.
3. Replace floating ranges with the exact resolved version (`"foo": "1.2.3"`).
4. Ensure `package-lock.json` exists. If absent: `npm install --package-lock-only` (no full install). If lockfile present but stale: regenerate with `--package-lock-only` and **diff every changed `integrity` against the registry's `dist.integrity` for the same version** — mismatch = STOP and report.
5. `.npmrc` next to every `package.json` — create or edit:
   ```ini
   min-release-age=1
   ignore-scripts=true
   ```
   If `ignore-scripts=true` would break a known-needed install hook (e.g. `esbuild`, `puppeteer`), add it as an allowlisted exception in a side note for the operator.
6. CI workflows — replace every `npm install` / `npm i` / `npm install --omit=dev` with `npm ci` (preserve flags). If a workflow has no install step, leave it.
7. Bump `engines.npm` (or `packageManager`) to `>=11.10.0` if not already.

## Checklist returned to orchestrator

| Control | Status | Evidence |
|---|---|---|
| `package-lock.json` committed | | path |
| No floating specifiers in any `package.json` | | grep result |
| CI uses `npm ci` everywhere | | workflow paths |
| `.npmrc` has `min-release-age=1` | | path |
| `.npmrc` has `ignore-scripts=true` (with allowlist if needed) | | path |
| npm version pinned ≥ 11.10.0 | | manifest line |
| No `npm update` in CI / cron | | grep |

Statuses: **Pass / Fail (fixed) / Fail (manual) / Needs confirmation / N/A**.

## Hard rules

- Never run `npm update` / `npm install` (full) — only `--package-lock-only` for lockfile gen.
- Never write a version or hash you didn't fetch from `registry.npmjs.org` in this run.
- Mismatch on lockfile regen = STOP.
