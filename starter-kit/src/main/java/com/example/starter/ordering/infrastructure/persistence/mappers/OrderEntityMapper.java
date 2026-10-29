package com.example.starter.ordering.infrastructure.persistence.mappers;

import com.example.starter.ordering.domain.models.aggregates.Order;
import com.example.starter.ordering.domain.models.valueobjects.OrderId;
import com.example.starter.ordering.domain.models.valueobjects.OrderLine;
import com.example.starter.ordering.domain.models.valueobjects.Quantity;
import com.example.starter.ordering.infrastructure.persistence.entities.OrderEntity;
import com.example.starter.ordering.infrastructure.persistence.entities.OrderLineEntity;
import java.util.ArrayList;

public final class OrderEntityMapper {

  private OrderEntityMapper() {
  }

  public static OrderEntity toEntity(final Order order) {
    final var lines = order.getLines().stream()
        .map(line -> new OrderLineEntity(line.productId(), line.quantity().value()))
        .toList();
    return new OrderEntity(order.getId().value(), new ArrayList<>(lines));
  }

  public static Order toDomain(final OrderEntity entity) {
    final var lines = entity.getLines().stream()
        .map(line -> new OrderLine(line.getProductId(), new Quantity(line.getQuantity())))
        .toList();
    return new Order(new OrderId(entity.getId()), lines);
  }
}
