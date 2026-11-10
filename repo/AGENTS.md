# AGENTS.md

Authoritative reference for architecture, naming and conventions.
The constitution (`.specify/memory/constitution.md`) is the law; this file is the
detail. Where they disagree, the constitution wins and this file is a defect.

Every example below comes from the starter-kit this workflow ships with: two tiny
bounded contexts, `catalog` (add a product) and `ordering` (place an order of catalog
products). Replace them with your own as soon as your first context exists. Copy the
*shape* of the examples; never their *semantics*.

## Project Overview

Spring Boot service. Java 21, Spring Boot 4.1, Gradle with the Kotlin DSL and a version
catalog, Lombok, Liquibase, H2 by default and PostgreSQL under the `postgres` profile.
Base package `com.example.starter` — rename it to your own when you adopt the kit.

## Architecture

Clean architecture with DDD tactical patterns. Each bounded context is a top-level
package with four layers:

```
com.example.starter/
├── core/                                  cross-cutting technical code, same four layers
│   ├── application/ports/                 EventEmitter
│   ├── domain/exceptions/                 DomainException
│   ├── infrastructure/events/             SpringEventEmitter
│   ├── infrastructure/handlers/           GlobalExceptionHandler
│   └── presentation/dtos/responses/       ApiResponse
├── shared/                                shared kernel — empty until two contexts agree on a type
└── {context}/
    ├── domain/
    │   ├── models/aggregates/
    │   ├── models/entities/
    │   ├── models/valueobjects/
    │   ├── events/                        domain events, records
    │   └── exceptions/
    ├── application/
    │   ├── usecase/
    │   ├── command/
    │   ├── results/
    │   ├── ports/
    │   └── exceptions/
    ├── infrastructure/persistence/
    │   ├── adapters/
    │   ├── entities/
    │   ├── mappers/
    │   └── repositories/
    ├── infrastructure/acl/                the only package crossing to another context
    └── presentation/
        ├── controller/
        ├── dto/request/
        ├── dto/response/
        └── mapper/
```

### Layer dependency rules (enforced by ArchUnit)

| Layer | May access |
|---|---|
| `domain` | nothing |
| `application` | `domain` |
| `presentation` | `domain`, `application` |
| `infrastructure` | `domain`, `application`, `presentation` |

`domain` must not import `org.springframework..` or `jakarta..`.
`application` must not import `org.springframework.web..` or `jakarta.persistence..`.
Controllers never touch `domain.models` directly. No package cycles between slices.

Between contexts: only `{context}/infrastructure/acl/` may import another context, and
only where `BoundedContextIsolationRulesTest` declares the crossing. See
*Anti-corruption layer* below.

Enforced by `src/test/java/com/example/starter/architecture/`:
`LayerDependencyRulesTest`, `NamingConventionRulesTest`, `AnnotationUsageRulesTest`,
`PackageStructureRulesTest`, `BoundedContextIsolationRulesTest` (built with the
`BoundedContexts` helper next to it).

### Screaming architecture

Top-level packages are bounded contexts — business capabilities. Listing that
directory must tell a reader what the system does. `core` is reserved for
cross-cutting technical code; `shared` is the declared shared kernel.

**This applies to `domain` and `application`.** `infrastructure` and `presentation`
exist to speak the language of a technology: `*Adapter`, `*Entity`, `*EntityMapper`,
`*Controller` and `*Dto` are the *correct* names there, and the naming table below
mandates them. A technical name is a defect only where a business concept was
expected.

Inside `domain` and `application`, names must say what the code *means*, not what it
technically *is*. `OrderManager`, `OrderService` and a `utils` package are the usual
symptoms: each one marks a business notion that has not been named. A class you want
to call `OrderService` is a use case named after the action it performs —
`PlaceOrderUseCase`.

**Treat these as examples, not as a checklist.** No list of forbidden suffixes
captures the rule, and no ArchUnit test enforces it — deliberately. `shared` is a
dumping ground most of the time and a legitimate DDD shared kernel the rest of the
time (declared in `docs/domain/context-map.md`), and a test cannot tell them apart.
This is a judgement carried by whoever designs, implements or reviews the code.

The ban concerns the class-name *suffix*, never the `@Service` *annotation*, which use
cases still carry.

## Naming Conventions

