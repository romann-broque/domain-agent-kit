<!--
Sync Impact Report
- Version change: 1.1.0 → 1.2.0
- 1.2.0 (MINOR): Principle II — a `Background:` shared by every rule sits at feature
  level, one specific to a rule inside it (was: "may use a `Background:` inside a `Rule:`").
- 1.1.0 (MINOR): Principle II — an anti-corruption layer is a second exception to "no
  test on infrastructure", alongside cross-cutting technical logic in `core`.
- 1.0.0: ratified from the agentic-setup catalogue; principles I–V, constraints, workflow and governance.
- Templates reviewed: spec-template.md ✅, plan-template.md ✅, tasks-template.md ✅
- Follow-up: set [RATIFICATION_DATE]; replace `com.example.starter` with your base package.
-->

# Project Constitution

## Core Principles

### I. Domain-Driven Layered Architecture

Every bounded context MUST be a top-level package under the base package
(`com.example.starter` in the starter kit — replace it with yours), and MUST expose
exactly four layers:

```
{context}/domain/          models/aggregates | models/entities | models/valueobjects | events | exceptions
{context}/application/     usecase | command | results | ports | exceptions
{context}/infrastructure/  persistence/{adapters,entities,mappers,repositories} | acl
{context}/presentation/    controller | dto/request | dto/response | mapper
```

Dependency direction is one-way and MUST be enforced by ArchUnit:

- `domain` depends on no other layer.
- `application` depends only on `domain`.
- `presentation` depends only on `domain` and `application`.
- `infrastructure` may depend on `domain`, `application` and `presentation`.

The `domain` layer MUST NOT import `org.springframework..` or `jakarta..`. The
`application` layer MUST NOT import `org.springframework.web..` or
`jakarta.persistence..`. Cross-context package cycles are forbidden.

Every application port MUST be a single-method `@FunctionalInterface` carrying no
Spring annotation, named after the single operation it performs
(`ProductRetriever`, `OrderSaver`). Adapters implementing ports live in
`infrastructure` and are the only classes allowed to know about persistence.

Cross-cutting code shared by all contexts lives in `core` and follows the same
four-layer split.

**Crossing a context boundary.** A context that needs what another context knows
declares a port in its own `application`, in its own words, and implements it with a
`{Port}Acl` in its `infrastructure/acl/`. That class is the only one allowed to import
the upstream context: it calls the upstream's `application` (a use case or a port),
may use the upstream `domain` types that call requires, and never lets one leave the
class. It translates what it receives into the downstream context's own types before
returning; only `shared` and `core` types cross untranslated. The `domain`,
`application` and `presentation` of a context import nothing from another context, and
no context imports another's `infrastructure`. Enforced by ArchUnit
(`BoundedContextIsolationRulesTest`), whose list of allowed crossings is the record of
every anti-corruption layer in the codebase.

**Use case result channel.** A use case MUST return a dedicated result model named
`{UseCase}Result`, coherent by construction: any error occurring before the return
is thrown and caught by the caller of the use case.

**Starter-kit examples.** The `catalog` and `ordering` contexts shipped by the starter
kit are layout and convention templates. They carry no business value. Copy their
shape, never their semantics, and delete them once a real context exists.

**Domain-Driven Design discipline.** The layering above is a means; the domain model
is the end. Therefore:

- **Ubiquitous language.** Class, method and package names MUST use the vocabulary of
  the business as recorded in `docs/domain/glossary.md`. A term means one thing inside
  one bounded context; the same word appearing in two contexts is two distinct types,
  never a shared one.
- **Aggregates guard invariants.** An aggregate root is the consistency boundary of
  its cluster. Its internals MUST NOT be mutated from outside: every change goes
  through a method on the root, which rejects any transition that would break an
  invariant. A value object MUST refuse construction with invalid data.
- **No anemic domain model.** Business rules live in the `domain` layer. A use case
  orchestrates — it loads, delegates to the model, and persists. A use case that
  reads an aggregate's state, computes a decision and writes the result back has
  stolen behaviour that belongs to the aggregate.
- **A context boundary is a linguistic boundary.** A bounded context exists because
  its language is coherent and distinct, not because it groups technically similar
  code. Contexts communicate through explicit, named contracts and never share
  domain types.

Verification: enforced at review time by the `code-reviewer` skill, and — when a
specification needs a term absent from the glossary — at specification time by the
`domain-challenge` skill.

**Screaming architecture.** The package tree MUST announce what the system does, not
what it is built with.

- Top-level packages under the base package are bounded contexts, that is business
  capabilities. A reader MUST be able to learn what the system does by listing that
  directory. `core` is the single exception, reserved for cross-cutting code.
