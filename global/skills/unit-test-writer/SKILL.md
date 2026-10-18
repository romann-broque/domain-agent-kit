---
name: unit-test-writer
description: >
  Write tests (unit, integration, or otherwise) for any language or framework by first
  loading project conventions from TESTING.md or a rules/ folder before writing anything.
  Use this skill whenever the user wants to create, add, generate, fix, or correct tests —
  including "write tests for this", "tester cette méthode", "add tests for my service",
  "je veux tester ça", "can you test this function", "fix test violations",
  "corrige les tests", "analyse les tests avec TESTING.md",
  "les tests ne respectent pas les conventions".
  Also triggers when the task involves modifying existing tests to comply with project
  conventions — even if the request comes after a code review or PR analysis.
  Does NOT trigger for: debugging failing tests, explaining testing concepts,
  or creating standalone TESTING.md documentation.
---

# Unit Test Writer

The goal of this skill is to produce tests that feel native to the project — following the
same conventions, structure, and style as tests already written there. Convention files
(`TESTING.md`, `rules/`) are the primary source of truth; everything else (framework
detection, naming inference) is a fallback when those files don't exist yet.

---

## Phase 1 — Load Context (always first)

This phase runs before looking at any code to test. The conventions govern everything that follows.

### 1.1 — Scan for convention files

Search two locations only: **project root** and **each direct subdirectory (level 1)**. Never go deeper.

Look for:
- Any folder named `rules/` → load all `.md` files inside it
- A file named `TESTING.md`, `testing.md`, or `TEST.md`

If multiple `rules/` folders exist (root + level-1 subfolder), load them all. If both `TESTING.md`
and `rules/` are found, load both — `TESTING.md` takes priority on conflicts.

### 1.2 — If nothing found → offer to create

Do not silently infer and proceed. Instead, tell the user:

> No convention files found (`TESTING.md` or `rules/`). Want me to generate them based on
> what exists in the repo? I can create one or both — they're independent.

- If yes for `TESTING.md` → inspect existing tests in the repo, infer conventions, write the file,
  then continue using it
- If yes for `rules/` → create the folder with a starter `.md` file capturing the inferred rules,
  then continue using it
- If no → infer silently from existing tests and language standards; do not create any file

When generating convention files: detect language/framework from build files, imports, and existing
test files — not from the code being tested. Capture what you observe, not what you guess.

### 1.3 — Extract conventions

From the loaded files (or from silent inference if the user declined), establish:

| Convention | Source priority |
|---|---|
| Language + framework | `TESTING.md` / `rules/` → auto-detect |
| Test folder location | `TESTING.md` / `rules/` → infer from repo structure |
| Test file naming | `TESTING.md` / `rules/` → infer from existing test files |
| Class/method naming | `TESTING.md` / `rules/` → infer from existing test files |
| Assert / mock libraries | `TESTING.md` / `rules/` → infer from existing test imports |
| Coverage requirements | `TESTING.md` / `rules/` → none assumed |
| Special patterns | `TESTING.md` / `rules/` → none assumed |

If the language is explicitly declared in `TESTING.md` or `rules/`, use it. Otherwise detect it.

---

## Phase 2 — Analyze the target code

Read the file or method the user wants to test. Identify:
- **Nominal cases** — the happy path(s)
- **Error / exception cases** — invalid input, missing data, boundary violations
- **Edge cases** — nulls, empty collections, extreme values, concurrent access if relevant
- **Invariants** — rules that must always hold regardless of input

Also determine the correct output location for the test file based on the conventions from Phase 1.

---

## Phase 3 — Generate

Write the test file at the correct location. Apply all conventions from Phase 1.

Priority order when conventions conflict:
1. `TESTING.md`
2. `rules/` files
3. Inferred from existing tests in repo
4. Language/framework standards

Do not add comments explaining the conventions. The tests should look like they were written
by a developer who knows the codebase — not by a tool that just discovered it.

---

## Guiding principles

**Native feel over correctness theater.** A test that fits the project style is more valuable
than a technically complete test that violates all conventions. When in doubt, look at existing
tests and match them.

**No test for the sake of coverage.** Only generate tests that verify meaningful behavior. If a
method has no observable behavior worth testing, say so instead of generating a pointless assertion.

**Rules files as living documentation.** If the user created `TESTING.md` or `rules/` during
Phase 1.2, remind them to keep them updated as the project evolves — they'll benefit every future
run of this skill.
