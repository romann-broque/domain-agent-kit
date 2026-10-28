<!-- domain-knowledge
source: none yet — skeleton shipped with the workflow, before any ingestion
status: EMPTY
updated: YYYY-MM-DD
-->

# Decision Points

> **Source**: none yet — skeleton shipped with the workflow, before any ingestion
> **Status**: EMPTY
> **Authority**: descriptive — where production code and behaviour tests exist, the code wins

Every decision point of the domain model lives here, open or resolved, and only
here. A file that depends on one points at it by identifier; it does not restate
the question.

Identifiers are flat and permanent, of the form `OP-<n>` numbered from one. They
are never reused and never renumbered. A resolved point is not deleted — it changes
state and gains its decision, so that pointers keep resolving and the reason survives
the meeting it was decided in. That is why this file is not named for one of the
two states: a registry called *open points* would lie the day it recorded its
first answer, and moving resolved entries to a second file would break every
pointer aimed at them.

The shape of an entry is fixed by
`.specify/templates/domain-open-point-template.md`.

## Current state

No point has been registered. Entry counts, and counts by state, are reported by
`.specify/scripts/bash/verify-domain-base.sh`; no prose in this file states one.

## Entry format

An example, commented out so that it counts as nothing. Its identifier is left as
`OP-<n>` on purpose: a real number here would be read as a real entry.

<!--
### OP-<n> — May an order hold a product the catalog has discontinued?
- **state**: open
- **blocks**: `Order Line` — whether a line may name a product that is no longer offered
- **decides**: whether ordering must ask the catalog if a product is still offered, or only
  whether it exists — and so what crosses the anti-corruption layer between them.
- **owner**: the product owner
- **issues**:
  - no, a discontinued product cannot be ordered → the catalog publishes whether a product
    is offered, and ordering refuses a line naming one that is not
  - yes, until its stock runs out → ordering needs a notion of stock that no context owns yet
  - yes, always → nothing changes; discontinuing only hides a product from the catalog's listing

When answered, `state` becomes `resolved` and one field is appended:
- **decision**: <what was decided> (<YYYY-MM-DD>)
-->

## Points

None yet.

## Rules

Which marker a blocked item carries, and where it carries it, is fixed by
`docs/domain/README.md` § *A blocked item says so where it is defined*.

What is proper to this registry is that the pairing is checked in both directions
by `.specify/scripts/bash/verify-domain-base.sh`. The direction that matters is
the second one: an item suspended on an unanswered question, saying nothing about
it, is the defect this registry exists to prevent.
