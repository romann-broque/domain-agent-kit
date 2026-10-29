package com.example.starter.ordering.infrastructure.persistence.repositories;

import com.example.starter.ordering.infrastructure.persistence.entities.OrderEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderJpaRepository extends JpaRepository<OrderEntity, UUID> {
}
