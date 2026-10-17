package com.example.starter.ordering.application.ports;

import com.example.starter.ordering.domain.models.aggregates.Order;

@FunctionalInterface
public interface OrderSaver {

  void save(Order order);
}
