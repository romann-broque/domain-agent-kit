package com.example.starter.ordering.domain.models.valueobjects;

import com.example.starter.fixture.ordering.domain.valueobjects.OrderLineFixture;
import com.example.starter.ordering.domain.exceptions.OrderException;
import com.example.starter.testutils.templates.CreationTest;
import java.util.stream.Stream;
import org.junit.jupiter.params.provider.Arguments;

class OrderLineTest extends CreationTest<OrderLine, OrderLineFixture, OrderException> {

  @Override
  protected Stream<Arguments> validCreationProvider() {
    // Covers: 002: US1, FR-001, FR-003
    return Stream.of(Arguments.of(aLineForAProductAndAQuantity()));
  }

  @Override
  protected Stream<Arguments> invalidCreationProvider() {
    // Covers: 002: US1, FR-001, FR-003
    return Stream.of(
        Arguments.of(aLineWithoutProduct()),
        Arguments.of(aLineWithoutQuantity()));
  }

  private static OrderLineFixture aLineForAProductAndAQuantity() {
    return OrderLineFixture.defaultFixture();
  }

  private static OrderLineFixture aLineWithoutProduct() {
    return OrderLineFixture.defaultFixture().withoutProductId();
  }

  private static OrderLineFixture aLineWithoutQuantity() {
    return OrderLineFixture.defaultFixture().withoutQuantity();
  }
}
