package com.example.starter.catalog.domain.models.valueobjects;

import com.example.starter.catalog.domain.exceptions.ProductException;

public record ProductName(String value) {

  private static final int MAX_LENGTH = 100;

  public ProductName {
    requireNotBlank(value);
    value = value.trim();
    requireAtMostMaxLength(value);
  }

  private static void requireNotBlank(final String value) {
    if (value == null || value.isBlank()) {
      throw new ProductException("A product name is required");
    }
  }

  private static void requireAtMostMaxLength(final String value) {
    if (value.length() > MAX_LENGTH) {
      throw new ProductException("A product name holds at most " + MAX_LENGTH + " characters");
    }
  }
}
