package com.example.starter.catalog.presentation.dto.request;

import jakarta.validation.constraints.Digits;
import java.math.BigDecimal;

public record AddProductRequestDto(
    String name,
    @Digits(integer = 10, fraction = 2, message = "The price exceeds what can be stored") BigDecimal price) {
}
