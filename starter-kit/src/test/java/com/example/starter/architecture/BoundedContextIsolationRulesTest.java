package com.example.starter.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;

import com.tngtech.archunit.core.domain.Dependency;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchCondition;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.ConditionEvents;
import com.tngtech.archunit.lang.SimpleConditionEvent;

@AnalyzeClasses(packages = "com.example.starter", importOptions = ImportOption.DoNotIncludeTests.class)
class BoundedContextIsolationRulesTest {

  private static final String BASE = "com.example.starter";

  private static final BoundedContexts CONTEXTS = BoundedContexts.withSharedKernel(BASE + ".shared")
      .context("catalog", BASE + ".catalog").and()
      .context("ordering", BASE + ".ordering")
      .mayCross("infrastructure.acl", "catalog", "application")
      .mayCross("infrastructure.acl", "catalog", "domain")
      .and()
      .build();

  @ArchTest
  static final ArchRule aContextCrossesOnlyThroughADeclaredAntiCorruptionLayer = classes()
      .that().resideInAnyPackage(CONTEXTS.packagePatterns())
      .should(crossOnlyWhereDeclared())
      .because("only the infrastructure/acl of a context may use another context, and only where declared");

  @ArchTest
  static final ArchRule everyTopLevelPackageIsADeclaredContextTheCoreOrTheSharedKernel = classes()
      .that().resideInAPackage(BASE + "..")
      .and().resideOutsideOfPackages(BASE, BASE + ".core..", BASE + ".shared..")
      .should().resideInAnyPackage(CONTEXTS.packagePatterns())
      .because("a context left undeclared here would escape the isolation rule");

  private static ArchCondition<JavaClass> crossOnlyWhereDeclared() {
    return new ArchCondition<>("cross into another context only where declared") {
      @Override
      public void check(final JavaClass source, final ConditionEvents events) {
        for (final Dependency dependency : source.getDirectDependenciesFromSelf()) {
          final JavaClass target = dependency.getTargetClass();
          if (!CONTEXTS.allowsCrossing(source.getPackageName(), target.getPackageName())) {
            events.add(SimpleConditionEvent.violated(source, "%s depends on %s, crossing from %s into %s".formatted(
                source.getFullName(),
                target.getFullName(),
                CONTEXTS.contextOf(source.getPackageName()).orElseThrow().name(),
                CONTEXTS.contextOf(target.getPackageName()).orElseThrow().name())));
          }
        }
      }
    };
  }
}
