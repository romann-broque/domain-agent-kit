package com.example.starter.fixture.catalog.domain.valueobjects;

import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = ProductName.class, dataModelClass = ProductNameDataSet.DataModel.class)
public class ProductNameDataSet {

  public static ProductName build(final DataModel model) {
    return new ProductName(model.value);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public String value = "Desk lamp";
  }
}
