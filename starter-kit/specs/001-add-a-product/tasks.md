# Tasks: Add a product

**Input**: `specs/001-add-a-product/spec.md`

## Phase 1: User Story 1 - Add a product (Priority: P1)

### Tests for User Story 1

- [x] T001 [US1] Write `src/test/resources/behaviors/catalog/add_product.feature` from the acceptance scenarios (FR-001, FR-002, FR-003)
- [x] T002 [P] [US1] Write the creation tests `src/test/java/com/example/starter/catalog/domain/models/valueobjects/ProductNameTest.java` (FR-001) and `src/test/java/com/example/starter/catalog/domain/models/valueobjects/PriceTest.java` (FR-002)
- [x] T003 [US1] [GATE] Run the tests and paste the failing output

```text
> Task :compileTestJava FAILED
error: cannot find symbol
  symbol:   class AddProductUseCase
BUILD FAILED
```

### Implementation for User Story 1

- [x] T004 [US1] Write the domain: `src/main/java/com/example/starter/catalog/domain/models/aggregates/Product.java` (FR-001, FR-002)
- [x] T005 [US1] Write `src/main/java/com/example/starter/catalog/application/usecase/AddProductUseCase.java` (FR-003)
- [x] T006 [US1] Expose `POST /api/products` in `src/main/java/com/example/starter/catalog/presentation/controller/ProductController.java`
