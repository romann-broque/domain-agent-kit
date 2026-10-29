# Unit Test Patterns

## The base class for value object and command creation tests

`src/test/java/com/example/starter/testutils/templates/CreationTest.java`

```java
package com.example.starter.testutils.templates;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.ParameterizedType;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.params.provider.Arguments;

@SuppressWarnings("unchecked")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public abstract class CreationTest<ENTITY, FIXTURE, EXCEPTION extends RuntimeException> {

  private final String entityClassName;
  private final Class<EXCEPTION> exceptionClass;

  private List<Arguments> validFixtures;
  private List<Arguments> invalidFixtures;

  protected CreationTest() {
    final ParameterizedType type = (ParameterizedType) getClass().getGenericSuperclass();
    this.entityClassName = ((Class<ENTITY>) type.getActualTypeArguments()[0]).getSimpleName();
    this.exceptionClass = (Class<EXCEPTION>) type.getActualTypeArguments()[2];
  }

  @BeforeEach
  void setup() {
    validFixtures = validCreationProvider().toList();
    invalidFixtures = invalidCreationProvider().toList();
  }

  protected Stream<Arguments> validCreationProvider() {
    return Stream.empty();
  }

  protected Stream<Arguments> invalidCreationProvider() {
    return Stream.empty();
  }

  @TestFactory
  @DisplayName("✅ Valid creation")
  public Stream<DynamicTest> validCreationTests() {
    assumeTrue(!validFixtures.isEmpty(), "No valid cases provided, skipping tests.");

    final AtomicInteger count = new AtomicInteger(1);
    return validFixtures.stream().map(args -> {
      final FIXTURE fixture = (FIXTURE) args.get()[0];

      return DynamicTest.dynamicTest("#" + count.getAndIncrement() + ": " + entityClassName + " - Valid creation",
          () -> assertThatCode(() -> invokeBuild(fixture)).doesNotThrowAnyException());
    });
  }

  @TestFactory
  @DisplayName("❌ Invalid creation")
  public Stream<DynamicTest> invalidCreationTests() {
    assumeTrue(!invalidFixtures.isEmpty(), "No invalid cases provided, skipping tests.");

    final AtomicInteger count = new AtomicInteger(1);
    return invalidFixtures.stream().map(args -> {
      final FIXTURE fixture = (FIXTURE) args.get()[0];

      return DynamicTest.dynamicTest("#" + count.getAndIncrement() + ": " + entityClassName + " - Invalid creation",
          () -> assertThatThrownBy(() -> invokeBuild(fixture)).isInstanceOf(exceptionClass));
    });
  }

  private void invokeBuild(final FIXTURE fixture) throws Throwable {
    try {
      fixture.getClass().getMethod("build").invoke(fixture);
    } catch (final InvocationTargetException e) {
      throw e.getCause();
    }
  }
}
```

## Reference usage

`src/test/java/com/example/starter/catalog/domain/models/valueobjects/PriceTest.java`

```java
package com.example.starter.catalog.domain.models.valueobjects;

import com.example.starter.catalog.domain.exceptions.ProductException;
import com.example.starter.fixture.catalog.domain.valueobjects.PriceFixture;
import com.example.starter.testutils.templates.CreationTest;
import java.math.BigDecimal;
import java.util.stream.Stream;
import org.junit.jupiter.params.provider.Arguments;

class PriceTest extends CreationTest<Price, PriceFixture, ProductException> {

  @Override
  protected Stream<Arguments> validCreationProvider() {
    // Covers: 001: US1, FR-002
    return Stream.of(
        Arguments.of(aPriceWithTwoDecimals()),
        Arguments.of(theSmallestPrice()));
  }

  @Override
  protected Stream<Arguments> invalidCreationProvider() {
    // Covers: 001: US1, FR-002
    return Stream.of(
        Arguments.of(aMissingPrice()),
        Arguments.of(aZeroPrice()),
        Arguments.of(aNegativePrice()),
        Arguments.of(aPriceWithThreeDecimals()));
  }

  private static PriceFixture aPriceWithTwoDecimals() {
    return PriceFixture.defaultFixture().withAmount(new BigDecimal("24.90"));
  }

  private static PriceFixture theSmallestPrice() {
    return PriceFixture.defaultFixture().withAmount(new BigDecimal("0.01"));
  }

  private static PriceFixture aMissingPrice() {
    return PriceFixture.defaultFixture().withoutAmount();
  }

  private static PriceFixture aZeroPrice() {
    return PriceFixture.defaultFixture().withAmount(BigDecimal.ZERO);
  }

  private static PriceFixture aNegativePrice() {
    return PriceFixture.defaultFixture().withAmount(new BigDecimal("-1.00"));
  }

  private static PriceFixture aPriceWithThreeDecimals() {
    return PriceFixture.defaultFixture().withAmount(new BigDecimal("1.999"));
  }
}
```

## Which style for what

- **Every model of the `domain` and `application` layers** — aggregate roots,
  entities, value objects and commands alike — extends
  `CreationTest<ENTITY, FIXTURE, EXCEPTION>` and supplies `validCreationProvider()`
  and `invalidCreationProvider()`. Each `Arguments` carries a *fixture*, not a built
  instance — the base class calls `build()` itself and asserts that it either succeeds
  or throws `EXCEPTION`.
- **Non-creation behaviour** — an aggregate mutator such as `Product.changePrice` —
  gets plain JUnit 5 tests with AssertJ assertions, **in addition to** the
  `CreationTest`, never instead of it. From `ProductTest`:

  ```java
  @Test
  void changingThePriceKeepsTheNewPrice() {
    final Product lamp = ProductFixture.defaultFixture().build();

    lamp.changePrice(new Price(new BigDecimal("19.00")));

    assertThat(lamp.getPrice().amount()).isEqualByComparingTo("19.00");
  }
  ```

- **Test data always comes from generated fixtures** — never construct domain objects
  by hand in a test. See `fixture-patterns.md`.
- **All method and constructor parameters are declared `final`.**
- 2-space indent, 120 columns, LF, UTF-8, final newline.
- **No comments.** A `CreationTest` builds its cases from a `Stream<Arguments>`, so the
  cases are anonymous in the report — that is the pressure that makes people comment
  them. Name them instead, as `PriceTest` does above:

  ```java
  @Override
  protected Stream<Arguments> invalidCreationProvider() {
    // Covers: 001: US1, FR-002
    return Stream.of(
        Arguments.of(aMissingPrice()),
        Arguments.of(aZeroPrice()),
        Arguments.of(aNegativePrice()));
  }

  private static PriceFixture aZeroPrice() {
    return PriceFixture.defaultFixture().withAmount(BigDecimal.ZERO);
  }
  ```

  The name is compiler-checked, reads at the call site, and names the frame in a
  failure. The single `// Covers:` line per provider method is the one authorised
  exception — the project's `AGENTS.md` § *Code Style* → *No comments*. Prose is not on
  that list. Once a second spec adds cases to a provider, the line is qualified by spec
  number, and the earlier spec's group is kept, never overwritten:
  `// Covers: 001: US1, FR-002; 003: US2, FR-005`.
- A reason an assertion matters goes in `.as("…")`, not above it:

  ```java
  assertThat(order.getLines())
      .as("two lines for one product must merge, else the product is counted twice")
      .containsExactly(lineOf(DESK_LAMP, 5), lineOf(NOTEBOOK, 1));
  ```
