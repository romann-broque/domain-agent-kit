---
name: deps-harden-uv
description: >-
  Audit AND fix a uv-managed Python repo against the supply-chain hardening
  standard. Verifies every version against pypi.org before writing.
mode: subagent
---

# deps-harden-uv

Audit AND fix a uv-managed Python repo. Orchestrator passes the repo path and the list of `pyproject.toml` files.

## Three layers

1. **Lockfile** — `uv.lock` committed.
2. **Strict CI** — `uv sync --frozen` (or `--locked`) on every install step.
3. **Cooldown** — `[tool.uv].exclude-newer = "1 day"` in **every** `pyproject.toml` (root + nested).

## Workflow

1. Read every `pyproject.toml`. Flag direct deps not pinned with `==` (no bare names, no `>=`, no `^`).
2. For each non-pinned dep, query PyPI:
   ```
   https://pypi.org/pypi/<pkg>/json
   ```
   Pick the highest `releases[<v>]` where `upload_time` is **> 24h ago** AND `releases[<v>][*].yanked == false`. Reject anything yanked. Sort with **PEP 440** rules (use `packaging.version.Version`; never SemVer or naive string sort). Exclude pre-releases (`a/b/rc/dev`) unless the manifest already pins one for that package.

   Do it in Python using `uv` to fetch every package's metadata in parallel — much faster than a curl loop. If a package is not on public PyPI, it's likely on a private index referenced under `[[tool.uv.index]]` / `--index-url` / TE Artifactory; query that. If still not found or the call fails, stop and ask the operator.
3. Rewrite the dep to `<pkg>==<v>`.
4. Add to every `pyproject.toml`:
   ```toml
   [tool.uv]
   exclude-newer = "1 day"
   ```
5. Lockfile: if missing, `uv lock`. If present, run `uv lock --check` first; if it fails, regenerate with `uv lock` and **diff each changed `sha256` in `uv.lock` against `https://pypi.org/pypi/<pkg>/<v>/json`'s `urls[*].digests.sha256`**. Mismatch = STOP.
6. Workflows — rewrite every `uv sync` / `uv pip install` lacking `--frozen` or `--locked`. Prefer `uv sync --frozen --no-dev` for prod jobs.
7. Flag any `[tool.uv.sources]` entry pointing at a `git`/`url`/`path` source — list in report.
8. Flag any `--no-build-isolation` or `--no-build` absence; recommend `--only-binary :all:` in CI install steps to avoid arbitrary `setup.py` execution.

## Checklist

| Control | Status | Evidence |
|---|---|---|
| `uv.lock` committed | | path |
| All direct deps pinned `==` in every `pyproject.toml` | | grep |
| `[tool.uv].exclude-newer = "1 day"` on every pyproject | | paths |
| CI uses `uv sync --frozen` or `--locked` | | workflow paths |
| `[tool.uv.sources]` reviewed (no rogue git/URL) | | scan |
| `--only-binary :all:` or `--no-build` in CI installs | | workflow grep |
| `requires-python` pinned tightly | | manifest |
| `.python-version` matches `requires-python` | | files |
| No unattended `uv lock --upgrade` in CI | | workflow grep |

## Hard rules

- Never run `uv lock --upgrade`.
- Never write a `sha256` you didn't fetch from PyPI in this run.
- Yanked release in resolution = STOP.
- Mismatch on lockfile regen = STOP.
