package com.example.starter.fixture.ordering.domain.aggregates;

import com.example.starter.fixture.ordering.domain.valueobjects.OrderIdFixture;
import com.example.starter.fixture.ordering.domain.valueobjects.OrderLineFixture;
import com.example.starter.ordering.domain.models.aggregates.Order;
import com.example.starter.ordering.domain.models.valueobjects.OrderId;
import com.example.starter.ordering.domain.models.valueobjects.OrderLine;
import io.github.romannbroque.fixture.annotations.GenerateFixture;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@GenerateFixture(entityClass = Order.class, dataModelClass = OrderDataSet.DataModel.class)
public class OrderDataSet {

  public static Order build(final DataModel model) {
    return new Order(model.id, model.lines);
  }

  @NoArgsConstructor
  @AllArgsConstructor
  public static class DataModel {
    public OrderId id = OrderIdFixture.buildDefault();
    public List<OrderLine> lines = List.of(OrderLineFixture.buildDefault());
  }
}
