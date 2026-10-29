package com.example.starter.ordering.infrastructure.persistence.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderLineEntity {

  @Column(name = "product_id", nullable = false)
  private UUID productId;

  @Column(nullable = false)
  private int quantity;
}
