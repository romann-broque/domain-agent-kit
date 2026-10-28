# Cucumber Patterns

Behavior tests run Cucumber on the JUnit Platform, under the ordinary `test` task —
there is no separate source set. There is **no `cucumber-spring`**, no
`@CucumberContextConfiguration` and no Spring context of any kind: a step definition
class mocks every port with Mockito and instantiates the use case directly through its
constructor. One runner class selects exactly one feature file and scopes the glue to
that feature's own step package, so step definitions never leak between features.
Assertions are AssertJ, made on the value returned by the use case and on mock
interactions. A step may assert that a refusal occurred (the caught exception is not
null), never on its type, and on its message only when the spec fixes its wording.
Scenarios and steps speak the domain's meaning, never the bounded context or port that
answers. Test data always comes from generated
fixtures.

## Reference feature file

`src/test/resources/behaviors/catalog/add_product.feature`

```gherkin
# Covers: US1, FR-001, FR-002, FR-003
Feature: Add a product
  As a user
  I want to add a product to the catalog
  So that it can be ordered at a known price

  Rule: A product needs a valid name and price

    Scenario: ✅ Valid product
      Given the catalog holds no product named "Desk lamp"
      When the user adds a product named "Desk lamp" priced 24.90
      Then the product is kept with the name "Desk lamp" and the price 24.90
      And the addition is announced

    Scenario: ❌ Blank name
      When the user adds a product named "   " priced 24.90
      Then the addition is refused and no product is kept

    Scenario: ❌ Zero price
      When the user adds a product named "Desk lamp" priced 0
      Then the addition is refused and no product is kept

  Rule: Names are unique

    Scenario: ❌ Duplicate name
      Given the catalog already holds a product named "Desk lamp"
      When the user adds a product named "Desk lamp" priced 19.00
      Then the addition is refused and no product is kept
```

## Reference runner — one per feature

`src/test/java/com/example/starter/behaviors/catalog/runners/AddProductBehaviorTest.java`

```java
package com.example.starter.behaviors.catalog.runners;

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.PLUGIN_PROPERTY_NAME;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectClasspathResource;
import org.junit.platform.suite.api.Suite;

@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("behaviors/catalog/add_product.feature")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "com.example.starter.behaviors.catalog.steps.add_product")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "pretty, html:build/reports/behaviors/catalog/add-product.html")
public class AddProductBehaviorTest {
}
```

## Reference step definitions

`src/test/java/com/example/starter/behaviors/catalog/steps/add_product/AddProductSteps.java`

```java
package com.example.starter.behaviors.catalog.steps.add_product;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.starter.catalog.application.ports.ProductRetrieverByName;
import com.example.starter.catalog.application.ports.ProductSaver;
import com.example.starter.catalog.application.usecase.AddProductUseCase;
import com.example.starter.catalog.domain.events.ProductAdded;
import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import com.example.starter.core.application.ports.EventEmitter;
import com.example.starter.fixture.catalog.application.command.AddProductCommandFixture;
import com.example.starter.fixture.catalog.domain.aggregates.ProductFixture;
import io.cucumber.java.Before;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.math.BigDecimal;
import java.util.Optional;
import org.mockito.ArgumentCaptor;

public class AddProductSteps {

  private ProductRetrieverByName productRetrieverByName;
  private ProductSaver productSaver;
  private EventEmitter eventEmitter;
  private AddProductUseCase addProduct;
  private Throwable failure;

  @Before
  public void setUp() {
    productRetrieverByName = mock(ProductRetrieverByName.class);
    productSaver = mock(ProductSaver.class);
    eventEmitter = mock(EventEmitter.class);
    when(productRetrieverByName.retrieveByName(any())).thenReturn(Optional.empty());
    addProduct = new AddProductUseCase(productRetrieverByName, productSaver, eventEmitter);
    failure = null;
  }

  @Given("the catalog holds no product named {string}")
  public void theCatalogHoldsNoProductNamed(final String name) {
    when(productRetrieverByName.retrieveByName(new ProductName(name))).thenReturn(Optional.empty());
  }

  @Given("the catalog already holds a product named {string}")
  public void theCatalogAlreadyHoldsAProductNamed(final String name) {
    final Product existing = ProductFixture.defaultFixture().withName(new ProductName(name)).build();
    when(productRetrieverByName.retrieveByName(new ProductName(name))).thenReturn(Optional.of(existing));
  }

  @When("the user adds a product named {string} priced {bigdecimal}")
  public void theUserAddsAProduct(final String name, final BigDecimal price) {
    failure = catchThrowable(() -> addProduct.execute(
        AddProductCommandFixture.defaultFixture().withName(name).withPrice(price).build()));
  }

  @Then("the product is kept with the name {string} and the price {bigdecimal}")
  public void theProductIsKept(final String name, final BigDecimal price) {
    assertThat(failure).isNull();
    final ArgumentCaptor<Product> saved = ArgumentCaptor.forClass(Product.class);
    verify(productSaver).save(saved.capture());
    assertThat(saved.getValue().getName().value()).isEqualTo(name);
    assertThat(saved.getValue().getPrice().amount()).isEqualByComparingTo(price);
  }

  @Then("the addition is announced")
  public void theAdditionIsAnnounced() {
    verify(eventEmitter).emit(any(ProductAdded.class));
  }

  @Then("the addition is refused and no product is kept")
  public void theAdditionIsRefused() {
    assertThat(failure).isNotNull();
    verify(productSaver, never()).save(any());
    verify(eventEmitter, never()).emit(any());
  }
}
```

