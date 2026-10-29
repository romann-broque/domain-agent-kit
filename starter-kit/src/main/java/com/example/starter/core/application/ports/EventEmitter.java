package com.example.starter.core.application.ports;

@FunctionalInterface
public interface EventEmitter {

  void emit(Object event);
}
