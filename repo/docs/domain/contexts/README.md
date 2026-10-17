<!-- domain-knowledge
source: none yet — skeleton shipped with the workflow, before any ingestion
status: EMPTY
updated: YYYY-MM-DD
-->

# Contexts

> **Source**: none yet — skeleton shipped with the workflow, before any ingestion
> **Status**: EMPTY
> **Authority**: descriptive — where production code and behaviour tests exist, the code wins

One directory per **detailed** bounded context. There is none yet. When the first one
is written, list it here — `ordering/` — Ordering, detailed YYYY-MM-DD — and append the
same fact to this file's `source`.

A context named in `docs/domain/context-map.md` has no directory here until there is
depth material for it. That absence is the record that it has not been detailed yet —
do not pre-create empty files to fill the gap.

## Shape

A context directory holds four files, each opening with its own provenance header:

```
contexts/<name>/
├── overview.md      why it exists, what it is and is not responsible for, its boundary, its language
├── aggregates.md    each aggregate root, its invariants, entities and value objects; open questions
├── events.md        events published and consumed, each as the business fact it records
└── flows.md         business-level flows, and where this context takes part
```

`docs/domain/shared/` and `docs/domain/core/` use the reduced two-file shape —
`overview.md` and `aggregates.md` only — because a kernel publishes nothing and
orchestrates nothing.

The exact headings are fixed by `.specify/templates/domain-context-template.md`, and
`.specify/scripts/bash/verify-domain-base.sh` checks every directory here against it.
The form lives there and not here on purpose. This file is read and rewritten by
ingestion passes; a template that lives inside the thing it governs drifts with
it. A shape is read and instantiated here, never redefined here — read the
template, instantiate it, and if its shape does not fit what you have, say so
and stop. Changing it is a governance act, not a transcription detail.

Naming a context, detailing it and registering it are three separate acts —
see `docs/domain/README.md` § *Named, detailed, registered*.

Write only what has actually been decided. A section left empty with an honest
`status` is useful; a section filled with plausible inference is not.
