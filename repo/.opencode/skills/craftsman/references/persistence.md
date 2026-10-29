# Recipe — Persistence: JPA entity, repository, mapper, adapter, Liquibase

## Purpose

Give a domain aggregate a place to live in the database, and wire the application
ports to it.

## When to use

A use case needs a port implemented, or an aggregate needs new persisted state.

> Persistence is the one part of the stack the behaviour tests do **not** cover — they
> mock the ports. Nothing here is driven by a RED behaviour test, so be especially
> conservative: write what the port signature demands and no more.
>
> **No test is written for this layer by default** (Constitution Principle II). Entities,
> repositories, mappers and adapters translate; they do not decide. A uniqueness or
> existence rule belongs to the use case, which asks a port and is covered by its
> behaviour test — never to an adapter catching a constraint violation. If you find
> yourself wanting to test an adapter, the logic you want to test is in the wrong layer.
> The smoke test (`StarterApplicationSmokeTest`) is what proves the wiring: the context
> starts, Liquibase runs, and Hibernate validates the entities against the schema.

## The order

Liquibase changelog → JPA entities → repository → mapper → adapter. Schema first,
because the entity annotations must match columns that exist: `ddl-auto: validate`
refuses to start otherwise.

### 1. The Liquibase changelog

Changelogs are written in **YAML**, using Liquibase change types (`createTable`,
`addColumn`, `createIndex`, …) — database-agnostic, which matters because tests run on
H2 and deployments on PostgreSQL. Raw SQL files are not used: they tie a migration to
one dialect.

Layout — one folder per bounded context, files numbered from `001` within each folder:

```
src/main/resources/db/changelog/
├── db.changelog-master.yaml        the one master, every profile
├── catalog/
│   └── 001-create-product.yaml
└── ordering/
    └── 001-create-order.yaml
```

The master includes each context folder once:

```yaml
databaseChangeLog:
  - includeAll:
      path: db/changelog/catalog/
      errorIfMissingOrEmpty: false
  - includeAll:
      path: db/changelog/ordering/
      errorIfMissingOrEmpty: false
```

A new file in an existing folder is picked up with no edit to the master; a new
context adds one `includeAll` entry. Files run in name order, which is why each one
starts with its number.

Each file carries one changeset, whose id is `{context}-{NNN}-{action}` — the context
prefix and the file name without extension:

```yaml
databaseChangeLog:
  - changeSet:
      id: catalog-001-create-product
      author: starter
      changes:
        - createTable:
            tableName: product
            columns:
              - column:
                  name: id
                  type: uuid
                  constraints:
                    primaryKey: true
                    nullable: false
              - column:
                  name: name
                  type: varchar(100)
                  constraints:
                    nullable: false
                    unique: true
              - column:
                  name: price
                  type: decimal(12, 2)
                  constraints:
                    nullable: false
```

A child table references its parent with a named foreign key:

```yaml
        - createTable:
            tableName: order_line
            columns:
              - column:
                  name: order_id
                  type: uuid
                  constraints:
                    nullable: false
                    foreignKeyName: fk_order_line_order
                    references: customer_order(id)
```

`DATABASECHANGELOG` identifies a changeset by path, id and author. **A changelog that
has already run on a shared database is never moved or renamed** — it would be replayed
as new. If a file must move, pin its old path with `logicalFilePath` first.

A migration that must tolerate a database where it was already applied uses
preconditions:

```yaml
  - changeSet:
      id: {context}-{NNN}-{action}
      author: {author}
      preConditions:
        - onFail: MARK_RAN
        - not:
            - columnExists:
                tableName: {table}
                columnName: {column}
      changes:
        - addColumn:
            tableName: {table}
            columns:
              - column:
                  name: {column}
                  type: uuid
```

Naming conventions: tables in snake_case singular, named after the aggregate
(`product`), avoiding SQL reserved words (`customer_order`, not `order`); unique
constraint names `uk_{table}_{columns}`; index names `idx_{table}_{column}`; foreign key
names `fk_{table}_{target}`.

**A changeset that has already run is immutable.** Liquibase checksums it. Fix a
mistake with a new changeset, never by editing the old one.

Types in use: `uuid`, `varchar(n)`, `int`, `decimal(p, s)`.

### 2. The JPA entities

```java
package com.example.starter.catalog.infrastructure.persistence.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "product")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ProductEntity {

  @Id
  private UUID id;

  @Column(nullable = false, unique = true, length = 100)
  private String name;

  @Column(nullable = false, precision = 12, scale = 2)
  private BigDecimal price;
}
```

Points that are deliberate:

- **Imports listed one by one**, never `jakarta.persistence.*`.
- `@NoArgsConstructor` is required by JPA; `@AllArgsConstructor` is what the mapper
  calls. Both are there for the framework and the mapper, nobody else.
- **No `@GeneratedValue`.** The identity is minted by the domain (`ProductId.newId()`)
  before the aggregate is saved; the database only stores it.
- `@Table(name = ...)` always explicit. Each `@Column` restates the constraints of its
  changelog column (`nullable`, `unique`, `length`, `precision`/`scale`); give it a
  `name` whenever the field name and the column name differ.

A part of the aggregate with no identity of its own is an `@Embeddable` held in an
`@ElementCollection`:

