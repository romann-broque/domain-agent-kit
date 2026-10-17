package com.example.starter.catalog.application.exceptions;

import com.example.starter.catalog.domain.exceptions.ProductException;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;

public class ProductAlreadyExistsException extends ProductException {

  public ProductAlreadyExistsException(final ProductName name) {
    super("A product named \"" + name.value() + "\" already exists");
  }
}
