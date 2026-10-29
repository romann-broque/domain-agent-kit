package com.example.starter.catalog.domain.exceptions;

import com.example.starter.core.domain.exceptions.DomainException;

public class ProductException extends DomainException {

  public ProductException(final String message) {
    super(message);
  }
}