| Kind | Pattern | Package | Example |
|---|---|---|---|
| Aggregate root | `{Noun}` (a `class`, equal by identity) | `domain.models.aggregates` | `Product`, `Order` |
| Entity | `{Noun}` | `domain.models.entities` | — |
| Value object | `{Noun}` (a `record`) | `domain.models.valueobjects` | `Price`, `Quantity` |
| Domain exception | `{Aggregate}Exception` extends `DomainException` | `domain.exceptions` | `ProductException` |
| Domain event | `{Fact}`, past tense, no `Event` suffix (a `record`) | `domain.events` | `ProductAdded`, `OrderPlaced` |
| Use case | `{Verb}{Noun}UseCase` | `application.usecase` | `PlaceOrderUseCase` |
| Command | `{Verb}{Noun}Command` (a `record`) | `application.command` | `PlaceOrderCommand` |
| Use case result | `{Verb}{Noun}Result` (a `record`) | `application.results` | `PlaceOrderResult` |
| Use case refusal | named after the fact refused, extends the context's domain exception | `application.exceptions` | `UnknownProductException` |
| Port | `{Aggregate}{Action}` — `@FunctionalInterface`, one method (see *Port names*) | `application.ports` | `ProductRetrieverByName` |
| Adapter | `{Aggregate}Adapter` — `@Component`, implements every port of the aggregate | `infrastructure.persistence.adapters` | `ProductAdapter` |
| Anti-corruption layer | `{Port}Acl` — `@Component`, implements one local port by calling another context | `infrastructure.acl` | `OrderedProductCheckerAcl` |
| JPA entity | `{Noun}Entity` | `infrastructure.persistence.entities` | `ProductEntity` |
| JPA repository | `{Noun}JpaRepository` | `infrastructure.persistence.repositories` | `ProductJpaRepository` |
| Persistence mapper | `{Aggregate}EntityMapper` — `toEntity` / `toDomain` | `infrastructure.persistence.mappers` | `ProductEntityMapper` |
| Controller | `{Aggregate}Controller` — `@RestController` | `presentation.controller` | `ProductController` |
| Presentation mapper | `{Verb}{Noun}Mapper` — one per use case, holding `toCommand` (request → command) and `toResponse` (result → response DTO) | `presentation.mapper` | `AddProductMapper` |
| Request DTO | `{Verb}{Noun}RequestDto` (a `record`) | `presentation.dto.request` | `AddProductRequestDto` |
| Response DTO | `{Verb}{Noun}ResponseDto` (a `record`) | `presentation.dto.response` | `PlaceOrderResponseDto` |

`{Verb}{Noun}` is the use case root without its suffix: `PlaceOrderUseCase` takes a
`PlaceOrderCommand` and returns a `PlaceOrderResult`. The suffixes are enforced by
`NamingConventionRulesTest`.

### Port names

A port name says what it does to the aggregate, in the vocabulary of the domain
(screaming architecture). The action is one of a closed set:

| Port | Method | Does |
|---|---|---|
| `{Aggregate}Retriever` | `retrieve` | reads one aggregate by its identity — `ProductRetriever` |
| `{Aggregate}RetrieverBy{Criterion}` | `retrieveBy{Criterion}` | reads by a criterion — `ProductRetrieverByName` |
| `{Aggregate}Saver` | `save` | inserts a new aggregate — `ProductSaver`, `OrderSaver` |
| `{Aggregate}Updater` | `update` | writes back an aggregate already held |
| `{Aggregate}Checker` | `exists` | tells whether an aggregate exists, without reading it — `OrderedProductChecker` |

No `Searcher`, `Finder` or `Lookup`: they say *how*, the port names *what*. A port
reading one aggregate returns an `Optional`. A port returning several returns a `List`
when their order means something (stated in the method contract), a `Set` otherwise.

### Domain events

A domain event is a `record` in `{context}/domain/events/`, named after the fact it
records, with no `Event` suffix — `ProductAdded`, `OrderPlaced`.

A use case hands an event to whoever consumes it through the single port
`core.application.ports.EventEmitter`, `void emit(Object event)`. No context declares
an emitting port of its own and no context writes an emitting adapter: the single
implementation is `core.infrastructure.events.SpringEventEmitter`, which delegates to
Spring's `ApplicationEventPublisher`, synchronously, inside the use case's transaction.
The consuming side is added by the first ticket that consumes an event. Behaviour steps
mock the `EventEmitter` and capture what it was handed.

### Aggregates are changed in place

