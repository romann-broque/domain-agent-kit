---
name: test-first
description: Write the failing test before any production code exists. Use this skill whenever implementing a new use case, adding or changing a business model (aggregate, entity, value object, command), or fixing a bug in business code — before writing any implementation. Triggers on "implement this use case", "add a new endpoint", "change this aggregate", "fix this behaviour", "start the TDD loop", "write the behavior test", "commence par les tests", "implémente cette user story". This skill writes tests only; it never writes into src/main/java and always ends by presenting an observed test failure.
---

# Test-First

You write the test that fails. You do not write production code. Ever.

**Announce at start:** "Using test-first to write the failing test for [unit of change]."

## Step 1 — Classify the change

Decide which kind of test is required. This determines everything that follows.

| The change... | Test to write first |
|---|---|
| Creates or modifies a use case | Cucumber behavior test |
| Touches an aggregate, entity, value object or command | Unit test |
| Touches only `infrastructure` or `presentation` — adapter, JPA entity, repository, mapper, controller, DTO, changelog | No test — say so and stop. A uniqueness or existence rule is the use case's, covered by its behavior test |
| Touches an anti-corruption layer under `infrastructure/acl` | Unit test, mocking the upstream port |
| Touches cross-cutting technical logic in `core` — security, error handling, event emission | Unit test |
| Touches only build files, configuration or documentation | No test — say so and stop |

If a change spans both — a new use case that also introduces a value object — write
both, unit test first (it is the smaller loop), then the behavior test.

State your classification explicitly before writing anything. If you cannot classify
it, ask.

## Step 2 — Transcribe, do not invent

<!-- TRACE:BEGIN -->
If a `spec.md` exists for this work, **it is the source of the scenarios and you
are a transcriber, not an author.**

1. Read the `## Source Ticket` block — the verbatim request.
2. Read the `**Acceptance Scenarios**` of the user story you are implementing.
3. Transcribe each acceptance scenario into exactly one Cucumber scenario. One
   in, one out. No merging, no splitting, no "while I'm here" additions.
4. Open the feature file with the coverage header:

   ```gherkin
   # Covers: US1, FR-001, FR-002
   Feature: ...
   ```

   List every user story and functional requirement this file covers. This header
   is what makes coverage checkable by script instead of by opinion — a feature
   file without it cannot be verified and will be reported as a gap.

If a scenario in `spec.md` cannot be transcribed — it is ambiguous, or it
contradicts another — **stop and report it**. Do not repair it silently in
Gherkin. A scenario quietly fixed at this stage is a divergence between what was
approved and what is tested, and nobody will ever see it.

If you find yourself writing a scenario that is in no acceptance scenario, you
have left transcription and started designing. Either it belongs in `spec.md`
first, or it does not belong at all.

Where there is no `spec.md` (a small fix, a model change outside the spec-kit
flow), you write the scenarios yourself — and say explicitly that you did.
<!-- TRACE:END -->

## Step 3 — Write the test

Read the matching reference before you write:

- `references/cucumber-patterns.md` — behavior tests
- `references/unit-test-patterns.md` — unit tests
- `references/fixture-patterns.md` — `*DataSet` fixtures, needed by both

Non-negotiables:

- Feature files at `src/test/resources/behaviors/{context}/{use_case}.feature`.
- Plain wording. The actor is `user`, never an invented role. Titles are short labels,
  not sentences. See `.opencode/skills/test-first/references/cucumber-patterns.md` § *Wording — plain and direct*.
- Step definitions instantiate the use case directly with Mockito-mocked ports.
  **No Spring context.**
- Assertions with AssertJ, on the returned result and on mock interactions only.
  A refusal may be asserted to have occurred (caught exception not null), never on
  its type, and on its message only when the spec fixes its wording.
- Scenarios and steps speak the domain's meaning (*the product is not known*), never
  the bounded context or port that answers.
- All test data from generated fixtures. If a fixture is missing, write its
  `*DataSet` — that is part of your job.
- All method and constructor parameters `final`.
- 2-space indent, 120 columns.
- **No comments.** A case in a provider is named by a private factory method —
  `aZeroPrice()` — never by a commented literal. A test name states the
  fact it pins. A reason an assertion matters goes in AssertJ's `.as("…")`, where it
  shows up when the test fails. The closed list of exceptions is held by
  the project's `AGENTS.md` § *Code Style*; the `// Covers:` traceability line is on it, prose is not.

Write the test against the API you *want*, not the API that exists. It is expected
that the code you are calling does not compile yet — that is the point.

## Step 4 — Run it and require the failure

```bash
./gradlew test --tests '<precise pattern>'
```

Use the narrowest pattern that covers your test, for example
`'com.example.starter.behaviors.catalog.runners.AddProductBehaviorTest'`.

Three possible outcomes:

- **Compilation error because the production type or method does not exist yet** —
  this is a valid RED. Keep the output.
- **Test runs and fails on an assertion** — this is a valid RED. Keep the output.
- **Test passes** — 🛑 **STOP.** This is a defect. Either the behaviour already
  exists, or your test asserts nothing meaningful. Do not "fix" it by making it
  stricter and moving on silently. Report it, explain which of the two it is, and
  wait for a decision.

## Step 5 — Stop and hand over

Do not write production code. Do not create files under `src/main/java/**`. Do not
"just add a stub so it compiles" — the compilation failure *is* the red.

End with:

1. The list of test files you created or modified.
2. The exact command you ran.
3. The failing output, verbatim.
4. `RED confirmed. Hand over to the craftsman skill.`

## Red Flags

| Thought | Reality |
|---|---|
| "I'll add an empty class so the test compiles" | That is production code. Stop. |
| "This change is too small to test" | Business code always gets a test first. |
| "The test passes, so we're done early" | A test green before implementation is broken. Report it. |
| "I'll write the test after, it's faster" | The test would then be shaped by the code, which is the failure mode this skill exists to prevent. |
| "I'll mock the repository" | Mock the port, never the repository. |
| "I'll load a Spring context to make it realistic" | Forbidden. Ports are mocked, the use case is instantiated directly. |
| "This scenario in `spec.md` is a bit off, I'll fix it in Gherkin" | That is a silent divergence from what was approved. Report it instead. |
| "I'll add a scenario the spec forgot" | Then the spec is wrong. Say so. Designing here bypasses the review gate. |
