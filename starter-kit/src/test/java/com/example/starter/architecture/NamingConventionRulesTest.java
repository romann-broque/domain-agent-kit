package com.example.starter.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;

import com.tngtech.archunit.base.DescribedPredicate;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

@AnalyzeClasses(packages = "com.example.starter", importOptions = ImportOption.DoNotIncludeTests.class)
class NamingConventionRulesTest {

  @ArchTest
  static final ArchRule useCasesArePublic = classes()
      .that().resideInAPackage("..application.usecase..")
      .should().bePublic()
      .because("Use cases are the entry points of the application layer");

  @ArchTest
  static final ArchRule useCasesAreSuffixedUseCase = classes()
      .that().resideInAPackage("..application.usecase..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("UseCase")
      .because("A use case is named {Verb}{Noun}UseCase");

  @ArchTest
  static final ArchRule commandsAreSuffixedCommand = classes()
      .that().resideInAPackage("..application.command..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("Command")
      .because("Commands follow the naming convention *Command");

  @ArchTest
  static final ArchRule classesSuffixedCommandResideInCommandPackage = classes()
      .that().haveSimpleNameEndingWith("Command")
      .and().resideInAPackage("..application..")
      .should().resideInAPackage("..application.command..")
      .because("Commands live in the command package");

  @ArchTest
  static final ArchRule resultsAreSuffixedResult = classes()
      .that().resideInAPackage("..application.results..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("Result")
      .because("Results follow the naming convention {UseCase}Result");

  @ArchTest
  static final ArchRule portsAreInterfaces = classes()
      .that().resideInAPackage("..application.ports..")
      .should().beInterfaces()
      .because("Ports are contracts the infrastructure fulfils");

  @ArchTest
  static final ArchRule adaptersAreSuffixedAdapter = classes()
      .that().resideInAPackage("..infrastructure..adapters..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("Adapter")
      .because("Adapters follow the naming convention {Aggregate}Adapter");

  @ArchTest
  static final ArchRule classesSuffixedAdapterResideInAdaptersPackage = classes()
      .that().haveSimpleNameEndingWith("Adapter")
      .should().resideInAPackage("..infrastructure..adapters..")
      .because("Adapters live in the adapters package");

  @ArchTest
  static final ArchRule aclsAreSuffixedAcl = classes()
      .that().resideInAPackage("..infrastructure.acl..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("Acl")
      .because("An anti-corruption layer is named {Port}Acl");

  @ArchTest
  static final ArchRule controllersAreSuffixedController = classes()
      .that().resideInAPackage("..presentation.controller..")
      .should().haveSimpleNameEndingWith("Controller")
      .because("Controllers follow the naming convention *Controller");

  @ArchTest
  static final ArchRule classesSuffixedControllerResideInControllerPackage = classes()
      .that().haveSimpleNameEndingWith("Controller")
      .and().resideInAPackage("..presentation..")
      .should().resideInAPackage("..presentation.controller..")
      .because("Controllers live in the controller package");

  @ArchTest
  static final ArchRule requestDtosAreSuffixedDto = classes()
      .that().resideInAPackage("..presentation.dto.request..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("RequestDto")
      .because("Request DTOs follow the naming convention *RequestDto");

  @ArchTest
  static final ArchRule responseDtosAreSuffixedDto = classes()
      .that().resideInAPackage("..presentation.dto.response..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("ResponseDto")
      .because("Response DTOs follow the naming convention *ResponseDto");

  @ArchTest
  static final ArchRule classesSuffixedRequestDtoResideInRequestPackage = classes()
      .that().haveSimpleNameEndingWith("RequestDto")
      .should().resideInAPackage("..presentation.dto.request..")
      .because("Request DTOs live in the dto.request package");

  @ArchTest
  static final ArchRule classesSuffixedResponseDtoResideInResponsePackage = classes()
      .that().haveSimpleNameEndingWith("ResponseDto")
      .should().resideInAPackage("..presentation.dto.response..")
      .because("Response DTOs live in the dto.response package");

  @ArchTest
  static final ArchRule aggregatesArePublic = classes()
      .that().resideInAPackage("..domain.models.aggregates..")
      .should().bePublic()
      .because("Aggregates are used by the application layer");

  @ArchTest
  static final ArchRule valueObjectsArePublic = classes()
      .that().resideInAPackage("..domain.models.valueobjects..")
      .should().bePublic()
      .because("Value objects are used by the application layer");

  @ArchTest
  static final ArchRule mappersAreSuffixedMapper = classes()
      .that().resideInAnyPackage("..presentation.mapper..", "..persistence.mappers..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("Mapper")
      .because("Mappers follow the naming convention *Mapper");

  @ArchTest
  static final ArchRule classesSuffixedMapperResideInAMapperPackage = classes()
      .that().haveSimpleNameEndingWith("Mapper")
      .should().resideInAnyPackage("..presentation.mapper..", "..persistence.mappers..")
      .because("Mappers live in presentation.mapper or persistence.mappers");

  @ArchTest
  static final ArchRule exceptionsAreSuffixedException = classes()
      .that().resideInAPackage("..exceptions..")
      .and().areTopLevelClasses()
      .should().haveSimpleNameEndingWith("Exception")
      .because("Exceptions follow the naming convention *Exception");

  @ArchTest
  static final ArchRule classesSuffixedExceptionResideInExceptionsPackage = classes()
      .that().haveSimpleNameEndingWith("Exception")
      .should().resideInAPackage("..exceptions..")
      .because("Exceptions live in an exceptions package");

  @ArchTest
  static final ArchRule useCaseExecuteMethodsReturnAResult = methods()
      .that().areDeclaredInClassesThat().resideInAPackage("..application.usecase..")
      .and().arePublic()
      .and().haveName("execute")
      .should().haveRawReturnType(aResultType())
      .because("A use case's execute method returns its own {UseCase}Result");

  private static DescribedPredicate<JavaClass> aResultType() {
    return DescribedPredicate.describe(
        "a dedicated {UseCase}Result type", javaClass -> javaClass.getSimpleName().endsWith("Result"));
  }
}
