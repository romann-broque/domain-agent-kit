package com.example.starter.fixture.catalog.domain.valueobjects;

import com.example.starter.catalog.domain.models.valueobjects.Price;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.math.BigDecimal;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = Price.class, dataModelClass = PriceDataSet.DataModel.class)
public class PriceDataSet {

  public static Price build(final DataModel model) {
    return new Price(model.amount);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public BigDecimal amount = new BigDecimal("24.90");
  }
}
