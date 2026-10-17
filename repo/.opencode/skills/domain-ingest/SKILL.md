---
name: domain-ingest
description: Challenge new domain knowledge before it is written into docs/domain/. Use this skill whenever domain understanding is being brought into the repository — a whiteboard / modelling session to transcribe, a new bounded context, a new aggregate or invariant, a glossary term, a domain event, or a correction to what is already written. Triggers on "here is what we modelled on the whiteboard", "voici ce qu'on a modélisé", "add this context to the domain", "ajoute ce concept au domain", "on a défini un nouvel agrégat", "update the glossary", "mets à jour le domain model", "transcris la session de modelling". It reviews and challenges the incoming knowledge, writes the files only once the incoherences are resolved, and never invents domain content that was not given to it.
---

# Domain Ingest

New domain knowledge enters `docs/domain/` through this skill.

## Why this skill exists

`docs/domain/` sits upstream of everything. An incoherence frozen there under
`status: REVIEWED` contaminates every ticket that follows, and nobody will look at
it again — it will be read as established truth. The moment of transcription is the
moment a whiteboard ambiguity hardens into law.

A modelling session is allowed to be ambiguous. A file in `docs/domain/` is not.
The job here is to find where the ambiguity was, before it becomes invisible.

This skill is **not** `domain-challenge`. That one takes a ticket and asks whether
it fits the model. This one takes the model itself and asks whether it holds
together. Different inputs, different questions, different verdicts.

## What belongs here, and what does not

`docs/domain/` carries the slow substrate: the vocabulary, the context boundaries,
the aggregates and the invariants they guard — what a single feature cannot
invalidate. Use-case level material has a better home: acceptance scenarios,
functional requirements and the shape of one particular workflow accumulate in
`specs/{ID}-{short-name}/`, dated and traceable to the ticket that produced them
(Constitution, Principle V).

A modelling session hands you both, mixed — a board drawn by a team is full of
steps, screens and cases that only make sense as a future ticket. Setting that
material aside is not losing it: the board remains the source, and it re-enters the
repository as a `spec.md` when the ticket is worked. Writing it into `docs/domain/`
is what causes damage, because it freezes one chosen workflow as if it were the
domain, and nothing will re-examine it.

A board usually carries a third layer: the mechanics of the solution — endpoints,
queues, batches, retries, screens. None of it belongs in `docs/domain/`, and unlike
use-case material it has no later home either; it describes one implementation, and
the code is where it becomes true. Read it anyway, because it is good challenge
material: an integration nobody can attach to a context is an orphan (mode 4), and a
step that has to cross three contexts to complete usually marks a boundary drawn in
the wrong place (mode 3). Report what it revealed under Findings, and write none of
it.

This layer is harder to set aside than use-case material, precisely because it does
not look like a workflow — it looks like domain:

- A box named `Messaging`, `Integration` or `Reporting` reads as a bounded
  context. It is a technical grouping, and promoting it would create a top-level
  package that lies about what the system does (Constitution, Principle I — screaming
  architecture). Ask which language is coherent inside it; a technical box has no
  answer.
- An arrow labelled `POST /api/orders` or `publish to queue` reads as an event. It
  records no business fact — it is one component calling another, and the fact it
  happens to carry has a name of its own. Ask what changed in the business, not what
  moved between two systems.

Sorting is therefore part of the job, and the sorting itself can be wrong. A rule
stated as immutable business truth and a step in a process the team happened to
choose look identical on a whiteboard. Where you cannot tell which one you are
holding, that is a blocking question — not a call to make quietly. Either way,
report what you set aside (Step 7).

## Step 1 — Read what already exists

Read the whole of `docs/domain/`: `README.md`, `context-map.md`, `glossary.md`,
`decision-points.md`, and every file under `contexts/`. Read the provenance header of
each — its form, machine block and human quote alike, is fixed by
`docs/domain/README.md` § *Every file carries a provenance header*.

What each status claims is defined in `docs/domain/README.md` § *Status is not decoration*.
What is proper to this skill is the use made of it: when incoming knowledge
contradicts an existing file, **the status decides how loudly you object** —
contradicting a `DRAFT` is routine, contradicting a `STABLE` is a finding that must
be raised explicitly.

Read the markers that point at `decision-points.md` too —
`docs/domain/README.md` § *A blocked item says so where it is defined*. A definition
can be settled and blocked at once, so a file read on its status alone reads as
firmer than it is. And an incoming answer to a point already registered is not a new
open point: it resolves that one, by identifier.

