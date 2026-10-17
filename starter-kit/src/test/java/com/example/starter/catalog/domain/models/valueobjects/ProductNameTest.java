package com.example.starter.catalog.domain.models.valueobjects;

import static org.assertj.core.api.Assertions.assertThat;

import com.example.starter.catalog.domain.exceptions.ProductException;
import com.example.starter.fixture.catalog.domain.valueobjects.ProductNameFixture;
import com.example.starter.testutils.templates.CreationTest;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.provider.Arguments;

class ProductNameTest extends CreationTest<ProductName, ProductNameFixture, ProductException> {

  @Override
  protected Stream<Arguments> validCreationProvider() {
    // Covers: 001: US1, FR-001
    return Stream.of(
        Arguments.of(aShortName()),
        Arguments.of(aNameOf100Characters()));
  }

  @Override
  protected Stream<Arguments> invalidCreationProvider() {
    // Covers: 001: US1, FR-001
    return Stream.of(
        Arguments.of(aMissingName()),
        Arguments.of(aBlankName()),
        Arguments.of(aNameOf101Characters()));
  }

  @Test
  void surroundingSpacesAreTrimmed() {
    assertThat(new ProductName("  Desk lamp  ").value()).isEqualTo("Desk lamp");
  }

  private static ProductNameFixture aShortName() {
    return ProductNameFixture.defaultFixture().withValue("Pen");
  }

  private static ProductNameFixture aNameOf100Characters() {
    return ProductNameFixture.defaultFixture().withValue("a".repeat(100));
  }

  private static ProductNameFixture aMissingName() {
    return ProductNameFixture.defaultFixture().withoutValue();
  }

  private static ProductNameFixture aBlankName() {
    return ProductNameFixture.defaultFixture().withValue("   ");
  }

  private static ProductNameFixture aNameOf101Characters() {
    return ProductNameFixture.defaultFixture().withValue("a".repeat(101));
  }
}
