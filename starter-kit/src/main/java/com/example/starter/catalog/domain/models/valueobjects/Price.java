package com.example.starter.catalog.domain.models.valueobjects;

import com.example.starter.catalog.domain.exceptions.ProductException;
import java.math.BigDecimal;

public record Price(BigDecimal amount) {

  private static final int MAX_DECIMALS = 2;

  public Price {
    requirePositive(amount);
    requireAtMostTwoDecimals(amount);
  }

  private static void requirePositive(final BigDecimal amount) {
    if (amount == null || amount.signum() <= 0) {
      throw new ProductException("A price must be greater than zero");
    }
  }

  private static void requireAtMostTwoDecimals(final BigDecimal amount) {
    if (amount.stripTrailingZeros().scale() > MAX_DECIMALS) {
      throw new ProductException("A price holds at most " + MAX_DECIMALS + " decimals");
    }
  }
}
