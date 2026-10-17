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
import com.example.starter.core.domain.exceptions.DomainException;
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
    assertThat(failure).isInstanceOf(DomainException.class);
    verify(productSaver, never()).save(any());
    verify(eventEmitter, never()).emit(any());
  }
}
