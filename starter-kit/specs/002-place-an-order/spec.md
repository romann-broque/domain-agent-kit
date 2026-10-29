# Feature Specification: Place an order

**Feature Branch**: `002-place-an-order`

**Created**: 2026-10-17

**Status**: Implemented

**Input**: User description: "Let a user order products of the catalog, each with a quantity."

<!-- TRACE:BEGIN -->
## Source Ticket *(verbatim — do not edit)*

```text
PROJ-2 — Place an order

As a user, I want to order products from the catalog, each with a quantity,
so that they are reserved for me.

Acceptance criteria
- Every ordered product must exist in the catalog.
- An order has at least one line.
- Each quantity is between 1 and 999.
- Ordering the same product twice in one order adds the quantities up.

Out of scope
- Payment, delivery, stock.
```

**Ticket reference**: PROJ-2
<!-- TRACE:END -->

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Place an order (Priority: P1)

A user orders one or more products of the catalog, each with a quantity. The order is kept and announced. The
ordering context never reads the catalog's data directly: it asks the catalog through an anti-corruption layer.

**Why this priority**: It is the only thing a user comes to do.

**Independent Test**: Add a product, then order it through `POST /api/orders` and check that the order is kept.

**Acceptance Scenarios**:

1. ✅ **Given** the catalog knows "Desk lamp" and "Notebook", **When** the user orders 2 "Desk lamp" and 1 "Notebook",
   **Then** the order is kept with those lines, and it is announced.
2. ❌ **Given** the catalog knows "Desk lamp" and "Notebook", **When** the user orders 1 "Desk lamp" and 1 "Ghost",
   **Then** the order is refused because "Ghost" is unknown.
3. ❌ **Given** the catalog knows "Desk lamp" and "Notebook", **When** the user orders nothing, **Then** the order is
   refused and nothing is kept.
4. ❌ **Given** the catalog knows "Desk lamp" and "Notebook", **When** the user orders 0 "Desk lamp", **Then** the
   order is refused and nothing is kept.
5. ✅ **Given** the catalog knows "Desk lamp" and "Notebook", **When** the user orders 2 "Desk lamp" then 3 more
   "Desk lamp", **Then** the order is kept with a single line of 5 "Desk lamp", and it is announced.

### Edge Cases

- Merged lines must still respect the 1–999 bound: 500 + 500 of the same product is refused.
- When several products are unknown, the first one met is reported.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST refuse an order with a line whose product the catalog does not know.
- **FR-002**: System MUST refuse an order with no line.
- **FR-003**: System MUST refuse a line whose quantity is below 1 or above 999.
- **FR-004**: System MUST merge the lines of one order that reference the same product, summing their quantities.

### Key Entities

- **Order**: what a user asked for at once. It has an identity and one line per product.
- **Order line**: a product of the catalog, referenced by its identity, and a quantity.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every refused order leaves nothing kept and announces nothing.

## Assumptions

- The catalog is the only authority on which products exist (see spec 001).
