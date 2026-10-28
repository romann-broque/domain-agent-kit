# Recipe — Use case, command, ports and result

## Purpose

Add a use case to the `application` layer of a bounded context, with its command, its
result, its exceptions and the ports it needs.

## When to use

The failing test you must turn green is a Cucumber behaviour test on a use case —
that is, a `.feature` under `src/test/resources/behaviors/{context}/` with a runner
and step definitions instantiating the use case directly with mocked ports.

## The order

Command → exceptions → result → ports → use case. The behaviour test compiles only
once all of them exist, so expect the RED run to be a compilation failure at first.

### 1. The command

A command is a `record` in `application/command`. It carries **primitives and
DTO-free values**, never domain types — it crosses the boundary from presentation.

```java
package com.example.starter.catalog.application.command;

import java.math.BigDecimal;

public record AddProductCommand(String name, BigDecimal price) {
}
```

Repeated line items are a second command record of their own, in the same package:

```java
public record PlaceOrderCommand(List<PlaceOrderLineCommand> lines) {
}

public record PlaceOrderLineCommand(UUID productId, int quantity) {
}
```

The business rules on these values are not the command's: the use case turns them into
value objects (`ProductName`, `Price`, `Quantity`), which refuse an invalid value. A
command validates in its compact constructor only a shape rule that belongs to no value
object — then through `require*` guards throwing an application exception, like a value
object.

> Command validation, when there is some, is tested by a `CreationTest` subclass,
> **not** by the behaviour test. The behaviour test exercises the use case, and a
> command that cannot be built never reaches it.

### 2. The exceptions

An application exception lives in `application/exceptions`, is named after the refusal it
reports, and extends the domain exception family of its context, hence `DomainException`:

```java
package com.example.starter.catalog.application.exceptions;

import com.example.starter.catalog.domain.exceptions.ProductException;
import com.example.starter.catalog.domain.models.valueobjects.ProductName;

public class ProductAlreadyExistsException extends ProductException {

  public ProductAlreadyExistsException(final ProductName name) {
    super("A product named \"" + name.value() + "\" already exists");
  }
}
```

`DomainException` is already mapped to HTTP 400 by `GlobalExceptionHandler`; a new
exception in that family needs no handler and no `@ResponseStatus`.

When the use case cannot complete because the thing designated does not exist, its
exception extends a `core` not-found base (`{Aggregate}NotFoundException` extending
`NotFoundException`) mapped to 404 in `GlobalExceptionHandler`. The starter kit has no
such use case yet: add the base and its single mapping the first time one is needed.

### 3. The result

**A dedicated `{UseCase}Result` per use case.** It is a record that is coherent by
construction: if it exists, the use case succeeded. It lives in `application/results` —
never in `application/usecase`, where ArchUnit requires every top-level class to end
in `UseCase`. Any error occurring before the `return` is thrown and caught by the caller.

```java
package com.example.starter.catalog.application.results;

import java.util.UUID;

public record AddProductResult(UUID productId) {
}
```

> ⚠️ A sealed `Result<T>` (`Success` / `Failure`) wrapper, if your codebase still has
> one, is legacy. **Do not use it in new code.** ArchUnit requires `execute` to return a
> type whose name ends in `Result` (Constitution Principle I).

The practical consequence for your test: a `{UseCase}Result` use case signals failure
by **throwing**. The behaviour test does not assert on the thrown exception's type
(Constitution Principle II): it catches it, asserts that a refusal occurred, and asserts
on what was, or was not, returned and on the mocked ports' interactions.

### 4. The ports

One port, one method, one operation. `@FunctionalInterface`, no Spring annotation —
the `application` layer must not know Spring exists beyond `@Service` and
`@Transactional`.

```java
package com.example.starter.catalog.application.ports;

@FunctionalInterface
public interface ProductRetriever {

  Optional<Product> retrieve(ProductId id);
}
```

```java
@FunctionalInterface
public interface ProductRetrieverByName {

  Optional<Product> retrieveByName(ProductName name);
}
```

```java
@FunctionalInterface
public interface ProductSaver {

  void save(Product product);
}
```

Name the port after the operation, not after the technology: `ProductRetriever`, not
`ProductJpaRepository`. Absence is expressed by `Optional` (or an empty collection),
never by `null`.

