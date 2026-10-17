---
name: review-triage
description: Triage the review comments a human left on a pull request and route each one back into the workflow before anything is changed. Use this skill whenever a PR has review comments to process — after a reviewer's pass, before touching code in reaction to it. Triggers on "process the review", "traite les commentaires de la PR", "apply the review of the PR", "applique la review", "le reviewer a commenté", "address the PR comments", "réponds aux commentaires", "regarde les retours sur la PR". Classifies every unresolved thread, presents a review card, then delegates each item to the step that owns it; it writes no production code itself. Bot reviewers (Copilot, Sonar, CodeRabbit…) go to the global copilot-review-processor skill instead.
---

# Review triage

A review comment is an input to the chain, not a shortcut around it. A comment that
changes what the code must do is a spec change, and a spec change goes through
`/speckit.clarify`, a failing test and an implementation — in that order, in separate
commits. A comment about the domain goes through `domain-ingest`. Only a comment that
changes nothing observable is a refactor.

The failure this skill exists to prevent is concrete: a single `refactor:` commit,
pushed in answer to a review, rewrites `spec.md`, several feature files and the
behaviour of several use cases at once. Nothing in it is wrong on its own. Together, it
erases the trace that the chain exists to keep, and semantic-release reads it as a
patch.

**Announce at start:** "Using review-triage on <owner>/<repo>/<pr>."

## Step 0 — The entry gate

1. Read the PR: `rtk proxy gh pr view <pr> --repo <owner>/<repo> --json number,headRefName,baseRefName,url`.
2. The current repository and branch must be the PR's head. If not → 🛑 **STOP**, say
   which one you are on and which the PR needs. Never apply a backend comment to
   another repository.
3. The working tree is clean (`git status --short` empty) and `./gradlew test` is green.
   Red → 🛑 **STOP**; triage on red code mixes the reviewer's defects with yours.
4. Fetch **unresolved** threads only:

   ```bash
   rtk proxy gh api graphql -f query='
   { repository(owner: "<owner>", name: "<repo>") { pullRequest(number: <pr>) {
       reviewThreads(first: 100) { nodes {
         id isResolved path line
         comments(first: 10) { nodes { databaseId author { login } body } } } } } } }'
   ```

   Keep the nodes with `isResolved: false`. Threads opened by a bot (Copilot, Sonar,
   CodeRabbit…) are not triaged here: hand them to the global `copilot-review-processor`
   skill. A thread already answered "Fixed in …" but
   left unresolved is listed with that reply, not re-triaged blind. A thread you believe
   an older commit already fixed is checked at `HEAD` before you say so.

## Step 1 — Classify

For every thread, read the code at `path:line` **and** what it rests on — the spec
section, the scenario, the `docs/domain/` page. Then give it exactly one class.

| Class | It is this when… | Route |
|---|---|---|
| **R** refactor | nothing a caller, a scenario or the spec can observe changes — a rename, a mapper loop, a fixture, an annotation on an adapter | apply under `code-reviewer`'s criteria |
| **B** behaviour | the spec already says it, the code does otherwise | `test-first` (RED) → `craftsman` (GREEN) |
| **S** spec change | the expected behaviour itself changes — a field becomes required, a query takes another criterion, a value is always written | `/speckit.clarify` amendment → `test-first` → `craftsman` |
| **D** domain | it states something about the domain — what an aggregate is responsible for, a word not to use, which layer owns a check | `domain-ingest` first; it may then yield R, B or S items |
| **Q** question | the reviewer asks why | draft the answer; change nothing until it is answered; it may reclassify |
| **W** workflow | the defect got through because of a skill, a command or a script under `.opencode/` or `.specify/` | fix the tooling |
| **C** contradicts | it conflicts with the constitution or `AGENTS.md` | decline, citing the rule |
| **H** out of scope | right, but not this ticket | decline; propose a ticket via `ticket-writer` if worth it |

**⇧rule** is a flag, not a class: the reviewer asks for the point to become a
standard ("apply and add to the standards"). It adds a `docs(governance):` commit and a
check of whether ArchUnit can enforce it, on top of the item's class.

**The test for R.** Ask: after this change, would any `.feature` step, any `FR-NNN` or
any HTTP response read differently? If yes, or if you cannot tell, it is not R. Moving a
check from one layer to another — command to use case, domain to presentation, aggregate
to value object — changes which exception a caller gets, when, and with which status:
that is S or D, never R. So is an error message the spec or a scenario quotes.

