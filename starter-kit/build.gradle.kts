import org.springframework.boot.gradle.plugin.SpringBootPlugin

plugins {
  java
  jacoco
  alias(libs.plugins.spring.boot)
}

group = "com.example"
version = "0.1.0"

java {
  toolchain {
    languageVersion = JavaLanguageVersion.of(21)
  }
}

repositories {
  mavenCentral()
}

// Supply chain: every resolved version is locked and every artifact checksum is verified.
// After adding or bumping a dependency, regenerate both files and commit them:
//   ./gradlew dependencies --write-locks
//   ./gradlew --write-verification-metadata sha256 help
dependencyLocking {
  lockAllConfigurations()
}

dependencies {
  val springBootBom = platform(SpringBootPlugin.BOM_COORDINATES)
  implementation(springBootBom)
  annotationProcessor(springBootBom)
  testImplementation(springBootBom)
  testAnnotationProcessor(springBootBom)

  implementation(libs.bundles.spring.boot.app)
  runtimeOnly(libs.h2)
  runtimeOnly(libs.postgresql)

  compileOnly(libs.lombok)
  annotationProcessor(libs.lombok)

  testImplementation(libs.spring.boot.starter.test)
  testImplementation(libs.spring.boot.starter.webmvc.test)
  testImplementation(libs.archunit.junit5)
  testImplementation(libs.bundles.cucumber)
  testImplementation(libs.fixture.annotations)
  testAnnotationProcessor(libs.fixture.processor)
  testCompileOnly(libs.lombok)
  testAnnotationProcessor(libs.lombok)
}

tasks.test {
  useJUnitPlatform()
  finalizedBy(tasks.jacocoTestReport)
}

tasks.jacocoTestReport {
  dependsOn(tasks.test)
  reports {
    xml.required = true
    html.required = true
  }
}
