package com.example.starter.architecture;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

final class BoundedContexts {

  private final String sharedKernelPackage;
  private final List<Context> contexts;

  private BoundedContexts(final String sharedKernelPackage, final List<Context> contexts) {
    this.sharedKernelPackage = sharedKernelPackage;
    this.contexts = List.copyOf(contexts);
  }

  static Builder withSharedKernel(final String sharedKernelPackage) {
    return new Builder(sharedKernelPackage);
  }

  String[] packagePatterns() {
    return contexts.stream().map(context -> context.basePackage() + "..").toArray(String[]::new);
  }

  Optional<Context> contextOf(final String packageName) {
    return contexts.stream().filter(context -> context.holds(packageName)).findFirst();
  }

  boolean allowsCrossing(final String sourcePackage, final String targetPackage) {
    if (targetPackage.startsWith(sharedKernelPackage)) {
      return true;
    }
    final Optional<Context> source = contextOf(sourcePackage);
    final Optional<Context> target = contextOf(targetPackage);
    if (source.isEmpty() || target.isEmpty() || source.equals(target)) {
      return true;
    }
    return source.get().crossings().stream()
        .anyMatch(crossing -> crossing.allows(
            source.get().subPathOf(sourcePackage), target.get(), target.get().subPathOf(targetPackage)));
  }

  record Context(String name, String basePackage, List<Crossing> crossings) {

    boolean holds(final String packageName) {
      return packageName.equals(basePackage) || packageName.startsWith(basePackage + ".");
    }

    String subPathOf(final String packageName) {
      return packageName.equals(basePackage) ? "" : packageName.substring(basePackage.length() + 1);
    }
  }

  record Crossing(String fromSubPackage, String toContext, String toSubPackage) {

    boolean allows(final String sourceSubPath, final Context target, final String targetSubPath) {
      return startsWithPackage(sourceSubPath, fromSubPackage)
          && target.name().equals(toContext)
          && startsWithPackage(targetSubPath, toSubPackage);
    }

    private static boolean startsWithPackage(final String subPath, final String prefix) {
      return subPath.equals(prefix) || subPath.startsWith(prefix + ".");
    }
  }

  static final class Builder {

    private final String sharedKernelPackage;
    private final List<Context> contexts = new ArrayList<>();

    private Builder(final String sharedKernelPackage) {
      this.sharedKernelPackage = sharedKernelPackage;
    }

    ContextBuilder context(final String name, final String basePackage) {
      return new ContextBuilder(this, name, basePackage);
    }

    BoundedContexts build() {
      return new BoundedContexts(sharedKernelPackage, contexts);
    }
  }

  static final class ContextBuilder {

    private final Builder owner;
    private final String name;
    private final String basePackage;
    private final List<Crossing> crossings = new ArrayList<>();

    private ContextBuilder(final Builder owner, final String name, final String basePackage) {
      this.owner = owner;
      this.name = name;
      this.basePackage = basePackage;
    }

    ContextBuilder mayCross(final String fromSubPackage, final String toContext, final String toSubPackage) {
      crossings.add(new Crossing(fromSubPackage, toContext, toSubPackage));
      return this;
    }

    Builder and() {
      owner.contexts.add(new Context(name, basePackage, List.copyOf(crossings)));
      return owner;
    }
  }
}
