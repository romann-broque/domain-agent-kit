package com.example.starter.ordering.application.ports;

import java.util.UUID;

@FunctionalInterface
public interface OrderedProductChecker {

  boolean exists(UUID productId);
}
