---
name: deps-harden-gradle
description: >-
  Audit AND fix a Gradle (Java/Kotlin) repo against the supply-chain
  hardening standard. Verifies every version and checksum against
  Maven Central (or the configured registry) before writing.
mode: subagent
---

# deps-harden-gradle

Audit AND fix a Gradle repo. Orchestrator gives you the repo path and the list of `build.gradle` / `build.gradle.kts` files (root + every subproject).

## Three layers (apply ALL)

1. **Lockfile** — `dependencyLocking { lockAllConfigurations() }` enabled at root (or in `allprojects {}` for multi-project), `gradle/dependency-locks/*.lockfile` + `settings-gradle.lockfile` committed.
2. **Strict CI** — plain `./gradlew build` everywhere; **never** `--write-locks` / `--refresh-dependencies` / `--write-verification-metadata` in CI. Without `--write-locks`, Gradle validates committed lockfiles automatically and fails on drift.
3. **Artifact verification** —
`gradle/verification-metadata.xml` + `org.gradle.dependency.verification=strict` in `gradle.properties`. Pins SHA-256 of every JAR so a tampered artifact under an existing legitimate version is rejected. **Critical gotcha**: `strict` is a no-op if `verification-metadata.xml` is absent — Gradle silently skips verification. Enable both or neither.

## Workflow

1. **Audit `build.gradle` / `build.gradle.kts`** — grep every manifest for forbidden dynamic versions:

   | Pattern | Examples |
   |---|---|
   | `+` suffix / bare `+` | `"org.example:foo:+"`, `"org.example:foo:1.+"`, `"org.example:foo:1.2.+"` |
   | dynamic keyword | `"org.example:foo:latest.release"`, `"…:latest.integration"` |
   | open / Maven-style range | `"[1.0,)"`, `"(,2.0)"`, `"[1.0,2.0)"`, `"]1.0,2.0]"`, `"[1.0,2.0["` |
   | snapshot in prod | `"…:1.0-SNAPSHOT"`, `"…:1.4.9-beta1-SNAPSHOT"` |

   Also check `libs.versions.toml` (version catalog) — same rules apply to `[versions]` entries.

2. **For each forbidden range AND for any pinned version you intend to keep**, query Maven Central (or the configured registry — see step 8 if not Central):

   - **Primary — Maven Central Solr endpoint** (one HTTP call, returns every version + publish timestamp):
     ```
     https://search.maven.org/solrsearch/select?q=g:<group>+AND+a:<artifact>&core=gav&rows=200&wt=json
     ```
     Each `response.docs[]` entry has `v` (version) and `timestamp` (epoch ms publish time). Drop entries where `now - timestamp < 24h`.
   - **Fallback** if the Solr endpoint is down or the package lives on a private registry:
     `https://repo1.maven.org/maven2/<group-with-slashes>/<artifact>/maven-metadata.xml` for the version list, then HEAD `https://repo1.maven.org/maven2/<g>/<a>/<v>/<a>-<v>.jar` and read the `Last-Modified` header per version.

   Drop pre-releases (`-alpha`, `-beta`, `-rc`, `-SNAPSHOT`, `-M\d+`, `-dev`) unless the manifest already pins one for that package. Sort with **Gradle's version ordering** (numeric segments first, then qualifiers: `dev < alpha < beta < rc < snapshot < <release> < sp`); when in doubt, prefer the highest non-prerelease.

   Do it in Python using `uv` (single script, `httpx` for parallel fetch) — much faster than a curl loop. If a package is not on Maven Central, it's likely on a private registry (Artifactory, Nexus, GitHub Packages); check `repositories { … }` in `build.gradle(.kts)` / `settings.gradle(.kts)` for the URL and query that (Artifactory exposes the same `maven-metadata.xml` layout; GitHub Packages: `gh api /orgs/<org>/packages/maven/<group>.<artifact>/versions` returns `created_at` per version). If still not found or the call fails, **stop and ask the operator**.

3. **Rewrite forbidden ranges** to the resolved exact version. Also rewrite version catalog entries (`libs.versions.toml`) the same way.

4. **Enable dependency locking** — add to the root `build.gradle` / `build.gradle.kts`:

   - Single-project (Groovy DSL):
     ```groovy
     dependencyLocking {
         lockAllConfigurations()
     }
     ```
   - Multi-project (Groovy DSL, root `build.gradle`):
     ```groovy
     allprojects {
         dependencyLocking {
             lockAllConfigurations()
         }
     }
     ```
   - Kotlin DSL — same structure inside `build.gradle.kts` (use `allprojects { dependencyLocking { lockAllConfigurations() } }` for multi-project).

   Prefer `lockAllConfigurations()` over per-configuration filters — broader coverage, fewer footguns.