- **In `domain` and `application`**, names come from the business, never from a
  framework or a pattern. A name that describes a technical role instead of a domain
  concept — `OrderManager`, `OrderService`, a `utils` package — is a signal that a
  business notion has not been named yet. These are examples, not a list to check
  against: the rule is a judgement about whether the name says what the code *means*,
  and no enumeration of forbidden suffixes can express it.
- **`infrastructure` and `presentation` are exempt.** They exist to speak the language
  of a technology, so `*Adapter`, `*Entity`, `*EntityMapper`, `*Controller` and
  `*Dto` are the correct names there — they are mandated by the naming table in
  `AGENTS.md`. A technical name is a defect only where a business concept was
  expected.
- Use cases are named as business actions in the imperative, suffixed with their role:
  `{Verb}{Noun}UseCase` (`PlaceOrderUseCase`), never as technical operations
  (`OrderCreationService`). The suffix is enforced by ArchUnit.
- The one name that legitimately looks technical is `shared`, when it designates a
  deliberate DDD shared kernel declared in `docs/domain/context-map.md`. That is
  precisely why none of this is mechanically enforced: a test cannot tell a shared
  kernel from a dumping ground. Whoever designs, implements or reviews carries it.

**Assumed trade-off.** Inside a context, the first level is technical (`domain`,
`application`, `infrastructure`, `presentation`) rather than feature-oriented. This
is a deliberate decision: the layering is mechanically enforced by ArchUnit and
reorganising it by feature would trade a verifiable guarantee for a stylistic one.
The architecture screams at the context level and layers below it. This trade-off
MUST NOT be reopened by invoking screaming architecture in isolation.

Verification: no ArchUnit rule enforces naming intent, by design. It is enforced at
review time by the `code-reviewer` skill and at design time by the `domain-challenge`
skill.

`AGENTS.md` at the repository root is the authoritative reference for interpreting
this principle: naming conventions, package placement, routing and mapper rules.

**Rationale**: The layering is already enforced mechanically by ArchUnit, so writing
it into the constitution costs nothing and gives every agent a single place to read
the rules before generating code. Naming the example contexts as examples prevents
the most likely failure mode of an autonomous agent on a fresh repository — mistaking
starter-kit scaffolding for real domain knowledge and building on top of it.

### II. Test-First Delivery

No production code is written before a test that fails.

Every change MUST first be classified:

- **The change introduces or modifies a use case** → a Cucumber behavior test is
  written first.
- **Any other change to business code** — aggregate, entity, value object, command —
  → a unit test is written first.
- **A change to `infrastructure` or `presentation`** — adapter, JPA entity,
  repository, persistence or presentation mapper, controller, DTO, changelog — → no
  test is written by default. These layers translate; they MUST NOT decide. A rule
  such as uniqueness or the existence of a referenced item is guaranteed by the use
  case, through its ports, and is therefore covered by its behavior test. A rule
  found living in an adapter is a defect to move up, not a reason to test the adapter.
  There are two exceptions, both unit-tested like business code: an anti-corruption
  layer under `infrastructure/acl`, whose translation is a contract between contexts,
  and cross-cutting technical logic in `core` — security, error handling, attribution.
- **A change with no behavioural surface** — configuration, build files,
  documentation — → no test is required, and this exemption MUST NOT be stretched to
  cover business code.

In the first two cases the sequence is mandatory and non-negotiable:

1. Write the test.
2. Run it.
3. **Observe the failure** and keep the output.
4. Only then write the minimum production code that turns it green.

A test that passes on its first run is a defect in the test, not a success. Work
MUST stop and the anomaly MUST be reported.

**Behavior test conventions.** Feature files live at
`src/test/resources/behaviors/{context}/{use_case}.feature`. A feature opens with a
`# Covers:` header, then `As a / I want / So that`, groups its scenarios under `Rule:`
blocks — a `Background:` shared by every rule sits at feature level, one specific to a
rule sits inside that `Rule:` — and prefixes each scenario title
with ✅ for a success path or ❌ for a failure path. Each feature has exactly one runner
class in `behaviors/{context}/runners/`, annotated `@Suite @IncludeEngines("cucumber")`
with its glue package scoped to that single feature and an HTML report emitted under
`build/reports/behaviors/{context}/`. Step definitions live in
`behaviors/{context}/steps/{use_case}/`, instantiate the use case directly with
Mockito-mocked ports, and MUST NOT load a Spring context. Assertions use AssertJ and
bear exclusively on the value returned by the use case and on the interactions with
the mocked ports. A step MAY assert that a refusal occurred — that the caught exception
is not null — and MUST NOT assert on its type, nor on its message unless the spec fixes
its wording. Scenarios, steps and refusal messages MUST speak the domain's meaning to the
user, never the bounded context or the port that answers. Test data is built
with the generated fixtures, never with ad-hoc constructors.