> Copy the *shape* of these files, not their content. Note how a refusal is handled:
> the `When` step captures it with `catchThrowable`, and the `Then` step asserts only
> that it occurred, plus the absence of side effects on the mocked ports.

## Wording — plain and direct

A feature file is read by people who know the business, not the code. Write it the way
they would say it, as briefly as the scenario allows.

- **The actor is `user`.** Write `As a user` and `When the user …`. Do not invent a role
  such as *curator*, *manager* or *operator*. A role that nobody named becomes, on the
  page, a business notion nobody decided. If the spec names a real role, use that role
  instead.
- **The feature title is the use case as an action.** `Feature: Add a product`, not a
  sentence about the catalog.
- **`I want` repeats the action. `So that` gives the business reason in one line.**
- **A `Rule:` is a short statement of the rule itself.** For example, `A product needs a
  valid name and price`.
- **Scenario titles are short labels**, two to eight words after ✅ or ❌, saying only what
  makes this case different: `✅ Valid product`, `❌ Blank name`, `❌ Duplicate name`,
  `❌ Name longer than 100 characters`. The `Given/When/Then` lines carry the detail, so
  the title does not repeat it. A title that reads like a full sentence, or that copies
  the acceptance scenario, is too long.
- **Steps speak business language**, quoting the business values (`"Desk lamp"`,
  `24.90`). Never quote class names, ports or technical identifiers.

<!-- TRACE:BEGIN -->
## Coverage header

Every feature file opens with the list of what it covers, before `Feature:`:

```gherkin
# Covers: US1, FR-001, FR-002, FR-003
Feature: Add a product
```

`US*` are the user stories of `spec.md`, `FR-*` its functional requirements.

This turns "are the acceptance scenarios covered?" into a join a script can check,
instead of a judgement someone has to make by reading two documents side by side.
A feature file without this header is reported as unverifiable, not as compliant.

A feature holds every story exercising its use case, each as its own `Rule:`. When a
rule covers a narrower set than the header, its own `# Covers:` sits right above it;
the script counts a scenario under its rule's line, or under the header when the rule
has none:

```gherkin
# Covers: US1, US2, FR-001, FR-005
Feature: {Use case as an action}

  # Covers: US1, FR-001
  Rule: {Short statement of the first rule}

  # Covers: US2, FR-005
  Rule: {Short statement of the second rule}
```

A line written by one spec stays unqualified. Once a second spec touches it, every
group is qualified by its spec number and none is overwritten — US and FR numbers
restart with each spec:

```gherkin
# Covers: 001: US1, FR-003; 003: US1, FR-002
```

When the header is qualified, every rule line of the file is qualified too; a rule line
that is not, or one that does not sit right above a `Rule:`, is reported as
unverifiable.
<!-- TRACE:END -->

## Checklist

- [ ] Feature file opens with `# Covers: US..., FR-...` naming what it covers; a rule
      covering less carries its own line right above it; lines shared by two specs are
      qualified by spec number.
- [ ] One acceptance scenario of `spec.md` = one Cucumber scenario. No merging.
- [ ] Scenario titles prefixed ✅ for success, ❌ for failure.
- [ ] Feature opens with `As a user / I want / So that`. No role is invented, and steps
      say `the user`, never `I`.
- [ ] Feature and scenario titles are short and plain: the use case as an action, and
      two to eight words saying what makes each case different.
- [ ] Scenarios grouped under `Rule:`.
- [ ] `Background:` sits **inside** a `Rule:`, never at feature level.
- [ ] One runner per feature; the glue package is scoped to that feature's own step
      package and to nothing else.
- [ ] HTML report at `build/reports/behaviors/{context}/{use-case}.html`.
- [ ] Feature file at `src/test/resources/behaviors/{context}/{use_case}.feature`
      (snake_case), report file name in kebab-case.
- [ ] Ports mocked with Mockito, use case instantiated directly — no Spring context,
      no `cucumber-spring`, no `@CucumberContextConfiguration`.
- [ ] AssertJ only, on the returned result and on mock interactions.
- [ ] No assertion on the type of a caught exception, nor on its message unless the spec fixes its wording (that one occurred is allowed).
- [ ] All method and constructor parameters declared `final`.
- [ ] Test data comes from generated fixtures — see `fixture-patterns.md`.
