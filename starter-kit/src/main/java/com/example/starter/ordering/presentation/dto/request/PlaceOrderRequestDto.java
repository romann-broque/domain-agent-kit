package com.example.starter.ordering.presentation.dto.request;

import java.util.List;

public record PlaceOrderRequestDto(List<PlaceOrderLineRequestDto> lines) {
}
