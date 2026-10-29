package com.example.starter.ordering.infrastructure.persistence.entities;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "customer_order")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderEntity {

  @Id
  private UUID id;

  @ElementCollection(fetch = FetchType.EAGER)
  @CollectionTable(name = "order_line", joinColumns = @JoinColumn(name = "order_id"))
  private List<OrderLineEntity> lines = new ArrayList<>();
}