| Operation | Port | Method |
|---|---|---|
| read one by its identifier | `{Aggregate}Retriever` — `ProductRetriever` | `retrieve` |
| read by any other criterion | `{Aggregate}RetrieverBy{Criterion}` — `ProductRetrieverByName` | `retrieveBy{Criterion}` |
| insert a new aggregate | `{Aggregate}Saver` — `ProductSaver`, `OrderSaver` | `save` |
| store the change of a held aggregate | `{Aggregate}Updater` | `update` |
| answer a yes/no question | `{Noun}Checker` — `OrderedProductChecker` | a `boolean` query, `exists` |

A reading port is a *retriever*, whatever it filters on: never `Searcher`, `Finder` or
`Lookup`, which name the same operation twice. A criterion that designates one aggregate
returns an `Optional`; one that designates several returns a `List` when the order is
part of the answer, a `Set` otherwise.

Ports return and accept **domain types** of their own context, or JDK types. They are
the boundary the domain owns. A port answered by another context is covered by
`anti-corruption-layer.md`.

### 5. The use case

```java
package com.example.starter.catalog.application.usecase;

@Service
@Transactional
@RequiredArgsConstructor
public class AddProductUseCase {

  private final ProductRetrieverByName productRetrieverByName;
  private final ProductSaver productSaver;
  private final EventEmitter eventEmitter;

  public AddProductResult execute(final AddProductCommand command) {
    final ProductName name = new ProductName(command.name());
    final Price price = new Price(command.price());
    requireUniqueName(name);

    final Product product = new Product(ProductId.newId(), name, price);
    productSaver.save(product);
    eventEmitter.emit(new ProductAdded(product.getId()));

    return new AddProductResult(product.getId().value());
  }

  private void requireUniqueName(final ProductName name) {
    if (productRetrieverByName.retrieveByName(name).isPresent()) {
      throw new ProductAlreadyExistsException(name);
    }
  }
}
```

The uniqueness rule is the use case's: it asks a port and refuses. It is covered by the
behaviour test, never by an adapter catching a constraint violation.

Rules that hold regardless of the use case:

- **Exactly one public method**, named `execute`, taking one `{UseCase}Command`.
- `@Service` + `@RequiredArgsConstructor`, ports injected as `private final` fields.
- `@Transactional` (`org.springframework.transaction.annotation`) on the class or on
  `execute`, or `@Transactional(readOnly = true)` when the use case only reads. The use
  case is the transaction boundary: every port it calls runs in one transaction, so a
  check through one port and a write through another see the same state.
- The use case **orchestrates**; it does not decide. Every `if` on aggregate state
  belongs to a mutator on the aggregate.
- Events are emitted through the `core` `EventEmitter` port, after the save.
- All parameters `final`.

For reference, the legacy wrapper shape — do not reproduce it:

```java
  public Result<{Aggregate}> execute(final {UseCase}Command command) {
    try {
      // ...
      return Result.success({aggregate});
    } catch (DomainException e) {
      return Result.failure("...: " + e.getMessage(), e);
    }
  }
```

## Best practices

- No `org.springframework.web..`, no `jakarta.persistence..` under `application`.
  ArchUnit enforces it.
- A use case never touches a repository, an entity or a DTO. Only commands, domain
  types, ports and its own result.
- Naming: use cases are business imperatives suffixed with their role —
  `AddProductUseCase`, `PlaceOrderUseCase`. Command and result keep the root:
  `PlaceOrderCommand`, `PlaceOrderResult`. ArchUnit enforces the suffixes.
  Never `OrderService`, `OrderManager`, `OrderProcessor`. A technical suffix in
  `application` is the signal that a business concept was not named.
- Adding a port means adding its implementation — an adapter (see `persistence.md`) or
  an ACL (see `anti-corruption-layer.md`). A port with no implementation fails Spring
  wiring at startup, not at compile time.

## Checklist

- [ ] The command is a `record` of primitives; any shape rule of its own validates in
      its compact constructor.
- [ ] Each refusal has an exception in `application/exceptions`, extending its
      context's `DomainException` family (or a not-found base for an absence).
- [ ] The use case returns a dedicated `{UseCase}Result`, not a legacy `Result<T>`.
- [ ] The use case is named `{Verb}{Noun}UseCase`.
- [ ] Exactly one public `execute` method, `@Transactional` (`readOnly = true` if it
      only reads).
- [ ] Every port is a single-method `@FunctionalInterface` with no Spring annotation.
- [ ] Every new port has an implementation, otherwise the context will not start.
- [ ] No business decision left in the use case that belongs to the aggregate.
- [ ] The behaviour test that was RED is now green.
- [ ] `./gradlew test --tests 'com.example.starter.architecture.*'` is green.
