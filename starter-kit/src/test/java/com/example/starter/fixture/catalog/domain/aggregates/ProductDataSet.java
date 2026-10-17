package com.example.starter.fixture.catalog.domain.aggregates;

import com.example.starter.catalog.domain.models.aggregates.Product;
import com.example.starter.catalog.domain.models.valueobjects.Price;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;
import com.example.starter.fixture.catalog.domain.valueobjects.PriceFixture;
import com.example.starter.fixture.catalog.domain.valueobjects.ProductIdFixture;
import com.example.starter.fixture.catalog.domain.valueobjects.ProductNameFixture;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = Product.class, dataModelClass = ProductDataSet.DataModel.class)
public class ProductDataSet {

  public static Product build(final DataModel model) {
    return new Product(model.id, model.name, model.price);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public ProductId id = ProductIdFixture.buildDefault();
    public ProductName name = ProductNameFixture.buildDefault();
    public Price price = PriceFixture.buildDefault();
  }
}
