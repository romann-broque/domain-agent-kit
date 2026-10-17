package com.example.starter.catalog.presentation.dto.request;

import java.math.BigDecimal;

public record AddProductRequestDto(String name, BigDecimal price) {
}
