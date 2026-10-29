package com.example.starter.catalog.infrastructure.persistence.mappers;

import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.Price;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import com.example.starter.catalog.infrastructure.persistence.entities.ProductEntity;

public final class ProductEntityMapper {

  private ProductEntityMapper() {
  }

  public static ProductEntity toEntity(final Product product) {
    return new ProductEntity(product.getId().value(), product.getName().value(), product.getPrice().amount());
  }

  public static Product toDomain(final ProductEntity entity) {
    return new Product(
        new ProductId(entity.getId()),
        new ProductName(entity.getName()),
        new Price(entity.getPrice()));
  }
}
