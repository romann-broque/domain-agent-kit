package com.example.starter.catalog.infrastructure.persistence.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "product")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ProductEntity {

  @Id
  private UUID id;

  @Column(nullable = false, unique = true, length = 100)
  private String name;

  @Column(nullable = false, precision = 12, scale = 2)
  private BigDecimal price;
}
