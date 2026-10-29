# Recipe — HTTP endpoint: DTOs, mappers, controller, error mapping

## Purpose

Expose a use case over HTTP without letting a domain type or an exception leak out of
the boundary.

## When to use

A use case exists and is green under its behaviour test, and it must now be reachable.

> The behaviour tests instantiate the use case directly and never go through HTTP, so
> this layer is not driven by a RED test either. Write the thinnest possible shell.

## The order

Request DTO → response DTO → mapper → controller. Error mapping is already in place;
check it before adding a handler.

### 1. The request DTO

A `record` in `presentation/dto/request`, named `{UseCase}RequestDto`, mirroring the JSON
body field for field:

```java
package com.example.starter.catalog.presentation.dto.request;

import jakarta.validation.constraints.Digits;
import java.math.BigDecimal;

public record AddProductRequestDto(
    String name,
    @Digits(integer = 10, fraction = 2, message = "The price exceeds what can be stored") BigDecimal price) {
}
```

A nested JSON object or array element is a second request DTO of its own, in the same
package:

```java
public record PlaceOrderRequestDto(
    List<@NotNull(message = "An order line is required") @Valid PlaceOrderLineRequestDto> lines) {
}

public record PlaceOrderLineRequestDto(UUID productId, int quantity) {
}
```

- The business rules on the values — a blank name, a length, a bound — are the value
  objects' (`ProductName`, `Quantity`), not the DTO's. They hold whatever the entry point,
  and the refusal comes back through `GlobalExceptionHandler`.
- Jakarta validation (`spring-boot-starter-validation` is on the classpath) is for what
  only the transport can check. Every constraint then carries a message naming the field,
  never listing the values it may take; the controller parameter takes `@Valid`, and a
  nested DTO or collection field takes `@Valid` too, or its constraints are silently
  skipped. `GlobalExceptionHandler` already turns `MethodArgumentNotValidException` into an
  enveloped 400. The starter uses it twice: the price column's precision
  (`@Digits(integer = 10, fraction = 2)`, so an oversized price is a 400, not a database
  error at commit), and a `null` order line.
- Path variables are **not** DTO fields. They arrive as `@PathVariable` and are passed
  to the mapper separately.

### 2. The response DTO

A `record` in `presentation/dto/response`, named `{UseCase}ResponseDto`:

```java
package com.example.starter.catalog.presentation.dto.response;

import java.util.UUID;

public record AddProductResponseDto(UUID productId) {
}
```

A response DTO must never expose a domain type: identifiers cross the wire as a `UUID`
or a `String`, never as a value object. A shape shared by two responses gets its own
top-level DTO; one response never reuses another response's nested type.

### 3. The mapper

One per use case, named `{UseCase}Mapper`, in `presentation/mapper`, holding both
directions: `toCommand` turns HTTP input into a command, `toResponse` turns the use case
result into a response DTO. Do not split a use case's mapping into a request mapper and a
response mapper.

```java
package com.example.starter.ordering.presentation.mapper;

public final class PlaceOrderMapper {

  private PlaceOrderMapper() {
  }

  public static PlaceOrderCommand toCommand(final PlaceOrderRequestDto request) {
    final var lines = request.lines() == null
        ? List.<PlaceOrderLineCommand>of()
        : request.lines().stream()
            .map(line -> new PlaceOrderLineCommand(line.productId(), line.quantity()))
            .toList();
    return new PlaceOrderCommand(lines);
  }

  public static PlaceOrderResponseDto toResponse(final PlaceOrderResult result) {
    return new PlaceOrderResponseDto(result.orderId());
  }
}
```

A `final` class with a private constructor and static methods: a mapper holds no state
and injects nothing. A path variable is an extra parameter of `toCommand`.

### 4. The controller

```java
@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

  private final AddProductUseCase addProduct;

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public ApiResponse<AddProductResponseDto> add(@Valid @RequestBody final AddProductRequestDto request) {
    final var result = addProduct.execute(AddProductMapper.toCommand(request));
    return ApiResponse.ok(AddProductMapper.toResponse(result));
  }
}
```

Class-level: `@RestController`, `@RequestMapping("/api/{plural-resource}")`,
`@RequiredArgsConstructor`, use cases injected as `private final` fields — one per
endpoint, named after the action.

Per method: the HTTP verb mapping, `@ResponseStatus` when the status is not 200
(`CREATED` on a creation), `@Valid @RequestBody` on the input.

