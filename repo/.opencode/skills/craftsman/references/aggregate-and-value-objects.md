# Recipe — Aggregate, entity and value objects

## Purpose

Add or extend a model in the `domain` layer of a bounded context: a value object, a
domain exception, an entity, an aggregate root, or a domain event.

## When to use

You are implementing a `[GATE]`-cleared unit of change whose failing test is a
`CreationTest` subclass or a plain JUnit test on a domain model.

> Every model of the `domain` and `application` layers — of any kind — is tested
> through `CreationTest<ENTITY, FIXTURE, EXCEPTION>`. Behaviour that is not creation
> (an aggregate mutator, for example) gets plain JUnit tests **in addition, never
> instead**. See Constitution Principle II.

## The order

Build inwards-out: exceptions, then value objects, then entities, then the aggregate
root, then its events. Each step compiles on its own.

### 1. The domain exception

One exception family per aggregate (or per invariant family). It extends the
context-free base in `core`:

```java
package com.example.starter.core.domain.exceptions;

public abstract class DomainException extends RuntimeException {

  protected DomainException(final String message) {
    super(message);
  }
}
```

```java
package com.example.starter.catalog.domain.exceptions;

import com.example.starter.core.domain.exceptions.DomainException;

public class ProductException extends DomainException {

  public ProductException(final String message) {
    super(message);
  }
}
```

No Spring annotation here. `DomainException` is mapped to HTTP 400 by
`GlobalExceptionHandler` — the domain never knows that.

### 2. The value object

A value object is a `record` that **refuses to exist in an invalid state**. Validation
lives in the compact constructor, one named `require*` guard per rule, and nowhere else.

A record compares its components with their own `equals`, so the compact constructor
also **reduces the value to one canonical form** once it is valid: `ProductName` trims,
and a `BigDecimal` amount is stored `stripTrailingZeros()`, because `BigDecimal.equals`
treats `24.9` and `24.90` as different. Two values that mean the same thing must be
equal; a test asserts it.

**Scalar VO with rules:**

```java
package com.example.starter.catalog.domain.models.valueobjects;

import com.example.starter.catalog.domain.exceptions.ProductException;

public record ProductName(String value) {

  private static final int MAX_LENGTH = 100;

  public ProductName {
    requireNotBlank(value);
    value = value.trim();
    requireAtMostMaxLength(value);
  }

  private static void requireNotBlank(final String value) {
    if (value == null || value.isBlank()) {
      throw new ProductException("A product name is required");
    }
  }

  private static void requireAtMostMaxLength(final String value) {
    if (value.length() > MAX_LENGTH) {
      throw new ProductException("A product name holds at most " + MAX_LENGTH + " characters");
    }
  }
}
```

**VO with behaviour** — an operation returns a new value, which validates itself:

```java
public record Quantity(int value) {

  private static final int MIN = 1;
  private static final int MAX = 999;

  public Quantity {
    requireWithinBounds(value);
  }

  public Quantity plus(final Quantity other) {
    return new Quantity(value + other.value);
  }

  private static void requireWithinBounds(final int value) {
    if (value < MIN || value > MAX) {
      throw new OrderException("A quantity lies between " + MIN + " and " + MAX);
    }
  }
}
```

**Composite VO with required components** — each component gets its own guard, so a
`NullPointerException` never escapes the domain; nested VOs validate themselves:

```java
public record OrderLine(UUID productId, Quantity quantity) {

  public OrderLine {
    requireProduct(productId);
    requireQuantity(quantity);
  }

  public OrderLine mergedWith(final OrderLine other) {
    return new OrderLine(productId, quantity.plus(other.quantity));
  }

  private static void requireProduct(final UUID productId) {
    if (productId == null) {
      throw new OrderException("An order line needs a product");
    }
  }

  private static void requireQuantity(final Quantity quantity) {
    if (quantity == null) {
      throw new OrderException("An order line needs a quantity");
    }
  }
}
```

`OrderLine` holds the product as a plain `UUID`, not as a catalog `ProductId`: the
`ordering` context never imports `catalog` types (see `anti-corruption-layer.md`).

**Identity VO** — wraps a `UUID`, refuses a missing one, mints a new one on demand:

```java
public record ProductId(UUID value) {

  public ProductId {
    requireValue(value);
  }

  public static ProductId newId() {
    return new ProductId(UUID.randomUUID());
  }

  private static void requireValue(final UUID value) {
    if (value == null) {
      throw new ProductException("A product id is required");
    }
  }
}
```

> ⚠️ A mutable class with no validation standing in for a value object is never the
> shape to imitate, whatever older code does. A value object is a `record`.

### 3. The entity

An entity has an identity within the aggregate but is not the root; it lives in
`domain/models/entities`. The starter kit has none yet. Fields `final`, private
constructor, static factory that validates through the same `require*` guards:

```java
@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class {Entity} {

  private final {Entity}Id id;
  private final {ValueObject} {value};

  public static {Entity} create(final {Entity}Id id, final {ValueObject} {value}) {
    return new {Entity}(require(id, "..."), require({value}, "..."));
  }
}
```

Keep your parameter order aligned with the record or constructor you are calling: two
parameters of the same type swapped compile and lose data silently.

### 4. The aggregate root

