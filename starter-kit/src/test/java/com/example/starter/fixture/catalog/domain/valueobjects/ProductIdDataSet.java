package com.example.starter.fixture.catalog.domain.valueobjects;

import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = ProductId.class, dataModelClass = ProductIdDataSet.DataModel.class)
public class ProductIdDataSet {

  public static ProductId build(final DataModel model) {
    return new ProductId(model.value);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public UUID value = UUID.fromString("00000000-0000-0000-0000-000000000001");
  }
}
