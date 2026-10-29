package com.example.starter.core.presentation.dtos.responses;

public record ApiResponse<T>(T data, String error) {

  public static <T> ApiResponse<T> ok(final T data) {
    return new ApiResponse<>(data, null);
  }

  public static <T> ApiResponse<T> error(final String error) {
    return new ApiResponse<>(null, error);
  }
}