**One line per object.** The body reads as the steps of the endpoint: a `final` local
for the command, one for the result, then the `ApiResponse` factory around the mapped
response. No call nested inside another — a nested `useCase.execute(mapper.toCommand(...))`
hides the command, and with it the type the use case receives. The starter's controllers
still nest it; in new code write:

```java
    final AddProductCommand command = AddProductMapper.toCommand(request);
    final AddProductResult result = addProduct.execute(command);
    return ApiResponse.ok(AddProductMapper.toResponse(result));
```

**No `@ExceptionHandler` in a controller, no `try/catch`.** Every status mapping lives in
`GlobalExceptionHandler` (§ 6).

Routing conventions:

| Verb | Path | Intent |
|---|---|---|
| `POST` | `/api/products`, `/api/orders` | create |
| `GET` | `/api/{resources}/{id}` | read one |
| `GET` | `/api/{resources}/{id}/{part}` | read a part |
| `POST` | `/api/{resources}/{id}/{parts}` | add to a sub-collection |

> ⚠️ Never unwrap a legacy `Result<T>` with `.getValue().orElseThrow()`: it turns a
> business failure into a `NoSuchElementException` and short-circuits the failure
> channel. With a `{UseCase}Result`, the use case throws on failure and
> `GlobalExceptionHandler` maps the exception.

### 5. The envelope

Every response body goes through `ApiResponse<T>` in `core.presentation.dtos.responses`:

```java
public record ApiResponse<T>(T data, String error) {

  public static <T> ApiResponse<T> ok(final T data) {
    return new ApiResponse<>(data, null);
  }

  public static <T> ApiResponse<T> error(final String error) {
    return new ApiResponse<>(null, error);
  }
}
```

A success is `{"data":{...},"error":null}`, a refusal `{"data":null,"error":"<message>"}`.
Return `ApiResponse.ok(...)` and set the status with `@ResponseStatus`; do not build a
`ResponseEntity` in a controller. A new factory goes in `ApiResponse` itself, the first
time a use case needs it.

### 6. Error mapping — read before adding a handler

`core.infrastructure.handlers.GlobalExceptionHandler` is the one `@RestControllerAdvice`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

  @ExceptionHandler(DomainException.class)
  public ResponseEntity<ApiResponse<Void>> handleDomainException(final DomainException exception) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error(exception.getMessage()));
  }
}
```

| Exception | Status |
|---|---|
| **`DomainException`** and every subclass — domain and application refusals | **400**, enveloped |
| **`MethodArgumentNotValidException`** — a request DTO constraint failed | **400**, enveloped, first constraint message |
| anything else | Spring's default |

Because every refusal of the domain and application layers extends `DomainException`
(`use-case-and-ports.md`), **a new refusal needs no handler**. It inherits 400
automatically. Add a handler only when a specific exception genuinely deserves a
different status — a not-found base mapped to 404, for instance — and then add it in `GlobalExceptionHandler`, enveloped
through an `ApiResponse` factory, never as a `try/catch` or an `@ExceptionHandler` in
the controller.

## Best practices

- A controller does three things: map input, call one use case, map output. Any `if` on
  business state there belongs in the domain.
- No domain type in any DTO, in either direction.
- No `try/catch` in a controller. The advice handles it.
- Read `docs/domain/glossary.md` before naming a route or a DTO field. The URL is part
  of the ubiquitous language.

## Checklist

- [ ] Request and response DTOs are records named `{UseCase}RequestDto` /
      `{UseCase}ResponseDto`, in `dto/request` and `dto/response`.
- [ ] No business rule duplicated in a DTO; any Jakarta constraint carries a message
      naming the field and listing no value, with `@Valid` on nested DTOs and collections.
- [ ] No DTO exposes a domain type.
- [ ] One `{UseCase}Mapper` per use case holding `toCommand` and `toResponse`, `final`,
      static, stateless.
- [ ] Each controller method has one `final` local per object and no nested call.
- [ ] The body is built by an `ApiResponse` factory; the status by `@ResponseStatus`.
- [ ] No `.orElseThrow()` unwrapping of a result, no `try/catch`, no `@ExceptionHandler`
      in the controller.
- [ ] Any new exception either falls under an existing `GlobalExceptionHandler` mapping
      or gets one there.
- [ ] `./gradlew build` is green.
