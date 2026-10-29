package com.example.starter.architecture;

import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

@AnalyzeClasses(packages = "com.example.starter", importOptions = ImportOption.DoNotIncludeTests.class)
class LayerDependencyRulesTest {

  @ArchTest
  static final ArchRule cleanArchitectureLayers = layeredArchitecture()
      .consideringOnlyDependenciesInLayers()
      .layer("Domain").definedBy("..domain..")
      .layer("Application").definedBy("..application..")
      .layer("Infrastructure").definedBy("..infrastructure..")
      .layer("Presentation").definedBy("..presentation..")
      .whereLayer("Domain").mayNotAccessAnyLayer()
      .whereLayer("Application").mayOnlyAccessLayers("Domain")
      .whereLayer("Infrastructure").mayOnlyAccessLayers("Domain", "Application", "Presentation")
      .whereLayer("Presentation").mayOnlyAccessLayers("Domain", "Application");
}
