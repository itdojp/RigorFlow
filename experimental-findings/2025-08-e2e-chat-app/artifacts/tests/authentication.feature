# authentication.feature
# BDD scenarios for authentication system

Feature: User Authentication and Authorization
  As a user of the E2E encrypted chat application
  I want to securely authenticate and manage my sessions
  So that I can access my messages safely

  Background:
    Given the authentication service is running
    And the database is connected

  Scenario: User Registration
    Given I am a new user
    When I register with username "alice" and email "alice@example.com"
    And I provide a strong password "SecurePass123!"
    Then I should receive a registration confirmation
    And my password should be securely hashed
    And I should receive a JWT token
    And my public keys should be generated
    And my user profile should be created in the database

  Scenario: User Login with Valid Credentials
    Given I am a registered user "bob"
    When I login with email "bob@example.com" and password "ValidPass456!"
    Then I should receive a JWT access token
    And I should receive a refresh token
    And the tokens should contain my user ID and permissions
    And my login should be recorded with timestamp
    And my device should be registered for this session

  Scenario: User Login with Invalid Credentials
    Given I am attempting to login
    When I provide incorrect email "wrong@example.com" or password "WrongPass"
    Then I should receive an authentication error
    And the error should not reveal which field was incorrect
    And the failed attempt should be logged
    And rate limiting should be applied after 3 failed attempts

  Scenario: JWT Token Validation
    Given I have a valid JWT token
    When I make an authenticated request to "/api/v1/messages"
    Then my token should be validated
    And my request should be authorized
    And my user context should be available
    And the token expiry should be checked
    And token signature should be verified

  Scenario: Token Refresh
    Given I have an expired access token
    And I have a valid refresh token
    When I request a new access token
    Then I should receive a new JWT access token
    And the old access token should be invalidated
    And my session should continue uninterrupted
    And the refresh token rotation should occur

  Scenario: Logout
    Given I am logged in with active session
    When I logout
    Then my JWT token should be invalidated
    And my refresh token should be revoked
    And my session should be terminated
    And my WebSocket connections should be closed
    And logout should be recorded with timestamp

  Scenario: Password Reset Request
    Given I forgot my password
    When I request a password reset for "alice@example.com"
    Then I should receive a reset token via email
    And the token should expire in 1 hour
    And the reset request should be rate limited
    And previous reset tokens should be invalidated

  Scenario: Password Reset Completion
    Given I have a valid password reset token
    When I set a new password "NewSecurePass789!"
    Then my password should be updated
    And all existing sessions should be terminated
    And I should be required to login again
    And the reset token should be consumed

  Scenario: Multi-Factor Authentication Setup
    Given I am logged in
    When I enable 2FA
    Then I should receive a TOTP secret
    And I should see a QR code
    And I must verify with a valid TOTP code
    And backup codes should be generated
    And 2FA status should be saved

  Scenario: Multi-Factor Authentication Login
    Given I have 2FA enabled
    When I login with correct credentials
    Then I should be prompted for TOTP code
    And I must provide valid TOTP within 30 seconds
    And only then should I receive JWT tokens
    And failed TOTP attempts should be logged

  Scenario: Session Management
    Given I am logged in on multiple devices
    When I view my active sessions
    Then I should see all device sessions
    And I should see login times and locations
    And I should be able to revoke specific sessions
    And revoked sessions should immediately lose access

  Scenario: API Key Authentication
    Given I need programmatic access
    When I generate an API key
    Then I should receive a unique API key
    And the key should have configurable permissions
    And the key should be revocable
    And API key usage should be tracked

  Scenario: OAuth2 Integration
    Given I want to login with external provider
    When I authenticate with "Google OAuth"
    Then I should be redirected to provider
    And upon successful OAuth authentication
    And my account should be linked or created
    And I should receive JWT tokens

  Scenario: Rate Limiting
    Given I am making authentication requests
    When I exceed 5 requests per minute
    Then I should receive rate limit error
    And I should see retry-after header
    And the limit should reset after cooldown
    And persistent violators should be temporarily banned

  Scenario: Account Lockout
    Given I have failed login 5 times
    When I try to login again
    Then my account should be temporarily locked
    And I should receive lockout notification
    And I should wait 15 minutes before retry
    And admin should be notified of suspicious activity