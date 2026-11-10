---
name: code-reviewer
description: Review backend code once the tests are green, against the constitution and AGENTS.md. Use this skill after the craftsman skill reaches GREEN, before committing or opening a pull request, or when asked to review changes on this repository. Triggers on "review this", "relis mon code", "check the implementation", "is this ready to commit", "review before PR", "vérifie que ça respecte les conventions". This is the only step allowed to propose refactoring.
---

# Code Reviewer

You review what is already green. You are the only step allowed to propose
refactoring — and you propose it, you do not smuggle it in.

**Announce at start:** "Using code-reviewer to review [unit of change]."

## Step 0 — The entry gate

Confirm the tests are green:

```bash
./gradlew test
```

If anything fails → 🛑 **STOP.** Reviewing red code wastes everyone's time. Hand back
to `craftsman`.

Then look at what actually changed:

```bash
git status --short
git diff
```

Review only the diff. Pre-existing problems outside the diff go into a "noted, out of
scope" list — you do not fix them here.

## Step 1 — Test-first compliance

The first question, before any code quality consideration:

- Was a test written before the implementation, and observed failing?
- Does every new or modified use case have a `.feature` file?
- Does every business model change have a unit test?
- Is there a test on `infrastructure` or `presentation` (adapter, mapper, repository,
  controller) outside an anti-corruption layer and cross-cutting technical logic in
  `core`? It is a 🟡 finding: delete
  it. If it pins a rule — uniqueness, existence — that rule is in the wrong layer; it
  belongs to the use case and its behavior test, which makes it a 🔴.
- Do the tests assert on behaviour, or merely mirror the implementation?

A green implementation whose test was written afterwards is a **blocking finding**,
even if the code is otherwise perfect. Say so plainly.

## Step 2 — Architecture

- Is every class in the layer its responsibility belongs to?
- Does `domain` stay free of `org.springframework..` and `jakarta..`?
- Does `application` stay free of `org.springframework.web..` and
  `jakarta.persistence..`?
- Is every port a single-method `@FunctionalInterface` with no Spring annotation?
- Does the use case depend only on ports?
- Does the controller leak a domain type into a DTO?
- Are new use cases named `{Verb}{Noun}UseCase`?
- Do new use cases return a dedicated `{UseCase}Result` (`AddProductResult`) rather than a
  generic wrapper such as `Result<T>`?
- Is `execute` `@Transactional` — `readOnly = true` when it only reads — and does each
  persistence adapter carry `@Transactional(readOnly = true)` on its reads and
  `@Transactional` on its writes?
- Is there one `{Aggregate}Adapter` per aggregate implementing all its ports, rather
  than one adapter per port?
- Is there exactly one presentation mapper per use case (`{UseCase}Mapper`) holding
  both `toCommand` and `toDto`, rather than one mapper per aggregate or a separate
  request and response mapper?
- Does each controller method hold one `final` local per object (command, result,
  response DTO), with no nested call and no `@ExceptionHandler`?
- Is a domain error (an absence, a duplicate) reported through a `DomainException`
  subclass (`UnknownProductException`, `ProductAlreadyExistsException`) and left to the
  global handler in `core`, rather than handled in the controller?
- **Does anything cross a context boundary?** Only a `{Port}Acl` in
  `infrastructure/acl/` may import another context, and only to call its use case with
  its command and read the result, with the domain types that result carries. Check it against every rule of
  `.opencode/skills/craftsman/references/anti-corruption-layer.md` § *Rules* (ACL-01
  onward): port in the downstream's types and words, translation in the ACL, only the
  *absent* exception caught, crossing declared in `BoundedContextIsolationRulesTest`. A
  violation of a rule ArchUnit holds is 🔴; of a rule only review holds, 🟡.
- Was anything built on top of the `catalog` or `ordering` starter examples as if they
  were real domain?
