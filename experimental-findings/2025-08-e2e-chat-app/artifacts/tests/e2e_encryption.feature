@security @critical
Feature: End-to-End Encryption
  As a security-conscious user
  I want my messages to be end-to-end encrypted
  So that only the intended recipient can read them

  Background:
    Given the system uses the following cryptographic algorithms:
      | Algorithm Type | Implementation |
      | Symmetric      | AES-256-GCM    |
      | Key Exchange   | X25519         |
      | Signature      | Ed25519        |
      | KDF            | HKDF-SHA256    |
    And the Double Ratchet protocol is properly initialized
    And all users have valid identity keys

  @smoke @encryption
  Scenario: Basic message encryption between two users
    Given Alice and Bob are registered users
    And Alice and Bob have performed X3DH key exchange
    When Alice sends the message "Hello, Bob!" to Bob
    Then the message should be encrypted with AES-256-GCM
    And the message should include a valid authentication tag
    And Bob should be able to decrypt the message
    And the decrypted message should be "Hello, Bob!"
    And Eve should not be able to decrypt the message

  @pfs @critical
  Scenario: Perfect Forward Secrecy verification
    Given Alice and Bob have an established session
    And they have exchanged the following messages:
      | Sender | Message              | Message Number |
      | Alice  | First message        | 1              |
      | Bob    | Second message       | 2              |
      | Alice  | Third message        | 3              |
      | Bob    | Fourth message       | 4              |
      | Alice  | Fifth message        | 5              |
    When the current session key is compromised at message 5
    Then messages 1 through 4 should remain secure
    And future messages should use new keys
    And the compromised key cannot decrypt previous messages

  @double-ratchet
  Scenario: Double Ratchet key evolution
    Given Alice and Bob have an active session
    When Alice sends a message to Bob
    Then Alice's sending chain key should advance
    And a new message key should be derived
    When Bob replies to Alice
    Then a DH ratchet step should occur
    And both root keys should be updated
    And new chain keys should be established
    And old keys should be deleted from memory

  @replay-attack
  Scenario: Replay attack prevention
    Given Alice sends message M with nonce N to Bob
    And Bob successfully receives and decrypts message M
    When Eve intercepts and replays message M
    Then Bob should detect the replay attempt
    And Bob should reject the replayed message
    And a security alert should be generated with details:
      | Alert Type    | Replay Attack Detected |
      | Severity      | High                   |
      | Action Taken  | Message Rejected       |

  @out-of-order
  Scenario: Out-of-order message handling
    Given Alice and Bob have an active session
    When Alice sends messages in this order:
      | Message | Content      | Sequence |
      | M1      | First        | 1        |
      | M2      | Second       | 2        |
      | M3      | Third        | 3        |
    And Bob receives messages in this order:
      | Message | Sequence |
      | M2      | 2        |
      | M3      | 3        |
      | M1      | 1        |
    Then Bob should be able to decrypt all messages
    And Bob should store skipped message keys temporarily
    And the messages should be displayed in correct order

  @key-verification
  Scenario: Security number verification
    Given Alice and Bob have established a session
    When Alice views Bob's security number
    And Bob views Alice's security number
    Then both should see the same 60-digit number
    And the number should be derived from their identity keys
    And they should be able to verify via QR code
    And successful verification should mark the session as trusted

  @multi-device
  Scenario: Multi-device message synchronization
    Given Alice has devices:
      | Device Name | Device Type |
      | Phone       | Mobile      |
      | Laptop      | Desktop     |
    And Bob sends a message to Alice
    When Alice's Phone receives the message
    Then the message should be encrypted separately for each device
    And Alice's Laptop should also receive the message
    And both devices should decrypt to the same plaintext
    And sender verification should succeed on both devices

  @session-reset
  Scenario: Session reset and re-establishment
    Given Alice and Bob have an active session
    And they have exchanged 100 messages
    When Alice initiates a session reset
    Then all existing keys should be deleted
    And a new X3DH exchange should occur
    And new session keys should be established
    And old messages should remain readable
    But old keys cannot decrypt new messages

  @metadata-protection
  Scenario: Metadata minimization
    Given Alice sends a message to Bob
    When the message transits through the server
    Then the server should only see:
      | Visible Data     | Purpose                |
      | Sender ID        | Routing                |
      | Receiver ID      | Routing                |
      | Timestamp        | Ordering               |
      | Encrypted Blob   | Message Storage        |
    And the server should not see:
      | Hidden Data      | Protection Method      |
      | Message Content  | E2E Encryption         |
      | Message Type     | Encrypted in Header    |
      | Conversation     | Derived Client-side    |

  @key-exhaustion
  Scenario: One-time prekey exhaustion handling
    Given Bob has 10 one-time prekeys remaining
    When 10 different users initiate sessions with Bob
    Then all one-time prekeys should be consumed
    When Alice attempts to initiate a new session
    Then the signed prekey should be used instead
    And Bob should be notified to upload new one-time prekeys
    And the session should still establish successfully

  @algorithm-agility
  Scenario Outline: Cryptographic algorithm support
    Given the system supports <algorithm_type>
    When a message is encrypted using <algorithm>
    Then the message should be properly encrypted
    And the recipient should successfully decrypt
    And performance should meet requirements

    Examples:
      | algorithm_type | algorithm         |
      | AEAD          | AES-256-GCM       |
      | AEAD          | ChaCha20-Poly1305 |
      | KDF           | HKDF-SHA256       |
      | KDF           | HKDF-SHA512       |

  @performance
  Scenario: Encryption performance requirements
    Given a message of size <message_size>
    When the message is encrypted
    Then encryption time should be less than <max_time>
    And memory usage should be less than <max_memory>

    Examples:
      | message_size | max_time | max_memory |
      | 1 KB        | 10 ms    | 1 MB       |
      | 100 KB      | 50 ms    | 5 MB       |
      | 1 MB        | 100 ms   | 10 MB      |

  @compliance
  Scenario: Regulatory compliance verification
    Given the system processes user data
    Then the following compliance requirements should be met:
      | Regulation | Requirement                           | Status    |
      | GDPR      | Data encrypted at rest                | Compliant |
      | GDPR      | Data encrypted in transit             | Compliant |
      | GDPR      | Right to erasure supported            | Compliant |
      | HIPAA     | 256-bit encryption minimum            | Compliant |
      | PCI DSS   | Strong cryptography requirements      | Compliant |