package com.example.starter.catalog.application.ports;

import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import java.util.Optional;

@FunctionalInterface
public interface ProductRetriever {

  Optional<Product> retrieve(ProductId id);
}
