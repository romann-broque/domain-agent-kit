package com.example.starter.catalog.application.command;

import java.math.BigDecimal;

public record AddProductCommand(String name, BigDecimal price) {
}