- **Do the names in `domain` and `application` say what the code means?** No ArchUnit
  rule covers this — it is yours to catch. Symptoms, not a checklist: `ProductManager`,
  `OrderService`, a `utils` package, a domain concept parked in `core` because nobody
  decided which context owns it. Each marks a business notion left unnamed; ask what
  it is and name it. Two exceptions: `infrastructure` and `presentation` are meant to
  be named technically (`*Adapter`, `*Entity`, `*Controller`, `*Dto` — see the naming
  table in `AGENTS.md`), and a `shared` package that is a declared DDD shared kernel
  in `docs/domain/context-map.md`. Judge the intent, do not pattern-match on suffixes.

## Step 3 — Conventions

- Naming against the table in `AGENTS.md`.
- **All method and constructor parameters `final`**, except Lombok-generated
  constructors. Check every signature in the diff; this is the most frequently missed
  rule.
- 2-space indent, 120 columns, LF, final newline.
- **No comments.** The closed list of exceptions is in `AGENTS.md` § *Code Style* →
  *No comments*. Anything outside it is a missing name: report the name it should have
  had, not the comment it should have kept. This rule can never become an ArchUnit
  test — comments do not survive compilation — so this step is the only enforcement it
  will ever have.
- **Javadoc is a comment.** Admissible only on a type reached as a tool, and never in
  `domain` or `application`. One in the diff that was not explicitly validated is a
  finding.
- Aggregate roots changed in place by their mutators and equal by identity; value
  objects immutable `record`s.
- Collections unmodifiable by default (`toUnmodifiableSet()`, `Stream.toList()`), in
  every layer, unless the receiver must mutate them.
- No guard name carrying a literal value (`requireNameAtMost100Characters` → a constant
  and `requireNameWithinMaximumLength`).
- Value objects as `record`s validating in the compact constructor.
- No technical limit in `domain` or a command — a `strip()` of an input, a column size, a
  length nobody would state without knowing the column. It belongs to the request DTO
  (`AGENTS.md` § *Technical limits belong to the request*). A limit the domain states stays.
- Test data from generated fixtures, never ad-hoc constructors in a step definition.
- Dependency versions in `gradle/libs.versions.toml` only.
- If a dependency was added: are `gradle.lockfile`, `settings-gradle.lockfile` and
  `gradle/verification-metadata.xml` regenerated?

## Step 4 — Run the architecture suite explicitly

```bash
./gradlew test --tests 'com.example.starter.architecture.*'
```

## Step 5 — Report

Group findings by severity, and be honest about which is which:

- **🔴 Blocking** — violates the constitution: test written after code, layer
  violation, secret committed, stale lockfile.
- **🟡 Should fix** — convention breach: missing `final`, wrong name, wrong package.
- **🟢 Suggestion** — refactoring you propose. State the benefit; do not apply it
  without agreement.
- **⚪ Noted, out of scope** — pre-existing debt you saw but did not touch.

For each finding give `file:line`, what is wrong, and the concrete fix. No vague
"consider improving error handling".

If you find nothing, say so — do not manufacture findings to look thorough.

## Red Flags

| Thought | Reality |
|---|---|
| "I'll just fix this while reviewing" | Propose it. Silent refactoring destroys the review trail. |
| "Tests are green so it's fine" | Green says nothing about *when* the test was written. |
| "This pre-existing bug should be fixed too" | Note it, out of scope. |
| "I should find at least three issues" | Manufactured findings are noise. |
| "The `final` rule is pedantic" | It is in the constitution. Report it. |
| "It's one comment, on a genuinely tricky line" | Then the line needs a name. Extract a named method, or move the reason into `.as("…")`. Report it. |
| "The comment is helpful, it explains the intent" | Intent belongs in a name, where the compiler checks it. A helpful comment is the most durable kind of missing name. |
| "It's a Javadoc, not a comment" | It is a comment. Admissible only on a tool-facing type, never in `domain` or `application`, and only if it was validated explicitly. |
