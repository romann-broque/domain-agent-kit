package com.example.starter.ordering.application.exceptions;

import com.example.starter.ordering.domain.exceptions.OrderException;
import java.util.UUID;
import lombok.Getter;

@Getter
public class UnknownProductException extends OrderException {

  private final UUID productId;

  public UnknownProductException(final UUID productId) {
    super("The catalog knows no product " + productId);
    this.productId = productId;
  }
}
