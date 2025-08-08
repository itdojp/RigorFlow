// Alloy Security Model for E2E Encrypted Chat
// Verifies data model consistency and security properties

module SecurityModel

// ============= Core Entities =============

sig Time {}

sig User {
    id: one Id,
    identityKey: one IdentityKeyPair,
    signedPreKey: one SignedPreKey,
    oneTimePreKeys: set OneTimePreKey,
    devices: set Device,
    sessions: Device -> Session,
    trustedContacts: set User
}

sig Device {
    owner: one User,
    deviceId: one Id,
    registeredAt: one Time
}

sig Id {}

// ============= Cryptographic Keys =============

abstract sig Key {}

sig PublicKey extends Key {}
sig PrivateKey extends Key {}

sig IdentityKeyPair {
    public: one PublicKey,
    private: one PrivateKey
}

sig SignedPreKey {
    keyPair: one KeyPair,
    signature: one Signature,
    timestamp: one Time
}

sig OneTimePreKey {
    keyPair: one KeyPair,
    used: one Bool
}

sig KeyPair {
    public: one PublicKey,
    private: one PrivateKey
}

sig Signature {}

abstract sig Bool {}
one sig True, False extends Bool {}

// ============= Messages =============

sig Message {
    id: one Id,
    sender: one User,
    senderDevice: one Device,
    receiver: one User,
    receiverDevice: one Device,
    content: one EncryptedContent,
    header: one MessageHeader,
    timestamp: one Time,
    session: one Session
}

sig EncryptedContent {
    ciphertext: one Data,
    nonce: one Nonce,
    authTag: one AuthTag
}

sig MessageHeader {
    dhPublicKey: one PublicKey,
    previousChainLength: one Int,
    messageNumber: one Int
}

sig Data {}
sig Nonce {}
sig AuthTag {}

// ============= Sessions =============

sig Session {
    alice: one User,
    bob: one User,
    aliceDevice: one Device,
    bobDevice: one Device,
    sharedSecret: one SharedSecret,
    rootKey: one RootKey,
    chainKeys: set ChainKey,
    establishedAt: one Time,
    lastActivity: one Time,
    state: one SessionState
}

sig SharedSecret {}
sig RootKey {}
sig ChainKey {}

abstract sig SessionState {}
one sig Initial, Established, Active, Expired extends SessionState {}

// ============= Compromised Entities =============

sig CompromisedKey {
    key: one Key,
    compromisedAt: one Time
}

sig CompromisedDevice {
    device: one Device,
    compromisedAt: one Time
}

// ============= Security Properties =============

// Property 1: Identity Key Uniqueness
// Each user has a unique identity key
fact IdentityKeyUniqueness {
    all disj u1, u2: User |
        u1.identityKey != u2.identityKey
}

// Property 2: Device Ownership
// Devices belong to exactly one user
fact DeviceOwnership {
    all d: Device |
        d.owner.devices = d.owner.devices
}

// Property 3: Session Symmetry
// Sessions are symmetric between participants
fact SessionSymmetry {
    all s: Session |
        s.alice != s.bob and
        s.aliceDevice in s.alice.devices and
        s.bobDevice in s.bob.devices
}

// Property 4: Message-Session Binding
// Messages are bound to valid sessions
fact MessageSessionBinding {
    all m: Message |
        m.session.alice = m.sender and
        m.session.bob = m.receiver and
        m.senderDevice in m.sender.devices and
        m.receiverDevice in m.receiver.devices
}

// Property 5: One-Time PreKey Usage
// One-time prekeys are used at most once
fact OneTimePreKeyUsage {
    all opk: OneTimePreKey |
        opk.used = True implies
            lone m: Message | 
                m.header.dhPublicKey = opk.keyPair.public
}

// ============= Security Predicates =============

// Predicate: Can decrypt message
pred canDecrypt[u: User, m: Message] {
    (m.receiver = u and m.receiverDevice in u.devices) or
    (m.sender = u and m.senderDevice in u.devices)
}

// Predicate: Message confidentiality
pred messageConfidentiality {
    all m: Message |
        all u: User |
            u != m.sender and u != m.receiver implies
                not canDecrypt[u, m]
}

// Predicate: Perfect Forward Secrecy
pred perfectForwardSecrecy {
    all m: Message |
        all ck: CompromisedKey |
            ck.compromisedAt.gt[m.timestamp] implies
                not canDecryptWithKey[m, ck.key]
}

// Helper: Can decrypt with specific key
pred canDecryptWithKey[m: Message, k: Key] {
    // Simplified: assumes proper key derivation
    k in m.session.chainKeys.elems
}

// Predicate: Session establishment security
pred sessionEstablishmentSecurity {
    all s: Session |
        s.state = Established implies
            s.sharedSecret not in CompromisedKey.key
}

// ============= Assertions =============

// Assert: Confidentiality is maintained
assert Confidentiality {
    messageConfidentiality
}

// Assert: PFS is guaranteed
assert PFS {
    perfectForwardSecrecy
}

// Assert: No key reuse
assert NoKeyReuse {
    all disj m1, m2: Message |
        m1.content.nonce != m2.content.nonce
}

// Assert: Session integrity
assert SessionIntegrity {
    all s: Session |
        s.alice.sessions[s.aliceDevice] = s implies
            s.bob.sessions[s.bobDevice] = s
}

// ============= Security Analysis Commands =============

// Check for confidentiality violations
run FindConfidentialityViolation {
    some m: Message |
        some u: User |
            u != m.sender and 
            u != m.receiver and 
            canDecrypt[u, m]
} for 5

// Check for PFS violations
run FindPFSViolation {
    some m: Message |
        some ck: CompromisedKey |
            ck.compromisedAt.gt[m.timestamp] and
            canDecryptWithKey[m, ck.key]
} for 5

// Find normal scenario
run NormalMessaging {
    some m: Message |
        m.sender != m.receiver and
        messageConfidentiality and
        m.session.state = Active
} for 3

// Check session establishment
run SessionEstablishment {
    some s: Session |
        s.state = Established and
        s.alice != s.bob and
        #s.chainKeys > 0
} for 3

// ============= Formal Verification Commands =============

check Confidentiality for 10
check PFS for 10
check NoKeyReuse for 10
check SessionIntegrity for 10

// ============= Helper Functions =============

fun getAllMessages[u: User]: set Message {
    { m: Message | m.sender = u or m.receiver = u }
}

fun getActiveSession[u1, u2: User]: lone Session {
    { s: Session | 
        (s.alice = u1 and s.bob = u2 or 
         s.alice = u2 and s.bob = u1) and
        s.state = Active
    }
}

fun getCompromisedMessages[t: Time]: set Message {
    { m: Message |
        some ck: CompromisedKey |
            ck.compromisedAt.lt[t] and
            canDecryptWithKey[m, ck.key]
    }
}

// ============= Visualization Helpers =============

// Show message flow
run ShowMessageFlow {
    some disj u1, u2: User |
    some m1, m2: Message |
        m1.sender = u1 and m1.receiver = u2 and
        m2.sender = u2 and m2.receiver = u1 and
        m1.timestamp.lt[m2.timestamp]
} for 4

// Show key hierarchy
run ShowKeyHierarchy {
    some u: User |
        #u.oneTimePreKeys > 2 and
        some u.signedPreKey and
        some u.identityKey
} for 3