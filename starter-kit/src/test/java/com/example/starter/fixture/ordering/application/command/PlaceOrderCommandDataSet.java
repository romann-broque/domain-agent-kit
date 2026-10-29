package com.example.starter.fixture.ordering.application.command;

import com.example.starter.ordering.application.command.PlaceOrderCommand;
import com.example.starter.ordering.application.command.PlaceOrderLineCommand;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = PlaceOrderCommand.class, dataModelClass = PlaceOrderCommandDataSet.DataModel.class)
public class PlaceOrderCommandDataSet {

  public static PlaceOrderCommand build(final DataModel model) {
    return new PlaceOrderCommand(model.lines);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public List<PlaceOrderLineCommand> lines = List.of(PlaceOrderLineCommandFixture.buildDefault());
  }
}
