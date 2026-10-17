# Tasks: Place an order

**Input**: `specs/002-place-an-order/spec.md`

## Phase 1: User Story 1 - Place an order (Priority: P1)

### Tests for User Story 1

- [x] T001 [US1] Write `src/test/resources/behaviors/ordering/place_order.feature` from the acceptance scenarios (FR-001, FR-002, FR-003, FR-004)
- [x] T002 [P] [US1] Write the creation tests `src/test/java/com/example/starter/ordering/domain/models/aggregates/OrderTest.java` (FR-002, FR-004) and `src/test/java/com/example/starter/ordering/domain/models/valueobjects/QuantityTest.java` (FR-003)
- [x] T003 [P] [US1] Write `src/test/java/com/example/starter/ordering/infrastructure/acl/OrderedProductCheckerAclTest.java` (FR-001)
- [x] T004 [US1] [GATE] Run the tests and paste the failing output

```text
> Task :compileTestJava FAILED
error: cannot find symbol
  symbol:   class PlaceOrderUseCase
BUILD FAILED
```

### Implementation for User Story 1

- [x] T005 [US1] Write the domain: `src/main/java/com/example/starter/ordering/domain/models/aggregates/Order.java` (FR-002, FR-003, FR-004)
- [x] T006 [US1] Write `src/main/java/com/example/starter/ordering/application/usecase/PlaceOrderUseCase.java` (FR-001)
- [x] T007 [US1] Ask the catalog through `src/main/java/com/example/starter/ordering/infrastructure/acl/OrderedProductCheckerAcl.java` (FR-001)
- [x] T008 [US1] Expose `POST /api/orders` in `src/main/java/com/example/starter/ordering/presentation/controller/OrderController.java`
