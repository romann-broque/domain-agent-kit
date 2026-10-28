---
name: craftsman
description: Write the minimum production code that turns an already-failing test green. Use this skill only after a test has been written and observed failing — typically right after the test-first skill hands over a RED output. Triggers on "make the test pass", "implement it now", "go green", "the test is red, implement", "implémente maintenant", "fais passer le test au vert". This skill refuses to start without an observed failing test output and stops as soon as the test is green.
---

# Craftsman

You turn RED into GREEN with the least code that honestly does it.

**Announce at start:** "Using craftsman to implement [unit of change] against the failing test."

## Step 0 — The entry gate

Before touching anything, confirm you have:

1. The test file(s) that were written.
2. The exact command that was run.
3. The **verbatim failing output** of that run.

If any of the three is missing → 🛑 **STOP.** Say so and hand back to the
`test-first` skill. Do not reconstruct the output from memory, do not re-run the test
yourself and call that the gate, and do not proceed "just this once".

If the output shows the test **passing** → 🛑 **STOP.** There is nothing to
implement; the test is defective. Report it.

## Step 1 — Implement the minimum

**Load the recipe for what you are about to write.** Each one is drawn from the
`catalog` and `ordering` example contexts of the starter kit, and flags the places where
an older or simpler shape must not be imitated:

| You are writing | Read first |
|---|---|
| a value object, a domain exception, an entity, an aggregate root | `references/aggregate-and-value-objects.md` |
| a use case, a command, a port, a `{UseCase}Result` | `references/use-case-and-ports.md` |
| a JPA entity, a repository, a persistence mapper, an adapter, a Liquibase changelog | `references/persistence.md` |
| a request or response DTO, a presentation mapper, a controller, an error mapping | `references/endpoint.md` |
| a port answered by another context, an `{Port}Acl`, an allowed crossing in ArchUnit | `references/anti-corruption-layer.md` |

Each recipe gives the ordered steps, the exact code shape, and a closing checklist. If
your change spans several layers, read each recipe as you reach that layer — not all of
them upfront.

Write only what the failing test demands. Constitution Principle I and `AGENTS.md`
govern the shape:

- **Domain** — aggregate roots are classes equal by identity whose mutators change them
  in place (`AGENTS.md` § *Aggregates are changed in place*); a new identity is minted
  once, by the caller creating the aggregate, and a stored one is only ever restored —
  a constructor taking the identity, or `create(...)` / `reconstitute(...)` once the two
  paths diverge. Value objects are `record`s validating in their compact constructor
  through `require*` guards. Domain events are past-tense `record`s with no `Event`
  suffix. No Spring, no Jakarta.
- **Application** — use case `@Service` with `@RequiredArgsConstructor`, named
  `{Verb}{Noun}UseCase`, one public `execute` method taking a `{UseCase}Command`,
  returning `{UseCase}Result`, annotated `@Transactional` —
  `@Transactional(readOnly = true)` when it only reads. Errors before the return are
  thrown and caught by the caller. Do **not** use a legacy `Result<T>` wrapper in new
  code.
- **Ports** — one `@FunctionalInterface`, one method, no Spring annotation, named
  after the operation: `{Aggregate}Retriever`, `{Aggregate}RetrieverBy{X}`,
  `{Aggregate}Saver`, `{Aggregate}Updater`, `{Noun}Checker`.
- **Infrastructure** — one adapter per aggregate, `@Component`, named
  `{Aggregate}Adapter`, implementing all the ports of that aggregate; the only place
  that knows about persistence.
- **Another context** — reached only through a port of this context implemented by a
  `{Port}Acl` in `infrastructure/acl/`, calling the upstream's application layer and
  translating its answer; the only class allowed to import the upstream context.
- **Presentation** — controller maps the use case result to a response DTO wrapped in
  `ApiResponse<T>` and never leaks domain types; one `{UseCase}Mapper` per use case
  holding both `toCommand` and `toResponse`.
- **Collections** — unmodifiable by default (`toUnmodifiableSet()`, `Stream.toList()`,
  `List.copyOf`), unless the receiver must mutate them.

Style: 2-space indent, 120 columns, LF, all method and constructor parameters
`final` except in Lombok-generated constructors.

**No comments.** Not on a validation branch, not on a non-obvious expression, not as
a Javadoc — `domain` and `application` are where Javadoc is forbidden outright, and
they are the only layers this skill writes for a domain-only ticket. If a line needs
explaining, extract it into a named private method. The closed list of exceptions is
in `AGENTS.md` § *Code Style* → *No comments*, and nothing this skill writes is on it.

Add no dependency without justifying it. If you do add one, regenerate the lockfiles:

```bash
./gradlew dependencies --write-locks
./gradlew --write-verification-metadata sha256 help
```

## Step 2 — Run the test

```bash
./gradlew test --tests '<the same pattern as the RED run>'
```

If it still fails, iterate on the production code — **never on the test**. If you
believe the test itself is wrong, stop and say so; you are not allowed to weaken a
test to reach green.

## Step 3 — Confirm nothing else broke

```bash
./gradlew test
```

The ArchUnit suite must stay green. If a layer or naming rule broke, your placement
is wrong — fix the code, not the rule.

## Step 4 — Stop at green

You are done. Do not refactor, do not rename adjacent code, do not "improve while
you're in there". That is the `code-reviewer` skill's job.

End with:

1. The list of production files created or modified.
2. The command and its passing output.
3. `GREEN confirmed. Hand over to the code-reviewer skill.`

## Red Flags

| Thought | Reality |
|---|---|
| "I'm sure the test is red, let me start" | Sure is not observed. Get the output. |
| "I'll adjust the test slightly to match" | Never. The test defines the requirement. |
| "While I'm here I'll clean up this class" | Not your job. Stop at green. |
| "I'll return a `Result<T>` wrapper, older code does" | New use cases return `{UseCase}Result` and throw on failure. |
| "The adapter can call the domain directly" | Adapters implement ports. Respect the layers. |
| "I'll add a bit of extra behaviour, it'll be needed later" | YAGNI. Only what the test demands. |
| "ArchUnit is being annoying, I'll relax the rule" | The rule is right, your placement is wrong. |
