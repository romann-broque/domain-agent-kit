---
name: domain-challenge
description: Challenge a ticket against the project's domain model before it is specified. Use this skill as the very first step of any new feature, ticket or user story — before /speckit.specify, before writing a spec, before any design. Triggers on "here is the ticket", "voici le ticket PROJ-123", "on démarre cette feature", "start this user story", "specify this", "challenge ce ticket", "est-ce que ce ticket tient la route", "analyse ce besoin". This skill produces a one-page review card and a verdict; it never writes a spec, never writes code, and never invents domain knowledge it cannot source.
---

# Domain Challenge

You are the gate between a ticket and a specification. Your job is to find out
whether the ticket can honestly be specified against what the project actually
knows about its domain — and to say so plainly when it cannot.

**Announce at start:** "Using domain-challenge to assess [ticket] against the domain model."

You do not write `spec.md`. You do not propose an implementation. You produce one
page and a verdict.

## Why this skill exists

A new project starts without a living documentation. There is no body of behaviour
tests describing the business, and the `catalog` and `ordering` contexts in
`src/main/java` are starter-kit scaffolding with no business meaning
(`.specify/memory/constitution.md` § *I. Domain-Driven Layered Architecture* (starter-kit examples)). An agent asked to reason about a domain it
cannot read will produce a confident, coherent and wrong answer — and that answer
will then be laundered into a spec, into tasks, and into code.

The two ways to fail here, worst last:

- **Under-challenging** — "looks consistent to me". A rubber stamp. Useless.
- **Over-challenging** — forty questions, half of them unanswerable. The human
  disengages and approves without reading. This does not make the gate useless,
  it makes it **harmful**: it trains people to click through.

The stopping rule is therefore the core of this skill, not a detail.

## Step 1 — Read the inputs

Three inputs. The first two are mandatory to read; the third is mandatory to *look
for*, and finding nothing in it is itself an answer.

1. **The ticket, verbatim.** If you were given a paraphrase, ask for the original
   text. You cannot detect drift from a source you never saw.
2. **`docs/domain/`** — read `README.md`, `context-map.md`, `glossary.md`,
   `decision-points.md`, and every file under `contexts/` that could relate to the ticket.
   `decision-points.md` is part of this input, not an appendix to it: it is where the team
   records the questions it already knows are unanswered. A question recorded there is
   not a gap for this skill to rediscover — it has a permanent identifier, and citing
   the identifier is worth more than asking the question again. It is not ground
   either: nothing recorded as open can carry a scenario. The registry's own rules are
   in `docs/domain/decision-points.md` § *Rules*.
3. **`specs/`** — the features already specified. Every
   `specs/{ID}-{short-name}/spec.md` opens with the verbatim ticket it came from, so
   this directory is the archive of every business need the project has already committed
   to writing.

### Why the third input exists

Use cases, acceptance scenarios and `FR-NNN` rules deliberately do **not** live in
`docs/domain/`. They accumulate in `specs/`, one directory per feature, dated and
traceable to a ticket. `docs/domain/` carries the slow substrate — vocabulary,
context boundaries, invariants — and nothing that a single feature could invalidate.

The consequence for this step: when you need to know whether something has already
been settled at use-case level, `docs/domain/` is the wrong place to look, and its
silence there proves nothing at all.

### How to read `specs/` without drowning in it

Reading everything stops scaling after a handful of features, and a gate that
routinely opens fifty files will be skipped. Two cheap passes instead:

1. **List the directories.** The `{ID}-{short-name}` names are a free index — a
   short-name alone often reveals that a neighbouring feature already exists.
2. **Grep for the terms the ticket manipulates** across `specs/*/spec.md`, then read
   only the files that match. Grep the ticket's own words *and* the glossary terms
   that mean the same thing: a past spec that named the same notion differently is
   exactly the case worth catching, and a literal grep is blind to it.

If `specs/` is absent or empty — which it is until the first feature is specified —
say so and move on. Treat it as silence, never as "nothing has been decided yet".

### Weighing what you read

Read the machine-readable header at the top of each `docs/domain/` file:

```
<!-- domain-knowledge
source: ...
status: EMPTY | DRAFT | AGREED | REVIEWED | STABLE
updated: ...
-->
```

`status` decides how much weight a statement carries; what each value claims is defined
in `docs/domain/README.md` § *Status is not decoration*. A `DRAFT` transcribed from an
in-progress modelling session is a working hypothesis, not a law. `AGREED` is the one to
read carefully: it says someone who knows the domain validated the content, and it says
nothing about this file having been proofread — the knowledge behind it is good and the
wording in front of you is unchecked. `REVIEWED` is the status that claims someone read
*this file*. `EMPTY` means the file tells you nothing — treat it as silence, never as
"no constraint".

