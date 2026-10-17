# Domain context template

The shape of a detailed bounded context under `docs/domain/contexts/<name>/`,
and the reduced shape used by `docs/domain/shared/` and `docs/domain/core/`.
Read and instantiate it; do not rewrite it during an ingestion pass. Changing
this form is a governance act — say it and stop.

A directory appears here only when there is depth material to put in it. Naming
a context is a different act from detailing it — see
`docs/domain/README.md` § *Named, detailed, registered*.

## A bounded context — four files

Every file carries a provenance header as its first block, per
`docs/domain/README.md` § *Every file carries a provenance header*.

### overview.md

    ## Why this context exists
    ## What it is responsible for
    ## What it is explicitly not responsible for
    ## Boundary
    ## Language

`Boundary` carries the reason the boundary was drawn where it is — one line is
enough. A boundary without its reason reads, a month later, as a fact nobody is
allowed to question.

`Language` names the terms this context owns, each linking to its
`../../glossary.md` row rather than redefining it.

### aggregates.md

    ## Aggregates
    ### <Aggregate root>
    #### Invariants
    #### Entities
    #### Value objects
    ## Open questions

`Invariants` is the home of every invariant this context guards. An invariant
recorded elsewhere while waiting for this file to exist **moves** here; it is
not copied. Two files carrying the same invariant is a contradiction waiting
for one of them to be edited.

### events.md

    ## Events published
    ## Events consumed

Each event states the business fact it records. A call between two components is
not a business fact — see
`.opencode/skills/domain-ingest/SKILL.md` § *What belongs here, and what does not*.

### flows.md

    ## Flows
    ### <Flow name>

Business-level flows only, and where this context takes part. Endpoints,
queues, retries and screens are solution mechanics and belong nowhere in this
directory.

## A shared kernel or the core mechanism — two files

`docs/domain/shared/` and `docs/domain/core/` use `overview.md` and
`aggregates.md` only. They publish nothing and orchestrate nothing, so
`events.md` and `flows.md` would be empty headings, and an empty heading costs
a line of every reader's budget while teaching them to skim the others.

`overview.md` additionally carries, for `shared/`, the obligations a declared
kernel accepts — joint ownership, negotiated change, staying small — and the
exit route if it stops being justified.