An aggregate root is a `class`, equal by identity, whose mutators change it in place —
`Product.changePrice`. A mutator never returns a modified copy: an aggregate has one
life, and a copy would be a second aggregate with the same identity. Its value objects
stay immutable `record`s, each storing one canonical form of its value — `ProductName`
trims, a decimal amount strips its trailing zeros — so that equality is by meaning, not
by representation.

### Constructor guards

A compact constructor delegates each refusal to a `private static void require…`
method that names the rule it enforces — `requireNotBlank`, `requirePositive`,
`requireAtMostMaxLength`.

**A guard name never carries a literal value.** The bound lives in a named constant and
the guard names the rule: `requireAtMostMaxLength` with `MAX_LENGTH` (`ProductName`),
not `requireAtMost100Characters`. Changing the bound then touches one line.

### Technical limits belong to the request

A limit that comes from transport or storage is not a rule of the domain. Trimming the
spaces around an input, refusing a blank text because a column is `NOT NULL`, a column
size: these are held by the presentation request DTO — Bean Validation constraints such
as `@NotBlank` or `@Size(max = …)` — and refused there as a 400. Below the request, the
command and the domain hold the value as given.

A limit the domain states stays in the domain, wherever it was decided: a product name
of at most 100 characters is in the acceptance criteria of `specs/001-add-a-product`,
so it stays in `ProductName`. The test is the source: a limit nobody would state
without knowing the column is technical.

No ArchUnit rule can tell a technical limit from a domain one; `code-reviewer` checks it.

## Writing a Use Case

- Named `{Verb}{Noun}UseCase` — `AddProductUseCase`. The verb and noun carry the
  business action; the suffix names the role.
- Annotated `@Service @Transactional`, dependencies injected through
  `@RequiredArgsConstructor`. The use case is the transaction boundary.
- Single public method `execute`, taking a `{Verb}{Noun}Command` and returning a
  `{Verb}{Noun}Result`. Errors that occur before the return are thrown.
- Depends only on ports, never on adapters or repositories.
- A refusal is an exception named after the fact refused —
  `ProductAlreadyExistsException`, `UnknownProductException` — extending the context's
  domain exception, so that `GlobalExceptionHandler` maps it to a 400.

A command carries what its caller hands over, in the caller's own terms: a text, a
number, an identifier (`AddProductCommand` carries a `String` and a `BigDecimal`). It
may carry a value of the `shared` kernel, since a `shared` type crosses every context
untranslated. A command never carries a type of another context. The use case builds
the value objects, which guard themselves.

## API Routing

`@RequestMapping("/api/{plural-aggregate}")` on the controller — `/api/products`,
`/api/orders`. Sub-resources are nested: `/api/orders/{orderId}/lines`. Controllers go
through the use case's mapper and must not leak domain types.

A controller carries no `@ExceptionHandler`: status mapping lives in
`GlobalExceptionHandler`, and every response is wrapped in `ApiResponse`
(`{"data": …, "error": …}`).

## Anti-corruption layer

A context that needs what another context knows declares a port in its own
`application/ports/`, in its own types, and implements it with a `{Port}Acl` in its
`infrastructure/acl/`. In the starter-kit, `ordering` asks whether a product exists
through its own `OrderedProductChecker` (`boolean exists(UUID productId)`), and
`OrderedProductCheckerAcl` answers it by calling `catalog`'s `ProductRetriever`.

The ACL translates in both directions: it builds the upstream's input from its own
types, reads what comes back, and returns its own types — never an upstream type. Only
`shared` and `core` types cross untranslated. When the upstream has no code yet, a
stand-in ACL answers in its place, under the name the real one will take.

Every allowed crossing is declared in `BoundedContextIsolationRulesTest`, one
`mayCross(...)` line per source package and target layer. An undeclared top-level
package fails the build.

The detailed rules and the code shape live in
`.opencode/skills/craftsman/references/anti-corruption-layer.md`. A new ACL rule is
added there, not here.

## Collections

Unmodifiable by default — `Collectors.toUnmodifiableSet()`, `toUnmodifiableList()`,
`Stream.toList()`, `List.copyOf(...)` — in every layer, unless the receiver genuinely
has to mutate the collection.

## Build & Run

```bash
./gradlew build                 # compile + architecture + behaviours + unit tests + JaCoCo
./gradlew test                  # unit + ArchUnit + Cucumber
./gradlew test --tests 'com.example.starter.behaviors.*'      # behaviour tests only
./gradlew test --tests 'com.example.starter.architecture.*'   # ArchUnit only
./gradlew bootRun               # H2 in memory
SPRING_PROFILES_ACTIVE=postgres ./gradlew bootRun              # PostgreSQL
```