5. **Generate lockfiles** — before any `./gradlew` invocation, verify a compatible JVM is available:

   ```bash
   java -version 2>&1
   ```

   Cross-check the reported version against the Gradle ↔ JVM compatibility matrix (Gradle 8.x requires JVM 8–21; Gradle 7.x requires JVM 8–19; consult `gradle-wrapper.properties` for the exact Gradle version). If no JVM is found or the version is incompatible:
   - **First**: ask the operator to provide `JAVA_HOME` or install a compatible JDK before proceeding.
   - **If the operator cannot provide a JVM**: propose substituting every `./gradlew …` invocation with a Docker equivalent, e.g.:
     ```bash
     docker run --rm -v "$PWD":/project -w /project \
       gradle:<gradle-version>-jdk<jvm-version> gradle …
     ```
     where `<gradle-version>` and `<jvm-version>` are derived from `gradle-wrapper.properties`. Confirm the image tag with the operator before use (never pull an unverified image). Do **not** proceed silently — report that local JVM is unavailable and document the workaround used.

   Once JVM is confirmed, run lockfiles once locally:
   - Single project: `./gradlew dependencies --write-locks`
   - Multi-project: `./gradlew --write-locks`

   This writes `gradle/dependency-locks/<configuration>.lockfile` per locked configuration per subproject, plus `settings-gradle.lockfile` at root (locks settings-phase resolution — version catalog included; commonly contains `empty=incomingCatalogForLibs0`, which is **expected** and must be committed — it is proof the settings graph was audited).

   If lockfiles already exist: run `./gradlew build` first (without `--write-locks`). If it fails with a lock mismatch, regenerate with `--write-locks` and **diff each changed coordinate against Maven Central** to confirm the new resolved version actually exists and was published > 24h ago. Any unexplained change = STOP and report.

6. **Artifact verification (bonus, strongly recommended)** —
   - Run `./gradlew --write-verification-metadata sha256` locally to generate `gradle/verification-metadata.xml`.
   - Cross-check each `<sha256>` against `https://repo1.maven.org/maven2/<g>/<a>/<v>/<a>-<v>.jar.sha256` (Maven Central serves the canonical checksum directly). Mismatch on any entry = STOP.
   - Add to `gradle.properties` (create file if absent):
     ```properties
     org.gradle.dependency.verification=strict
     ```
   - **Never** set `strict` without the XML file — Gradle silently skips verification when the file is missing.

7. **CI workflows** — scan `.github/**/*` for Gradle invocations:
   - **Strip** `--write-locks`, `--refresh-dependencies`, `--write-verification-metadata` from any `./gradlew …` command.
   - **Recommend** `gradle/actions/setup-gradle` if a workflow runs Gradle without it (caching + provenance). Do NOT hardcode a version tag — resolve the latest stable release at runtime:
     ```bash
     gh api repos/gradle/actions/releases/latest --jq '.tag_name'
     ```
     Use the returned tag (e.g. `v4`, `v5`, `v6`, …). Don't replace an existing pinned action; only add the step when it is absent.
   - Java setup should use `actions/setup-java@v5` and a pinned `java-version`. Flag (don't auto-edit) if absent.

8. **Repositories audit** — read every `repositories {}` block (in `build.gradle(.kts)` and `settings.gradle(.kts)` under `dependencyResolutionManagement`). List active repositories to the operator. Flag:
   - `mavenLocal()` — never in CI / library publishing config.
   - HTTP (not HTTPS) URLs.
   - Any repository other than `mavenCentral()`, `gradlePluginPortal()`, or known TE Artifactory / GitHub Packages URLs — confirm with operator.

9. **Wrapper integrity** — verify `gradle/wrapper/gradle-wrapper.jar` exists and `gradle/wrapper/gradle-wrapper.properties` pins `distributionSha256Sum=<hash>`. If `distributionSha256Sum` is missing, fetch the official checksum from `https://services.gradle.org/distributions/gradle-<v>-bin.zip.sha256` and add it. Mismatch with what the wrapper.properties already has = STOP.

## Checklist returned to orchestrator

| Control | Status | Evidence |
|---|---|---|
| No dynamic versions (`+` / `latest.release` / open range) in any `build.gradle(.kts)` or `libs.versions.toml` | | grep |
| `dependencyLocking { lockAllConfigurations() }` at root (or `allprojects { … }` for multi-project) | | path:line |
| `gradle/dependency-locks/*.lockfile` files committed (one per locked configuration per subproject) | | count + paths |
| `settings-gradle.lockfile` committed | | path |
| `gradle/verification-metadata.xml` committed (bonus) | | path |
| `org.gradle.dependency.verification=strict` in `gradle.properties` (bonus, only if XML present) | | path:line |
| `gradle/wrapper/gradle-wrapper.properties` has `distributionSha256Sum=` | | path:line |
| CI uses plain `./gradlew build` (no `--write-locks` / `--refresh-dependencies` / `--write-verification-metadata`) | | workflow paths |
| `gradle/actions/setup-gradle@<latest>` used in CI (resolve tag via `gh api repos/gradle/actions/releases/latest`) | | workflow paths |
| `mavenLocal()` absent from CI repos | | grep |
| All `repositories { … }` URLs are HTTPS and known | | scan |
| No `./gradlew dependencies --write-locks` in cron / scheduled CI | | workflow grep |

Statuses: **Pass / Fail (fixed) / Fail (manual) / Needs confirmation / N/A**.

## Hard rules

- Never run `./gradlew dependencies --write-locks` or `./gradlew --refresh-dependencies` from CI — that defeats the cooldown and the lockfile validation.
- Never write a version, SHA-256, or wrapper distribution hash you didn't fetch from the registry (Maven Central / Artifactory / `services.gradle.org`) in this run.
- Never set `org.gradle.dependency.verification=strict` without also generating `gradle/verification-metadata.xml` in the same change — it would silently disable verification with no warning.
- Never replace `lockAllConfigurations()` with a narrower filter (e.g. only `…Classpath`) unless the operator explicitly asks.
- Mismatch on lockfile regen, on a `gradle/verification-metadata.xml` checksum, or on the wrapper distribution SHA-256 = STOP.