```java
  @ElementCollection(fetch = FetchType.EAGER)
  @CollectionTable(name = "order_line", joinColumns = @JoinColumn(name = "order_id"))
  private List<OrderLineEntity> lines = new ArrayList<>();
```

```java
@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderLineEntity {

  @Column(name = "product_id", nullable = false)
  private UUID productId;

  @Column(nullable = false)
  private int quantity;
}
```

A JPA entity never embeds a domain type: it holds columns, and the mapper converts.

### 3. The repository

Spring Data, `{Aggregate}JpaRepository`, holding only the derived queries a port needs:

```java
public interface ProductJpaRepository extends JpaRepository<ProductEntity, UUID> {

  Optional<ProductEntity> findByName(String name);
}
```

```java
public interface OrderJpaRepository extends JpaRepository<OrderEntity, UUID> {
}
```

### 4. The persistence mapper

`{Aggregate}EntityMapper` in `persistence/mappers`: a `final` class with a private
constructor and two static directions.

```java
public final class ProductEntityMapper {

  private ProductEntityMapper() {
  }

  public static ProductEntity toEntity(final Product product) {
    return new ProductEntity(product.getId().value(), product.getName().value(), product.getPrice().amount());
  }

  public static Product toDomain(final ProductEntity entity) {
    return new Product(
        new ProductId(entity.getId()),
        new ProductName(entity.getName()),
        new Price(entity.getPrice()));
  }
}
```

**`toDomain` restores the stored identity — `new ProductId(entity.getId())` — and never
mints one** (`ProductId.newId()`, or a `create(...)` factory). Minting would silently
discard the stored identity. This is the single most important line in the whole file.
When the aggregate has split factories, `toDomain` calls `reconstitute(...)`.

Rehydration goes through the value objects, so a row that breaks a rule fails loudly
instead of producing an invalid aggregate.

### 5. The adapter

One adapter per aggregate, implementing every port of that aggregate. It is the only
class allowed to know both worlds:

```java
@Component
@RequiredArgsConstructor
public class ProductAdapter implements ProductRetriever, ProductRetrieverByName, ProductSaver {

  private final ProductJpaRepository repository;

  @Override
  public Optional<Product> retrieve(final ProductId id) {
    return repository.findById(id.value()).map(ProductEntityMapper::toDomain);
  }

  @Override
  public Optional<Product> retrieveByName(final ProductName name) {
    return repository.findByName(name.value()).map(ProductEntityMapper::toDomain);
  }

  @Override
  public void save(final Product product) {
    repository.save(ProductEntityMapper.toEntity(product));
  }
}
```

Named `{Aggregate}Adapter`, in `persistence/adapters`. Ports stay single-method
`@FunctionalInterface`s, so a use case still depends on exactly what it needs; only the
implementation is grouped, so the repository of an aggregate is wired once. Each method
body is one line — translate and delegate. Any logic here is logic that escaped the
domain. `save` inserts a new aggregate; an `update` (for a `{Aggregate}Updater` port)
loads the held entity and applies the change, which JPA dirty checking writes at commit.

The use case is the transaction boundary (`use-case-and-ports.md`) and the adapter's
methods join it. An adapter whose methods may also be called outside a use case marks
them `@Transactional(readOnly = true)` on a read and `@Transactional` on a write. The
starter's adapters are reached only through use cases, and carry none.

> ⚠️ One adapter per port (`{Aggregate}RetrieverAdapter`, `{Aggregate}SaverAdapter`, …)
> is a deviation. Group them in `{Aggregate}Adapter`.

Collections built here are unmodifiable — `Collectors.toUnmodifiableSet()`,
`Stream.toList()` — unless the receiving side must mutate them. A JPA collection field
is such a side: `OrderEntityMapper` copies the lines into a `new ArrayList<>(...)` for
Hibernate.

## Best practices

- The `domain` layer never imports anything from `infrastructure`. The dependency runs
  one way, and ArchUnit checks it.
- A JPA entity is **not** a domain model. Two classes, always, joined by the mapper.
- Adding a Gradle dependency means regenerating the supply-chain files:
  ```bash
  ./gradlew dependencies --write-locks
  ./gradlew --write-verification-metadata sha256 help
  ```

## Checklist

- [ ] The changelog is YAML, sits in its context's folder under `db/changelog/`, is
      numbered after the last file of that folder, and holds one changeset whose id is
      `{context}-{NNN}-{action}`.
- [ ] A new context's folder gets one `includeAll` in `db/changelog/db.changelog-master.yaml`.
- [ ] No existing changeset was edited.
- [ ] `@Table` and `@Column` match the tables and columns Liquibase creates.
- [ ] No `@GeneratedValue`: the domain mints identities.
- [ ] Imports are explicit, no `jakarta.persistence.*`.
- [ ] `toDomain` restores the stored identity, never mints one.
- [ ] One `{Aggregate}Adapter` per aggregate, implementing all its ports, doing nothing
      but translate and delegate.
- [ ] Collections produced by mappers are unmodifiable, except those handed to JPA.
- [ ] No adapter, mapper, repository or JPA test was written.
- [ ] Lockfiles and `verification-metadata.xml` regenerated if a dependency was added.
- [ ] `./gradlew build` is green.
