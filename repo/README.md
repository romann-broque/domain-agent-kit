# repo/

The per-project workflow: spec-driven, test-first, domain-aware. Copy the content of this
folder to the root of a project (for instance on top of a copy of `../starter-kit/`),
leaving out this README and appending the ignore rules instead of copying them:

```bash
rsync -a --exclude /README.md --exclude /.gitignore.snippet repo/ <project>/
cat repo/.gitignore.snippet >> <project>/.gitignore
```

```
repo/
├── AGENTS.md                  project rules the agent reads first (architecture, tests, style, workflow)
├── docs/
│   ├── WORKFLOW.md            the workflow for humans: which step, which command, what comes out
│   └── domain/                domain knowledge base — glossary, context map, open points, contexts
├── .opencode/
│   ├── skills/                domain-challenge, ticket-writer, domain-ingest,
│   │                          test-first, craftsman, code-reviewer, review-triage
│   └── commands/              speckit.* (spec-kit, customised) + workflow.verify
├── .specify/
│   ├── memory/constitution.md the project constitution (to adapt)
│   ├── templates/             spec, plan, tasks, checklist, constitution, domain context, open point
│   ├── scripts/bash/          spec-kit scripts + verify-* mechanical checks (and their tests)
│   └── workflows/             spec-kit workflow definition
├── .githooks/commit-msg       Conventional Commits check — enable with git config core.hooksPath .githooks
├── .github/pull_request_template.md
└── .gitignore.snippet         lines to append to the project's .gitignore
```

## Workflow order

Each step ends with a review card (Decided / Assumed / Uncertain). Nothing chains by itself:
you read the card, then type the next step.

| # | Step | Produces |
|---|---|---|
| 0 | `/speckit.constitution` | `.specify/memory/constitution.md` (once per project) |
| 1 | `domain-challenge` skill | readiness verdict for a ticket — READY / NEEDS ANSWERS / DOMAIN GAP / TOO LARGE |
| 1a | `ticket-writer` skill | smaller tickets when the verdict is TOO LARGE |
| 1b | `domain-ingest` skill | `docs/domain/**` when the verdict is DOMAIN GAP |
| 2 | `/speckit.specify` | `specs/NNN-name/spec.md` with the ticket pasted verbatim |
| 3 | `/speckit.clarify` | answers encoded into the spec |
| 4 | `/speckit.plan` (+ `/speckit.checklist`) | `plan.md`, `research.md`, `data-model.md`, `contracts/` |
| 5 | `/speckit.tasks` (+ `/speckit.analyze`) | `tasks.md` with a `[GATE]` after each test block |
| 5b | `/speckit.taskstoissues` | one tracker issue per task — only on explicit request |
| 5c | `/workflow.verify` | the joins ticket → spec → tasks, checked before any code |
| 6 | `/speckit.implement` → `test-first` → `craftsman` | failing test (RED), then minimum code (GREEN) |
| 7 | `/workflow.verify`, `code-reviewer`, `/speckit.converge` | evidence check, diff review, spec-vs-code gap |
| 8 | `review-triage` skill | human PR comments classified and routed back to the right step |

```
ticket ──▶ domain-challenge ──▶ spec ──▶ plan ──▶ tasks ──▶ verify ──▶ test (RED) ──▶ code (GREEN) ──▶ verify + review ──▶ PR
              │        ▲                                                                                                │
              ▼        │                                                                                                ▼
         domain-ingest ─┘  writes docs/domain/                                                           review-triage routes each
         ticket-writer     splits a ticket too large                                                     comment back to its step
```

`docs/WORKFLOW.md` tells the same story in more detail.

## Skills

Used by the agent when their step comes (`.opencode/skills/`):

| Skill | What it does |
|---|---|
| `domain-challenge` | First step of every ticket. Confronts it with `docs/domain/` and answers READY, NEEDS ANSWERS (blocking questions), DOMAIN GAP (the documentation does not know enough) or TOO LARGE. |
| `domain-ingest` | Brings domain knowledge into `docs/domain/`: a modelling session, a new context, a term, a rule, a correction. Challenges it first (contradictions, missing sources, duplicates), writes only what lasts beyond one feature, and lists what it set aside. Usually runs after a DOMAIN GAP. |
| `ticket-writer` | Writes tickets in a standard format and splits a ticket that is too large into independent ones. |
| `test-first` | Writes the failing test before any production code: a Cucumber scenario per use case, a creation test per model. Stops at RED. |
| `craftsman` | Writes the minimum code that turns the failing test green, following the clean-architecture conventions. |
| `code-reviewer` | Reviews the green code against the constitution and `AGENTS.md` before commit or PR. |
| `review-triage` | Classifies each human review comment and routes it back to the right step instead of patching code directly. |

## How tickets, documentation and code stay consistent

| Confrontation | Who does it |
|---|---|
| Ticket ↔ domain documentation: does the ticket use known words, respect known rules, fit one context? | `domain-challenge` |
| New knowledge ↔ documentation and code: is it consistent, sourced, not already written, and does the running code agree? | `domain-ingest` |
| Ticket ↔ spec ↔ tasks: did every requirement and scenario reach a task? | `/workflow.verify` (`verify-traceability.sh`) |
| Tasks ↔ commits: was each test committed and seen failing before its code? | `/workflow.verify` (`verify-implementation.sh`) |
| Spec ↔ code: does the code do what was specified, and only that? | `code-reviewer`, `/speckit.converge` |
| Review comments ↔ workflow: is a comment a refactor, a bug, a spec change or a domain change? | `review-triage` (`verify-review-commits.sh`) |
| Documentation ↔ itself: are references, statuses and open points intact? | `verify-domain-base.sh` |

The checks are shell scripts: they say "drift", "OK" or "could not check", never a silent pass.

## Adapting it

- Replace `com.example.starter` and the `catalog` / `ordering` examples in the constitution
  and `AGENTS.md` with your own base package and bounded contexts.
- Replace `PROJ-123` with your ticket key pattern.
- Spec-kit files are stock 0.16.2 except the blocks between `<!-- TRACE:BEGIN/END -->` and
  `<!-- TDD:BEGIN/END -->`; after `specify upgrade`, re-apply only those blocks.
  `workflow.verify` is named outside `speckit.*` so upgrades never overwrite it.
