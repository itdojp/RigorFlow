/* Alloy model for Double Ratchet Algorithm verification */

// Key types
abstract sig Key {}
sig DHKey extends Key {}
sig ChainKey extends Key {}
sig MessageKey extends Key {}
sig RootKey extends Key {}

// Users in the system
abstract sig User {
  dhKeys: set DHKey,
  rootKey: one RootKey,
  sendChain: one ChainKey,
  recvChain: one ChainKey,
  messageKeys: set MessageKey,
  sessions: set Session
}

sig Alice extends User {}
sig Bob extends User {}

// Session between two users
sig Session {
  participants: set User,
  sharedSecret: one Key,
  messages: seq Message,
  ratchetCount: Int
} {
  #participants = 2  // Exactly two participants
  ratchetCount >= 0
}

// Messages in the protocol
sig Message {
  sender: one User,
  receiver: one User,
  msgKey: one MessageKey,
  content: one Content,
  header: one Header,
  sequenceNum: Int
} {
  sender != receiver  // Cannot send to self
  sequenceNum >= 0
}

// Message content (encrypted)
sig Content {
  ciphertext: seq Int
}

// Message header
sig Header {
  dhPublic: one DHKey,
  previousChainLength: Int,
  messageNumber: Int
} {
  previousChainLength >= 0
  messageNumber >= 0
}

// Key derivation relation
sig KeyDerivation {
  parent: one Key,
  child: one Key,
  derivationType: one DerivationType
} {
  parent != child  // Derived key must be different
}

abstract sig DerivationType {}
one sig KDF_RK extends DerivationType {}  // Root key derivation
one sig KDF_CK extends DerivationType {}  // Chain key derivation
one sig KDF_MK extends DerivationType {}  // Message key derivation

// Facts (invariants)

// Fact: Keys must be unique across the system
fact UniqueKeys {
  // No key can be both DH and Chain key
  no (DHKey & ChainKey)
  no (DHKey & MessageKey)
  no (ChainKey & MessageKey)
  
  // Each message uses a unique message key
  all disj m1, m2: Message | m1.msgKey != m2.msgKey
}

// Fact: Session consistency
fact SessionConsistency {
  // All messages in a session are between participants
  all s: Session, m: Message |
    m in s.messages.elems => 
      (m.sender in s.participants and m.receiver in s.participants)
  
  // Shared secret is known only to participants
  all s: Session | 
    s.sharedSecret in (s.participants.dhKeys + s.participants.rootKey)
}

// Fact: Key derivation chain
fact KeyDerivationChain {
  // Root keys derive chain keys
  all ck: ChainKey |
    some kd: KeyDerivation |
      kd.child = ck and kd.derivationType = KDF_CK
  
  // Chain keys derive message keys
  all mk: MessageKey |
    some kd: KeyDerivation |
      kd.child = mk and kd.derivationType = KDF_MK
  
  // No cycles in derivation
  no k: Key | k in k.^(~KeyDerivation.parent)
}

// Fact: Message ordering
fact MessageOrdering {
  // Messages from same sender have increasing sequence numbers
  all s: Session, disj m1, m2: Message |
    (m1 in s.messages.elems and m2 in s.messages.elems and
     m1.sender = m2.sender and m1.sequenceNum < m2.sequenceNum) =>
      s.messages.idxOf[m1] < s.messages.idxOf[m2]
}

// Predicates

// Perfect Forward Secrecy: Old keys cannot decrypt new messages
pred PerfectForwardSecrecy {
  all disj m1, m2: Message |
    (m1.sequenceNum < m2.sequenceNum) =>
      (m1.msgKey != m2.msgKey and
       no kd: KeyDerivation | 
         kd.parent = m1.msgKey and kd.child = m2.msgKey)
}

// Future Secrecy: Compromise of old keys doesn't affect new keys
pred FutureSecrecy {
  all k1, k2: Key |
    (some kd: KeyDerivation | kd.parent = k1 and kd.child = k2) =>
      no kd2: KeyDerivation | kd2.parent = k2 and kd2.child = k1
}

// Key Uniqueness: Each message has a unique key
pred KeyUniqueness {
  all disj m1, m2: Message | m1.msgKey != m2.msgKey
}

// No Key Reuse: Keys are never reused
pred NoKeyReuse {
  // Message keys are never reused
  all mk: MessageKey | lone m: Message | m.msgKey = mk
  
  // Chain keys advance
  all u: User | u.sendChain != u.recvChain
}

// Session Security: Only participants can decrypt
pred SessionSecurity {
  all s: Session, m: Message |
    m in s.messages.elems =>
      m.msgKey in (s.participants.messageKeys)
}

// Assertions

// Assert: Security properties hold
assert SecurityPropertiesHold {
  PerfectForwardSecrecy and
  FutureSecrecy and
  KeyUniqueness and
  NoKeyReuse and
  SessionSecurity
}

// Assert: No key cycles
assert NoKeyCycles {
  no k: Key | k in k.^(KeyDerivation.child)
}

// Assert: Message integrity
assert MessageIntegrity {
  all m: Message |
    m.sender in User and
    m.receiver in User and
    m.msgKey in MessageKey
}

// Commands for verification

// Check security properties for small scope
check SecurityPropertiesHold for 5 but 3 User, 10 Message, 15 Key

// Check no key cycles
check NoKeyCycles for 10 Key

// Check message integrity
check MessageIntegrity for 5

// Run predicates to find examples

// Find a valid Double Ratchet session
run ValidSession {
  some s: Session |
    #s.participants = 2 and
    #s.messages > 0 and
    PerfectForwardSecrecy
} for 5

// Find a key derivation chain
run KeyChain {
  some disj k1, k2, k3: Key |
    some kd1, kd2: KeyDerivation |
      kd1.parent = k1 and kd1.child = k2 and
      kd2.parent = k2 and kd2.child = k3
} for 5

// Find a secure message exchange
run SecureExchange {
  some s: Session |
    #s.messages >= 3 and
    s.ratchetCount > 0 and
    PerfectForwardSecrecy and
    KeyUniqueness
} for 5 but exactly 2 User

// Scenarios

// Scenario: Basic message exchange
run BasicExchange {
  some alice: Alice, bob: Bob, s: Session |
    s.participants = alice + bob and
    #s.messages = 2 and
    some m1, m2: Message |
      m1.sender = alice and m1.receiver = bob and
      m2.sender = bob and m2.receiver = alice and
      m1 + m2 in s.messages.elems
} for 5

// Scenario: Ratchet step
run RatchetStep {
  some s: Session |
    s.ratchetCount > 0 and
    all m: s.messages.elems |
      m.header.dhPublic in s.participants.dhKeys
} for 5

// Scenario: Out-of-order delivery
run OutOfOrder {
  some s: Session |
    some disj m1, m2: Message |
      m1 in s.messages.elems and
      m2 in s.messages.elems and
      m1.sequenceNum < m2.sequenceNum and
      s.messages.idxOf[m2] < s.messages.idxOf[m1]
} for 5