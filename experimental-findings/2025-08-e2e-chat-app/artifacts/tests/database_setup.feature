Feature: Database Environment Setup
  As a system administrator
  I want to set up the database environment
  So that the application can store and retrieve encrypted messages

  Background:
    Given the system requirements are met
    And Podman or Docker is installed

  Scenario: PostgreSQL database startup
    Given PostgreSQL is not running
    When I start PostgreSQL with correct configuration
    Then PostgreSQL should be accessible on port 5432
    And the database "chatdb" should exist
    And the user "chatuser" should have access

  Scenario: Database initialization
    Given PostgreSQL is running
    And the database "chatdb" exists
    When I run the initialization script "scripts/init.sql"
    Then the following tables should exist:
      | table_name        |
      | users            |
      | sessions         |
      | messages         |
      | prekeys          |
      | devices          |
      | message_receipts |
      | audit_log        |
    And all required indexes should be created
    And initial test data should be inserted

  Scenario: Redis cache startup
    Given Redis is not running
    When I start Redis with correct configuration
    Then Redis should be accessible on port 6379
    And Redis should respond to PING with PONG

  Scenario: Database connection from application
    Given PostgreSQL is running on port 5432
    And Redis is running on port 6379
    When the application starts
    Then it should successfully connect to PostgreSQL
    And it should successfully connect to Redis
    And health check endpoint should return "healthy"

  Scenario: Database connection failure handling
    Given PostgreSQL is not running
    When the application attempts to connect
    Then it should log the connection error
    And it should retry connection 3 times
    And health check should return "unhealthy" with database status "disconnected"