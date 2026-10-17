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
