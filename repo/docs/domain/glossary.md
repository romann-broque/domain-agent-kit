<!-- domain-knowledge
source: none yet — skeleton shipped with the workflow, before any ingestion
status: EMPTY
updated: YYYY-MM-DD
-->

# Ubiquitous Language

> **Source**: none yet — skeleton shipped with the workflow, before any ingestion
> **Status**: EMPTY
> **Authority**: descriptive — where production code and behaviour tests exist, the code wins

The vocabulary of the domain. Class, method and package names come from this glossary
(`.specify/memory/constitution.md` § *I. Domain-Driven Layered Architecture*).

## Current state

No term has been recorded. The `Terms` table below is empty, and the example in
*Entry format* is commented out. Term counts and per-term statuses are reported by
`.specify/scripts/bash/verify-domain-base.sh`; no prose in this file states one.

## Entry format

One row per term, in the `Terms` table. Columns:

- **Term** — the word, in backticks, as the code will spell it.
- **Context** — the bounded context it belongs to, as named in `context-map.md`.
- **Definition** — what it means to the business, in a sentence or three. A term whose
  definition hangs on an open question carries `[blocked: OP-<n>]` in this cell.
- **Source wording** — the business's own words, quoted, when somebody gave words at
  all. Empty means nobody has put the concept into words — not that a translation is
  missing. An `AGREED` term with no source wording is a claim with no evidence.
- **Status** — one token, with the meaning `docs/domain/README.md` § *Status is not decoration* gives it.

An example, commented out so that it counts as nothing:

<!--
| `Order Line` | Ordering | A product of the catalog and the quantity of it an order asks for. An order holds at least one; two lines naming the same product are one line. [blocked: OP-<n>] | "each line of the order says which product and how many" | DRAFT |
-->

## Terms

| Term | Context | Definition | Source wording | Status |
|---|---|---|---|---|
| — | — | — | — | — |

## Rules

**One term, one context.** A term is defined inside a bounded context. The same
word appearing in two contexts is two distinct types with two distinct definitions,
never a shared one — a `Product` of the catalog and a product as an order line names it
are two entries. When that happens, both entries stay: the duplication is the
information.

**No synonyms in code.** If the business uses two words for the same thing, pick
one, record the other as a rejected alias, and use only the chosen one everywhere.

**A definition says what the term means, never how it is built.** The composition of a
notion belongs here — an order line names a product and a quantity, and that is domain.
What does not belong is the shape the code gives it, the moment an invalid one is
refused, or the reason one design was chosen over another: those live in `specs/` and in
the code, which is where they are checked. A definition a domain expert would not
recognise is a defect even when every word of it is true of the code.

**A term absent from here is a gap, not a detail.** A specification that needs an
undefined term must extend this file first
(`.specify/memory/constitution.md` § *V. Domain Knowledge Is Written Down*).
