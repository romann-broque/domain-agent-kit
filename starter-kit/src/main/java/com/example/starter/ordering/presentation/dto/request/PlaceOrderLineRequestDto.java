package com.example.starter.ordering.presentation.dto.request;

import java.util.UUID;

public record PlaceOrderLineRequestDto(UUID productId, int quantity) {
}
