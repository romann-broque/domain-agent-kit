package com.example.starter.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

@AnalyzeClasses(packages = "com.example.starter", importOptions = ImportOption.DoNotIncludeTests.class)
class AnnotationUsageRulesTest {

  @ArchTest
  static final ArchRule controllersAreAnnotatedWithRestController = classes()
      .that().resideInAPackage("..presentation.controller..")
      .and().haveSimpleNameEndingWith("Controller")
      .should().beAnnotatedWith("org.springframework.web.bind.annotation.RestController")
      .because("Controllers expose REST endpoints");

  @ArchTest
  static final ArchRule useCasesAreAnnotatedWithService = classes()
      .that().resideInAPackage("..application.usecase..")
      .and().areNotInterfaces()
      .should().beAnnotatedWith("org.springframework.stereotype.Service")
      .because("Use cases are Spring-managed services");

  @ArchTest
  static final ArchRule useCasesAreTransactional = classes()
      .that().resideInAPackage("..application.usecase..")
      .and().areNotInterfaces()
      .should().beAnnotatedWith("org.springframework.transaction.annotation.Transactional")
      .because("A use case is one unit of work");

  @ArchTest
  static final ArchRule adaptersAreAnnotatedWithComponent = classes()
      .that().resideInAPackage("..infrastructure..adapters..")
      .and().haveSimpleNameEndingWith("Adapter")
      .and().areNotInterfaces()
      .should().beAnnotatedWith("org.springframework.stereotype.Component")
      .orShould().beAnnotatedWith("org.springframework.stereotype.Service")
      .because("Adapters are Spring-managed components");

  @ArchTest
  static final ArchRule aclsAreAnnotatedWithComponent = classes()
      .that().resideInAPackage("..infrastructure.acl..")
      .and().haveSimpleNameEndingWith("Acl")
      .and().areNotInterfaces()
      .should().beAnnotatedWith("org.springframework.stereotype.Component")
      .because("Anti-corruption layers are Spring-managed components");

  @ArchTest
  static final ArchRule portsHaveNoSpringAnnotations = classes()
      .that().resideInAPackage("..application.ports..")
      .and().areInterfaces()
      .should().notBeAnnotatedWith("org.springframework.stereotype.Service")
      .andShould().notBeAnnotatedWith("org.springframework.stereotype.Component")
      .andShould().notBeAnnotatedWith("org.springframework.stereotype.Repository")
      .because("Ports are pure interfaces");

  @ArchTest
  static final ArchRule domainModelsHaveNoSpringAnnotations = classes()
      .that().resideInAPackage("..domain.models..")
      .should().notBeAnnotatedWith("org.springframework.stereotype.Component")
      .andShould().notBeAnnotatedWith("org.springframework.stereotype.Service")
      .andShould().notBeAnnotatedWith("org.springframework.context.annotation.Configuration")
      .because("Domain models are framework-independent");

  @ArchTest
  static final ArchRule domainModelsHaveNoJpaAnnotations = classes()
      .that().resideInAPackage("..domain.models..")
      .should().notBeAnnotatedWith("jakarta.persistence.Entity")
      .andShould().notBeAnnotatedWith("jakarta.persistence.Table")
      .andShould().notBeAnnotatedWith("jakarta.persistence.Embeddable")
      .because("Domain models are not mapped to tables; persistence entities are");

  @ArchTest
  static final ArchRule controllerMethodsHaveRequestMappingAnnotations = methods()
      .that().areDeclaredInClassesThat().resideInAPackage("..presentation.controller..")
      .and().arePublic()
      .and().areDeclaredInClassesThat().haveSimpleNameEndingWith("Controller")
      .and().areNotDeclaredIn(Object.class)
      .should().beAnnotatedWith("org.springframework.web.bind.annotation.GetMapping")
      .orShould().beAnnotatedWith("org.springframework.web.bind.annotation.PostMapping")
      .orShould().beAnnotatedWith("org.springframework.web.bind.annotation.PutMapping")
      .orShould().beAnnotatedWith("org.springframework.web.bind.annotation.PatchMapping")
      .orShould().beAnnotatedWith("org.springframework.web.bind.annotation.DeleteMapping")
      .orShould().beAnnotatedWith("org.springframework.web.bind.annotation.RequestMapping")
      .because("Every public controller method is an HTTP endpoint");

  @ArchTest
  static final ArchRule commandsHaveNoSpringAnnotations = classes()
      .that().resideInAPackage("..application.command..")
      .should().notBeAnnotatedWith("org.springframework.stereotype.Component")
      .andShould().notBeAnnotatedWith("org.springframework.stereotype.Service")
      .because("Commands are plain values");

  @ArchTest
  static final ArchRule dtosHaveNoSpringAnnotations = classes()
      .that().resideInAPackage("..presentation.dto..")
      .should().notBeAnnotatedWith("org.springframework.stereotype.Component")
      .andShould().notBeAnnotatedWith("org.springframework.stereotype.Service")
      .because("DTOs are plain values");

  @ArchTest
  static final ArchRule exceptionsHaveNoSpringAnnotations = classes()
      .that().resideInAPackage("..exceptions..")
      .should().notBeAnnotatedWith("org.springframework.stereotype.Component")
      .andShould().notBeAnnotatedWith("org.springframework.stereotype.Service")
      .because("Exceptions are not managed by Spring");
}
