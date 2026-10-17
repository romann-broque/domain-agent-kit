---
name: deps-harden-nuget
description: >-
  Audit AND fix a .NET / NuGet repo against the supply-chain hardening
  standard. Verifies every version against api.nuget.org before writing.
mode: subagent
---

# deps-harden-nuget

Audit AND fix a .NET repo. Orchestrator gives you the repo path and the list of `*.csproj` / `*.fsproj` files.

> **Why .NET is special.** `Version="9.10.0"` in a `.csproj` does **NOT** pin to 9.10.0 — it means `>=9.10.0` (open range, transitive bumps allowed). And `dotnet restore` silently regenerates `packages.lock.json` on drift unless `RestoreLockedMode` is set. NuGet has **no native cooldown** today — Dependabot cooldown (orchestrator handles) is the substitute.

## Three layers

1. **Lockfile** — `packages.lock.json` next to every `.csproj`, all committed.
2. **Strict CI** — `RestoreLockedMode=true` gated on `$(ContinuousIntegrationBuild)`, plus `ContinuousIntegrationBuild: true` in CI env.
3. **Cooldown** — none native.

## The pattern (3 files)

### 1. `Directory.Build.props` at repo root

```xml
<Project>
  <PropertyGroup>
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
    <RestoreLockedMode Condition="'$(ContinuousIntegrationBuild)' == 'true'">true</RestoreLockedMode>
  </PropertyGroup>
</Project>
```

### 2. CI env

```yaml
env:
  ContinuousIntegrationBuild: true
```

### 3. Generated lockfiles

`dotnet restore` → commit every `**/packages.lock.json` + `Directory.Build.props`.

## Workflow

1. Grep every `.csproj` / `.fsproj` for `Version="*"`, `Version="x.*"`, `Version="[*,)"`. **Forbidden — auto-pwn.**
2. For each forbidden range AND for any `Version="x.y.z"` you intend to keep, query NuGet:
   ```
   https://api.nuget.org/v3-flatcontainer/<pkg-lower>/index.json
   ```
   Pick the highest version in `versions[]`. For the publish-time check, pull the catalog entry:
   ```
   https://api.nuget.org/v3/registration5-gz-semver2/<pkg-lower>/index.json
   ```
   Drop versions whose `published` is within the last 24h.

   Do it in Python using uv to fetch evertyhing at once. If packages are not available on NuGet, they might be private. Try using the GH CLI to query your organisation's GitHub Packages. If not found or not working, stop and ask the user.
3. Rewrite forbidden ranges to the resolved exact version. Confirm with `dotnet list <proj> package` after restore.
4. `Directory.Build.props` — create or edit at repo root with the snippet above.
5. `dotnet restore` once, locally — generates `packages.lock.json` next to every `.csproj`. If a lockfile already exists and `dotnet restore --locked-mode` fails, regenerate without `--locked-mode` and **diff each changed SHA-512 against the catalog entry's `packageHash`**. Mismatch = STOP.
6. Workflows — add `ContinuousIntegrationBuild: true` to env (workflow-level or job-level). Verify there is no `--use-lock-file false` / `--force` flag elsewhere overriding it.
7. Review any `nuget.config` — list the active package sources to the operator. Don't force `<clear />` (inheritance from parent / machine-wide configs is sometimes intentional); setup `<packageSourceMapping>` if multiple sources are active and no mapping is in place.

## Checklist

| Control | Status | Evidence |
|---|---|---|
| No `Version="*"` / `"x.*"` / `"[*,)"` in any project file | | grep |
| `Directory.Build.props` at root with both lockfile properties | | path |
| `packages.lock.json` next to every `.csproj`, all committed | | paths |
| CI sets `ContinuousIntegrationBuild: true` | | workflow paths |
| `nuget.config` sources reviewed (mapping in place if multiple active sources) | | path |
| No `dotnet add package` / `dotnet outdated --upgrade` in CI | | workflow grep |
| (Optional) `Directory.Packages.props` for monorepo CPM | | path |

## Hard rules

- Never run `dotnet add package` / `dotnet outdated --upgrade` — pin the currently-resolved version.
- Never write a SHA-512 you didn't fetch from the NuGet catalog in this run.
- `listed == false` (yanked equivalent) = STOP.
