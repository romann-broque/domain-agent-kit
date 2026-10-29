# How we work

One page. Find what you want to do, run the thing next to it.

Everything here is manual: **nothing chains automatically**. Each arrow below is a
human deciding to type the next command. That is the point — those are the review
gates.

---

## I want to…

| …do this | …run this |
|---|---|
| Set or change the project's principles | `/speckit.constitution` |
| Bring a ticket into the project | skill **`domain-challenge`** — paste the ticket verbatim |
| Split a ticket that is too large, or write a ticket body for the tracker | skill **`ticket-writer`** |
| Add domain knowledge (a modelling session, a new context, a new term) | skill **`domain-ingest`** |
| Turn a validated ticket into a spec | `/speckit.specify` |
| Answer the open questions in a spec | `/speckit.clarify` |
| Get a technical plan | `/speckit.plan` |
| Check the quality of the requirements themselves | `/speckit.checklist` |
| Break the plan into tasks | `/speckit.tasks` |
| Check spec, plan and tasks agree with each other | `/speckit.analyze` |
| Turn the tasks into tracker issues | `/speckit.taskstoissues` |
| Check nothing was lost between the ticket and the tasks | `/workflow.verify` |
| Implement | `/speckit.implement` (drives `test-first` → `craftsman`) |
| Check the implementation matches what was asked | `/workflow.verify`, then skill **`code-reviewer`** |
| Compare the codebase against the spec, and add what is missing as tasks | `/speckit.converge` |
| Write a test before code, on its own | skill **`test-first`** |
| Review code that is already green | skill **`code-reviewer`** |
| Process the comments a human left on my PR | skill **`review-triage`** |
| Process the comments a bot left on my PR | global skill **`copilot-review-processor`** |

---

## The full chain

```
0   /speckit.constitution   once per project: the principles every gate checks against
ticket
1   domain-challenge        does this ticket fit the domain? blocking questions
1a    ↳ ticket-writer       if TOO LARGE: sibling tickets, each re-enters at 1
1b    ↳ domain-ingest       if DOMAIN GAP: write the missing knowledge, then re-run 1
2   /speckit.specify        user stories + acceptance scenarios (Given/When/Then)
3   /speckit.clarify        only if the spec has open questions
4   /speckit.plan           technical approach; Constitution Check must pass
4a  /speckit.checklist      optional: a checklist on the quality of the requirements
5   /speckit.tasks          tasks, each tagged [USn], each user story gated
5a  /speckit.analyze        read-only: do spec, plan and tasks agree?
5b  /speckit.taskstoissues  optional, only when asked: one tracker issue per task
5c  /workflow.verify        mechanical: is anything missing between ticket and tasks?
6   /speckit.implement      test-first writes the failing test, craftsman makes it pass
7   /workflow.verify        mechanical: does the evidence hold? did tests come first?
7a  code-reviewer           conventions, layering, naming, final params
7b  /speckit.converge       semantic: does the code do what the spec said?
8   review-triage           on human PR comments: classify, route back into the chain
```

| # | Step | Run by | What you approve |
|---|---|---|---|
| 0 | Constitution | `/speckit.constitution` | the principles, and the version bump |
| 1 | Challenge the ticket | skill `domain-challenge` | the verdict and the blocking questions |
| 1a | Write or split tickets | skill `ticket-writer` | the sibling tickets and their links |
| 1b | Ingest domain knowledge | skill `domain-ingest` | what went into `docs/domain/`, and what was set aside |
| 2 | Specify | `/speckit.specify` | the scenarios are faithful to the ticket |
| 3 | Clarify | `/speckit.clarify` | the answers, encoded in the spec |
| 4 | Plan | `/speckit.plan` | the Constitution Check |
| 4a | Checklist | `/speckit.checklist` | the gaps it found in the requirements |
| 5 | Tasks | `/speckit.tasks` | the `[USn]` tags and the `[GATE]` tasks |
| 5a | Analyze | `/speckit.analyze` | the inconsistencies it reports (it edits nothing) |
| 5b | Tasks to issues | `/speckit.taskstoissues` | the issues to be created — a write to the tracker, so only on explicit request |
| 5c | Verify, before code | `/workflow.verify` | the mechanical joins ticket → spec → tasks |
| 6 | Implement | `/speckit.implement` → skills `test-first`, then `craftsman` | each RED, then each GREEN |
| 7 | Verify, after code | `/workflow.verify` | the evidence, and the test-before-code order of the commits |
| 7a | Review | skill `code-reviewer` | the findings, and any refactoring it proposes |
| 7b | Converge | `/speckit.converge` | the unbuilt work it appends to `tasks.md` |
| 8 | Triage review comments | skill `review-triage` | the class and the route of each comment |

`ticket-writer` is a branch out of step 1, not a step of its own. `domain-challenge`
returns `TOO LARGE` and stops — it is a gate, it does not draft what comes after. The
split is a separate decision, taken by a human who read the card, and `ticket-writer`
writes the sibling tickets that come out of it: one shape, `is blocked by` links, never
sub-tasks. Each ticket then re-enters the chain at step 1 on its own.

