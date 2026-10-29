package com.example.starter.ordering.infrastructure.persistence.adapters;

import com.example.starter.ordering.application.ports.OrderSaver;
import com.example.starter.ordering.domain.models.aggregates.Order;
import com.example.starter.ordering.infrastructure.persistence.mappers.OrderEntityMapper;
import com.example.starter.ordering.infrastructure.persistence.repositories.OrderJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class OrderAdapter implements OrderSaver {

  private final OrderJpaRepository repository;

  @Override
  public void save(final Order order) {
    repository.save(OrderEntityMapper.toEntity(order));
  }
}
