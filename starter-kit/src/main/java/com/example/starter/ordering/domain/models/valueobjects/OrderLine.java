package com.example.starter.ordering.domain.models.valueobjects;

import com.example.starter.ordering.domain.exceptions.OrderException;
import java.util.UUID;

public record OrderLine(UUID productId, Quantity quantity) {

  public OrderLine {
    requireProduct(productId);
    requireQuantity(quantity);
  }

  public OrderLine mergedWith(final OrderLine other) {
    return new OrderLine(productId, quantity.plus(other.quantity));
  }

  private static void requireProduct(final UUID productId) {
    if (productId == null) {
      throw new OrderException("An order line needs a product");
    }
  }

  private static void requireQuantity(final Quantity quantity) {
    if (quantity == null) {
      throw new OrderException("An order line needs a quantity");
    }
  }
}
