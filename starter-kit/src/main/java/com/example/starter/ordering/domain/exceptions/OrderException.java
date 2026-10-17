package com.example.starter.ordering.domain.exceptions;

import com.example.starter.core.domain.exceptions.DomainException;

public class OrderException extends DomainException {

  public OrderException(final String message) {
    super(message);
  }
}
