package com.example.starter.catalog.presentation.controller;

import com.example.starter.catalog.application.usecase.AddProductUseCase;
import com.example.starter.catalog.presentation.dto.request.AddProductRequestDto;
import com.example.starter.catalog.presentation.dto.response.AddProductResponseDto;
import com.example.starter.catalog.presentation.mapper.AddProductMapper;
import com.example.starter.core.presentation.dtos.responses.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

  private final AddProductUseCase addProduct;

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public ApiResponse<AddProductResponseDto> add(@Valid @RequestBody final AddProductRequestDto request) {
    final var result = addProduct.execute(AddProductMapper.toCommand(request));
    return ApiResponse.ok(AddProductMapper.toResponse(result));
  }
}
