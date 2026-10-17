package com.example.starter.ordering.infrastructure.acl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.example.starter.catalog.application.ports.ProductRetriever;
import com.example.starter.catalog.domain.models.valueobjects.ProductId;
import com.example.starter.fixture.catalog.domain.aggregates.ProductFixture;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class OrderedProductCheckerAclTest {

  private static final UUID PRODUCT_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

  private ProductRetriever productRetriever;
  private OrderedProductCheckerAcl acl;

  @BeforeEach
  void setUp() {
    productRetriever = mock(ProductRetriever.class);
    acl = new OrderedProductCheckerAcl(productRetriever);
  }

  @Test
  void aProductKnownByTheCatalogExists() {
    when(productRetriever.retrieve(new ProductId(PRODUCT_ID)))
        .thenReturn(Optional.of(ProductFixture.buildDefault()));

    assertThat(acl.exists(PRODUCT_ID)).isTrue();
  }

  @Test
  void aProductUnknownByTheCatalogDoesNotExist() {
    when(productRetriever.retrieve(new ProductId(PRODUCT_ID))).thenReturn(Optional.empty());

    assertThat(acl.exists(PRODUCT_ID)).isFalse();
  }
}