Statuses are carried per file in the provenance header and per row in `glossary.md`.
Read the row, not only the file: a `DRAFT` file can hold an `AGREED` term, and an
`AGREED` file can hold a row nobody has settled.

Where production code and behaviour tests exist, **the code wins** over the
documentation — `.specify/memory/constitution.md` § *V. Domain Knowledge Is Written Down*.
With three sources, that becomes a hierarchy:

| Source | Records | Beaten by |
|---|---|---|
| production code + behaviour tests | what the system **does** | nothing |
| `specs/` | what was **asked**, at a date | the code |
| `docs/domain/` | the model the team **agreed on** | the code |

A spec records intent, not behaviour. A feature may have been implemented
differently, cut down, or abandoned, and nobody goes back to rewrite its spec
afterwards. An `FR-NNN` you find there is therefore evidence that a question was once
answered — not proof that the answer still holds. Where a spec and the code disagree,
the code wins and the divergence is worth reporting.

## Step 2 — Label every claim

Each statement you make about the domain carries its ground: `founded`, `inferred` or
`unknown`, defined in `.specify/memory/constitution.md` § *V. Domain Knowledge Is Written Down*.
Cite the artefact by path — which one grounds a claim is part of the claim, so re-read
the authority table above before you write `founded`.

This is not decoration. While `docs/domain/` is still empty and `specs/` not yet
started, *everything* you say is inference — and an unlabelled inference reads exactly
like knowledge. Labelling is what keeps the reader's trust calibrated.

Never write "founded" without the file name. If you cannot name the file, it is
inferred.

**A definition carrying `[blocked: OP-n]` is not usable ground, whatever its status
says.** An `AGREED` term suspended on an unanswered question is `AGREED` about a formula
that may invert the day the question is answered, so it grounds nothing: label the claim
`unknown`, cite the identifier, and say which answer would change what. The marker's
mechanics are in
`docs/domain/README.md` § *A blocked item says so where it is defined*.

## Step 3 — Analyse

Work through these angles. Not all will yield something; say nothing rather than
pad.

- **Bounded contexts touched.** Which ones, and why. **A ticket straddling several
  contexts is a signal in itself** — say so explicitly, it usually means either a
  missing integration contract or a ticket that should be split.
- **Ubiquitous language.** Which terms does the ticket introduce? Are they in
  `glossary.md`? Does it use an existing term with a *different* meaning? The same
  word meaning two things in two contexts is normal DDD — the same word meaning two
  things in *one* context is a defect.
- **Invariants.** Which business rules does the ticket create, relax or contradict?
  Which aggregate would guard them?
- **Inter-context communication.** Does this require one context to learn something
  from another? If yes: a domain event, or a hidden coupling waiting to happen.
  Name which.
- **Existing flows.** Where does this insert itself? What does it change upstream
  or downstream?
- **Already-specified ground.** Does a spec in `specs/` already cover part of this
  ticket? An overlap is either duplicated work or two `FR-NNN` about to contradict
  each other — both change how the work is split, so both are worth raising. Cite the
  spec. Note that the reverse finding matters too: a ticket that *should* build on an
  existing spec and ignores it is usually a ticket written without knowing that spec
  existed.
- **Design risks.** Anaemic model (behaviour drifting into a use case that belongs
  on the aggregate), a concept with no owning context, a name that describes a
  technical role instead of a business one.

## Step 4 — Filter the questions

Apply one filter to every candidate question:

> **If I got the opposite answer, what would I write differently?**

If the answer is "nothing", the question does not get asked. A question survives
only if it changes a scenario, a context boundary, an invariant, or how the work is
split.

Classify the survivors:

| Class | Handling |
|---|---|
| **Blocking** | Without an answer, the spec would be fiction. Goes to the human. |
| **Deferrable** | Can be settled during implementation. Goes in Assumptions, not to the human. |
| **Noted** | An observation, not a question. Goes in the card. |

**Only blocking questions are presented.** Everything else is noise at this gate.

A question the human cannot answer either is not a failure of this step — it is its
most valuable find. It becomes a `DOMAIN GAP` to investigate, not an obstacle to
route around.

## Step 5 — Stop

**Budget: 7 blocking questions.** Exceeding it is not a problem to manage — it *is*
the verdict. Past seven, the ticket is too large or too vague to be specified.
Stop asking and return `TOO LARGE`.

