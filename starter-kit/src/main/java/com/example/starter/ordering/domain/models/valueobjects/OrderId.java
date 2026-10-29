package com.example.starter.ordering.domain.models.valueobjects;

import com.example.starter.ordering.domain.exceptions.OrderException;
import java.util.UUID;

public record OrderId(UUID value) {

  public OrderId {
    requireValue(value);
  }

  public static OrderId newId() {
    return new OrderId(UUID.randomUUID());
  }

  private static void requireValue(final UUID value) {
    if (value == null) {
      throw new OrderException("An order id is required");
    }
  }
}
