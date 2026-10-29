# Covers: US1, FR-001, FR-002, FR-003
Feature: Add a product
  As a user
  I want to add a product to the catalog
  So that it can be ordered at a known price

  Rule: A product needs a valid name and price

    Scenario: ✅ Valid product
      Given the catalog holds no product named "Desk lamp"
      When the user adds a product named "Desk lamp" priced 24.90
      Then the product is kept with the name "Desk lamp" and the price 24.90
      And the addition is announced

    Scenario: ❌ Blank name
      When the user adds a product named "   " priced 24.90
      Then the addition is refused and no product is kept

    Scenario: ❌ Zero price
      When the user adds a product named "Desk lamp" priced 0
      Then the addition is refused and no product is kept

  Rule: Names are unique

    Scenario: ❌ Duplicate name
      Given the catalog already holds a product named "Desk lamp"
      When the user adds a product named "Desk lamp" priced 19.00
      Then the addition is refused and no product is kept
