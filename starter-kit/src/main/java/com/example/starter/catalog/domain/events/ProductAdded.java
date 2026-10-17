package com.example.starter.catalog.domain.events;

import com.example.starter.catalog.domain.models.valueobjects.ProductId;

public record ProductAdded(ProductId productId) {
}
