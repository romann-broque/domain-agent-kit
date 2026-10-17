package com.example.starter.fixture.ordering.application.command;

import com.example.starter.ordering.application.command.PlaceOrderLineCommand;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = PlaceOrderLineCommand.class, dataModelClass = PlaceOrderLineCommandDataSet.DataModel.class)
public class PlaceOrderLineCommandDataSet {

  public static PlaceOrderLineCommand build(final DataModel model) {
    return new PlaceOrderLineCommand(model.productId, model.quantity);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public UUID productId = UUID.fromString("00000000-0000-0000-0000-000000000001");
    public int quantity = 1;
  }
}
