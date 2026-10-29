package com.example.starter.ordering.domain.models.valueobjects;

import com.example.starter.ordering.domain.exceptions.OrderException;

public record Quantity(int value) {

  private static final int MIN = 1;
  private static final int MAX = 999;

  public Quantity {
    requireWithinBounds(value);
  }

  public Quantity plus(final Quantity other) {
    return new Quantity(value + other.value);
  }

  private static void requireWithinBounds(final int value) {
    if (value < MIN || value > MAX) {
      throw new OrderException("A quantity lies between " + MIN + " and " + MAX);
    }
  }
}
