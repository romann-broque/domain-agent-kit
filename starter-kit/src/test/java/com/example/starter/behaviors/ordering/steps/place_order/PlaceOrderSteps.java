package com.example.starter.behaviors.ordering.steps.place_order;

import static java.nio.charset.StandardCharsets.UTF_8;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.starter.core.application.ports.EventEmitter;
import com.example.starter.fixture.ordering.application.command.PlaceOrderCommandFixture;
import com.example.starter.fixture.ordering.application.command.PlaceOrderLineCommandFixture;
import com.example.starter.ordering.application.command.PlaceOrderLineCommand;
import com.example.starter.ordering.application.exceptions.UnknownProductException;
import com.example.starter.ordering.application.ports.OrderSaver;
import com.example.starter.ordering.application.ports.OrderedProductChecker;
import com.example.starter.ordering.application.usecase.PlaceOrderUseCase;
import com.example.starter.ordering.domain.events.OrderPlaced;
import com.example.starter.ordering.domain.models.aggregates.Order;
import com.example.starter.ordering.domain.models.valueobjects.OrderLine;
import com.example.starter.ordering.domain.models.valueobjects.Quantity;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.Before;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.mockito.ArgumentCaptor;

public class PlaceOrderSteps {

  private OrderedProductChecker orderedProductChecker;
  private OrderSaver orderSaver;
  private EventEmitter eventEmitter;
  private PlaceOrderUseCase placeOrder;
  private Throwable failure;

  @Before
  public void setUp() {
    orderedProductChecker = mock(OrderedProductChecker.class);
    orderSaver = mock(OrderSaver.class);
    eventEmitter = mock(EventEmitter.class);
    placeOrder = new PlaceOrderUseCase(orderedProductChecker, orderSaver, eventEmitter);
    failure = null;
  }

  @Given("the catalog knows the products {string} and {string}")
  public void theCatalogKnowsTheProducts(final String first, final String second) {
    when(orderedProductChecker.exists(idOf(first))).thenReturn(true);
    when(orderedProductChecker.exists(idOf(second))).thenReturn(true);
  }

  @When("the user orders")
  public void theUserOrders(final DataTable table) {
    placeAnOrderWith(linesOf(table));
  }

  @When("the user orders nothing")
  public void theUserOrdersNothing() {
    placeAnOrderWith(List.of());
  }

  @Then("the order is kept with the lines")
  public void theOrderIsKeptWithTheLines(final DataTable table) {
    assertThat(failure).isNull();
    final ArgumentCaptor<Order> saved = ArgumentCaptor.forClass(Order.class);
    verify(orderSaver).save(saved.capture());
    final List<OrderLine> expected = linesOf(table).stream()
        .map(line -> new OrderLine(line.productId(), new Quantity(line.quantity())))
        .toList();
    assertThat(saved.getValue().getLines()).containsExactlyElementsOf(expected);
  }

  @Then("the order is announced")
  public void theOrderIsAnnounced() {
    verify(eventEmitter).emit(any(OrderPlaced.class));
  }

  @Then("the order is refused because {string} is unknown")
  public void theOrderIsRefusedBecauseIsUnknown(final String product) {
    assertThat(failure).isInstanceOfSatisfying(UnknownProductException.class,
        unknown -> assertThat(unknown.getProductId()).isEqualTo(idOf(product)));
    nothingIsKept();
  }

  @Then("the order is refused and nothing is kept")
  public void theOrderIsRefusedAndNothingIsKept() {
    assertThat(failure).isNotNull();
    nothingIsKept();
  }

  private void placeAnOrderWith(final List<PlaceOrderLineCommand> lines) {
    failure = catchThrowable(() -> placeOrder.execute(
        PlaceOrderCommandFixture.defaultFixture().withLines(lines).build()));
  }

  private void nothingIsKept() {
    verify(orderSaver, never()).save(any());
    verify(eventEmitter, never()).emit(any());
  }

  private static List<PlaceOrderLineCommand> linesOf(final DataTable table) {
    return table.asMaps().stream().map(PlaceOrderSteps::lineOf).toList();
  }

  private static PlaceOrderLineCommand lineOf(final Map<String, String> row) {
    return PlaceOrderLineCommandFixture.defaultFixture()
        .withProductId(idOf(row.get("product")))
        .withQuantity(Integer.parseInt(row.get("quantity")))
        .build();
  }

  private static UUID idOf(final String product) {
    return UUID.nameUUIDFromBytes(product.getBytes(UTF_8));
  }
}
