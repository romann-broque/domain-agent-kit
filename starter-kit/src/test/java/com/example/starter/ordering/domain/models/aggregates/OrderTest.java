package com.example.starter.ordering.domain.models.aggregates;

import static org.assertj.core.api.Assertions.assertThat;

import com.example.starter.fixture.ordering.domain.aggregates.OrderFixture;
import com.example.starter.fixture.ordering.domain.valueobjects.OrderLineFixture;
import com.example.starter.ordering.domain.exceptions.OrderException;
import com.example.starter.ordering.domain.models.valueobjects.OrderLine;
import com.example.starter.ordering.domain.models.valueobjects.Quantity;
import com.example.starter.testutils.templates.CreationTest;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.provider.Arguments;

class OrderTest extends CreationTest<Order, OrderFixture, OrderException> {

  private static final UUID DESK_LAMP = UUID.fromString("00000000-0000-0000-0000-000000000001");
  private static final UUID NOTEBOOK = UUID.fromString("00000000-0000-0000-0000-000000000002");

  @Override
  protected Stream<Arguments> validCreationProvider() {
    // Covers: 002: US1, FR-002, FR-004
    return Stream.of(
        Arguments.of(anOrderWithOneLine()),
        Arguments.of(anOrderWithTwoProducts()),
        Arguments.of(anOrderWhoseMergedQuantityIsTheLargest()));
  }

  @Override
  protected Stream<Arguments> invalidCreationProvider() {
    // Covers: 002: US1, FR-002, FR-003, FR-004
    return Stream.of(
        Arguments.of(anOrderWithoutId()),
        Arguments.of(anOrderWithoutLines()),
        Arguments.of(anOrderWithNoLine()),
        Arguments.of(anOrderWhoseMergedQuantityIsAboveTheLargest()));
  }

  @Test
  void linesForTheSameProductAreMergedBySummingTheirQuantities() {
    final Order order = OrderFixture.defaultFixture()
        .withLines(List.of(lineOf(DESK_LAMP, 2), lineOf(NOTEBOOK, 1), lineOf(DESK_LAMP, 3)))
        .build();

    assertThat(order.getLines()).containsExactly(lineOf(DESK_LAMP, 5), lineOf(NOTEBOOK, 1));
  }

  @Test
  void twoOrdersWithTheSameIdAreTheSameOrder() {
    final Order order = OrderFixture.defaultFixture().build();
    final Order other = OrderFixture.defaultFixture().withLines(List.of(lineOf(NOTEBOOK, 4))).build();

    assertThat(order).isEqualTo(other).hasSameHashCodeAs(other);
  }

  private static OrderFixture anOrderWithOneLine() {
    return OrderFixture.defaultFixture();
  }

  private static OrderFixture anOrderWithTwoProducts() {
    return OrderFixture.defaultFixture().withLines(List.of(lineOf(DESK_LAMP, 1), lineOf(NOTEBOOK, 2)));
  }

  private static OrderFixture anOrderWhoseMergedQuantityIsTheLargest() {
    return OrderFixture.defaultFixture().withLines(List.of(lineOf(DESK_LAMP, 500), lineOf(DESK_LAMP, 499)));
  }

  private static OrderFixture anOrderWithoutId() {
    return OrderFixture.defaultFixture().withoutId();
  }

  private static OrderFixture anOrderWithoutLines() {
    return OrderFixture.defaultFixture().withoutLines();
  }

  private static OrderFixture anOrderWithNoLine() {
    return OrderFixture.defaultFixture().withLines(List.of());
  }

  private static OrderFixture anOrderWhoseMergedQuantityIsAboveTheLargest() {
    return OrderFixture.defaultFixture().withLines(List.of(lineOf(DESK_LAMP, 500), lineOf(DESK_LAMP, 500)));
  }

  private static OrderLine lineOf(final UUID productId, final int quantity) {
    return OrderLineFixture.defaultFixture().withProductId(productId).withQuantity(new Quantity(quantity)).build();
  }
}
