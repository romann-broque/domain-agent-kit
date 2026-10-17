package com.example.starter;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class StarterApplicationSmokeTest {

  @Autowired
  private MockMvc mockMvc;

  @Test
  void aProductCanBeAddedThenOrdered() throws Exception {
    final String added = mockMvc.perform(post("/api/products")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"name\":\"Desk lamp\",\"price\":24.90}"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.data.productId").exists())
        .andReturn().getResponse().getContentAsString();
    final String productId = JsonPath.read(added, "$.data.productId");

    mockMvc.perform(post("/api/orders")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"lines\":[{\"productId\":\"" + productId + "\",\"quantity\":2}]}"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.data.orderId").exists());
  }

  @Test
  void anInvalidProductIsRefusedWithABadRequest() throws Exception {
    mockMvc.perform(post("/api/products")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"name\":\" \",\"price\":24.90}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").exists());
  }

  @Test
  void aPriceBeyondWhatCanBeStoredIsRefusedWithABadRequest() throws Exception {
    mockMvc.perform(post("/api/products")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"name\":\"Big lamp\",\"price\":99999999999999}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").exists());
  }

  @Test
  void aMissingOrderLineIsRefusedWithABadRequest() throws Exception {
    mockMvc.perform(post("/api/orders")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"lines\":[null]}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").exists());
  }
}
