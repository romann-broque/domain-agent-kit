<!-- domain-knowledge
source: none yet — skeleton shipped with the workflow, before any ingestion
status: EMPTY
updated: YYYY-MM-DD
-->

# Context Map

> **Source**: none yet — skeleton shipped with the workflow, before any ingestion
> **Status**: EMPTY
> **Authority**: descriptive — where production code and behaviour tests exist, the code wins

This file records the bounded contexts of the domain and the relationships between them.

## What the system does

Not written yet. One paragraph, in business terms, stating what the system is for and
what bounds it — the sentence every boundary below is checked against.

## Current state

No context has been named. Naming, detailing and registering are three separate acts —
see `docs/domain/README.md` § *Named, detailed, registered*.

The `catalog` and `ordering` packages of the starter-kit are **not** contexts of this
domain. They are a layout template with no business meaning: copy their shape, never
their semantics, and delete them once your first context exists.

## Entry format

A context is one row of the `Contexts` table; a relationship is one row of the
`Relationships` table; the reason a boundary sits where it does is one bullet under
*Why these boundaries*. An example, commented out so that it counts as nothing:

<!--
In ## Contexts:

| Catalog | Which products exist, and at what price | — |
| Ordering | Turn what a user asks for into an order of catalog products | — |

In ### Why these boundaries:

- **Ordering does not own products.** An order names a product and a quantity; what a
  product is, and whether it still exists, is the catalog's to say. Drawn here so that
  a change to how products are described never forces a change to how orders are taken.

In ## Relationships:

| Catalog | Ordering | Anti-corruption layer | Ordering asks whether a product exists, by its identifier. Nothing else of a product crosses. [blocked: OP-<n>] |
-->

## Contexts

Every context that has been named gets a row here. A directory under
`contexts/<name>/` appears only once there is depth material to put in it: being
named and being detailed are two different states, and the `Directory` column
reads `—` until the second one is reached.

| Context | Responsibility | Directory |
|---|---|---|
| — | — | — |

### Why these boundaries

None drawn yet. Each boundary gets one bullet: where it is, and why it is there.

## Not bounded contexts

`shared` and `core` are not bounded contexts. `shared` is a declared shared kernel —
types two contexts agree on, jointly owned, changed only by negotiation with every
consumer, and kept small. `core` is cross-cutting technical mechanism. Either gets a
section here, and a directory under `docs/domain/`, only once it holds a model.

## Relationships

Record, for each pair of contexts that interact:

- the **direction**: which one is upstream, which one is downstream
- the **pattern**: anti-corruption layer, shared kernel, customer/supplier,
  conformist, published language
- the **contract**: what actually crosses the boundary, and under which name

A relationship that cannot be named is usually a boundary drawn in the wrong place.

| Upstream | Downstream | Pattern | Contract |
|---|---|---|---|
| — | — | — | — |

## Invariants surfaced here

Invariants found before their context is detailed. They belong to that context's
`aggregates.md` and **move** there when it is written, rather than being copied.

None yet.
