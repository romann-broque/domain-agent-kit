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
