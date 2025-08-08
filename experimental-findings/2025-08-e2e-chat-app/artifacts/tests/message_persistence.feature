# message_persistence.feature
# BDD scenarios for message persistence

Feature: Message Persistence and Storage
  As a user of the E2E encrypted chat application
  I want my messages to be securely stored and retrievable
  So that I can access conversation history and ensure message delivery

  Background:
    Given the message service is running
    And the database is connected
    And I am authenticated as "alice"

  Scenario: Send and Store Text Message
    Given I have an active chat session with "bob"
    When I send a message "Hello Bob!"
    Then the message should be saved to the database
    And the message should have a unique ID
    And the message should be timestamped
    And the message should be marked as "sent"
    And the encrypted content should be stored
    And the encryption headers should be preserved

  Scenario: Retrieve Message History
    Given I have previous messages with "bob"
    When I request message history for our conversation
    Then I should receive the last 50 messages by default
    And messages should be ordered by timestamp descending
    And each message should include sender information
    And encrypted messages should remain encrypted
    And pagination info should be included

  Scenario: Message Pagination
    Given I have 100 messages with "charlie"
    When I request page 2 with limit 20
    Then I should receive messages 21-40
    And I should receive pagination metadata
    And the total count should be 100
    And next/previous page indicators should be correct

  Scenario: Search Messages
    Given I have messages containing various keywords
    When I search for messages containing "meeting"
    Then I should receive only messages with that keyword
    And search should work across all my conversations
    And results should be ordered by relevance
    And search should respect encryption boundaries

  Scenario: Message Delivery Status
    Given I send a message to "diana"
    When the message is stored
    Then the status should be "sent"
    When "diana" receives the message
    Then the status should update to "delivered"
    When "diana" reads the message
    Then the status should update to "read"
    And status updates should be persisted

  Scenario: Offline Message Queue
    Given "eve" is offline
    When I send messages to "eve"
    Then messages should be queued in the database
    And messages should have status "pending"
    When "eve" comes online
    Then queued messages should be delivered
    And delivery status should be updated

  Scenario: Message Deletion
    Given I have a message with ID "msg123"
    When I delete the message
    Then the message should be marked as deleted
    And the message content should be removed
    And the message should not appear in history
    But the message metadata should be retained
    And other users should see "Message deleted"

  Scenario: Edit Message
    Given I sent a message "Original text"
    When I edit the message to "Updated text"
    Then the new content should be saved
    And the edit timestamp should be recorded
    And edit history should be maintained
    And other users should see the update
    And "Edited" indicator should be shown

  Scenario: Message Reactions
    Given there is a message from "frank"
    When I add a reaction "👍"
    Then the reaction should be stored
    And the reaction should be associated with my user
    And other users should see the reaction
    When I remove the reaction
    Then it should be deleted from storage

  Scenario: Thread Replies
    Given there is a message "Start a thread"
    When I reply in thread with "Thread reply"
    Then the reply should be linked to parent message
    And thread count should increment
    And thread participants should be tracked
    And thread messages should be retrievable

  Scenario: File Attachment Storage
    Given I want to send an image file
    When I upload "photo.jpg" (2MB)
    Then the file should be stored securely
    And file metadata should be saved
    And a file ID should be generated
    And the message should reference the file
    And file should be retrievable by authorized users

  Scenario: Message Expiration
    Given I send an ephemeral message with 1 hour expiry
    When the message is stored
    Then expiry time should be set
    And after 1 hour passes
    Then the message should be auto-deleted
    And deletion should be propagated to all clients

  Scenario: Backup and Restore
    Given I have 500 messages in various conversations
    When I request a backup
    Then all messages should be exported
    And export should include encryption keys
    And export format should be portable
    When I restore from backup
    Then all messages should be recovered
    And conversation state should be preserved

  Scenario: Storage Quotas
    Given each user has 1GB storage quota
    When I approach the storage limit
    Then I should receive a warning at 90% usage
    When I exceed the quota
    Then new message uploads should fail
    And I should be prompted to delete old content

  Scenario: Database Failover
    Given messages are being stored
    When the primary database fails
    Then the system should failover to replica
    And no messages should be lost
    And write operations should resume
    And consistency should be maintained

  Scenario: Message Sync Across Devices
    Given I am logged in on multiple devices
    When I send a message from device A
    Then it should appear on device B
    And read status should sync
    And deleted messages should sync
    And edit history should sync

  Scenario: Conversation Metadata
    Given I have a conversation with "grace"
    When I view conversation info
    Then I should see message count
    And I should see first message date
    And I should see last message date
    And I should see media count
    And I should see participant list

  Scenario: Archive Conversations
    Given I have an old conversation with "henry"
    When I archive the conversation
    Then it should be moved to archive storage
    And it should not appear in active chats
    But messages should remain searchable
    And I should be able to unarchive it

  Scenario: GDPR Compliance - Data Export
    Given I request my data under GDPR
    When the export is generated
    Then all my messages should be included
    And all metadata should be included
    And format should be machine-readable
    And export should be completed within 30 days

  Scenario: GDPR Compliance - Right to Erasure
    Given I request account deletion
    When the deletion is processed
    Then all my messages should be removed
    And all my files should be deleted
    And my user data should be purged
    But audit logs should be retained
    And deletion should be irreversible