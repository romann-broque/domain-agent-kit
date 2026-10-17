# Starter kit

A small Spring Boot service laid out the way the workflow in `../repo/` expects:
screaming architecture (one top-level package per bounded context), clean layers
inside each context, and three kinds of tests that keep it that way.

It ships with two tiny contexts so every convention has a working example:

- **catalog** — add a product (name, price).
- **ordering** — place an order of catalog products. It checks that the products exist
  through an **anti-corruption layer**, the only class allowed to reach into another context.

Copy the shape, never the semantics: delete `catalog` and `ordering` once your own
first context exists.

## Run it

Requires Java 21.

```bash
./gradlew build          # compile, architecture rules, behaviours, unit tests, coverage
./gradlew bootRun        # H2 in memory on http://localhost:8080
SPRING_PROFILES_ACTIVE=postgres ./gradlew bootRun   # PostgreSQL, see application-postgres.yml
```

```bash
curl -s -XPOST localhost:8080/api/products -H 'Content-Type: application/json' \
  -d '{"name":"Desk lamp","price":24.90}'
curl -s -XPOST localhost:8080/api/orders -H 'Content-Type: application/json' \
  -d '{"lines":[{"productId":"<id from above>","quantity":2}]}'
```

Enable the commit-message hook (Conventional Commits) once per clone:

```bash
git config core.hooksPath .githooks
```

## Layout

```
src/main/java/com/example/starter/
├── core/        technical plumbing shared by every context (errors, events, API envelope)
├── shared/      shared kernel: types two contexts agree on (empty until one exists)
├── catalog/
│   ├── domain/          models/{aggregates,valueobjects}, events, exceptions; no framework
│   ├── application/     usecase, command, results, ports, exceptions
│   ├── infrastructure/  persistence/{entities,repositories,mappers,adapters}
│   └── presentation/    controller, dto/{request,response}, mapper
└── ordering/    same layers, plus infrastructure/acl/ (asks catalog whether a product exists)
src/main/resources/db/changelog/<context>/   Liquibase, one folder per context
specs/NNN-name/{spec,tasks}.md               what each use case was asked to do
```

## Conventions

| Building block | Rule | Example |
|---|---|---|
| Aggregate | Class in `domain/models/aggregates`, equal by identity, guards its invariants | `Product`, `Order` |
| Value object | `record` in `domain/models/valueobjects`, `require*` guards in the compact constructor | `Price`, `Quantity` |
| Domain event | `record` in `domain/events`, past tense, no `Event` suffix | `ProductAdded`, `OrderPlaced` |
| Use case | `{Verb}{Noun}UseCase`, `@Service @Transactional`, one `execute(Command)` returning a `Result` | `AddProductUseCase` |
| Port | One-method `@FunctionalInterface` in `application/ports`: `Retriever`, `RetrieverBy{X}`, `Saver`, `Updater`, `Checker` | `ProductRetrieverByName` |
| Adapter | `{Aggregate}Adapter` in `infrastructure/persistence/adapters`, implements every port of its aggregate | `ProductAdapter` |
| ACL | `{Port}Acl` in `infrastructure/acl`, implements a local port by calling another context's application layer | `OrderedProductCheckerAcl` |
| Mapper | One per use case in `presentation/mapper`; one per aggregate in `persistence/mappers` | `AddProductMapper`, `ProductEntityMapper` |

Domain errors extend `core.domain.exceptions.DomainException` and come back as `400` with
`{"data":null,"error":"<message>"}`.

## Tests

| Folder | What it guards |
|---|---|
| `src/test/java/.../architecture/` | ArchUnit: layer direction, naming, annotations, package structure, context isolation |
| `src/test/resources/behaviors/<context>/<use_case>.feature` | One Cucumber feature per use case, transcribed from the spec's scenarios, opening with `# Covers: USn, FR-NNN` |
| `src/test/java/.../behaviors/<context>/` | One runner per feature (`runners/`) and its steps (`steps/<use_case>/`); Mockito ports, no Spring |
| `src/test/java/.../fixture/<context>/` | `*DataSet` classes; [java-fixture-generator](https://github.com/romann-broque/java-fixture-generator) generates the matching `*Fixture` builders |
| `src/test/java/.../<context>/domain/...` | One `CreationTest` per model: named valid and invalid cases |
| `StarterApplicationSmokeTest` | The context starts, Liquibase runs on H2, both endpoints answer |

Behaviour reports land in `build/reports/behaviors/<context>/<use-case>.html`.

## Add a context

1. Create `com.example.starter.<context>` with the four layers above.
2. Declare it in `architecture/BoundedContextIsolationRulesTest` (an undeclared top-level
   package fails the build), with a `mayCross(...)` line for each ACL it needs.
3. Add `src/main/resources/db/changelog/<context>/` and an `includeAll` for it in
   `db.changelog-master.yaml`.

## Drive it with the workflow

This folder is a bare project. To work on it with the agentic workflow, copy
`../repo/` on top of your copy of it (see the root README), then start at
`domain-challenge` with your first ticket.

## Supply chain

Every resolved version is locked (`gradle.lockfile`) and every artifact checksum is
verified (`gradle/verification-metadata.xml`). After adding or bumping a dependency:

```bash
./gradlew dependencies --write-locks
./gradlew --write-verification-metadata sha256 help
```