**If the base is empty**, say so and change register: there is nothing to
contradict, so coherence with the existing model cannot be checked at all. You
check internal coherence only, and you state that limitation in the report. Do not
present a first ingestion as validated against a model that does not exist.

Where production code and behaviour tests exist, **the code wins**. A divergence
between incoming knowledge and running code is a finding, not a correction to apply
silently. One exception, and on a fresh repository it is most of the code: the `catalog` and
`ordering` contexts are starter-kit examples whose semantics carry no business
meaning — `.specify/memory/constitution.md` § *I. Domain-Driven Layered Architecture* (starter-kit examples). Their
types are not evidence about the project's domain, and a term matching one of them
is a coincidence, not a collision.

Read `specs/` as well. The directory names alone (`{ID}-{short-name}`) are a free
index of what has already been specified; a grep across `specs/*/spec.md` for the
terms you are about to write — and for their glossary synonyms, since a past spec
that named the same notion differently is exactly the case worth catching — finds the
rest. What you are looking for is knowledge the team already settled once, in a
ticket, and that is about to be restated differently here. A spec records intent at a
date and the code wins over it, so a divergence is a finding to raise, never a
correction to apply. If `specs/` is absent or empty — which it is until the first
feature is specified — say so and move on. Treat it as silence, never as "nothing has
been decided".

## Step 2 — Label every claim

Label every claim `founded`, `inferred` or `unknown` —
`.specify/memory/constitution.md` § *V. Domain Knowledge Is Written Down*.

Cite the artefact by path. Which one grounds a claim is part of the claim, so name
it: `docs/domain/` records the model the team accepted, a `spec.md` records what was
asked at a date, and code records what the system does.

Without this, an empty or thin base turns every inference into apparent knowledge.

## Step 3 — Look for the seven failure modes

These are what actually goes wrong when knowledge is transcribed. Go through them
in order; do not stop at the first.

**1. Contradiction.** An invariant that denies another invariant. A rule that
cannot hold at the same time as one already written. The classic form is two
statements that are each reasonable alone.

**2. Vocabulary collision.** The same term carrying two meanings **inside the same
context**. The same word in two different contexts is not a finding — it is two
types, per `docs/domain/glossary.md` § *Rules*. What you flag is a term introduced
with a meaning the glossary already gives to something else, or a second word for a
notion the glossary has already named.

**3. Blurred boundary.** An aggregate whose invariants reach across data it does
not own. A concept claimed by two contexts. A context whose responsibility, as
described, overlaps another's. If nobody can say which context owns a concept, the
boundary is wrong or a context is missing.

**4. Orphans.** An event emitted that nothing consumes. An event consumed that
nothing emits. A glossary term referenced nowhere. An aggregate that appears in no
flow. Orphans are usually the visible end of something that was discussed but not
captured.

**5. Silent regression.** The incoming knowledge contradicts what is already
written without acknowledging it. This is the most dangerous mode, because it looks
like an addition. Any change to an existing statement must be stated **as a change**:
what it said, what it now says, why.

**6. Divergence from the code.** Where the aggregate, the invariant or the flow
already exists in `src/main/java` or in a behaviour test, compare. The code is
authoritative. A divergence means either the model has moved and the code has not,
or the transcription is wrong — and that difference matters.

**7. Divergence from an existing spec.** A notion that contradicts something already
specified but not yet built. Mode 6 cannot see it, because there is no code to
compare against; mode 5 cannot either, because `docs/domain/` never carried the
statement in the first place. Yet the team answered that question once, in a ticket.
Name the spec and the `FR-NNN` it clashes with, and leave the arbitration to a human
— the spec may simply have been superseded without anyone rewriting it.

## Step 4 — Filter the questions

Same filter as `domain-challenge`:

> **If I got the opposite answer, what would I write differently?**

If the answer is "nothing", the question does not need asking. Only questions that
change a file's content survive.

Classify what survives:

| Class | Meaning |
|---|---|
| **Blocking** | Writing the file without an answer would record something false or self-contradictory |
| **Deferrable** | Can be written now, provided the question is registered and the item it blocks says so |
| **Noted** | An observation worth recording, not a question |

Only blocking questions go to the human.

Deferrable questions go to `docs/domain/decision-points.md` as an entry in the shape
fixed by `.specify/templates/domain-open-point-template.md`, and every item they
block carries its marker on the line that defines it —
`docs/domain/README.md` § *A blocked item says so where it is defined*. They are not
written as prose in the file they concern: an open point restated in three files
diverges in three directions, and its identifier — flat and permanent, of the form
`OP-<n>` — is what other files point at.

The schema is also what keeps the report short. The reasoning belongs in `issues`
and `decides`; the paragraph that introduces the reasoning does not.

