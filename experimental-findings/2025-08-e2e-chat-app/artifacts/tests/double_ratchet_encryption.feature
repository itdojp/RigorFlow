# double_ratchet_encryption.feature
# BDD scenarios for Double Ratchet E2E encryption

Feature: End-to-End Encryption with Double Ratchet Protocol
  As a user of the secure chat application
  I want my messages to be end-to-end encrypted with Perfect Forward Secrecy
  So that my communications remain private even if keys are compromised

  Background:
    Given the encryption service is initialized
    And I am authenticated as "alice"
    And "bob" is another authenticated user

  Scenario: Initial Key Exchange (X3DH)
    Given I want to start an encrypted conversation with "bob"
    And "bob" has published his prekey bundle
    When I fetch "bob"'s prekey bundle containing:
      | identity_key    | IK_bob      |
      | signed_prekey   | SPK_bob     |
      | signature       | Sig_SPK     |
      | one_time_prekey | OPK_bob     |
    And I perform the X3DH key agreement
    Then I should derive a shared secret
    And I should initialize the Double Ratchet with:
      | shared_secret   | From X3DH   |
      | bob_public_key  | From bundle |
    And the root key should be established
    And sending/receiving chains should be initialized

  Scenario: Send First Encrypted Message
    Given I have completed key exchange with "bob"
    And I have initialized my Double Ratchet session
    When I encrypt the message "Hello Bob, this is Alice!"
    Then the message should be encrypted with current sending chain key
    And a new message key should be derived
    And the sending chain should ratchet forward
    And the encrypted message should include:
      | ciphertext      | Encrypted content    |
      | header.dh       | My public DH key     |
      | header.pn       | Previous chain length |
      | header.n        | Message number       |
    And the message key should be deleted after use

  Scenario: Receive and Decrypt Message
    Given "bob" has sent me an encrypted message
    And the message header contains his DH public key
    When I receive the encrypted message
    Then I should perform a DH ratchet step if needed
    And I should derive the correct message key
    And I should decrypt the message successfully
    And I should delete the used message key
    And I should advance the receiving chain

  Scenario: Bidirectional Communication
    Given I have an active encrypted session with "bob"
    When I send "Message 1 from Alice"
    And "bob" sends "Reply 1 from Bob"
    And I send "Message 2 from Alice"
    And "bob" sends "Reply 2 from Bob"
    Then all messages should be encrypted with different keys
    And each DH ratchet should generate new root keys
    And old message keys should be deleted
    And Perfect Forward Secrecy should be maintained

  Scenario: Out-of-Order Message Delivery
    Given "bob" sends me messages in sequence:
      | message_num | content        |
      | 1          | "First message"  |
      | 2          | "Second message" |
      | 3          | "Third message"  |
    When I receive them out of order: [3, 1, 2]
    Then I should store skipped message keys
    And I should decrypt message 3 first
    And I should decrypt message 1 using stored keys
    And I should decrypt message 2 using stored keys
    And all messages should be readable
    And skipped keys should be deleted after use

  Scenario: Key Ratcheting and Forward Secrecy
    Given I have sent 10 messages to "bob"
    When my current chain key is compromised
    Then previous messages should remain secure
    And future messages should use new keys
    And the compromise should not affect past communications
    And each message should have used a unique key

  Scenario: Session Recovery After Disconnect
    Given I have an active session with "bob"
    And we have exchanged 5 messages
    When I disconnect and reconnect
    Then I should restore my ratchet state
    And I should maintain message continuity
    And I should be able to continue the conversation
    And no messages should be lost
    And encryption should continue seamlessly

  Scenario: Simultaneous Message Sending
    Given both "alice" and "bob" have active sessions
    When we both send messages simultaneously
    Then both messages should be encrypted
    And both should trigger DH ratchets
    And both parties should handle the race condition
    And all messages should be decryptable
    And chains should converge correctly

  Scenario: Message Key Limits
    Given I have sent 1000 messages in one chain
    When I reach the chain key derivation limit
    Then a new DH ratchet should be triggered
    And a fresh root key should be generated
    And the chain should reset
    And security should be maintained

  Scenario: Skipped Message Key Storage
    Given "bob" sends 100 messages
    And I haven't received messages 50-60
    When I receive message 100
    Then I should store keys for messages 50-99
    And storage should have a maximum limit
    And old skipped keys should be pruned
    And I should still decrypt late messages 50-60

  Scenario: Identity Verification
    Given I have "bob"'s identity key fingerprint
    When I receive messages from "bob"
    Then each message should be authenticated
    And I should verify the sender's identity
    And I should detect any key substitution attacks
    And I should warn about identity changes

  Scenario: Group Message Encryption
    Given I am in a group with "bob" and "charlie"
    When I send a group message "Hello everyone!"
    Then I should encrypt it separately for each recipient
    And each should use their respective Double Ratchet session
    And each recipient should decrypt with their keys
    And forward secrecy should be maintained per recipient

  Scenario: Key Backup and Restoration
    Given I want to backup my encryption keys
    When I export my key material
    Then the export should be encrypted with a passphrase
    And it should include all active sessions
    And it should preserve ratchet states
    When I restore from backup on a new device
    Then all sessions should be recovered
    And I should continue conversations seamlessly

  Scenario: Ephemeral Message Encryption
    Given I send an ephemeral message to "bob"
    And the message has a 1-hour expiry
    When the message is encrypted
    Then it should include expiry metadata
    And the key should be marked for deletion
    And after expiry, the message should be undecryptable
    And the key should be permanently deleted

  Scenario: Attachment Encryption
    Given I want to send an encrypted file "document.pdf"
    When I encrypt the attachment
    Then the file should be encrypted with AES-256-GCM
    And the file key should be encrypted with Double Ratchet
    And the encrypted file should be stored separately
    And only "bob" should be able to decrypt it

  Scenario: Re-keying After Compromise
    Given my device might be compromised
    When I initiate a re-keying process
    Then a new X3DH exchange should occur
    And all old keys should be invalidated
    And new Double Ratchet sessions should start
    And previous message history should remain encrypted
    And future messages should use entirely new keys

  Scenario: Message Authentication Codes
    Given I send an encrypted message to "bob"
    When the message is encrypted
    Then it should include an HMAC
    And the MAC key should be derived from the chain
    And "bob" should verify the MAC before decryption
    And tampering should be detected
    And modified messages should be rejected

  Scenario: Protocol Version Negotiation
    Given "bob" uses Double Ratchet protocol v2
    And I use Double Ratchet protocol v1
    When we establish a session
    Then we should negotiate the common version
    And fall back to compatible encryption
    And maintain backward compatibility
    And upgrade when both parties support newer version

  Scenario: Rate Limiting Key Operations
    Given I am under a key exhaustion attack
    When excessive key derivation is attempted
    Then rate limiting should be applied
    And key operations should be throttled
    And legitimate operations should continue
    And the attack should be logged

  Scenario: Secure Key Deletion
    Given I have finished a conversation with "bob"
    When I delete the conversation
    Then all message keys should be securely wiped
    And chain keys should be overwritten
    And root keys should be zeroed
    And no cryptographic material should remain in memory
    And deleted keys should be unrecoverable