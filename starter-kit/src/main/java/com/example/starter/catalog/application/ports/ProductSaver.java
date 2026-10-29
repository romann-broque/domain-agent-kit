package com.example.starter.catalog.application.ports;

import com.example.starter.catalog.domain.models.aggregates.Product;

@FunctionalInterface
public interface ProductSaver {

  void save(Product product);
}
