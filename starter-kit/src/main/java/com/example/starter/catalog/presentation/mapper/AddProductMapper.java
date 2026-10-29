package com.example.starter.catalog.presentation.mapper;

import com.example.starter.catalog.application.command.AddProductCommand;
import com.example.starter.catalog.application.results.AddProductResult;
import com.example.starter.catalog.presentation.dto.request.AddProductRequestDto;
import com.example.starter.catalog.presentation.dto.response.AddProductResponseDto;

public final class AddProductMapper {

  private AddProductMapper() {
  }

  public static AddProductCommand toCommand(final AddProductRequestDto request) {
    return new AddProductCommand(request.name(), request.price());
  }

  public static AddProductResponseDto toResponse(final AddProductResult result) {
    return new AddProductResponseDto(result.productId());
  }
}
