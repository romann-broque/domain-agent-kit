package com.example.starter.catalog.domain.models.valueobjects;

import com.example.starter.catalog.domain.exceptions.ProductException;
import java.util.UUID;

public record ProductId(UUID value) {

  public ProductId {
    requireValue(value);
  }

  public static ProductId newId() {
    return new ProductId(UUID.randomUUID());
  }

  private static void requireValue(final UUID value) {
    if (value == null) {
      throw new ProductException("A product id is required");
    }
  }
}
