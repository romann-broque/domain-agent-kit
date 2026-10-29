package com.example.starter.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

@AnalyzeClasses(packages = "com.example.starter", importOptions = ImportOption.DoNotIncludeTests.class)
class PackageStructureRulesTest {

  @ArchTest
  static final ArchRule domainDoesNotDependOnSpringFramework = noClasses()
      .that().resideInAPackage("..domain..")
      .should().dependOnClassesThat().resideInAnyPackage("org.springframework..")
      .because("The domain layer is framework-independent");

  @ArchTest
  static final ArchRule domainDoesNotDependOnJakarta = noClasses()
      .that().resideInAPackage("..domain..")
      .should().dependOnClassesThat().resideInAnyPackage("jakarta..")
      .because("The domain layer depends on neither persistence nor web frameworks");

  @ArchTest
  static final ArchRule applicationDoesNotDependOnSpringWeb = noClasses()
      .that().resideInAPackage("..application..")
      .should().dependOnClassesThat().resideInAnyPackage("org.springframework.web..")
      .because("The application layer does not know about HTTP");

  @ArchTest
  static final ArchRule applicationDoesNotDependOnJakartaPersistence = noClasses()
      .that().resideInAPackage("..application..")
      .should().dependOnClassesThat().resideInAnyPackage("jakarta.persistence..")
      .because("The application layer does not know about persistence");

  @ArchTest
  static final ArchRule noClassResidesInDefaultPackage = noClasses()
      .should().resideInAPackage("")
      .because("Every class belongs to a package");

  @ArchTest
  static final ArchRule controllersDoNotDependOnDomainModels = noClasses()
      .that().resideInAPackage("..presentation.controller..")
      .should().dependOnClassesThat().resideInAPackage("..domain.models..")
      .because("Controllers reach the domain through use cases, never directly");

  @ArchTest
  static final ArchRule applicationClassesResideInDesignatedPackages = classes()
      .that().resideInAPackage("..application..")
      .should().resideInAnyPackage(
          "..application.usecase..",
          "..application.command..",
          "..application.results..",
          "..application.ports..",
          "..application.exceptions..")
      .because("The application layer holds only use cases, commands, results, ports and exceptions");

  @ArchTest
  static final ArchRule persistenceEntitiesResideInInfrastructurePersistence = classes()
      .that().areAnnotatedWith("jakarta.persistence.Entity")
      .should().resideInAPackage("..infrastructure.persistence.entities..")
      .because("JPA entities are an infrastructure concern");

  @ArchTest
  static final ArchRule packagesAreFreeOfCycles = slices()
      .matching("com.example.starter.(*)..")
      .should()
      .beFreeOfCycles()
      .because("Cyclic dependencies between contexts make the codebase harder to change");
}
