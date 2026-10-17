# Feature Specification: Add a product

**Feature Branch**: `001-add-a-product`

**Created**: 2026-10-17

**Status**: Implemented

**Input**: User description: "Let a user add a product to the catalog with a name and a price."

<!-- TRACE:BEGIN -->
## Source Ticket *(verbatim — do not edit)*

```text
PROJ-1 — Add a product to the catalog

As a user, I want to add a product to the catalog with a name and a price,
so that it can be ordered later.

Acceptance criteria
- A product has a name (required, at most 100 characters) and a price.
- The price is strictly positive, with at most two decimals.
- Two products cannot share the same name.

Out of scope
- Editing or removing a product.
```

**Ticket reference**: PROJ-1
<!-- TRACE:END -->

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add a product (Priority: P1)

A user adds a product to the catalog by giving its name and its price. The product is kept and its addition is
announced, so that other parts of the system can react to it.

**Why this priority**: Nothing can be ordered until the catalog holds products.

**Independent Test**: Add a product through `POST /api/products` and check that it is kept.

**Acceptance Scenarios**:

1. ✅ **Given** the catalog holds no product named "Desk lamp", **When** the user adds a product named "Desk lamp"
   priced 24.90, **Then** the product is kept with that name and price, and its addition is announced.
2. ❌ **When** the user adds a product with a blank name, **Then** the addition is refused and no product is kept.
3. ❌ **When** the user adds a product priced 0, **Then** the addition is refused and no product is kept.
4. ❌ **Given** the catalog already holds a product named "Desk lamp", **When** the user adds a product named
   "Desk lamp" priced 19.00, **Then** the addition is refused and no product is kept.

### Edge Cases

- A name surrounded by spaces is trimmed before it is checked and kept.
- A price with more than two decimals is refused, but trailing zeros (`24.900`) are accepted.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST refuse a product whose name is blank or longer than 100 characters, once trimmed.
- **FR-002**: System MUST refuse a product whose price is not strictly positive or has more than two decimals.
- **FR-003**: System MUST refuse a product whose name is already held by another product of the catalog.

### Key Entities

- **Product**: something the catalog offers. It has an identity, a unique name and a price.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every refused addition leaves the catalog unchanged.

## Assumptions

- Prices carry no currency: the catalog uses a single one.
