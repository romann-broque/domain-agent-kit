# Open point template

The shape of one entry in `docs/domain/decision-points.md`. Read and instantiate it;
do not rewrite it during an ingestion pass. Changing this form is a governance
act — say it and stop, as with the constitution.

Identifiers are flat and permanent: `OP-<n>`, numbered from 1. They are never
reused and never renumbered, because other files point at them by identifier. A
resolved point is not deleted; it changes state and gains a decision, so the
pointers keep resolving and the reason survives.

## Required shape

    ### OP-<n> — <the question, stated as a question or as the undecided thing>
    - **state**: open | resolved
    - **blocks**: `<term>`, `<term>` — the items whose definition cannot be
      trusted until this is answered. Each one carries `[blocked: OP-<n>]` at
      its point of definition. Leave the field out if it blocks nothing.
    - **decides**: what changes in the model depending on the answer. Not the
      question restated — the consequence.
    - **owner**: who can answer. A role, not a name, unless the name is the
      only accurate answer.
    - **issues**:
      - <one option> → <what follows for the model>
      - <another option> → <what follows for the model>

When it is answered, `state` becomes `resolved` and one field is appended:

    - **decision**: <what was decided> (<YYYY-MM-DD>)

## Why each field is there

`blocks` is the field that makes the base checkable. It is the direction that
catches an omission: a term whose definition is suspended on an unanswered
question, and which says nothing about it, is the defect this whole mechanism
exists to prevent.

`decides` is what makes an open point worth reading. A question without its
consequence cannot be prioritised, and unprioritised questions are answered in
the order someone happens to open the file.

`issues` is where the reasoning goes. Keep it — this is not the part to
shorten. The prose scaffolding around it is.