## Step 5 — Stop

**Budget: 7 blocking questions.** Past that, stop asking and diagnose why there are
so many, because the diagnosis decides what happens next.

Group the blocking questions by root cause, and count the roots rather than the
questions. One unsettled point rarely produces a single question: whether the product
an order line refers to and the `Product` the catalog manages are one notion or two
poisons the glossary, the responsibility of two contexts and the relationship between
them, all at once. Eleven questions tracing back
to three roots is good news wearing bad clothes — three answers release all eleven.

- **As many roots as questions** — the batch is simply too large. Split it.
- **A few roots driving many questions** — the domain itself is unsettled. Splitting
  would carry the same roots into every piece and raise the same questions again.

How to split depends on which pass this is:

- a **depth pass** — one context's aggregates, events and flows — splits by context,
  then by aggregate;
- a **breadth pass** — glossary and context map — does not split by section. Its
  sections answer each other: the row, the term and the relationship are decided in
  the same breath, so cutting between them carries the same roots into each piece and
  re-asks the same questions. It also rarely needs cutting — a single breadth pass
  routinely settles every relationship and term of the map in one go. If it genuinely must be cut,
  cut by root cause. Depth material it turns up on the way is parked, never written
  in breadth (Step 6).

| Verdict | Meaning |
|---|---|
| **COHERENT** | Write the files. Say at which status. |
| **NEEDS ANSWERS** | *n* blocking questions (n ≤ 7). Nothing is written until they are answered. |
| **CONFLICTS** | The incoming knowledge contradicts what is already written or what the code does. The contradiction must be resolved by a human, not arbitrated here. |
| **TOO BROAD** | The blocking questions come from independent parts of the batch. Split it; each piece becomes answerable on its own. |
| **UNSETTLED** | The blocking questions trace back to a handful of points the team has never settled. Write nothing and name those points — they get settled in a modelling session, not in a transcription. |

A question the humans cannot answer either is not a failure of this step. It is the
most valuable thing it produces: it means the domain has a genuinely open point,
and it belongs in `docs/domain/decision-points.md` under its own identifier rather than
being resolved by whoever transcribes fastest.

## Step 6 — Write the files

Only on `COHERENT`, or on `NEEDS ANSWERS` once answered.

- Templates are read and instantiated, never rewritten.
  `.specify/templates/domain-context-template.md` fixes the shape of a context
  directory, `.specify/templates/domain-open-point-template.md` that of an open point.
  If the shape does not fit what you were given, say so and stop — changing it is a
  governance act, exactly like amending the constitution, and a form that drifts
  silently is how a base stops being comparable to itself.
- Write **only what was given to you**, plus what is strictly implied by it. If a
  section of the template has no content, leave it empty with a line saying so.
  Filling `events.md` with plausible events nobody mentioned is fabrication, and it
  will be read next month as something the team decided.
- Set the provenance header honestly: `source` names the actual origin and its
  date, `status` reflects how settled it really is, `updated` is today.
- Attribute every statement to a role — the product owner, the team — never to the person who
  relayed it, in the header as in the body: `docs/domain/README.md` § *Nobody is named*.
  The user running this skill is the team, not a name to write down.
- A context boundary, and a relationship between two contexts, is written **with the
  reason it was drawn there**. A boundary is a design choice, not an observed fact;
  stripped of its reason it reads next month as something nobody is allowed to
  question. One line is enough — what makes the language on that side coherent, or
  why the concept could not live in the neighbouring context.
- Statuses are defined in `docs/domain/README.md` § *Status is not decoration*.
  Default to `DRAFT`. Use `AGREED` when someone who knows the domain validated the
  content without reading the file — which is the usual case straight out of a
  modelling session, and what the first pass should have said instead of `REVIEWED`.
- Depth material surfaced by a breadth pass is **parked, not duplicated**. An
  invariant belongs in its context's `aggregates.md`; until that directory exists,
  record it under a section naming where it will go, and **move** it when the
  directory appears — out of the provisional place, in the same edit. Copying it
  leaves two files carrying the same invariant, which is failure mode 1 armed and
  waiting: the day one side is edited the base contradicts itself with no way to tell
  which side is right.
- Naming a context, detailing it and registering it are three separate acts —
  `docs/domain/README.md` § *Named, detailed, registered*. A breadth pass names: it
  writes the row in `context-map.md` and the terms in `glossary.md`, creates no
  `contexts/<name>/` directory, and registers nothing. The constitution stays empty
  until something is built; where an incoming context genuinely is a commitment to
  build, say that the Bounded contexts entry needs a MINOR amendment and do not amend
  it here.