All dependency versions live in `gradle/libs.versions.toml`. Never write a version
string in `build.gradle.kts`.

The supply chain is locked: `dependencyLocking` with a committed `gradle.lockfile` and
`settings-gradle.lockfile`, and checksums in `gradle/verification-metadata.xml`. Any
dependency change regenerates them:

```bash
./gradlew dependencies --write-locks
./gradlew --write-verification-metadata sha256 help
```

### Database changelogs

Liquibase changelogs are written in **YAML**, one folder per bounded context that owns
tables: `src/main/resources/db/changelog/{context}/{NNN}-{action}.yaml`, numbered from
`001` within each folder. One changeset per file, its id `{context}-{NNN}-{action}`
(`catalog-001-create-product`). `db/changelog/db.changelog-master.yaml` is the single
master and holds one `includeAll` per context folder. A changeset that has run is never
edited.

## Testing

**Test-first is mandatory** — `.specify/memory/constitution.md` § *II. Test-First Delivery*.
A use case gets a Cucumber behaviour test before its implementation; an aggregate,
entity, value object or guarding command gets a unit test before its implementation.
The test must be observed failing first.

`infrastructure` and `presentation` (adapters, JPA entities, repositories, mappers,
controllers, DTOs, changelogs) get **no test by default**: they translate, they do not
decide. A uniqueness or existence rule belongs to the use case, checked through a port
and covered by its behaviour test. Two exceptions: an ACL, whose translation is a
contract between contexts (`OrderedProductCheckerAclTest`), and cross-cutting technical
logic in `core`. `StarterApplicationSmokeTest` checks that the application starts,
Liquibase runs on H2 and the endpoints answer.

### Layout

```
src/test/java/com/example/starter/
├── architecture/                          ArchUnit rules (@AnalyzeClasses + @ArchTest fields)
├── behaviors/{context}/runners/           one runner per feature
├── behaviors/{context}/steps/{use_case}/  step definitions
├── fixture/{context}/...                  *DataSet classes
├── {context}/                             unit tests
└── testutils/templates/CreationTest.java
src/test/resources/behaviors/{context}/{use_case}.feature
```

There is no separate source set for behaviours; everything runs under `./gradlew test`.

### Cucumber conventions

- The feature file opens with its `# Covers: US1, FR-001, …` line, then the feature, then
  `As a user / I want / So that`. The actor is `user` unless the spec names a real role.
  Never invent one.
- Titles are plain and short. The feature is the use case as an action (`Add a product`).
  A scenario title is two to eight words saying what makes the case different
  (`❌ Duplicate name`). Steps read `the user …`, never `I …`.
- Scenarios grouped under `Rule:`. A `Background:` shared by every rule sits at feature
  level; one specific to a rule sits inside it.
- Scenario titles prefixed ✅ (success) or ❌ (failure).
- One feature per use case. A story whose scenarios exercise that use case goes into its
  feature as its own `Rule:`, not into a separate feature file.
- One runner per feature (JUnit Platform Suite), glue scoped to that feature's step
  package, HTML report at `build/reports/behaviors/{context}/{use-case}.html` —
  `AddProductBehaviorTest`.
- Steps instantiate the use case directly with Mockito-mocked ports. **No Spring
  context, no `cucumber-spring`.**
- AssertJ assertions on the returned result and on mock interactions only. A step may
  assert that a refusal occurred (the caught exception is not null), so that a refusal
  cannot pass on a stub doing nothing; it asserts the message only when the spec fixes
  its wording.
- Scenarios, steps and refusal messages speak the domain's meaning to the user — *the
  product is unknown* — never the bounded context or the port that answers it.
- Test data comes from generated fixtures.

### Fixtures