**Unit test conventions.** Every model of the domain and application layers — of any
kind: aggregate root, entity, value object or command — is tested through
`CreationTest<ENTITY, FIXTURE, EXCEPTION>`, which generates the valid and invalid
creation cases from fixture providers. Behaviour that is not creation (a mutator on
an aggregate, for example) is covered by plain JUnit 5 tests in addition, never
instead. Test data is built with the generated fixtures.

Unit tests and ArchUnit tests complement behavior tests; they never substitute for
them. A use case without a behavior test is incomplete regardless of its unit test
coverage.

**Rationale**: Spec-kit ships with test tasks marked optional. Left alone, an agent
takes the shortest path and writes tests after the code, which produces tests shaped
by the implementation rather than by the requirement. Requiring an *observed* failure
is what makes the rule verifiable rather than declarative: a test that was never seen
red proves nothing about what it covers.

### III. Consistent Versioning and Changelog Discipline

Commit messages MUST follow Conventional Commits, matching the regex enforced by
`.githooks/commit-msg`:

```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z \-]+\))?!?: .+$
```

Releases follow Semantic Versioning. Amendments to this constitution are versioned
independently:

- **MAJOR** — a principle is removed, or redefined in a way that invalidates existing
  code.
- **MINOR** — a principle or a section is added, or materially extended.
- **PATCH** — wording, typo, or clarification that changes no rule.

Every amendment MUST update the Sync Impact Report at the top of this file and the
version line at the bottom.

**Rationale**: The commit convention is already enforced by a git hook; stating it
here makes it visible to agents that write commits. Versioning the constitution
itself is what allows a future reader to know whether a rule predates or postdates
the code they are looking at.

### IV. Security and Simplicity

No secret, token, credential or connection string is ever committed. Secret scanning
SHOULD run on every commit through a pre-commit hook; a finding blocks the commit and
MUST NOT be bypassed.

The dependency supply chain is locked. `org.gradle.dependency.verification=strict`
and `dependencyLocking` are enabled. Any dependency change MUST be accompanied by
regenerated `gradle.lockfile`, `settings-gradle.lockfile` and
`gradle/verification-metadata.xml`:

```bash
./gradlew dependencies --write-locks
./gradlew --write-verification-metadata sha256 help
```

Every new third-party dependency MUST be justified in the plan that introduces it.
Prefer what is already on the classpath.

YAGNI applies. Abstractions, configuration switches and extension points are added
when a requirement demands them, not in anticipation.

**Rationale**: Strict verification and lockfiles are already in place; the failure
mode is an agent adding a dependency and leaving the build broken or the verification
metadata stale. Making the regeneration commands part of the rule removes the excuse.

### V. Domain Knowledge Is Written Down

The domain model lives in `docs/domain/`, versioned alongside the code.

- It is **descriptive**, not normative: it records what the domain is understood to
  be. Where production code and behaviour tests exist, **the code is authoritative**
  and the documentation MUST be corrected to match it.
- It carries the **slow substrate** of the domain: vocabulary, context boundaries,
  aggregates and the invariants they guard — what a single feature cannot invalidate.
  Use-case level decisions, acceptance scenarios and `FR-NNN` requirements are
  deliberately **not** recorded here; they accumulate in `specs/`, dated and traceable
  to the ticket that produced them. The silence of `docs/domain/` on a use-case
  question therefore proves nothing, and MUST NOT be read as "nothing was decided".
- Every file MUST carry a provenance header stating its source, its status
  (`EMPTY` | `DRAFT` | `AGREED` | `REVIEWED` | `STABLE`) and this authority rule. What
  each of those five values claims is defined once, in
  `docs/domain/README.md` § *Status is not decoration*, and MUST NOT be restated here. A
  `DRAFT` transcribed from an in-progress modelling session MUST NOT be treated as
  settled.
- Bounded contexts are listed in `docs/domain/context-map.md`; the content of each
  context lives in `docs/domain/contexts/{context}/`.

**Speaking from an empty model is forbidden.** When a specification requires a notion
that `docs/domain/` does not define, the correct outcome is to say so and extend the
model first — never to infer a plausible answer and continue. Every statement about
the domain MUST carry one of three labels:

- **founded** — attributable to a named artefact of this repository, cited by path: a
  file in `docs/domain/`, a `spec.md` under `specs/`, or production code and its
  behaviour tests.