The root is the consistency boundary. It is the one object of the model meant to change:
a mutator changes the root **in place**, after its guards, and no caller can reach inside to
change a part. It is equal to another root by its identity alone. Value objects, inside it,
stay immutable records.

```java
package com.example.starter.catalog.domain.models.aggregates;

@Getter
public class Product {

  private final ProductId id;
  private final ProductName name;
  private Price price;

  public Product(final ProductId id, final ProductName name, final Price price) {
    this.id = require(id, "A product needs an id");
    this.name = require(name, "A product needs a name");
    this.price = require(price, "A product needs a price");
  }

  public void changePrice(final Price newPrice) {
    this.price = require(newPrice, "A product needs a price");
  }

  private static <T> T require(final T value, final String message) {
    if (value == null) {
      throw new ProductException(message);
    }
    return value;
  }

  @Override
  public boolean equals(final Object other) {
    return other instanceof Product product && id.equals(product.id);
  }

  @Override
  public int hashCode() {
    return Objects.hash(id);
  }
}
```

Only `price` is non-`final`, because `changePrice` changes it — in place, through the same
guard as the constructor, returning nothing.

An invariant spanning the parts is enforced by the root, and the parts it hands out cannot
be changed from outside:

```java
public Order(final OrderId id, final List<OrderLine> lines) {
  this.id = require(id, "An order needs an id");
  this.lines = merged(requireAtLeastOneLine(lines));
}

private static List<OrderLine> merged(final List<OrderLine> lines) {
  final Map<UUID, OrderLine> byProduct = new LinkedHashMap<>();
  lines.forEach(line -> byProduct.merge(line.productId(), line, OrderLine::mergedWith));
  return List.copyOf(byProduct.values());
}
```

**Minting an identity and restoring one are not interchangeable:**

| Path | Meaning | Who takes it |
|---|---|---|
| new identity — `new Product(ProductId.newId(), ...)`, or `create(...)` | a **new** thing is born, invariants checked | the use case creating it |
| stored identity — `new Product(new ProductId(stored), ...)`, or `reconstitute(...)` | rehydration of something that already exists | the persistence mapper, only |

In the starter kit both paths go through the constructor, which takes the identity as
an argument: the use case mints it with `ProductId.newId()`, the mapper restores it from
the column. When creation needs work that rehydration must skip (an initial state, an
event), split the constructor into `create(...)` and `reconstitute(...)` behind a private
constructor. Either way, a mapper that mints a fresh identity silently loses the stored one.

**Business logic belongs here, not in the use case.** A use case that reads the
aggregate's state, computes a decision and writes the result back has stolen
behaviour that belongs to the aggregate (Constitution Principle I, *No anemic domain
model*). If you are about to write an `if` on aggregate state inside a use case, the
method you need is a mutator on the aggregate.

### 5. The domain event

A `record` in `domain/events`, named in the past tense, with no `Event` suffix, carrying
the identity of what happened:

```java
package com.example.starter.catalog.domain.events;

public record ProductAdded(ProductId productId) {
}
```

The use case emits it through the `core` `EventEmitter` port after saving.

## Best practices

- No `org.springframework..`, no `jakarta..` anywhere under `domain`. ArchUnit
  enforces it. Lombok is allowed.
- All method and constructor parameters `final`, except in Lombok-generated
  constructors.
- Names come from `docs/domain/glossary.md`. A concept absent from the glossary is a
  gap to raise, not a name to invent.
- The same word in two bounded contexts is **two distinct types**. Never share a
  domain type across a context boundary.
- 2-space indent, 120 columns, LF.
- **Collections are unmodifiable by default** — `Collectors.toUnmodifiableSet()`,
  `Stream.toList()`, `List.copyOf(...)` — unless the code receiving them must mutate
  them, which a domain type never does.
- **A guard names its rule, never the value it checks against.**
  `requireAtMostMaxLength` with a `MAX_LENGTH` constant, not
  `requireAtMost100Characters`: the number lives in the constant, so changing it
  touches one line instead of a method name and its callers. (`Price` still has
  `requireAtMostTwoDecimals` — not to be imitated.)
- **No comments, and no Javadoc** — this file is about `domain`, where Javadoc is
  forbidden outright. A validation branch that needs explaining needs a named private
  method. See `AGENTS.md` § *Code Style* → *No comments*.

## Checklist

- [ ] Every new value object is a `record` validating in its compact constructor.
- [ ] Every value object stores a canonical form: two values meaning the same thing are
      `equals` (trimmed text, `stripTrailingZeros()` on a `BigDecimal`).
- [ ] Every validation failure throws a `DomainException` subclass, never a raw
      `NullPointerException` or `IllegalArgumentException`.
- [ ] The aggregate root's fields are `final`, except those its mutators change.
- [ ] Mutators change the root in place, through its guards; no duplicate is returned.
- [ ] The root is equal by identity only.
- [ ] Collections held or returned are unmodifiable.
- [ ] No guard name carries a literal value.
- [ ] A new identity is minted only on creation; rehydration restores the stored one.
- [ ] Domain events are past-tense records without an `Event` suffix.
- [ ] No Spring, no Jakarta, no persistence concern under `domain`.
- [ ] The `CreationTest` subclass that was RED is now green.
- [ ] `./gradlew test --tests 'com.example.starter.architecture.*'` is green.
