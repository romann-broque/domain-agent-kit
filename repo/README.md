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
│   ├── memory/constitution.md the project constitution (v1.0.0, to adapt)
│   ├── templates/             spec, plan, tasks, checklist, constitution, domain context, open point
│   ├── scripts/bash/          spec-kit scripts + verify-* mechanical checks (and their tests)
│   └── workflows/             spec-kit workflow definition
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
| 6 | `/speckit.implement` → `test-first` → `craftsman` | failing test (RED), then minimum code (GREEN) |
| 7 | `/workflow.verify`, `code-reviewer`, `/speckit.converge` | evidence check, diff review, spec-vs-code gap |
| 8 | `review-triage` skill | human PR comments classified and routed back to the right step |

`docs/WORKFLOW.md` tells the same story in more detail.

## Adapting it

- Replace `com.example.starter` and the `catalog` / `ordering` examples in the constitution
  and `AGENTS.md` with your own base package and bounded contexts.
- Replace `PROJ-123` with your ticket key pattern.
- Spec-kit files are stock 0.16.2 except the blocks between `<!-- TRACE:BEGIN/END -->` and
  `<!-- TDD:BEGIN/END -->`; after `specify upgrade`, re-apply only those blocks.
  `workflow.verify` is named outside `speckit.*` so upgrades never overwrite it.