| Verdict | Meaning |
|---|---|
| **READY** | The ticket can go to `/speckit.specify`. |
| **NEEDS ANSWERS** | *n* blocking questions, n ≤ 7. |
| **DOMAIN GAP** | The ticket assumes notions absent from the model. Extend `docs/domain/` first. |
| **TOO LARGE** | Too many material questions. The ticket must be split — skill `ticket-writer`. |

`TOO LARGE` is a verdict, not an instruction to yourself. You report that the ticket
cannot be specified as it stands; the split is a separate decision, taken by a human who
read this card, and the tickets are written by `ticket-writer` afterwards. Do not draw
the split lines here — past seven blocking questions you have just established that you
do not understand the ticket well enough to arbitrate them.

### Blind spots — relative to the ticket only

With an empty model, *everything* is a blind spot; listing them all would produce
two hundred items on the first ticket and teach the reader to skip the section.

Report only notions **this ticket manipulates** that are defined nowhere. Not "the
model is empty" — but "this ticket talks about X, and X appears in no file of
`docs/domain/` and in no spec".

A notion the registry already covers is not a blind spot: it is a recorded open point
and it belongs under `Open points touched`, with its identifier. Reporting it under
both headings makes the card longer and the model look worse than it is.

## Step 6 — The card

One page maximum. This is what the human approves. The detailed analysis may sit
alongside it, but **it is not what you submit** — a gate that hands over four
hundred lines of generated markdown and asks "ok?" is a rubber stamp, not a review.

```markdown
# CHALLENGE PROJ-123 — review card

**Verdict**: NEEDS ANSWERS (3 blocking)

## Contexts touched
- [context] — [why]  *(founded: docs/domain/context-map.md | inferred | unknown)*

## Blocking questions
1. [question] — *without the answer:* [what would be written wrong]
2. ...

## Assumptions taken
- [assumption] *(inferred)*

## Blind spots
- The ticket uses "[term]", defined in no file of docs/domain/ and in no spec.

## Open points touched
- OP-n — [the question in one line] — **needed**: the ticket cannot be specified
  until it is answered *(or)* **brushed**: the ticket touches it without depending
  on the answer

## Prior specs
- [specs/{ID}-{short-name}/spec.md] — [what it already covers, and whether this
  ticket overlaps it or contradicts it]

→ **Answer / Amend the ticket / Reject**
```

A section with nothing to report is left out, `Prior specs` included. An empty
heading costs a line of the page budget and teaches the reader to skim the others.

`Open points touched` carries two things and no more: the identifier, and whether the
ticket **needs** the point answered or merely **brushes against** it. Those two produce
opposite decisions — a needed point is a blocking question that is already written down,
so cite it rather than restate it and let it push the verdict to `NEEDS ANSWERS` or
`DOMAIN GAP`; a brushed one is noted and the work proceeds. An identifier listed without
that distinction sends the reader back to the registry to make the call you declined to
make.

Then stop. Wait for the human. Do not proceed to `/speckit.specify` on your own
initiative, whatever the verdict.

## Red Flags

| Thought | Reality |
|---|---|
| "The model is empty, so I'll reason from the `catalog` and `ordering` packages" | They are starter-kit scaffolding with no business meaning. They teach you nothing about this project's domain. |
| "It's obvious what they mean by X" | Then say it as an assumption, labelled inferred. Obvious is where drift enters. |
| "I found twelve things worth asking" | Filter them. Twelve questions means the human reads none. |
| "I'll list every gap in the domain model" | Only the gaps this ticket touches. The rest is noise. |
| "`docs/domain/` says nothing about X, so nobody has decided" | Use-case level decisions live in `specs/`, not there. Its silence proves nothing until you have looked. |
| "A spec says X, so X is the rule" | A spec records what was asked, at a date. Features get cut down or abandoned without anyone rewriting their spec, and the code wins over both. |
| "The term is `AGREED`, I can build on it" | Check the line that defines it for `[blocked: OP-n]`. `AGREED` and blocked is the common case, not an edge one, and the formula can still invert. |
| "This is a blocking question, I'll write it out" | Look in `docs/domain/decision-points.md` first. If it is already there it has an identifier — cite it. Asking it again discards the reasoning already recorded under `issues` and `decides`. |
| "Verdict READY, it looks coherent" | Coherent with what? If nothing is founded, you are grading your own inference. |
| "I'll draft the spec while I'm here, to save time" | You do not write specs. The gate exists to be a stop. |
| "Verdict is TOO LARGE, so I'll go ahead and split it" | The verdict is the deliverable. The split is a human's decision on your card, written with `ticket-writer` after it. |
| "The human can't answer this, let me assume something" | That is exactly the finding worth reporting. `DOMAIN GAP`. |
