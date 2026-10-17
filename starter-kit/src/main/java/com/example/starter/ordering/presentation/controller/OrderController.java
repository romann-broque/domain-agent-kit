package com.example.starter.ordering.presentation.controller;

import com.example.starter.core.presentation.dtos.responses.ApiResponse;
import com.example.starter.ordering.application.usecase.PlaceOrderUseCase;
import com.example.starter.ordering.presentation.dto.request.PlaceOrderRequestDto;
import com.example.starter.ordering.presentation.dto.response.PlaceOrderResponseDto;
import com.example.starter.ordering.presentation.mapper.PlaceOrderMapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

  private final PlaceOrderUseCase placeOrder;

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public ApiResponse<PlaceOrderResponseDto> place(@Valid @RequestBody final PlaceOrderRequestDto request) {
    final var result = placeOrder.execute(PlaceOrderMapper.toCommand(request));
    return ApiResponse.ok(PlaceOrderMapper.toResponse(result));
  }
}