Fixtures come from [java-fixture-generator](https://github.com/romann-broque/java-fixture-generator)
(Maven Central, `fixture-annotations` + `fixture-processor`). Hand-write a `*DataSet`
class annotated
`@GenerateFixture(entityClass = X.class, dataModelClass = XDataSet.DataModel.class)`
with a nested `DataModel` of public fields carrying defaults and a
`static X build(DataModel model)` — `PriceDataSet`, `ProductDataSet`. The annotation
processor generates a `{X}Fixture` builder with `defaultFixture()`, `with{Field}(v)`,
`without{Field}()` and `build()`.

### Unit tests

Every model of the `domain` and `application` layers that guards something — aggregate
roots, entities, value objects, commands — extends
`CreationTest<ENTITY, FIXTURE, EXCEPTION>` and supplies `validCreationProvider()` /
`invalidCreationProvider()` — `PriceTest`, `OrderTest`.

Non-creation behaviour (an aggregate mutator such as `Product.changePrice`) gets plain
JUnit 5 + AssertJ tests **in addition to** the `CreationTest`, not instead of it.

A `CreationTest` generates its cases from a `Stream<Arguments>`, so the cases are
anonymous in the report. **Name each one with a private factory method** rather than a
comment — `aZeroPrice()`, `aPriceWithThreeDecimals()`. The name is checked by the
compiler, reads at the call site, and gives a failing case an identifiable frame. A test
name states the fact it pins; where an assertion needs a reason, that reason goes in
AssertJ's `.as("…")`, where it appears in the failure output.

## Code Style

2-space indent, 120 columns, LF, UTF-8, final newline (`.editorconfig`).
All method and constructor parameters declared `final`, except in Lombok-generated
constructors. There is no Checkstyle or Spotless; this is reviewed, not linted.

### No comments

**Code carries no comments** — `.specify/memory/constitution.md` § *Additional Constraints*.
A comment explaining *what* code does is a missing name. The fix is the name.

| Instead of a comment | Write |
|---|---|
| a commented literal in a provider | a named private factory method — `aZeroPrice()` |
| a line explaining what a test checks | a test name stating the fact |
| a note on why an assertion matters | an AssertJ `.as("…")` description, which appears in the failure output |
| a `// Given` / `// When` / `// Then` marker | a blank line |
| a note on why a decision was taken | the decision record — `research.md`, or an open point |

**The list of authorised exceptions is closed.** It is this list, and nothing else:

1. **`# Covers: USn, FR-NNN`** at the top of a `.feature` file, and indented right above
   a `Rule:` whose scenarios cover a narrower set than the header. Machine-read by
   `.specify/scripts/bash/verify-traceability.sh`, which counts a scenario under the
   `# Covers:` of its rule, or of the header when its rule has none.
2. **`// Covers: USn, FR-NNN`** at the top of a provider method of a `CreationTest`
   subclass — one line per method, never per entry. Same traceability anchor, for the
   requirements whose scenarios are transcribed into creation tests instead of Gherkin.

   Both forms follow the same rule over time. US and FR numbers restart with each spec,
   so a line may be qualified by its spec number from the start, as `PriceTest` does
   with `// Covers: 001: US1, FR-002`, and **must be once a second spec touches it —
   every group qualified, none overwritten**: `// Covers: 001: US1, FR-002; 004: US2, FR-001`. An
   unqualified line rewritten by a later spec silently loses the earlier spec's coverage.
3. **Javadoc, on a type reached as a tool** — test infrastructure (`CreationTest`),
   `infrastructure`, a `package-info.java`, and the public surface of an API.
   **Forbidden in `domain` and `application`**, whose names are the documentation. Every
   Javadoc block must be **validated explicitly** by a human when introduced; an
   unvalidated one is a violation like any other comment.
4. **A generated file's own header.** Not written by hand, not reviewed, not committed.

Anything outside this list is replaced by a name, not justified in review.

## Commits and branches

Commits follow Conventional Commits, checked by `.githooks/commit-msg` — enable it once
per clone with `git config core.hooksPath .githooks`. If releases are derived from
commit messages, a wrong type is a wrong version, so the rule is not cosmetic.

Branches: `{type}/PROJ-{number}-{snake_case}` — `feat/PROJ-123-place_an_order`.

## Agentic Workflow

Feature work goes from a ticket to reviewed code through this chain. Nothing
advances on its own: each arrow is a human deciding to type the next command.
`docs/WORKFLOW.md` is the step-by-step version of this section, written for humans.

| # | Step | What is approved at the end |
|---|---|---|
| 0 | `/speckit.constitution` *(once per project)* | the principles every later step checks against |
| 1 | skill `domain-challenge` | verdict + blocking questions |
| 1a | skill `ticket-writer` *(on `TOO LARGE`)* | the split, as sibling tickets |
| 1b | skill `domain-ingest` *(on `DOMAIN GAP`)* | what was written to `docs/domain/`, what was set aside |
| 2 | `/speckit.specify` | are the scenarios faithful to the ticket? |
| 3 | `/speckit.clarify` *(if needed)* | the answers encoded in the spec |
| 4 | `/speckit.plan` | Constitution Check |
| 4a | `/speckit.checklist` *(optional)* | requirement-quality checklist |
| 5 | `/speckit.tasks` | tasks tagged `[USn]`, each story gated |
| 5a | `/speckit.analyze` | cross-artefact consistency |
| 5b | `/speckit.taskstoissues` *(optional, on explicit request)* | issues created from the tasks |
| 5c | `/workflow.verify` | mechanical traceability, ticket → tasks |
| 6 | `/speckit.implement` | TDD loop: `test-first` → `craftsman` |
| 7 | `/workflow.verify` | the evidence holds; tests came first |
| 7a | skill `code-reviewer` | conventions, layering, naming |
| 7b | `/speckit.converge` | does the code do what the spec said? |
| 8 | skill `review-triage` *(on human PR comments)* | per-comment class and route |

Domain knowledge enters through `domain-ingest` (1b), outside the main line — typically
triggered by a `DOMAIN GAP` verdict at step 1.

Tickets are written by `ticket-writer` (1a), also outside the main line. It branches
off step 1 on a `TOO LARGE` verdict — the split is a human's decision on the card, not
something `domain-challenge` drafts for itself — and it writes the bodies of the tickets
`domain-ingest` names under *Set aside*. Its output lands in `tickets/<slug>.md`, which
is git-ignored: the issue tracker is the record and that file is a paste buffer. Each
ticket then enters the chain at step 1 on its own.

Human review comments on a pull request re-enter the chain through `review-triage`. It
classifies each unresolved thread — refactor, behaviour, spec change, domain, question,
workflow defect, contradiction, out of scope — presents a review card, then hands each
item to the step that owns it: a spec change goes back through `/speckit.clarify`,
`test-first` and `craftsman`, a domain statement through `domain-ingest`. One class per
commit; `verify-review-commits.sh`, run by `/workflow.verify`, refuses a `refactor:`
that edits a scenario or a spec, an implemented requirement change with no test commit
before it, and a lost `Covers:` group. Bot reviewers go to the global skill
`copilot-review-processor`.

Artefacts land in `specs/{NNN}-{short-name}/` and are committed. Do not confuse this
with `docs/superpowers/`, which holds session design docs and is git-ignored.

### Review cards

Every step ends with a short card, not with the generated document:

```
Decided     what was settled
Assumed     ← this is what must be read
Uncertain   what remains open
→ Approve / Amend / Reject
```

Approving a hundred and fifty lines of generated markdown is a rubber stamp.
**Drift never hides in what was decided; it hides in what was assumed without
saying so.** The full document stays available — it is simply not what is
submitted for approval.

### Implementation skills, strictly in order

1. `test-first` — transcribes the acceptance scenarios of `spec.md` into a failing
   test, stops at RED, never touches `src/main/java`.
2. `craftsman` — starts only from an observed RED, writes minimal code, stops at GREEN.
3. `code-reviewer` — runs after GREEN, the only step allowed to propose refactoring.

### Traceability

The chain is checkable end to end because three anchors are written down:

- the **verbatim ticket** at the top of `spec.md`, between the `TRACE:BEGIN` and
  `TRACE:END` markers — the only unmodified record of what was asked;
- the **`[USn]` tags** on tasks and the **`FR-NNN`** numbering in the spec;
- the **`# Covers: US1, FR-001`** header opening every feature file, narrowed per
  `Rule:` when needed and qualified by spec number once two specs share a line
  (*No comments*, exceptions 1 and 2).

`/workflow.verify` walks these joins. It reports `DRIFT` when a join is broken and
`INCOMPLETE` when it could not parse something — never a silent pass.

## Key Libraries

Spring Boot 4.1 · Lombok · Liquibase · Hibernate Validator · H2 · PostgreSQL driver ·
JUnit 5 + JUnit Platform Suite · Mockito · AssertJ · Cucumber 8 · ArchUnit 1.5 ·
java-fixture-generator · JaCoCo.

## Known deviations in the starter-kit

Not to be imitated, and not to be fixed as a side effect of an unrelated ticket:

- `Price.requireAtMostTwoDecimals` carries a literal in its name (see *Constructor guards*).
- `Product` and `Order` guard their fields through a generic `require(value, message)`
  helper rather than one named guard per rule.
