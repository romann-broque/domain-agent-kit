package com.example.starter.ordering.presentation.mapper;

import com.example.starter.ordering.application.command.PlaceOrderCommand;
import com.example.starter.ordering.application.command.PlaceOrderLineCommand;
import com.example.starter.ordering.application.results.PlaceOrderResult;
import com.example.starter.ordering.presentation.dto.request.PlaceOrderRequestDto;
import com.example.starter.ordering.presentation.dto.response.PlaceOrderResponseDto;
import java.util.List;

public final class PlaceOrderMapper {

  private PlaceOrderMapper() {
  }

  public static PlaceOrderCommand toCommand(final PlaceOrderRequestDto request) {
    final var lines = request.lines() == null
        ? List.<PlaceOrderLineCommand>of()
        : request.lines().stream()
            .map(line -> new PlaceOrderLineCommand(line.productId(), line.quantity()))
            .toList();
    return new PlaceOrderCommand(lines);
  }

  public static PlaceOrderResponseDto toResponse(final PlaceOrderResult result) {
    return new PlaceOrderResponseDto(result.orderId());
  }
}
