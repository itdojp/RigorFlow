Feature: WebSocket Real-time Communication
  As a chat application user
  I want to send and receive messages in real-time
  So that I can have instant conversations with other users

  Background:
    Given the message service is running
    And the WebSocket endpoint is available at "ws://localhost:8081/ws"

  Scenario: Establish WebSocket connection
    Given I am a registered user "Alice"
    When I connect to the WebSocket endpoint
    Then the connection should be established successfully
    And I should receive a connection acknowledgment
    And the server should track my connection

  Scenario: Send encrypted message
    Given I have an active WebSocket connection
    And I have established a secure session with "Bob"
    When I send an encrypted message "Hello Bob"
    Then the message should be encrypted with the session key
    And the message should be sent through WebSocket
    And I should receive a delivery confirmation

  Scenario: Receive encrypted message
    Given I have an active WebSocket connection
    And "Bob" has sent me an encrypted message
    When the message arrives through WebSocket
    Then I should receive the message immediately
    And the message should be decrypted with the session key
    And I should send a read receipt

  Scenario: Handle multiple simultaneous connections
    Given multiple users are connected:
      | username |
      | Alice    |
      | Bob      |
      | Charlie  |
    When Alice sends a message to Bob
    Then only Bob should receive the message
    And Charlie should not receive the message
    And the server should route the message correctly

  Scenario: Connection recovery
    Given I have an active WebSocket connection
    When my connection is interrupted
    And I reconnect within 30 seconds
    Then my session should be restored
    And I should receive any missed messages
    And the message order should be preserved

  Scenario: Typing indicators
    Given I have an active WebSocket connection
    And I have a chat session with "Bob"
    When I start typing a message
    Then a typing indicator should be sent to Bob
    When I stop typing for 3 seconds
    Then the typing indicator should be cleared

  Scenario: Presence updates
    Given I have an active WebSocket connection
    When another user "Bob" comes online
    Then I should receive a presence update for Bob
    When Bob goes offline
    Then I should receive an offline notification for Bob

  Scenario: Rate limiting
    Given I have an active WebSocket connection
    When I send 100 messages within 1 minute
    Then the first 100 messages should be accepted
    When I send the 101st message
    Then I should receive a rate limit error
    And I should be informed to wait before sending more messages

  Scenario: Connection heartbeat
    Given I have an active WebSocket connection
    When 30 seconds pass without activity
    Then the server should send a ping message
    And I should respond with a pong message
    And the connection should remain active

  Scenario: Graceful disconnection
    Given I have an active WebSocket connection
    When I close the application properly
    Then a disconnect message should be sent
    And the server should clean up my session
    And other users should be notified of my offline status