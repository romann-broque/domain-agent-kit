package com.example.starter.ordering.application.usecase;

import com.example.starter.core.application.ports.EventEmitter;
import com.example.starter.ordering.application.command.PlaceOrderCommand;
import com.example.starter.ordering.application.command.PlaceOrderLineCommand;
import com.example.starter.ordering.application.exceptions.UnknownProductException;
import com.example.starter.ordering.application.ports.OrderSaver;
import com.example.starter.ordering.application.ports.OrderedProductChecker;
import com.example.starter.ordering.application.results.PlaceOrderResult;
import com.example.starter.ordering.domain.events.OrderPlaced;
import com.example.starter.ordering.domain.models.aggregates.Order;
import com.example.starter.ordering.domain.models.valueobjects.OrderId;
import com.example.starter.ordering.domain.models.valueobjects.OrderLine;
import com.example.starter.ordering.domain.models.valueobjects.Quantity;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
@RequiredArgsConstructor
public class PlaceOrderUseCase {

  private final OrderedProductChecker orderedProductChecker;
  private final OrderSaver orderSaver;
  private final EventEmitter eventEmitter;

  public PlaceOrderResult execute(final PlaceOrderCommand command) {
    final Order order = new Order(OrderId.newId(), linesOf(command));
    requireKnownProducts(order);

    orderSaver.save(order);
    eventEmitter.emit(new OrderPlaced(order.getId()));

    return new PlaceOrderResult(order.getId().value());
  }

  private static List<OrderLine> linesOf(final PlaceOrderCommand command) {
    if (command.lines() == null) {
      return List.of();
    }
    return command.lines().stream().map(PlaceOrderUseCase::lineOf).toList();
  }

  private static OrderLine lineOf(final PlaceOrderLineCommand line) {
    return new OrderLine(line.productId(), new Quantity(line.quantity()));
  }

  private void requireKnownProducts(final Order order) {
    order.getLines().stream()
        .map(OrderLine::productId)
        .filter(productId -> !orderedProductChecker.exists(productId))
        .findFirst()
        .ifPresent(unknown -> {
          throw new UnknownProductException(unknown);
        });
  }
}