## Step 2 — The review card

Present one row per thread, then the card. Nothing is changed before approval.

```
| # | path:line | comment (short quote) | class | route | why |
|---|-----------|-----------------------|-------|-------|-----|

Decided     the classes nobody could dispute
Assumed     ← read this one: every R that might be an S, every D you read as R,
            every Q whose drafted answer you are not sure of
Uncertain   comments you could not classify, and why
→ Approve / Amend / Reject, per row
```

## Step 3 — Route

In this order, because each step may change what the next one works on:

1. **W** — the tooling first, so the rest is checked by tooling that works.
2. **D** — run `domain-ingest` with the reviewer's statement as the incoming knowledge.
   Its outcome may turn other rows into S or B: re-present those rows.
3. **S** — `/speckit.clarify` writes a dated amendment into `spec.md`. The verbatim
   ticket at the top stays untouched. A decision recorded only in `research.md` is not
   an amendment. Then `test-first`, then `craftsman`.
4. **B** — `test-first`, then `craftsman`.
5. **R** — apply, `./gradlew test` stays green with no assertion changed.
6. **⇧rule** — write the rule where it belongs (`AGENTS.md`, constitution, a
   `craftsman` reference), list existing violations as *Known debt*, and say whether an
   ArchUnit rule can carry it.

Q, C and H change no file. Their answer is the thread reply.

You do not code. Each route hands over to its skill or command, which applies its own
gates.

## Step 4 — Commits

One class per commit. Never two.

| Class | Commits, in order |
|---|---|
| W | `fix(traceability):`, `fix(speckit):`, `docs(workflow):` … |
| D | `docs(domain):` |
| S | `docs(spec):` the amendment → `test(<ctx>):` RED observed → `feat(<ctx>):` or `fix(<ctx>):` |
| B | `test(<ctx>):` RED observed → `fix(<ctx>):` |
| R | `refactor(<ctx>):`, or `test(<ctx>):` when only tests move |
| ⇧rule | `docs(governance):` |

A `refactor:` commit never touches a `.feature`, `spec.md`, `data-model.md` or
`contracts/`. The script below refuses it. The commit that turns a RED test green is
never `refactor:`: if a test had to fail first, behaviour changed.

## Step 5 — Re-verify

```bash
./gradlew test
./.specify/scripts/bash/verify-review-commits.sh origin/<baseRefName>
```

Then `/workflow.verify`, `/speckit.converge` when any S or B was applied, and
`code-reviewer` on the triage diff. Report the script's output verbatim. A `DRIFT` on a
commit made during this triage is fixed now; a `DRIFT` on an older commit is reported,
not rewritten — history on a pushed branch is not rewritten.

## Step 6 — Close

Only after the user has explicitly authorised the push (global push policy):

1. Reply on every triaged thread, in English: the class, then the commit SHA and one
   line, or the rule cited, or the answer to the question.
2. Resolve the thread (`resolveReviewThread`), except Q threads waiting for the
   reviewer's answer.
3. Invoke `pr-message` to update the PR body.

## Red flags

| Thought | Reality |
|---|---|
| "It's the reviewer's request, so it's a refactor" | The type says what changed, not who asked. |
| "The check just moves to the use case / the DTO, behaviour is the same" | The caller gets another exception, at another moment, maybe another status. S or D, with a test first. |
| "The test went RED then GREEN, I'll call the fix `refactor:`" | A test that had to fail first means behaviour changed: `fix:` or `feat:`. |
| "I'll fix all the comments in one commit, it's one review" | One class per commit. The chain reads the order. |
| "The reviewer said it's out of scope for the aggregate, I'll just move the check" | That is a domain statement: `domain-ingest` first. |
| "The reviewer doesn't want the word 'item' — a rename will do" | A word banned by the domain is glossary knowledge: `domain-ingest`, then the rename. |
| "The spec is outdated, I'll update it alongside the code" | The amendment is its own commit, before the test. |
| "I'll note the scope change in `research.md`" | A changed behaviour is a dated amendment in `spec.md`, via `/speckit.clarify`. |
| "The question implies they want X, I'll do X" | Answer the question. Change nothing until they reply. |
| "I'll answer and tighten the code while I'm at it" | A Q row changes no file. A tightening is a new row, classified on its own. |
| "Overwriting this `Covers:` line is cleaner" | Qualify every group by spec number; never overwrite one. |
