package com.example.starter.ordering.domain.models.valueobjects;

import com.example.starter.fixture.ordering.domain.valueobjects.QuantityFixture;
import com.example.starter.ordering.domain.exceptions.OrderException;
import com.example.starter.testutils.templates.CreationTest;
import java.util.stream.Stream;
import org.junit.jupiter.params.provider.Arguments;

class QuantityTest extends CreationTest<Quantity, QuantityFixture, OrderException> {

  @Override
  protected Stream<Arguments> validCreationProvider() {
    // Covers: 002: US1, FR-003
    return Stream.of(
        Arguments.of(theSmallestQuantity()),
        Arguments.of(theLargestQuantity()));
  }

  @Override
  protected Stream<Arguments> invalidCreationProvider() {
    // Covers: 002: US1, FR-003
    return Stream.of(
        Arguments.of(aZeroQuantity()),
        Arguments.of(aNegativeQuantity()),
        Arguments.of(aQuantityAboveTheLargest()));
  }

  private static QuantityFixture theSmallestQuantity() {
    return QuantityFixture.defaultFixture().withValue(1);
  }

  private static QuantityFixture theLargestQuantity() {
    return QuantityFixture.defaultFixture().withValue(999);
  }

  private static QuantityFixture aZeroQuantity() {
    return QuantityFixture.defaultFixture().withValue(0);
  }

  private static QuantityFixture aNegativeQuantity() {
    return QuantityFixture.defaultFixture().withValue(-1);
  }

  private static QuantityFixture aQuantityAboveTheLargest() {
    return QuantityFixture.defaultFixture().withValue(1000);
  }
}