- **inferred** — deduced by analogy, from a ticket, or from context. Plausible,
  unverified.
- **unknown** — no artefact says anything either way.

**Founded is not current.** The three kinds of artefact do not carry equal authority:
production code and behaviour tests record what the system *does* and are
authoritative over both others; a `spec.md` records what was *asked, at a date*; and
`docs/domain/` records the model the team *accepted*. A feature can be reduced or
abandoned without its spec being rewritten — an `FR-NNN` found there is evidence that
a question was once answered, not proof that the answer still holds. Which artefact
grounds a claim is therefore part of the claim, and MUST be cited with it.

Verification: enforced at specification time by the `domain-challenge` skill, whose
`DOMAIN GAP` verdict stops the workflow rather than producing a specification built
on inference.

**Rationale**: A new project starts without a domain. Unlike a project where years of
code and behaviour tests act as living documentation, there is nothing for an agent
to read — and an agent asked to reason about an undocumented domain will produce a
confident, coherent and wrong answer. Labelling the source of every claim is what
makes that failure visible instead of invisible. Making the knowledge base a
first-class versioned artefact is what allows the discussions held around the domain
modelling to survive the meeting they happened in.

## Additional Constraints

**Technology.** Java 21. Spring Boot 4.1. Cucumber 8. ArchUnit 1.5. Fixtures generated
by `java-fixture-generator`. All versions MUST be declared in
`gradle/libs.versions.toml`; a version string written directly in a build script is a
violation.

**Style.** 2-space indentation, 120-column limit, LF line endings, UTF-8, final
newline — as specified by `.editorconfig`. All method and constructor parameters
MUST be declared `final`, except in constructors generated by Lombok.

**Comments.** Code carries no comments. Intent is carried by names — a named private
factory method instead of a commented literal, a test name that states the fact it
pins, an AssertJ `.as(...)` description that appears in the failure output instead of
a line nobody sees when the test breaks. A comment explaining *what* code does is a
missing name, and the correct fix is the name, never the comment.

Javadoc is not exempt. It is admissible in exactly one case — documenting a type for
a caller who reaches it as a tool: test infrastructure, infrastructure, and the
public surface of an API. It is forbidden in `domain` and `application`, whose names
come from the business and are the documentation. Every Javadoc block MUST be
validated explicitly when it is introduced; an unvalidated one is a violation like
any other comment.

The list of authorised exceptions to this rule is closed and is held by
`AGENTS.md` § *Code Style*. A comment outside that list MUST be replaced by a name,
not justified in review.

**Bounded contexts.** `docs/domain/context-map.md` names every context the domain has.
A context gets a top-level package only once it is declared there and in
`BoundedContextIsolationRulesTest`; ArchUnit fails on any undeclared top-level package.
`shared` is not a bounded context and the four-layer rule of Principle I does not apply
to it: it is a shared kernel, jointly owned, whose change is negotiated with every
consumer and which stays small.

**Quality gate.** JaCoCo produces a coverage report on every build. A coverage
threshold is introduced by MINOR amendment when the team agrees on one.

**Architecture reference.** `AGENTS.md` at the repository root is authoritative for
naming conventions, package placement and routing. Where `AGENTS.md` and this
constitution disagree, this constitution wins and `AGENTS.md` MUST be corrected.

## Development Workflow

Feature work flows through spec-kit:

```
/speckit.specify → /speckit.clarify → /speckit.plan → /speckit.tasks → /speckit.implement
```

Each feature owns a directory `specs/{ID}-{short-name}/` containing `spec.md`,
`plan.md` and `tasks.md`. These artefacts are committed.

Implementation follows the three-skill sequence, in order and without overlap:

1. **`test-first`** — writes the failing test and stops at RED. It never writes into
   `src/main/java`.
2. **`craftsman`** — refuses to start without an observed RED output, writes the
   minimum production code, and stops at GREEN.
3. **`code-reviewer`** — runs after GREEN. It is the only step allowed to propose
   refactoring.

Branches follow `{type}/PROJ-{number}-{snake_case}`. Direct commits to `main` are
forbidden.

## Governance

This constitution supersedes all other practice documents in this repository,
including `AGENTS.md`, the spec-kit templates and the skills. Any template or skill
that contradicts it is a defect in that file.

Amending it requires: a version bump per Principle III, an updated Sync Impact
Report, and a review of every template and skill listed in that report.

Compliance is expected to be verifiable. A rule that cannot be checked — by a test,
a hook, a linter or an explicit review step — belongs in `AGENTS.md` as guidance,
not here as law.

**Version**: 1.2.0 | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [RATIFICATION_DATE]
