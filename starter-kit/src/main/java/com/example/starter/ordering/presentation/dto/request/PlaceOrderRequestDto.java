package com.example.starter.ordering.presentation.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record PlaceOrderRequestDto(
    List<@NotNull(message = "An order line is required") @Valid PlaceOrderLineRequestDto> lines) {
}
