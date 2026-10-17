package com.example.starter.ordering.domain.events;

import com.example.starter.ordering.domain.models.valueobjects.OrderId;

public record OrderPlaced(OrderId orderId) {
}
