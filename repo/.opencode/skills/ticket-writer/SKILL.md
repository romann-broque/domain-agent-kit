---
name: ticket-writer
description: Write tickets in the standard JIRA format, and split a ticket whose scope is too large into independent sibling tickets. Use this skill whenever a ticket body has to be produced — after domain-challenge returned TOO LARGE, for the tickets domain-ingest names as set aside, or on a direct request. Triggers on "split this ticket", "découpe ce ticket", "on split en plusieurs tickets", "write the ticket", "écris le ticket", "fais-moi les tickets JIRA", "formate ce ticket pour JIRA", "crée les tickets", "ce ticket est trop gros". This skill produces ticket bodies to paste into JIRA; it never writes a spec, never writes code, and never creates anything in JIRA itself.
---

# Ticket Writer

You turn a need into ticket bodies the team can act on. Nothing else — you produce
text to paste into JIRA, and you stop.

**Announce at start:** "Using ticket-writer to write [n] ticket(s) for [subject]."

You do not write `spec.md`. You do not propose an implementation. You do not create
issues in JIRA — you have no access to it and the creation is the human's act.

## Why this skill exists

Two places in the workflow produce a ticket and then dead-end:

- **`domain-challenge` returns `TOO LARGE`** — the verdict says *split the ticket* and
  says nothing about who splits it or in what shape. The skill stops there on purpose:
  it is a gate, and `.opencode/skills/domain-challenge/SKILL.md` § *Red Flags* forbids
  it to draft anything downstream.
- **`domain-ingest` sets material aside** and names a ticket to create per coherent chunk
  of use-case material, and never writes its body.

Both hand over a name and an intent. This skill writes the body, in one shape, so that
two tickets written a month apart are readable the same way — and so that the verbatim
block at the top of a future `spec.md` has a single stable source.

The failure this guards against is not an ugly ticket. It is a **split that loses
scope**: four tickets that together deliver less than the one they replaced, with
nobody able to point at what evaporated.

## Step 1 — Read the inputs

1. **The parent ticket or the need, verbatim.** If you were given a paraphrase, ask for
   the original text. You cannot split what you have not read, and a split derived from
   a summary silently re-scopes the work.
2. **The `domain-challenge` card**, when the trigger is a `TOO LARGE` verdict. It
   carries the blocking questions, the contexts touched and the open points — that is
   the material the split lines are drawn along. Without it you have no basis for
   arbitrating anything.
3. **`docs/domain/decision-points.md`** — an unresolved question that blocks a ticket has an
   identifier there. Cite `OP-n`; do not restate the question in your own words.
4. **`docs/domain/glossary.md`** — use the agreed term where one exists. A ticket that
   invents a synonym for a settled notion costs the team a translation on every read.

## Step 2 — Draw the split

Only when there is more than one ticket to write. Four rules, in order of how often
they are broken.

**Split by capability, never by layer.** A split into "domain layer", "persistence" and
"endpoint" produces tickets no product owner can validate and no `spec.md` can express as a user
story. Each ticket must deliver something observable to someone.

**Cover everything.** Every element of the parent lands in exactly one child, or in an
explicit `Out of scope` of the split. Nothing evaporates. This is the only guard against
a split that quietly shrinks the work, and it is the check to run last, against the
parent text, before handing over.

**Keep each ticket independent.** A ticket that cannot state its acceptance criteria
without naming another ticket's deliverable is either to be merged back, or to be linked
`is blocked by`. There is no third option.

**One ticket, one branch, one spec, one PR.** That is the profile of a story, so the
links are `is blocked by` and never sub-tasks. It also sets the size: a chunk too small
to deserve its own branch belongs inside a sibling.

`EPIC` is not in scope here. An epic is far larger than a handful of tickets. A split produces sibling tickets, all of them stories.

## Step 3 — Write

Write the blocks into `tickets/<slug>.md`, where `<slug>` names the subject in
kebab-case — the parent ticket for a split, the need otherwise. `tickets/` is
git-ignored on purpose: JIRA is the record and this file is a paste buffer, which is
precisely why it does not sit committed next to `specs/`.

If that file already exists, rewrite it in place. Never open a second file with a
suffix. The human edits it between two runs, so read it before overwriting and say what
your rewrite changed.

One block per ticket. The heading is the JIRA Summary — do not repeat it as a field, and
do not number the tickets: a number shifts the moment one is added or dropped, and every
cross-reference below is by name for that reason.

The table appears only when there is more than one ticket.

````markdown
## To paste into JIRA

One block per ticket. The heading goes into the JIRA Summary field, the rest into the
description.

| Ticket | Status at creation | Blocked by |
|---|---|---|
| <ticket name> | To Do | — |
| <ticket name> | To Do | <ticket name> |
| <ticket name> | Blocked | OP-<n>, OP-<m> |

