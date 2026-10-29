<!-- domain-knowledge
source: none yet — skeleton shipped with the workflow, before any ingestion
status: EMPTY
updated: YYYY-MM-DD
-->

# Domain Knowledge

> **Source**: none yet — skeleton shipped with the workflow, before any ingestion
> **Status**: EMPTY
> **Authority**: descriptive — where production code and behaviour tests exist, the code wins

This directory is the written memory of the domain. It exists so that the
understanding built during modelling sessions, design discussions and code reviews
survives the meeting it happened in, and so that agents reasoning about the domain
have something to read other than scaffolding.

It is governed by `.specify/memory/constitution.md` § *V. Domain Knowledge Is Written Down*.

## Current state

Nothing has been ingested yet. `glossary.md`, `context-map.md` and `decision-points.md`
carry `EMPTY` and the shape their first entries will take, as commented-out examples;
`contexts/` holds no context.

The consequence for an agent: **every domain question is a gap** until this base
says otherwise. Say so, rather than inferring a plausible answer — that is what the
`DOMAIN GAP` verdict of the `domain-challenge` skill is for. The first ticket that hits
a gap is the invitation to fill it, through the `domain-ingest` skill. The base grows
one question at a time.

Replace this section with what is actually known once the first pass has been made.

## What belongs here, and what does not

This directory carries the **slow substrate** of the domain: the vocabulary, the
bounded contexts and why their boundaries were drawn there, the aggregates and the
invariants they guard. What a single feature cannot invalidate.

A modelling session produces more than that, mixed together on the same board. The
rest has other homes, and putting it here is not a shortcut — it is a loss:

| What arrives | Where it goes | Why not here |
|---|---|---|
| Vocabulary, contexts, boundaries, invariants | here | — |
| Use cases, acceptance criteria, "who does what when" | a ticket, then `specs/{NNN}-{short-name}/spec.md` | it is dated and traceable there; here it freezes one chosen workflow as if it were the domain, and nothing will re-examine it |
| Endpoints, queues, batches, retries, screens | nowhere in this repository — the code is where it becomes true | it describes one implementation among several |

Setting material aside is not losing it: the board remains its source, and use-case
material re-enters the repository as a `spec.md` when its ticket is worked. Whoever
sets it aside says so in the report, and names the ticket that will carry it.

Sorting is part of the work, and **the sorting itself can be wrong**. A rule stated
as immutable business truth and a step in a process the team happened to choose look
identical on a whiteboard. *An order holds at least one line* is the first kind;
*an order is confirmed by email* is likely the second. Where the two cannot be told
apart, that is a question to ask out loud, not a call to make quietly.

## Layout

```
docs/domain/
├── README.md              the rules of this base
├── decision-points.md     the registry — every open point, by permanent identifier
├── glossary.md            the ubiquitous language
├── context-map.md         which contexts exist, and how they relate
├── contexts/<name>/       overview · aggregates · events · flows
├── shared/                overview · aggregates — the declared kernel
└── core/                  overview · aggregates — the cross-cutting mechanism
```

`shared/` and `core/` hold the model of things that are not bounded contexts but
still have one. They use a reduced two-file shape: a kernel publishes no events and
orchestrates no flows.

A directory appears under `contexts/`, `shared/` or `core/` only when there is depth
material for it. Their shape is fixed by
`.specify/templates/domain-context-template.md`.

## Named, detailed, registered

Three states, not two, and they are reached separately.

| State | What it means | Where it shows |
|---|---|---|
| Named | The team knows this context exists and can say what it is responsible for. | A row in `context-map.md`, terms in `glossary.md`, `Directory` reading `—` |
| Detailed | Its aggregates, invariants, events and flows are written down. | A directory under `contexts/<name>/`, and `Directory` pointing at it |
| Registered | The project has committed to building it. | A top-level package declared in `BoundedContextIsolationRulesTest`, per `.specify/memory/constitution.md` § *Additional Constraints* |

Naming is not registering. This base describes the domain, including the parts
nobody intends to build — a `catalog` context can be named and detailed long before,
or without ever, getting a package. Keeping the states apart is what preserves the
difference between "we know this exists" and "we committed to building it".

## Rules

### Every file carries a provenance header

Both a machine-readable block and a human-readable quote, at the very top:

```markdown
<!-- domain-knowledge
source: modelling session on ordering, 2026-01-15
status: DRAFT
updated: 2026-01-15
-->

> **Source**: modelling session on ordering, 2026-01-15
> **Status**: DRAFT
> **Authority**: descriptive — where production code and behaviour tests exist, the code wins
```

The machine-readable block is what tooling reads. The quote is what a human reads.
They must agree field by field, character for character: `status` is one bare token
from `docs/domain/README.md` § *Status is not decoration*, and `source` is the same
string in both places rather than a rephrasing of it.

Qualifying a header field is how the two drift apart. A status reading
`DRAFT — breadth only` is no longer a token anything can match, and what it adds
belongs in the file's `Current state` section, which is what a reader opens for
exactly that. A header states; the body explains.

When a later pass changes a file, it appends to `source` — `; ordering detailed from
the review of PROJ-123, 2026-02-03` — and moves `updated`. The source is the file's
change log; it says what came from where, not who said it.

