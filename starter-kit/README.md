# Starter kit

A small Spring Boot service laid out the way the workflow in `../repo/` expects:
screaming architecture (one top-level package per bounded context), clean layers
inside each context, and three kinds of tests that keep it that way.

## Run it

Requires Java 21.

```bash
./gradlew build          # compile, architecture rules, behaviours, unit tests, coverage
./gradlew bootRun        # H2 in memory on http://localhost:8080
SPRING_PROFILES_ACTIVE=postgres ./gradlew bootRun   # PostgreSQL, see application-postgres.yml
```

Enable the commit-message hook once per clone:

```bash
git config core.hooksPath .githooks
```

## Layout

```
src/main/java/com/example/starter/
├── core/        technical plumbing shared by every context (errors, events, API envelope)
├── shared/      shared kernel: types two contexts agree on (empty until one exists)
└── <context>/   one package per bounded context
    ├── domain/          aggregates, value objects, events, exceptions; no framework
    ├── application/     use cases, commands, results, ports, exceptions
    ├── infrastructure/  persistence adapters, anti-corruption layers
    └── presentation/    controllers, DTOs, mappers
```

## Tests

| Folder (`src/test/java/com/example/starter/`) | What it guards |
|---|---|
| `architecture/` | ArchUnit rules: layer direction, naming, annotations, package structure, context isolation |
| `testutils/templates/CreationTest.java` | Base class for "this model can / cannot be built" unit tests |

ArchUnit is configured with `archRule.failOnEmptyShould=false`
(`src/test/resources/archunit.properties`) so rules about layers that a context
does not have yet do not fail.

## Supply chain

Every resolved version is locked (`gradle.lockfile`) and every artifact checksum is
verified (`gradle/verification-metadata.xml`). After adding or bumping a dependency:

```bash
./gradlew dependencies --write-locks
./gradlew --write-verification-metadata sha256 help
```
