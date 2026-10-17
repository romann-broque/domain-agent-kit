# Covers: US1, FR-001, FR-002, FR-003, FR-004
Feature: Place an order
  As a user
  I want to order products from the catalog
  So that they are reserved for me in the quantities I asked for

  Background:
    Given the catalog knows the products "Desk lamp" and "Notebook"

  Rule: Every ordered product must be known by the catalog

    Scenario: ✅ Order with known products
      When the user orders
        | product   | quantity |
        | Desk lamp | 2        |
        | Notebook  | 1        |
      Then the order is kept with the lines
        | product   | quantity |
        | Desk lamp | 2        |
        | Notebook  | 1        |
      And the order is announced

    Scenario: ❌ Unknown product
      When the user orders
        | product   | quantity |
        | Desk lamp | 1        |
        | Ghost     | 1        |
      Then the order is refused because "Ghost" is unknown

  Rule: An order holds at least one line, each with a quantity between 1 and 999

    Scenario: ❌ No lines
      When the user orders nothing
      Then the order is refused and nothing is kept

    Scenario: ❌ Quantity 0
      When the user orders
        | product   | quantity |
        | Desk lamp | 0        |
      Then the order is refused and nothing is kept

  Rule: Lines for the same product are merged

    Scenario: ✅ Two lines for the same product
      When the user orders
        | product   | quantity |
        | Desk lamp | 2        |
        | Desk lamp | 3        |
      Then the order is kept with the lines
        | product   | quantity |
        | Desk lamp | 5        |
      And the order is announced
