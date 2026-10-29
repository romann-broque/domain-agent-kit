package com.example.starter.catalog.infrastructure.persistence.adapters;

import com.example.starter.catalog.application.ports.ProductRetriever;
import com.example.starter.catalog.application.ports.ProductRetrieverByName;
import com.example.starter.catalog.application.ports.ProductSaver;
import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import com.example.starter.catalog.infrastructure.persistence.mappers.ProductEntityMapper;
import com.example.starter.catalog.infrastructure.persistence.repositories.ProductJpaRepository;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ProductAdapter implements ProductRetriever, ProductRetrieverByName, ProductSaver {

  private final ProductJpaRepository repository;

  @Override
  public Optional<Product> retrieve(final ProductId id) {
    return repository.findById(id.value()).map(ProductEntityMapper::toDomain);
  }

  @Override
  public Optional<Product> retrieveByName(final ProductName name) {
    return repository.findByName(name.value()).map(ProductEntityMapper::toDomain);
  }

  @Override
  public void save(final Product product) {
    repository.save(ProductEntityMapper.toEntity(product));
  }
}
