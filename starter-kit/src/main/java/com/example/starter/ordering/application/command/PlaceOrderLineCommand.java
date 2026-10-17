package com.example.starter.ordering.application.command;

import java.util.UUID;

public record PlaceOrderLineCommand(UUID productId, int quantity) {
}
