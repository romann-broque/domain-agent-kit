package com.example.starter.fixture.ordering.domain.valueobjects;

import com.example.starter.ordering.domain.models.valueobjects.OrderId;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = OrderId.class, dataModelClass = OrderIdDataSet.DataModel.class)
public class OrderIdDataSet {

  public static OrderId build(final DataModel model) {
    return new OrderId(model.value);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public UUID value = UUID.fromString("00000000-0000-0000-0000-000000000010");
  }
}
