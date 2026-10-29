package com.example.starter.catalog.domain.models.aggregates;

import static org.assertj.core.api.Assertions.assertThat;

import com.example.starter.catalog.domain.exceptions.ProductException;
import com.example.starter.catalog.domain.models.valueobjects.Price;
import com.example.starter.fixture.catalog.domain.aggregates.ProductFixture;
import com.example.starter.fixture.catalog.domain.valueobjects.ProductNameFixture;
import com.example.starter.testutils.templates.CreationTest;
import java.math.BigDecimal;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.provider.Arguments;

class ProductTest extends CreationTest<Product, ProductFixture, ProductException> {

  @Override
  protected Stream<Arguments> validCreationProvider() {
    // Covers: 001: US1, FR-001, FR-002
    return Stream.of(Arguments.of(aProductWithANameAndAPrice()));
  }

  @Override
  protected Stream<Arguments> invalidCreationProvider() {
    // Covers: 001: US1, FR-001, FR-002
    return Stream.of(
        Arguments.of(aProductWithoutId()),
        Arguments.of(aProductWithoutName()),
        Arguments.of(aProductWithoutPrice()));
  }

  @Test
  void twoProductsWithTheSameIdAreTheSameProduct() {
    final Product lamp = ProductFixture.defaultFixture().build();
    final Product renamed = ProductFixture.defaultFixture()
        .withName(ProductNameFixture.defaultFixture().withValue("Floor lamp").build())
        .build();

    assertThat(lamp).isEqualTo(renamed).hasSameHashCodeAs(renamed);
  }

  @Test
  void changingThePriceKeepsTheNewPrice() {
    final Product lamp = ProductFixture.defaultFixture().build();

    lamp.changePrice(new Price(new BigDecimal("19.00")));

    assertThat(lamp.getPrice().amount()).isEqualByComparingTo("19.00");
  }

  private static ProductFixture aProductWithANameAndAPrice() {
    return ProductFixture.defaultFixture();
  }

  private static ProductFixture aProductWithoutId() {
    return ProductFixture.defaultFixture().withoutId();
  }

  private static ProductFixture aProductWithoutName() {
    return ProductFixture.defaultFixture().withoutName();
  }

  private static ProductFixture aProductWithoutPrice() {
    return ProductFixture.defaultFixture().withoutPrice();
  }
}
