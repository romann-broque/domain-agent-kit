package com.example.starter.fixture.ordering.domain.valueobjects;

import com.example.starter.ordering.domain.models.valueobjects.Quantity;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = Quantity.class, dataModelClass = QuantityDataSet.DataModel.class)
public class QuantityDataSet {

  public static Quantity build(final DataModel model) {
    return new Quantity(model.value);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public int value = 1;
  }
}
