package com.example.starter.core.domain.exceptions;

public abstract class DomainException extends RuntimeException {

  protected DomainException(final String message) {
    super(message);
  }
}
