package com.example.starter.catalog.infrastructure.persistence.repositories;

import com.example.starter.catalog.infrastructure.persistence.entities.ProductEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductJpaRepository extends JpaRepository<ProductEntity, UUID> {

  Optional<ProductEntity> findByName(String name);
}
