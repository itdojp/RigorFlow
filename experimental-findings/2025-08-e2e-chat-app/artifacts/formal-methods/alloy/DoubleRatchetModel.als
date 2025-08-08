// Alloy Model for Double Ratchet Key Management
// Verifies data model consistency and security properties

module DoubleRatchetModel

// Time representation
sig Time {
    next: lone Time
}

// User entity
sig User {
    identity: one IdentityKey,
    sessions: set Session
}

// Cryptographic keys
abstract sig Key {
    created: one Time,
    expired: lone Time,
    owner: one User
}

// Different key types
sig IdentityKey extends Key {}
sig RootKey extends Key {
    derivedFrom: lone RootKey
}
sig ChainKey extends Key {
    derivedFrom: one Key  // Can be from RootKey or ChainKey
}
sig MessageKey extends Key {
    derivedFrom: one ChainKey,
    used: lone Message
}

// Session between two users
sig Session {
    userA: one User,
    userB: one User,
    rootKey: one RootKey,
    chainKeys: set ChainKey,
    established: one Time,
    closed: lone Time
}

// Encrypted message
sig Message {
    sender: one User,
    receiver: one User,
    session: one Session,
    encryptedWith: one MessageKey,
    sentAt: one Time,
    deliveredAt: lone Time,
    messageNumber: one Int
}

// Facts (constraints)

// Users cannot have session with themselves
fact NoSelfSession {
    all s: Session | s.userA != s.userB
}

// Session must involve exactly two different users
fact SessionUsers {
    all s: Session | 
        (s.userA in User and s.userB in User) and
        (s in s.userA.sessions and s in s.userB.sessions)
}

// Message must be between session participants
fact MessageInSession {
    all m: Message |
        (m.sender = m.session.userA and m.receiver = m.session.userB) or
        (m.sender = m.session.userB and m.receiver = m.session.userA)
}

// Keys are derived in proper order
fact KeyDerivation {
    // Root keys derive from DH exchange or previous root key
    all rk: RootKey | 
        rk.derivedFrom = none or rk.derivedFrom.created.^next = rk.created
    
    // Chain keys derive from root keys or other chain keys
    all ck: ChainKey |
        (ck.derivedFrom in RootKey or ck.derivedFrom in ChainKey) and
        ck.derivedFrom.created.^next = ck.created
    
    // Message keys derive from chain keys
    all mk: MessageKey |
        mk.derivedFrom.created.^next = mk.created
}

// Perfect Forward Secrecy: Keys are deleted after use
fact PerfectForwardSecrecy {
    // Message keys are used only once
    all mk: MessageKey | lone mk.used
    
    // After a message is delivered, its key expires
    all m: Message |
        some m.deliveredAt implies some m.encryptedWith.expired and
        m.encryptedWith.expired in m.deliveredAt.*next
    
    // Old chain keys expire when new ones are created
    all ck1, ck2: ChainKey |
        (ck2.derivedFrom = ck1) implies
        (some ck1.expired and ck1.expired in ck2.created.*next)
}

// Message ordering within session
fact MessageOrdering {
    all s: Session, m1, m2: Message |
        (m1.session = s and m2.session = s and 
         m1.sender = m2.sender and
         m1.messageNumber < m2.messageNumber) implies
        m1.sentAt.^next = m2.sentAt
}

// Key uniqueness
fact UniqueKeys {
    // No two keys are the same
    all k1, k2: Key | k1 != k2 implies k1.created != k2.created
    
    // Each message uses a unique key
    all m1, m2: Message | m1 != m2 implies m1.encryptedWith != m2.encryptedWith
}

// Temporal constraints
fact TemporalOrder {
    // Sessions are established before messages are sent
    all m: Message | m.session.established.^next = m.sentAt
    
    // Messages are sent before delivery
    all m: Message | some m.deliveredAt implies m.sentAt.^next = m.deliveredAt
    
    // Keys are created before use
    all m: Message | m.encryptedWith.created.^next = m.sentAt
}

// Session lifecycle
fact SessionLifecycle {
    // Closed sessions don't have new messages
    all s: Session, m: Message |
        (m.session = s and some s.closed) implies
        m.sentAt.^next != s.closed
}

// Predicates for verification

// Check if Perfect Forward Secrecy holds
pred PFSHolds[] {
    // All used keys eventually expire
    all mk: MessageKey |
        some mk.used implies some mk.expired
}

// Check if all messages in a session use different keys
pred UniqueKeysPerSession[s: Session] {
    all m1, m2: Message |
        (m1.session = s and m2.session = s and m1 != m2) implies
        m1.encryptedWith != m2.encryptedWith
}

// Check if key derivation chain is valid
pred ValidKeyChain[] {
    // No cycles in derivation
    no k: Key | k in k.^(~(ChainKey <: derivedFrom))
}

// Check for orphaned keys (keys never used)
pred NoOrphanedKeys[] {
    all mk: MessageKey | some mk.used
}

// Assertions to verify

// Assert that PFS is maintained
assert PerfectForwardSecrecyMaintained {
    PFSHolds[]
}

// Assert that each session uses unique keys
assert SessionKeysUnique {
    all s: Session | UniqueKeysPerSession[s]
}

// Assert valid key derivation
assert ValidKeyDerivation {
    ValidKeyChain[]
}

// Assert no key reuse across sessions
assert NoKeyReuseAcrossSessions {
    all s1, s2: Session, m1, m2: Message |
        (s1 != s2 and m1.session = s1 and m2.session = s2) implies
        m1.encryptedWith != m2.encryptedWith
}

// Run commands for verification

// Check for small instances
run SmallExample {
    #User = 2
    #Session = 1
    #Message = 3
    #Time = 5
} for 5

// Check PFS for larger instances
check PerfectForwardSecrecyMaintained for 10

// Check key uniqueness
check SessionKeysUnique for 10

// Check for key derivation validity
check ValidKeyDerivation for 8

// Check no key reuse
check NoKeyReuseAcrossSessions for 10

// Explore specific scenarios

// Scenario: Multiple messages in sequence
run MultipleMessages {
    some s: Session |
        #(s.userA.sessions & s.userB.sessions) = 1 and
        #{m: Message | m.session = s} >= 3
} for 10

// Scenario: Key rotation
run KeyRotation {
    some s: Session |
        #{ck: ChainKey | ck in s.chainKeys} >= 2
} for 8

// Scenario: Concurrent sessions
run ConcurrentSessions {
    some u1, u2: User |
        #{s: Session | s.userA = u1 and s.userB = u2} >= 2
} for 10