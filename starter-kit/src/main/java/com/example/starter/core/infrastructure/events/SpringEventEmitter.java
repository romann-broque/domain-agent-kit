package com.example.starter.core.infrastructure.events;

import com.example.starter.core.application.ports.EventEmitter;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

@Component
public class SpringEventEmitter implements EventEmitter {

  private final ApplicationEventPublisher publisher;

  public SpringEventEmitter(final ApplicationEventPublisher publisher) {
    this.publisher = publisher;
  }

  @Override
  public void emit(final Object event) {
    publisher.publishEvent(event);
  }
}
