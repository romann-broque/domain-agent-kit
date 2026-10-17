package com.example.starter.fixture.catalog.application.command;

import com.example.starter.catalog.application.command.AddProductCommand;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.math.BigDecimal;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = AddProductCommand.class, dataModelClass = AddProductCommandDataSet.DataModel.class)
public class AddProductCommandDataSet {

  public static AddProductCommand build(final DataModel model) {
    return new AddProductCommand(model.name, model.price);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public String name = "Desk lamp";
    public BigDecimal price = new BigDecimal("24.90");
  }
}
