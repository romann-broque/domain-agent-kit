package com.example.starter.fixture.ordering.domain.valueobjects;

import com.example.starter.ordering.domain.models.valueobjects.OrderLine;
import com.example.starter.ordering.domain.models.valueobjects.Quantity;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = OrderLine.class, dataModelClass = OrderLineDataSet.DataModel.class)
public class OrderLineDataSet {

  public static OrderLine build(final DataModel model) {
    return new OrderLine(model.productId, model.quantity);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public UUID productId = UUID.fromString("00000000-0000-0000-0000-000000000001");
    public Quantity quantity = QuantityFixture.buildDefault();
  }
}