Tooling reads **the first `domain-knowledge` block of the file** and ignores any
later occurrence — the example above is itself one, and must not be mistaken for
this file's header.

### Status is not decoration

| Status | Meaning |
|---|---|
| `EMPTY` | The file is a placeholder. It contains no knowledge. |
| `DRAFT` | Transcribed from an in-progress discussion. A working hypothesis, not a settled fact. |
| `AGREED` | The content was validated by someone who knows the domain — in a session, without this file having been read. |
| `REVIEWED` | Someone read **this file** and can say whether it is right. |
| `STABLE` | Reviewed, and confirmed by code that implements it. |

`AGREED` and `REVIEWED` are not degrees of confidence, they are different claims. A
definition of *order line* the product owner settled in a modelling session is
`AGREED`: the knowledge is good, and nobody has checked that this file transcribes it
faithfully. Collapsing the two is how a transcription error inherits the authority of
the discussion it came from.

A status can be carried by a whole file, in its provenance header, or by a single row
of a table — `glossary.md` does the latter, per term. The meanings are the same
either way.

A `DRAFT` must never be treated as settled. An agent quoting a `DRAFT` must say
that it is one.

### A blocked item says so where it is defined

A term, an invariant or a relationship whose definition is suspended on an unanswered
question carries `[blocked: OP-<n>]` on the line that defines it, and the matching
entry in `docs/domain/decision-points.md` names it under `blocks`.

This is orthogonal to `status`. A definition can be `AGREED` and blocked at the same
time: agreeing on what an order line is does not settle whether it may name a product
the catalog has withdrawn. An agent that filters on `status` alone will build on a
definition that cannot be trusted yet — the marker is what stops it, which is why it
is on the line and not in a paragraph beside it.

### Cross-references name a file and a section

A rule has one home. Everywhere else it is referenced, never restated, in this
form:

    `docs/domain/README.md` § *Status is not decoration*

The path is relative to the repository root, so the same string works from any file
and from any tool. The section title is matched against the target's headings. A
reference survives a section being promoted or demoted; it does not survive a
rename, which is deliberate — renaming a section is exactly when the reader needs to
be told.

The whole reference sits on one line, even where that pushes the line past the
120-column guide. A reference broken across a line break is found by no grep and by
no reader either, which costs more than the long line.

Headings here are not numbered, for the same reason: a number in a title invalidates
every pointer to it the moment a rule is inserted above it or removed.

Referencing costs a click; duplicating costs a contradiction nobody notices.

### This documentation is descriptive, the code is authoritative

At the start of a project `docs/domain/` is the only source of domain knowledge,
because there is no domain code. That will change. When production code and behaviour
tests implement a rule, **they become the reference** and this documentation must be
corrected to match — never the other way round.

Settling this now avoids arbitrating it in a hurry the first time the two diverge.

### Claims are attributable

Any statement about the domain — in a spec, a review, an analysis — is labelled
`founded`, `inferred` or `unknown`, defined in
`.specify/memory/constitution.md` § *V. Domain Knowledge Is Written Down*.

Cite the artefact by path: which one grounds a claim is part of the claim, because
the three kinds do not carry the same weight. Unlabelled claims are how an empty
model turns into confident fiction.

### Nobody is named

A statement is attributed to a role — *the product owner*, *the team*, *the human* —
never to a person. Not in a `source`, not in a decision, not in a change log: *from the
answers the product owner gave in a refinement meeting, 2026-01-20*, not *relayed by*
someone.

What a reader needs is the weight of a statement, and the role carries it: an answer of
the product owner settles what a statement of the team only proposes. A name adds no
weight, goes stale when the team changes, and puts personal data in a base meant to
outlive everyone who wrote it. Who relayed what is already in the git history, which is
where it belongs.

`.specify/scripts/bash/verify-domain-base.sh` reports any name of a commit author found
under `docs/domain/`. It cannot see a name nobody has committed under; the rule still
holds there.

## How to enrich it

1. Sort first. Only the slow substrate is written here — see *What belongs here, and
   what does not*. Name what you set aside, and where it goes instead.
2. Transcribe what was decided, in the vocabulary that was actually used — not a
   cleaned-up version of it.
3. Write a boundary, and a relationship between two contexts, **with the reason it
   was drawn there**. A boundary is a design choice, not an observed fact; stripped of
   its reason it reads next month as something nobody is allowed to question.
4. Set `source` to where it came from (a modelling board with its date, a discussion,
   a code reading) and `status` to `DRAFT`. Who said it is a role, never a person —
   see *Nobody is named*.
5. Add every new term to `glossary.md`, with the context it belongs to.
6. Register every question you could not answer in `decision-points.md`, and mark what
   it blocks.
7. Promote to `AGREED` when someone who knows the domain has validated the content,
   and to `REVIEWED` once someone has read the file itself against it.

The skill `domain-ingest` runs this sequence and reports what it set aside; see
`docs/WORKFLOW.md`. Doing it by hand is fine — the sorting step is not optional
either way.

Partial knowledge with an honest header is worth more than a polished document
nobody can date.
