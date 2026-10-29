# Fixture Patterns

## The mechanism

Test data is never constructed by hand. For every type used in a test there is a
hand-written `*DataSet` class under `src/test/java/com/example/starter/fixture/`,
mirroring the package of the type it builds. It is annotated:

```java
@GenerateFixture(entityClass = X.class, dataModelClass = XDataSet.DataModel.class)
```

and contains two things:

- a **nested `public static class DataModel`** whose public fields carry the default
  values for a valid instance;
- a **`public static X build(final DataModel model)`** that turns a `DataModel` into an
  `X`, going through the type's real creation path (`create`, `reconstitute`, or the
  canonical constructor) so that validation is exercised.

The annotation processor of
[java-fixture-generator](https://github.com/romann-broque/java-fixture-generator) then
generates `XFixture` at build time. It is an ordinary dependency from Maven Central,
declared on the test classpath only:

```kotlin
dependencies {
  testImplementation("io.github.romann-broque:fixture-annotations:<version>")
  testAnnotationProcessor("io.github.romann-broque:fixture-processor:<version>")
}
```

The annotation is imported as `io.github.romannbroque.fixture.annotations.GenerateFixture`.
The generated `XFixture` exposes a fluent API:

| Method | Purpose |
|---|---|
| `XFixture.defaultFixture()` | a fixture pre-loaded with the `DataModel` defaults |
| `XFixture.buildDefault()` | shorthand for `defaultFixture().build()` |
| `XFixture.withModel(model)` / `useModel(model)` | swap the whole `DataModel` |
| `withY(value)` | override field `y` |
| `withoutY()` | set field `y` to `null` — the way invalid cases are expressed |
| `getY()` | read field `y` back |
| `build()` | delegate to `XDataSet.build(model)` |

`withoutY()` is what makes `CreationTest.invalidCreationProvider()` readable: an
invalid case is a default fixture with one field removed.

## Reference `*DataSet`

`src/test/java/com/example/starter/fixture/catalog/domain/aggregates/ProductDataSet.java`

```java
package com.example.starter.fixture.catalog.domain.aggregates;

import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.Price;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import com.example.starter.fixture.catalog.domain.valueobjects.PriceFixture;
import com.example.starter.fixture.catalog.domain.valueobjects.ProductIdFixture;
import com.example.starter.fixture.catalog.domain.valueobjects.ProductNameFixture;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = Product.class, dataModelClass = ProductDataSet.DataModel.class)
public class ProductDataSet {

  public static Product build(final DataModel model) {
    return new Product(model.id, model.name, model.price);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public ProductId id = ProductIdFixture.buildDefault();
    public ProductName name = ProductNameFixture.buildDefault();
    public Price price = PriceFixture.buildDefault();
  }
}
```

The defaults of a composite type come from the fixtures of its parts
(`ProductNameFixture.buildDefault()`), so a valid value is defined once, in the
`*DataSet` of the type that owns it.

## The generated counterpart

`build/generated/sources/annotationProcessor/java/test/com/example/starter/fixture/catalog/domain/aggregates/ProductFixture.java`
— generated, never edited, never committed. Run `./gradlew test` once if the directory
is absent. Excerpt (one field shown; `name` and `price` follow the same pattern):

```java
package com.example.starter.fixture.catalog.domain.aggregates;

import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.fixture.catalog.domain.aggregates.ProductDataSet.DataModel;

/**
 * Auto-generated fixture class to simplify the creation of Product instances.
 * This class uses the builder pattern with a fluent API.
 */
public class ProductFixture {

    private DataModel model = new DataModel();

    public static ProductFixture defaultFixture() {
        return new ProductFixture();
    }

    public static ProductFixture withModel(final DataModel customModel) {
        return new ProductFixture().useModel(customModel);
    }

    public ProductFixture useModel(final DataModel customModel) {
        this.model = customModel;
        return this;
    }

    public DataModel getModel() {
        return this.model;
    }

    public static Product buildDefault() {
        return defaultFixture().build();
    }

    public ProductFixture withId(com.example.starter.catalog.domain.models.valueobjects.ProductId value) {
        model.id = value;
        return this;
    }

    public ProductFixture withoutId() {
        model.id = null;
        return this;
    }

    public com.example.starter.catalog.domain.models.valueobjects.ProductId getId() {
        return model.id;
    }

    public Product build() {
        return ProductDataSet.build(model);
    }
}
```

## Existing `*DataSet` classes

```
src/test/java/com/example/starter/fixture/
├── catalog/
│   ├── application/
│   │   └── command/
│   │       └── AddProductCommandDataSet.java
│   └── domain/
│       ├── aggregates/
│       │   └── ProductDataSet.java
│       └── valueobjects/
│           ├── PriceDataSet.java
│           ├── ProductIdDataSet.java
│           └── ProductNameDataSet.java
└── ordering/
    ├── application/
    │   └── command/
    │       ├── PlaceOrderCommandDataSet.java
    │       └── PlaceOrderLineCommandDataSet.java
    └── domain/
        ├── aggregates/
        │   └── OrderDataSet.java
        └── valueobjects/
            ├── OrderIdDataSet.java
            ├── OrderLineDataSet.java
            └── QuantityDataSet.java
```

## Missing fixtures

If the test you are writing needs a type that has no `*DataSet`, **write the
`*DataSet`**. That is part of the `test-first` job, and it belongs in the same RED
step as the test itself. Never improvise test data inline in a step definition or a
unit test — no `new Product(...)`, no ad-hoc builders, no literal domain objects. The
fixture is the single place where a valid default instance is defined, and that is
what keeps invalid cases expressible as a one-field deviation from it.
