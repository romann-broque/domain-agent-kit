# Recipe — Anti-corruption layer between two bounded contexts

## Purpose

Let a context (the **downstream**) use what another context (the **upstream**) knows,
without either one's model leaking into the other. Constitution Principle I, *Crossing a
context boundary*, is the law; this recipe is the shape, and its § *Rules* is the
register every future ACL rule is added to.

## When to use

- A use case needs an answer another context owns — the downstream asks, the upstream
  answers. Example: `ordering` asks `catalog` whether each ordered product exists before
  placing an order.
- A use case needs an answer from a context that has **no code yet** — the ACL is then a
  stand-in that answers on the upstream's behalf until it exists.

Not for: sharing a type. A type both contexts genuinely co-own goes to `shared`, by
negotiation recorded in `docs/domain/context-map.md` — never by an ACL passing it
through.

## The order

Port → behaviour test against the mocked port → `{Port}Acl` → allowed crossing in
ArchUnit. The use case and its behaviour test never see the ACL: they see the port.

### 1. The port, in the downstream's words

```java
package com.example.starter.ordering.application.ports;

import java.util.UUID;

@FunctionalInterface
public interface OrderedProductChecker {

  boolean exists(UUID productId);
}
```

- Lives in `<downstream>/application/ports/`, one method, no Spring annotation — like
  every port.
- Its parameter and return types are the **downstream's** (`<downstream>.domain…`),
  `shared` types, or plain JDK types. Never an upstream type: `OrderedProductChecker`
  takes a `UUID`, not a catalog `ProductId`.
- Named after the operation, from the downstream's point of view. It does not say
  where the answer comes from: nothing in the name mentions the upstream.
- An absence is `false`, `Optional.empty()` or an empty collection; the use case decides
  what an absence means for it. `PlaceOrderUseCase` refuses with `UnknownProductException`.

### 2. The ACL

```java
package com.example.starter.ordering.infrastructure.acl;

import com.example.starter.catalog.application.ports.ProductRetriever;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.ordering.application.ports.OrderedProductChecker;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class OrderedProductCheckerAcl implements OrderedProductChecker {

  private final ProductRetriever productRetriever;

  @Override
  public boolean exists(final UUID productId) {
    return productRetriever.retrieve(new ProductId(productId)).isPresent();
  }
}
```

- Named `{Port}Acl`, in `<downstream>/infrastructure/acl/`, `@Component`,
  `@RequiredArgsConstructor`. Not `*Adapter`: ArchUnit reserves that suffix for
  `infrastructure.persistence.adapters`, and an ACL is not persistence.
- Calls the upstream's **application layer** — its published contract. When the
  upstream has a use case for the question, the ACL calls it with its command, so the
  upstream's rules apply. When the answer is a plain read and the upstream publishes no
  use case for it, the ACL injects the upstream's application port, as above. Never the
  upstream's adapters, repositories or entities.
- Builds only the upstream values its call takes as arguments (`new ProductId(...)`),
  reads the upstream types the answer carries, and returns downstream, `shared` or JDK
  types only.
- When the answer has to be turned into a downstream type, the translation sits in
  `private static to{Type}(...)` methods inside the ACL. No separate translator class.
- Where an upstream type and a downstream type share a simple name, the upstream one is
  written fully qualified, in the translation method only.
- When the upstream signals absence by throwing, the ACL catches the **specific**
  upstream exception that means *absent* and returns the empty answer. Every other
  upstream exception propagates.
- Carries no `@Transactional`: the downstream use case is the transaction boundary, and
  the upstream call joins it.

### 3. A stand-in, when the upstream has no code

```java
@Component
public class {Port}Acl implements {Port} {

  private static final {Answer} EVERY_CASE = ...;

  @Override
  public {Answer} {operation}(final {Question} question) {
    return EVERY_CASE;
  }
}
```

- Same port, same place, same name as the real ACL will have. Replacing the stand-in
  touches this one class and the allowed crossings, nothing else.
- The error a stand-in makes is written down where the decision is (an open point
  `OP-<n>`, a `research.md` entry), not in the class.

### 4. The allowed crossing

In `src/test/java/com/example/starter/architecture/BoundedContextIsolationRulesTest.java`:

```java
private static final BoundedContexts CONTEXTS = BoundedContexts.withSharedKernel(BASE + ".shared")
    .context("catalog", BASE + ".catalog").and()
    .context("ordering", BASE + ".ordering")
    .mayCross("infrastructure.acl", "catalog", "application")
    .mayCross("infrastructure.acl", "catalog", "domain")
    .and()
    .build();
```

The crossing is declared **after** the ACL is written, so the rule is seen red first:
the ACL's import of the upstream fails the build until the line is added. The `domain`
crossing is there because the upstream call takes and returns the upstream's domain
types — `ProductId` in, `Optional<Product>` out (ACL-02). A stand-in crosses nothing and
declares nothing. A new context must be declared here at all: an undeclared top-level
package fails the build.

### 5. Tests

- The downstream's behaviour test mocks **the port** (`OrderedProductChecker`), never
  the ACL and never the upstream.
