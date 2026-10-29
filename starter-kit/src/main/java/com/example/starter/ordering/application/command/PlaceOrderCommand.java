package com.example.starter.ordering.application.command;

import java.util.List;

public record PlaceOrderCommand(List<PlaceOrderLineCommand> lines) {
}