---

### ▸ <Ticket name — one line, imperative>

**Links**
- `is blocked by`: <ticket name>
- Split from: <parent JIRA key, e.g. PROJ-123, or "initial request of <date>">

**Context**
<1 to 3 sentences: why this ticket exists, what problem it addresses>

**Scope**
- <what is delivered>

**Acceptance criteria**
1. <verifiable fact>

**Out of scope**
- <what is explicitly excluded, and where it goes: ticket name, or nowhere>

**Open points**
- <unresolved question, with its OP-n reference if it is in docs/domain/decision-points.md>
````

How to fill each field:

**Heading** — one line, imperative, business vocabulary. It is what the team reads in a
backlog list, so it has to be legible out of context.

**Links** — `is blocked by` names sibling tickets by their heading. `Split from` records
the origin: a JIRA key when the parent exists as a ticket, otherwise the dated request
or the modelling session that produced it.

**Context** — the *why*. One to three sentences. It reads the same whether the
implementation is one line or one thousand.

**Scope** — what is delivered, in business terms. Not a task list, not a file list.

**Acceptance criteria** — numbered, each one a fact someone can check. These are what
`/speckit.specify` turns into Given/When/Then scenarios, so a criterion that cannot be
observed will not survive the next step. Write the invariant, not the test.

**Out of scope** — what is deliberately excluded, and where it went. `"…, in <ticket
name>"` or `"…, nowhere"`. This field is what makes a split honest; leaving it empty on
a split is almost always an omission.

**Open points** — unresolved questions, cited by `OP-n` where they are registered. **An
open point that prevents starting sets `Status at creation` to `Blocked`.** A ticket
created as `To Do` while an answer is missing will be picked up and stall.

A field with nothing to report is left out. Do not write "None." — an empty heading
costs a line and teaches the reader to skim the others.

**Language: English.** Tickets are written in English from the start, so they are never
translated — and a translation of a ticket is an interpretation of a ticket. The
verbatim block of a future `spec.md` quotes this text as-is.

## Step 4 — Stop

Hand over the path and the headings you wrote — not the bodies. They are in the file;
reprinting them makes a second copy of the same text, and the two diverge the moment the
human edits one of them. The human reads the file, reworks it if needed, and creates the
tickets in JIRA.

Once pasted, **JIRA is the record**. `spec.md` will quote that description verbatim and
`/workflow.verify` will check the rest of the chain against it, so a later change of mind
is an amendment made in JIRA and re-quoted — not a quiet edit of the local file, which
is only a buffer and is authoritative over nothing.

Do not proceed to `/speckit.specify`, and do not start on a ticket you just wrote.

## When to refuse

| Situation | What to do |
|---|---|
| The parent ticket was given as a paraphrase | Ask for the verbatim text. Do not split from a summary. |
| A split is asked for with no `domain-challenge` card | Refuse the split — you have nothing to draw the lines along. Offer to run `domain-challenge` first. Writing a single ticket is still fine. |
| The split would produce a ticket with no acceptance criteria | It is not a ticket. Merge it into a sibling or say what is missing. |
| You are asked to also write the spec | You write tickets. `/speckit.specify` is a separate step behind a human gate. |

## Red Flags

| Thought | Reality |
|---|---|
| "I'll split it into domain / persistence / endpoint" | Those are layers. Nobody can validate a layer. Split by capability. |
| "This bit doesn't fit anywhere, I'll leave it out" | Then write it under `Out of scope` with `nowhere`. Silence is how a split loses scope. |
| "Four tickets is cleaner than three" | Cleaner for whom? A ticket too small to deserve its own branch and PR belongs inside a sibling. |
| "I'll number them, it's easier to reference" | Numbers shift when one is dropped. Reference by name. |
| "The parent is an epic, so these are sub-tasks" | An epic is far larger than a split. A split produces sibling stories linked `is blocked by`. |
| "I know what they mean by X, I'll name it my way" | Check `docs/domain/glossary.md`. A synonym for a settled term costs a translation on every read. |
| "There's an open question but the ticket is mostly clear" | If the answer changes what gets built, the ticket is `Blocked` at creation. `To Do` with a hole means someone stalls on it. |
| "I'll restate the open point in my own words, it's clearer" | It has an identifier in `docs/domain/decision-points.md`. Restated, it diverges from the registry. |
| "I'll write the acceptance criteria as test cases" | Write the invariant. `test-first` writes the tests, from the scenarios `/speckit.specify` derives. |
| "I'll draft the spec too, the ticket is fresh in mind" | You write tickets. The next step is a human deciding to run `/speckit.specify`. |
| "I'll commit `tickets/` so the ticket is traceable" | It is git-ignored. JIRA is the record; a committed copy is a second writer that drifts from it. |