- The ACL gets a unit test mocking the upstream port — Constitution Principle II owns
  this rule (`OrderedProductCheckerAclTest` is the example). Its boundary is held by
  `BoundedContextIsolationRulesTest`; its wiring by the smoke test, which adds a product
  then orders it.

## Rules

Every rule on anti-corruption layers is recorded here, in this format, numbered in the
order it was decided. A rule is never renumbered; a rule withdrawn keeps its number and
says *Withdrawn* with the date and the reason.

```
### ACL-NN — <the rule, stated in a short sentence>

**Rule.** What must or must not be written.
**Why.** The failure it prevents.
**Checked by.** ArchUnit rule | code-reviewer step | quickstart — name it.
**Since.** YYYY-MM-DD, <ticket, e.g. PROJ-123>.
```

### ACL-01 — Only `infrastructure/acl` crosses a context boundary

**Rule.** The `domain`, `application` and `presentation` of a context import nothing
from another context. Only a class in its `infrastructure/acl/` may.
**Why.** A downstream use case that knows an upstream type is coupled to the upstream
model; the boundary is then a folder name.
**Checked by.** `BoundedContextIsolationRulesTest`.
**Since.** Initial rule set.

### ACL-02 — An ACL reaches the upstream's `application`, never its `infrastructure`

**Rule.** An ACL calls an upstream use case with its command, or an upstream application
port when the upstream publishes no use case for that read. It may build the upstream
`domain` values that call takes as arguments and read the ones its answer carries, and
nothing more: it never calls a behaviour on one, or lets one leave the ACL. It never
injects an upstream adapter, repository or JPA entity.
**Why.** The upstream's application layer carries its rules (normalisation, refusals);
reading around it skips them and couples the downstream to a storage shape. A call into
the upstream's model takes and returns that model's types; forbidding them would force
every upstream to publish a flat copy of its model for each reader.
**Checked by.** `BoundedContextIsolationRulesTest` (crossings declared on
`application` and `domain`, never `infrastructure`); code-reviewer for the choice of a
use case over a port when the upstream has rules on the answer, and for a domain type
returned by an ACL.
**Since.** Initial rule set.

### ACL-03 — The port speaks the downstream's language

**Rule.** A port answered by an ACL takes and returns downstream, `shared` or JDK types,
and its name does not mention the upstream.
**Why.** The use case and its behaviour test must not change when the upstream does, or
when a stand-in is replaced by a real ACL.
**Checked by.** `BoundedContextIsolationRulesTest` (an upstream type on the port fails
it); code-reviewer for the name.
**Since.** Initial rule set.

### ACL-04 — Translation lives in the ACL

**Rule.** Upstream values are turned into downstream types inside the ACL, in
`private static to{Type}` methods when it takes more than an expression. Only `shared`
and `core` types pass untranslated.
**Why.** A translator elsewhere is a second class allowed to know both models.
**Checked by.** code-reviewer.
**Since.** Initial rule set.

### ACL-05 — Absence is empty, any other failure propagates

**Rule.** When the upstream reports absence by an exception, the ACL catches only that
exception and returns `false`, `Optional.empty()` or an empty collection. It never
catches a broader type.
**Why.** Swallowing a failure turns a broken upstream into a silent *not found*.
The upstream use case joins the downstream transaction and leaves its rollback rules alone:
its *absent* exception marks that transaction rollback-only, which is harmless as long as the
downstream refuses on absence. A downstream that must carry on without the value asks the
upstream for an `Optional`-returning query instead of making the upstream ignore its own
failure with `noRollbackFor`.
**Checked by.** code-reviewer.
**Since.** Initial rule set.

### ACL-06 — Named `{Port}Acl`, placed in `infrastructure/acl/`

**Rule.** One ACL per port, named after it with the `Acl` suffix, `@Component`.
**Why.** The suffix says the class crosses a boundary; a reader finds every crossing by
listing `infrastructure/acl/`.
**Checked by.** `NamingConventionRulesTest` for the suffix; code-reviewer for the
port it is named after.
**Since.** Initial rule set.

### ACL-07 — A context with no code is answered by a stand-in ACL

**Rule.** When the upstream does not exist yet, the port is implemented by a stand-in
ACL in the same place and under the same name the real one will take, and the error it
makes is recorded where the decision is.
**Why.** The use case is written once, against the port; only the stand-in is replaced.
**Checked by.** code-reviewer.
**Since.** Initial rule set.

## Checklist

- [ ] The port is in `<downstream>/application/ports/`, single-method, with downstream,
      `shared` or JDK types only, and a name that does not mention the upstream.
- [ ] The behaviour test mocks the port.
- [ ] The ACL is `{Port}Acl` in `<downstream>/infrastructure/acl/`, `@Component`, no
      `@Transactional`.
- [ ] It calls an upstream use case or application port, never an upstream adapter,
      repository or entity.
- [ ] Translation is in the ACL; only `shared` and `core` types cross untranslated, and
      no upstream type leaves it.
- [ ] Only the upstream's *absent* exception is caught, if any.
- [ ] The crossing is declared in `BoundedContextIsolationRulesTest`, after the rule was
      seen red.
- [ ] A new rule decided on the way is added to § *Rules* in the format above.