It also writes the bodies of the tickets `domain-ingest` names but never writes, and it
formats any ticket asked for outside a split. Its output lands in `tickets/<slug>.md`,
which is git-ignored: the issue tracker is the record and that file is a paste buffer.
It creates no spec, no issue, and nothing committed.

`domain-ingest` also sits off the main line. It runs when knowledge arrives — typically
because `domain-challenge` returned `DOMAIN GAP`. It writes only the slow substrate of
the domain, and reports the rest under **Set aside** rather than filing it away.
Use-case material found there becomes a ticket — written with `ticket-writer` — which
re-enters at step 1; that is the loop that closes. Solution mechanics is reported and
written nowhere: the code is where it becomes true.

`review-triage` runs once a human has reviewed the pull request. A comment is not a
licence to edit code directly: one that changes the expected behaviour goes back through
`/speckit.clarify` and the TDD loop, one about the domain through `domain-ingest`, and
only one that changes nothing observable is a refactor. `/workflow.verify` checks the
commits mechanically. Comments left by bots go to `copilot-review-processor` instead.

---

## What you approve at each gate

Each step ends with a **review card**, not a wall of markdown:

```
Decided     what the step established
Assumed     what it filled in that nobody said     ← read this one
Uncertain   what it could not resolve
→ Approve / Amend / Reject
```

- **Approve** — the human types the next command.
- **Amend** — the human says what to change; the same step runs again and shows a new card.
- **Reject** — the step's output is discarded; go back to the step that fed it.

The full document stays available. You are not asked to approve it. Drift never
hides in what was decided; it hides in what was assumed without saying so.

---

## Two rules that are not negotiable

**Tests come first.** Every use case gets a Cucumber behaviour test before any
production code. Every domain or application model that guards something gets a
`CreationTest` before it exists. The test is written, run, and **observed failing** —
the failing output is pasted into the `[GATE]` task. `/speckit.implement` refuses to
write into `src/main/java` until that gate is checked with real evidence.

**The ticket is kept verbatim.** `spec.md` opens with the original text, unedited,
between the `TRACE:BEGIN` and `TRACE:END` markers. It is the only unmodified trace of
what was actually asked, and everything downstream is checked against it.

---

## Reading `/workflow.verify`

It runs four scripts from `.specify/scripts/bash/`:

| Script | Checks |
|---|---|
| `verify-traceability.sh` | ticket → spec → tasks → `# Covers:` headers: every `FR-NNN` and `USn` is carried through |
| `verify-implementation.sh` | each `[GATE]` carries a real failing output; the test commit came before the implementation commit |
| `verify-domain-base.sh` | `docs/domain/`: headers, statuses, open points, blocked markers, cross-references |
| `verify-review-commits.sh` | review-fix commits: no `refactor:` touching a scenario or a spec, no lost `Covers:` group |

It prints two things and never merges them:

- **Mechanical** — true or false, a shell script answers. Does `FR-003` appear in
  `tasks.md`? Does each `[GATE]` carry a failing output? Did the test commit come
  before the implementation commit?
- **Semantic** — a model judging output a model produced. It catches outright
  omissions. It does not catch misunderstandings, because a misunderstanding is
  coherent with itself.

Exit codes: `0` no drift, `1` drift found, **`2` could not verify**. A `2` is not a
pass. A check that found nothing because it looked nowhere is worse than no check.

---

## Where things live

| What | Where |
|---|---|
| The rules (binding) | `.specify/memory/constitution.md` |
| Architecture and conventions (reference) | `AGENTS.md` |
| Domain knowledge — vocabulary, contexts, boundaries, invariants | `docs/domain/` |
| Use cases, acceptance criteria, `FR-NNN` — per feature | `specs/{NNN}-{short-name}/` |
| Behaviour tests | `src/test/resources/behaviors/{context}/` |
| Skills | `.opencode/skills/` |
| Commands | `.opencode/commands/` |
| Ticket drafts (git-ignored) | `tickets/` |
| Session design docs (git-ignored) | `docs/superpowers/` |

`docs/domain/` and `specs/` are not interchangeable. `docs/domain/` holds what a single
feature cannot invalidate; everything at use-case level belongs to a spec, where it is
dated and traceable to a ticket. So the silence of `docs/domain/` on a use-case question
proves nothing — look in `specs/` before concluding that nothing was decided.

The constitution wins over everything else. `AGENTS.md` explains how to apply it.

For everything else, three levels of authority, in order:

1. **code + behaviour tests** — what the system does. Beaten by nothing.
2. **`specs/{NNN}-{short-name}/spec.md`** — what was asked, at a date. An `FR-NNN` found
   there proves a question was once answered, not that the answer still holds: a feature
   can be reduced or dropped without anyone rewriting its spec.
3. **`docs/domain/`** — the model the team accepted. Descriptive: where code exists,
   the code wins.

Which one grounds a claim is part of the claim — cite it by path.

---

## Commands

```bash
./gradlew build                                                # everything
./gradlew test --tests 'com.example.starter.behaviors.*'       # behaviour tests
./gradlew test --tests 'com.example.starter.architecture.*'    # ArchUnit
```

Cucumber reports land in `build/reports/behaviors/{context}/`.