- Deferrable questions go to `docs/domain/decision-points.md`, not into the files they
  concern (Step 4), and each item they block carries its marker where it is defined.

## Step 7 — The report

One page. This is what the human approves — not the files.

```markdown
# Domain ingest — [what is being brought in]

**Verdict**: COHERENT | NEEDS ANSWERS | CONFLICTS | TOO BROAD | UNSETTLED
**Base status before**: EMPTY | DRAFT | AGREED | REVIEWED | STABLE
**Files written**: [paths, and at which status — or "none yet"]

## Decided
- [what the incoming knowledge establishes, in one line each]

## Assumed
- [everything filled in that was not explicitly given — be exhaustive here]

## Set aside
- [received and deliberately not written — name where it belongs instead, with the
  ticket to create for it, or say that it belongs nowhere in this repository]

## Findings
- [contradiction / collision / boundary / orphan / regression / code or spec divergence]
- [each one names the file and statement it clashes with]

## Blocking questions
1. [question] — *what changes depending on the answer*

## Roots
1. [the unsettled point behind them] — *drives 5 of the 11*

## Open points registered
- [each identifier added to `docs/domain/decision-points.md`, its question in one line,
  and the items it blocks]

→ Approve / Amend / Reject
```

Be exhaustive under **Assumed**. That section is the whole point: what was decided
is visible in the files, what was assumed is not.

**Set aside** is the same argument pointed the other way. Say how much came in and
how much was written — "thirty notions received, twenty written" is the reviewable
fact. A reader who sees only the twenty cannot tell whether the other ten
were correctly out of scope or quietly dropped, and by the time anyone wonders, the
board is closed and nobody remembers. A section with nothing to report is left out;
this one rarely has nothing to report.

Use-case material set aside gets a **ticket to create**, named in that section — one
per coherent chunk, not one per sticky note, parented to the ticket that triggered the
session if there is one. Saying "this is out of scope" leaves it in the board and
nowhere else; naming the ticket is what makes it come back, as a `spec.md`, through
the normal chain. You do not create the tickets — that is the human's call, and their
bodies are written with the skill `ticket-writer` — but an item listed without a
proposed ticket is an item being dropped, and the report should not disguise one as the
other.

Solution mechanics is the exception: it gets no ticket and no file. It is reported
because of what it revealed, not because it needs a home.

**Roots** appears only when there are blocking questions, and it is what tells the
human what to do with them. Give each root the number of questions it drives. Eleven
questions listed flat read as "the domain is a mess"; three roots driving eleven read
as "answer these three" — same facts, opposite decisions.

## Red Flags

| Thought | Reality |
|---|---|
| "The base is empty so there is nothing to check" | Internal coherence is still checkable. Say what you could not check. |
| "This mostly matches what's written, close enough" | "Mostly" is a contradiction with a polite name. Name it. |
| "I'll fill in the obvious events while I'm here" | Nobody said them. That is fabrication with a long half-life. |
| "The code does it differently, I'll write the model version" | The code wins. The difference is a finding. |
| "I'll mark it REVIEWED, we discussed it at length" | Discussion is not review. Content validated in session, with nobody having read the file, is `AGREED`. |
| "The code does it that way, so that is the domain" | Not in the `catalog` and `ordering` packages — they are starter-kit examples with no business meaning. |
| "I'll note the open question in the file it concerns" | It goes to `docs/domain/decision-points.md`, once, and the item it blocks carries its marker. Restated in three files, it diverges three ways. |
| "The template does not quite fit, I'll adjust it" | Changing a template is a governance act, like amending the constitution. Say so and stop. |
| "I'll copy the invariant here and tidy up when the context directory exists" | Copy it and two files carry it. Park it, and move it — failure mode 1 does not wait. |
| "Same word in two contexts, I'll factor it out" | That is exactly what DDD forbids. Two types. |
| "It was on the board, so it belongs in the model" | Boards carry use-case material too. That goes to a `spec.md` later, not to `docs/domain/` now. |
| "The boundary is obvious, no need to justify it" | Obvious today, unquestionable next month. A boundary without its reason stops being a choice. |
| "`Messaging` is one of their contexts, it was a box on the board" | A technical grouping is not a bounded context. Ask which language is coherent inside it. |
| "The board shows a call between two systems, that is an event" | A call is not a business fact. Name what changed in the business, or write nothing. |
| "Fifteen things to clarify, let me list them all" | Past seven, stop and group them by root cause. Whether to split the batch or to send it back to modelling depends on how many roots there are, not on how many questions. |
