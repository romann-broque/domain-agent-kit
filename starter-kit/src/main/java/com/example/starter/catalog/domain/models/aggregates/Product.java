package com.example.starter.catalog.domain.models.aggregates;

import com.example.starter.catalog.domain.exceptions.ProductException;
import com.example.starter.catalog.domain.models.valueobjects.Price;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import java.util.Objects;
import lombok.Getter;

@Getter
public class Product {

  private final ProductId id;
  private final ProductName name;
  private Price price;

  public Product(final ProductId id, final ProductName name, final Price price) {
    this.id = require(id, "A product needs an id");
    this.name = require(name, "A product needs a name");
    this.price = require(price, "A product needs a price");
  }

  public void changePrice(final Price newPrice) {
    this.price = require(newPrice, "A product needs a price");
  }

  private static <T> T require(final T value, final String message) {
    if (value == null) {
      throw new ProductException(message);
    }
    return value;
  }

  @Override
  public boolean equals(final Object other) {
    return other instanceof Product product && id.equals(product.id);
  }

  @Override
  public int hashCode() {
    return Objects.hash(id);
  }
}
