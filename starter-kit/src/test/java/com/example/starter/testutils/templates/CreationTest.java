package com.example.starter.testutils.templates;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.ParameterizedType;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.params.provider.Arguments;

/**
 * Base class for creation tests. A subclass lists valid and invalid fixtures; each one becomes a dynamic test that
 * calls {@code fixture.build()} and expects either no exception or an {@code EXCEPTION}.
 */
@SuppressWarnings("unchecked")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public abstract class CreationTest<ENTITY, FIXTURE, EXCEPTION extends RuntimeException> {

  private final String entityClassName;
  private final Class<EXCEPTION> exceptionClass;

  private List<Arguments> validFixtures;
  private List<Arguments> invalidFixtures;

  protected CreationTest() {
    final ParameterizedType type = (ParameterizedType) getClass().getGenericSuperclass();
    this.entityClassName = ((Class<ENTITY>) type.getActualTypeArguments()[0]).getSimpleName();
    this.exceptionClass = (Class<EXCEPTION>) type.getActualTypeArguments()[2];
  }

  @BeforeEach
  void setup() {
    validFixtures = validCreationProvider().toList();
    invalidFixtures = invalidCreationProvider().toList();
  }

  protected Stream<Arguments> validCreationProvider() {
    return Stream.empty();
  }

  protected Stream<Arguments> invalidCreationProvider() {
    return Stream.empty();
  }

  @TestFactory
  @DisplayName("✅ Valid creation")
  public Stream<DynamicTest> validCreationTests() {
    assumeTrue(!validFixtures.isEmpty(), "No valid cases provided, skipping tests.");

    final AtomicInteger count = new AtomicInteger(1);
    return validFixtures.stream().map(args -> {
      final FIXTURE fixture = (FIXTURE) args.get()[0];

      return DynamicTest.dynamicTest("#" + count.getAndIncrement() + ": " + entityClassName + " - Valid creation",
          () -> assertThatCode(() -> invokeBuild(fixture)).doesNotThrowAnyException());
    });
  }

  @TestFactory
  @DisplayName("❌ Invalid creation")
  public Stream<DynamicTest> invalidCreationTests() {
    assumeTrue(!invalidFixtures.isEmpty(), "No invalid cases provided, skipping tests.");

    final AtomicInteger count = new AtomicInteger(1);
    return invalidFixtures.stream().map(args -> {
      final FIXTURE fixture = (FIXTURE) args.get()[0];

      return DynamicTest.dynamicTest("#" + count.getAndIncrement() + ": " + entityClassName + " - Invalid creation",
          () -> assertThatThrownBy(() -> invokeBuild(fixture)).isInstanceOf(exceptionClass));
    });
  }

  private void invokeBuild(final FIXTURE fixture) throws Throwable {
    try {
      fixture.getClass().getMethod("build").invoke(fixture);
    } catch (final InvocationTargetException e) {
      throw e.getCause();
    }
  }
}
