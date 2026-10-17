package com.example.starter.catalog.application.usecase;

import com.example.starter.catalog.application.command.AddProductCommand;
import com.example.starter.catalog.application.exceptions.ProductAlreadyExistsException;
import com.example.starter.catalog.application.ports.ProductRetrieverByName;
import com.example.starter.catalog.application.ports.ProductSaver;
import com.example.starter.catalog.application.results.AddProductResult;
import com.example.starter.catalog.domain.events.ProductAdded;
import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.Price;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import com.example.starter.core.application.ports.EventEmitter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
@RequiredArgsConstructor
public class AddProductUseCase {

  private final ProductRetrieverByName productRetrieverByName;
  private final ProductSaver productSaver;
  private final EventEmitter eventEmitter;

  public AddProductResult execute(final AddProductCommand command) {
    final ProductName name = new ProductName(command.name());
    final Price price = new Price(command.price());
    requireUniqueName(name);

    final Product product = new Product(ProductId.newId(), name, price);
    productSaver.save(product);
    eventEmitter.emit(new ProductAdded(product.getId()));

    return new AddProductResult(product.getId().value());
  }

  private void requireUniqueName(final ProductName name) {
    if (productRetrieverByName.retrieveByName(name).isPresent()) {
      throw new ProductAlreadyExistsException(name);
    }
  }
}
