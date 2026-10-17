package com.example.starter.catalog.application.ports;

import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import java.util.Optional;

@FunctionalInterface
public interface ProductRetrieverByName {

  Optional<Product> retrieveByName(ProductName name);
}
