package com.example.starter.ordering.domain.models.aggregates;

import com.example.starter.ordering.domain.exceptions.OrderException;
import com.example.starter.ordering.domain.models.valueobjects.OrderId;
import com.example.starter.ordering.domain.models.valueobjects.OrderLine;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import lombok.Getter;

@Getter
public class Order {

  private final OrderId id;
  private final List<OrderLine> lines;

  public Order(final OrderId id, final List<OrderLine> lines) {
    this.id = require(id, "An order needs an id");
    this.lines = merged(requireAtLeastOneLine(lines));
  }

  private static List<OrderLine> requireAtLeastOneLine(final List<OrderLine> lines) {
    if (lines == null || lines.isEmpty()) {
      throw new OrderException("An order holds at least one line");
    }
    return lines;
  }

  private static List<OrderLine> merged(final List<OrderLine> lines) {
    final Map<UUID, OrderLine> byProduct = new LinkedHashMap<>();
    lines.forEach(line -> byProduct.merge(line.productId(), line, OrderLine::mergedWith));
    return List.copyOf(byProduct.values());
  }

  private static <T> T require(final T value, final String message) {
    if (value == null) {
      throw new OrderException(message);
    }
    return value;
  }

  @Override
  public boolean equals(final Object other) {
    return other instanceof Order order && id.equals(order.id);
  }

  @Override
  public int hashCode() {
    return Objects.hash(id);
  }
}
