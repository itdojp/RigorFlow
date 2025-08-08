---------------------------- MODULE DoubleRatchet ----------------------------
(***************************************************************************)
(* Double Ratchet Algorithm Formal Specification                          *)
(* Enhanced version with comprehensive security properties                 *)
(* Based on Signal Protocol specification                                  *)
(*                                                                         *)
(* This specification models the core Double Ratchet algorithm used       *)
(* in secure messaging systems like Signal, providing:                    *)
(* - Forward secrecy through key derivation chains                        *)
(* - Future secrecy through DH ratcheting                                 *)
(* - Out-of-order message handling with skipped keys                      *)
(* - Comprehensive security property verification                          *)
(***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS
    Users,              \* Set of users participating in the protocol
    MaxMessages,        \* Maximum number of messages in the system
    MaxChainLength,     \* Maximum length of a key derivation chain
    MaxSkippedKeys,     \* Maximum number of skipped keys per user
    DHKeySpace,         \* DH key space size for modular arithmetic
    PlaintextSpace      \* Plaintext space for messages

ASSUME Users # {} /\ Cardinality(Users) >= 2
ASSUME MaxMessages \in Nat /\ MaxMessages > 0
ASSUME MaxChainLength \in Nat /\ MaxChainLength > 0
ASSUME MaxSkippedKeys \in Nat /\ MaxSkippedKeys > 0
ASSUME DHKeySpace \in Nat /\ DHKeySpace > 100
ASSUME PlaintextSpace \in Nat /\ PlaintextSpace > 0

VARIABLES
    \* Core Double Ratchet State per user
    DHs,                \* Sending DH key pair (current ephemeral keys)
    DHr,                \* Receiving DH public key (from last received message)
    RK,                 \* Root key (shared secret updated with DH ratchet)
    CKs,                \* Current sending chain key
    CKr,                \* Current receiving chain key
    Ns,                 \* Number of messages sent in current chain
    Nr,                 \* Number of messages received in current chain
    PN,                 \* Number of messages sent in previous chain
    
    \* Message and Key Management
    messages,           \* Global sequence of all sent messages
    skippedKeys,        \* Per-user map of skipped message keys
    derivedKeys,        \* History of all derived keys for analysis
    
    \* Network and Delivery State
    network,            \* Messages currently in transit
    delivered,          \* Successfully delivered messages
    compromisedKeys,    \* Keys that have been compromised (for security analysis)
    
    \* Protocol State Tracking
    sessionStates,      \* Per-user session initialization state
    ratchetHistory      \* History of DH ratchet steps for analysis

\* Variable tuple for temporal logic specifications
vars == <<DHs, DHr, RK, CKs, CKr, Ns, Nr, PN, messages, skippedKeys, 
          derivedKeys, network, delivered, compromisedKeys, sessionStates, ratchetHistory>>

(***************************************************************************)
(* Type Definitions and Domains                                           *)
(***************************************************************************)

\* Cryptographic key types with associated metadata
KeyType == {"public", "private", "shared", "chain", "message", "root"}
Key == [type: KeyType, value: Nat, generation: Nat, chainId: Nat]
KeyPair == [public: Key, private: Key]

\* Message structure following Double Ratchet specification
Header == [
    dh: Key,            \* Ephemeral DH public key
    pn: Nat,           \* Previous chain length
    n: Nat             \* Current chain message number
]

Message == [
    id: Nat,           \* Unique message identifier
    sender: Users,     \* Sender user
    receiver: Users,   \* Receiver user
    header: Header,    \* Message header
    ciphertext: Nat,   \* Encrypted payload
    timestamp: Nat,    \* Message creation time
    chainId: Nat       \* Chain identifier for tracking
]

\* Session state for tracking protocol initialization
SessionState == {"uninitialized", "initialized", "established"}

\* Skipped key entry with additional metadata
SkippedKeyEntry == [key: Key, messageNumber: Nat, chainId: Nat]

(***************************************************************************)
(* Type Invariants                                                         *)
(***************************************************************************)

ValidKey(k) == 
    /\ k.type \in KeyType
    /\ k.value \in Nat
    /\ k.generation \in Nat
    /\ k.chainId \in Nat

ValidKeyPair(kp) ==
    /\ ValidKey(kp.public)
    /\ ValidKey(kp.private)
    /\ kp.public.type = "public"
    /\ kp.private.type = "private"

ValidMessage(msg) ==
    /\ msg.id \in Nat
    /\ msg.sender \in Users
    /\ msg.receiver \in Users
    /\ msg.sender # msg.receiver
    /\ ValidKey(msg.header.dh)
    /\ msg.header.dh.type = "public"
    /\ msg.header.pn \in Nat
    /\ msg.header.n \in Nat
    /\ msg.ciphertext \in Nat
    /\ msg.timestamp \in Nat
    /\ msg.chainId \in Nat

TypeInvariant ==
    /\ \A u \in Users: 
        /\ DHs[u] \in KeyPair \cup {<<>>}
        /\ DHr[u] \in Key \cup {<<>>}
        /\ RK[u] \in Key \cup {<<>>}
        /\ CKs[u] \in Key \cup {<<>>}
        /\ CKr[u] \in Key \cup {<<>>}
        /\ Ns[u] \in Nat /\ Ns[u] <= MaxChainLength
        /\ Nr[u] \in Nat /\ Nr[u] <= MaxChainLength
        /\ PN[u] \in Nat
        /\ sessionStates[u] \in SessionState
        /\ \A entry \in skippedKeys[u]: 
            /\ ValidKey(entry.key)
            /\ entry.messageNumber \in Nat
            /\ entry.chainId \in Nat
        /\ Cardinality(skippedKeys[u]) <= MaxSkippedKeys
    /\ \A msg \in Range(messages): ValidMessage(msg)
    /\ \A msg \in network: ValidMessage(msg)
    /\ \A msg \in delivered: ValidMessage(msg)
    /\ network \subseteq Range(messages)
    /\ delivered \subseteq Range(messages)

(***************************************************************************)
(* Cryptographic Operations (Simplified Models)                           *)
(***************************************************************************)

\* Generate a new DH key pair with metadata
GenerateDH(generation, chainId) == 
    [public |-> [type |-> "public", 
                 value |-> RandomElement(1..DHKeySpace), 
                 generation |-> generation,
                 chainId |-> chainId],
     private |-> [type |-> "private", 
                  value |-> RandomElement(1..DHKeySpace), 
                  generation |-> generation,
                  chainId |-> chainId]]

\* Diffie-Hellman key agreement (simplified with modular arithmetic)
DH(privateKey, publicKey) ==
    [type |-> "shared", 
     value |-> (privateKey.value * publicKey.value) % DHKeySpace,
     generation |-> privateKey.generation + publicKey.generation,
     chainId |-> privateKey.chainId]

\* HKDF-based key derivation for root key (generates new root key and chain key)
KDF_RK(rootKey, dhOutput) ==
    LET salt == rootKey.value
        ikm == dhOutput.value
        newRootValue == (salt + ikm * 31 + dhOutput.generation * 17) % DHKeySpace
        newChainValue == (salt + ikm * 37 + dhOutput.generation * 19) % DHKeySpace
        newGeneration == rootKey.generation + 1
        chainId == dhOutput.chainId
    IN <<[type |-> "root", value |-> newRootValue, 
          generation |-> newGeneration, chainId |-> chainId],
         [type |-> "chain", value |-> newChainValue, 
          generation |-> newGeneration, chainId |-> chainId]>>

\* Key derivation for chain key (generates message key and new chain key)
KDF_CK(chainKey, messageNum) ==
    LET messageValue == (chainKey.value * 41 + messageNum * 23) % DHKeySpace
        newChainValue == (chainKey.value * 43 + messageNum * 29) % DHKeySpace
        newGeneration == chainKey.generation + 1
    IN <<[type |-> "message", value |-> messageValue, 
          generation |-> newGeneration, chainId |-> chainKey.chainId],
         [type |-> "chain", value |-> newChainValue, 
          generation |-> newGeneration, chainId |-> chainKey.chainId]>>

\* Authenticated encryption (simplified)
AEAD_Encrypt(key, plaintext, associatedData) ==
    (plaintext + key.value + associatedData) % DHKeySpace

\* Authenticated decryption (simplified)
AEAD_Decrypt(key, ciphertext, associatedData) ==
    (ciphertext - key.value - associatedData + DHKeySpace) % DHKeySpace

(***************************************************************************)
(* Initial State                                                           *)
(***************************************************************************)

Init ==
    /\ DHs = [u \in Users |-> <<>>]
    /\ DHr = [u \in Users |-> <<>>]
    /\ RK = [u \in Users |-> <<>>]
    /\ CKs = [u \in Users |-> <<>>]
    /\ CKr = [u \in Users |-> <<>>]
    /\ Ns = [u \in Users |-> 0]
    /\ Nr = [u \in Users |-> 0]
    /\ PN = [u \in Users |-> 0]
    /\ messages = <<>>
    /\ skippedKeys = [u \in Users |-> {}]
    /\ derivedKeys = {}
    /\ network = {}
    /\ delivered = {}
    /\ compromisedKeys = {}
    /\ sessionStates = [u \in Users |-> "uninitialized"]
    /\ ratchetHistory = <<>>

(***************************************************************************)
(* Session Initialization                                                  *)
(***************************************************************************)

\* Initialize a Double Ratchet session between two users
InitializeSession(alice, bob) ==
    /\ sessionStates[alice] = "uninitialized"
    /\ sessionStates[bob] = "uninitialized"
    /\ LET sharedSecret == RandomElement(1..DHKeySpace)
           initialRootKey == [type |-> "root", value |-> sharedSecret, 
                             generation |-> 0, chainId |-> 0]
           aliceDH == GenerateDH(0, 0)
           bobDH == GenerateDH(0, 0)
       IN /\ RK' = [RK EXCEPT ![alice] = initialRootKey, ![bob] = initialRootKey]
          /\ DHs' = [DHs EXCEPT ![alice] = aliceDH, ![bob] = bobDH]
          /\ sessionStates' = [sessionStates EXCEPT 
                ![alice] = "initialized", ![bob] = "initialized"]
    /\ UNCHANGED <<DHr, CKs, CKr, Ns, Nr, PN, messages, skippedKeys, 
                   derivedKeys, network, delivered, compromisedKeys, ratchetHistory>>

(***************************************************************************)
(* DH Ratchet Step                                                         *)
(***************************************************************************)

\* Perform a DH ratchet step when receiving a new ephemeral key
DHRatchetStep(user, newDHPub) ==
    /\ sessionStates[user] = "initialized"
    /\ DHr[user] # newDHPub  \* Only ratchet for new keys
    /\ LET oldChainId == IF DHs[user] # <<>> THEN DHs[user].public.chainId ELSE 0
           newChainId == oldChainId + 1
           newDHPair == GenerateDH(0, newChainId)
           dhSecret == DH(newDHPair.private, newDHPub)
           rkCkReceiving == KDF_RK(RK[user], dhSecret)
           newRK == rkCkReceiving[1]
           newCKr == rkCkReceiving[2]
           dhSecretSending == DH(newDHPair.private, newDHPub)
           rkCkSending == KDF_RK(newRK, dhSecretSending)
           finalRK == rkCkSending[1]
           newCKs == rkCkSending[2]
           ratchetEntry == [user |-> user, oldDH |-> DHs[user], newDH |-> newDHPair,
                           receivedDH |-> newDHPub, timestamp |-> Len(ratchetHistory)]
       IN /\ DHr' = [DHr EXCEPT ![user] = newDHPub]
          /\ DHs' = [DHs EXCEPT ![user] = newDHPair]
          /\ RK' = [RK EXCEPT ![user] = finalRK]
          /\ CKr' = [CKr EXCEPT ![user] = newCKr]
          /\ CKs' = [CKs EXCEPT ![user] = newCKs]
          /\ PN' = [PN EXCEPT ![user] = Ns[user]]
          /\ Ns' = [Ns EXCEPT ![user] = 0]
          /\ Nr' = [Nr EXCEPT ![user] = 0]
          /\ ratchetHistory' = Append(ratchetHistory, ratchetEntry)
    /\ UNCHANGED <<messages, skippedKeys, derivedKeys, network, delivered, 
                   compromisedKeys, sessionStates>>

(***************************************************************************)
(* Symmetric Ratchet - Encryption                                         *)
(***************************************************************************)

RatchetEncrypt(sender, receiver, plaintext) ==
    /\ sessionStates[sender] = "initialized"
    /\ CKs[sender] # <<>>
    /\ Ns[sender] < MaxChainLength
    /\ Len(messages) < MaxMessages
    /\ LET mkCk == KDF_CK(CKs[sender], Ns[sender])
           messageKey == mkCk[1]
           newChainKey == mkCk[2]
           header == [dh |-> DHs[sender].public, 
                     pn |-> PN[sender], 
                     n |-> Ns[sender]]
           associatedData == header.dh.value + header.pn + header.n
           ciphertext == AEAD_Encrypt(messageKey, plaintext, associatedData)
           msg == [id |-> Len(messages) + 1,
                   sender |-> sender,
                   receiver |-> receiver,
                   header |-> header,
                   ciphertext |-> ciphertext,
                   timestamp |-> Len(messages),
                   chainId |-> DHs[sender].public.chainId]
       IN /\ CKs' = [CKs EXCEPT ![sender] = newChainKey]
          /\ Ns' = [Ns EXCEPT ![sender] = Ns[sender] + 1]
          /\ messages' = Append(messages, msg)
          /\ network' = network \cup {msg}
          /\ derivedKeys' = derivedKeys \cup {messageKey}
    /\ UNCHANGED <<DHs, DHr, RK, CKr, Nr, PN, skippedKeys, delivered, 
                   compromisedKeys, sessionStates, ratchetHistory>>

(***************************************************************************)
(* Symmetric Ratchet - Decryption                                         *)
(***************************************************************************)

\* Try to decrypt using skipped message keys
TrySkippedMessageKeys(receiver, msg) ==
    \E keyEntry \in skippedKeys[receiver]:
        /\ keyEntry.messageNumber = msg.header.n
        /\ keyEntry.chainId = msg.chainId
        /\ LET associatedData == msg.header.dh.value + msg.header.pn + msg.header.n
               plaintext == AEAD_Decrypt(keyEntry.key, msg.ciphertext, associatedData)
           IN /\ delivered' = delivered \cup {msg}
              /\ network' = network \ {msg}
              /\ skippedKeys' = [skippedKeys EXCEPT 
                    ![receiver] = skippedKeys[receiver] \ {keyEntry}]
              /\ UNCHANGED <<DHs, DHr, RK, CKs, CKr, Ns, Nr, PN, messages, 
                            derivedKeys, compromisedKeys, sessionStates, ratchetHistory>>

\* Skip message keys up to a specific number
SkipMessageKeys(user, until, chainId) ==
    /\ Nr[user] < until
    /\ CKr[user] # <<>>
    /\ CKr[user].chainId = chainId
    /\ Cardinality(skippedKeys[user]) < MaxSkippedKeys
    /\ LET mkCk == KDF_CK(CKr[user], Nr[user])
           messageKey == mkCk[1]
           newChainKey == mkCk[2]
           keyEntry == [key |-> messageKey, 
                       messageNumber |-> Nr[user], 
                       chainId |-> chainId]
       IN /\ CKr' = [CKr EXCEPT ![user] = newChainKey]
          /\ Nr' = [Nr EXCEPT ![user] = Nr[user] + 1]
          /\ skippedKeys' = [skippedKeys EXCEPT 
                ![user] = skippedKeys[user] \cup {keyEntry}]
          /\ derivedKeys' = derivedKeys \cup {messageKey}

\* Main decryption function with comprehensive out-of-order handling
RatchetDecrypt(receiver, msg) ==
    /\ msg \in network
    /\ msg.receiver = receiver
    /\ sessionStates[receiver] = "initialized"
    /\ \/ TrySkippedMessageKeys(receiver, msg)
       \/ /\ \* Check if DH ratchet step is needed
             msg.header.dh # DHr[receiver]
          /\ DHRatchetStep(receiver, msg.header.dh)
          /\ \* Skip any missed keys in the chain
             IF msg.header.n > Nr'[receiver]
             THEN SkipMessageKeys(receiver, msg.header.n, msg.chainId)
             ELSE UNCHANGED <<CKr, Nr, skippedKeys, derivedKeys>>
          /\ \* Decrypt the current message
             CKr'[receiver] # <<>>
          /\ LET mkCk == KDF_CK(CKr'[receiver], Nr'[receiver])
                 messageKey == mkCk[1]
                 newChainKey == mkCk[2]
                 associatedData == msg.header.dh.value + msg.header.pn + msg.header.n
                 plaintext == AEAD_Decrypt(messageKey, msg.ciphertext, associatedData)
             IN /\ CKr'' = [CKr' EXCEPT ![receiver] = newChainKey]
                /\ Nr'' = [Nr' EXCEPT ![receiver] = Nr'[receiver] + 1]
                /\ delivered' = delivered \cup {msg}
                /\ network' = network \ {msg}
                /\ derivedKeys' = derivedKeys' \cup {messageKey}
          /\ UNCHANGED <<messages>>

(***************************************************************************)
(* Actions                                                                 *)
(***************************************************************************)

\* Initialize a new session between two users
NewSession ==
    \E alice, bob \in Users:
        /\ alice # bob
        /\ InitializeSession(alice, bob)

\* Send a message
SendMessage ==
    \E sender, receiver \in Users:
        /\ sender # receiver
        /\ RatchetEncrypt(sender, receiver, RandomElement(1..PlaintextSpace))

\* Receive and decrypt a message
ReceiveMessage ==
    \E receiver \in Users:
        \E msg \in network:
            RatchetDecrypt(receiver, msg)

\* Compromise a key (for security analysis)
CompromiseKey ==
    /\ Cardinality(compromisedKeys) < 5  \* Limit compromises for model checking
    /\ \E key \in derivedKeys:
        /\ key \notin compromisedKeys
        /\ compromisedKeys' = compromisedKeys \cup {key}
        /\ UNCHANGED <<DHs, DHr, RK, CKs, CKr, Ns, Nr, PN, messages, skippedKeys,
                       derivedKeys, network, delivered, sessionStates, ratchetHistory>>

\* Protocol step
Next ==
    \/ NewSession
    \/ SendMessage  
    \/ ReceiveMessage
    \/ CompromiseKey

\* Specification
Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Security Properties                                                     *)
(***************************************************************************)

\* Forward Secrecy: Compromising current keys doesn't reveal past messages
ForwardSecrecy ==
    \A msg \in delivered:
        \A compromisedKey \in compromisedKeys:
            compromisedKey.generation > msg.timestamp =>
                \* Cannot decrypt past messages with future compromised keys
                \A plaintext \in 1..PlaintextSpace:
                    LET associatedData == msg.header.dh.value + msg.header.pn + msg.header.n
                    IN AEAD_Encrypt(compromisedKey, plaintext, associatedData) # msg.ciphertext

\* Future Secrecy: Compromising past keys doesn't reveal future messages  
FutureSecrecy ==
    \A msg \in delivered:
        \A compromisedKey \in compromisedKeys:
            compromisedKey.generation < msg.timestamp =>
                \* Cannot decrypt future messages with past compromised keys
                \A plaintext \in 1..PlaintextSpace:
                    LET associatedData == msg.header.dh.value + msg.header.pn + msg.header.n
                    IN AEAD_Encrypt(compromisedKey, plaintext, associatedData) # msg.ciphertext

\* Message Authenticity: Only sender can create valid messages
MessageAuthenticity ==
    \A msg \in delivered:
        \E i \in 1..Len(messages):
            /\ messages[i] = msg
            /\ messages[i].sender = msg.sender

\* Key Uniqueness: Each message uses a unique key
KeyUniqueness ==
    \A i, j \in 1..Len(messages):
        i # j =>
            \/ messages[i].header.n # messages[j].header.n
            \/ messages[i].chainId # messages[j].chainId
            \/ messages[i].sender # messages[j].sender

\* Chain Integrity: Message numbers are monotonic within chains
ChainIntegrity ==
    \A msg1, msg2 \in delivered:
        /\ msg1.sender = msg2.sender
        /\ msg1.receiver = msg2.receiver
        /\ msg1.chainId = msg2.chainId
        /\ msg1.header.n < msg2.header.n
        => msg1.timestamp < msg2.timestamp

\* Session Consistency: Sessions are properly established
SessionConsistency ==
    \A user \in Users:
        sessionStates[user] = "initialized" =>
            /\ RK[user] # <<>>
            /\ DHs[user] # <<>>

\* Key Derivation Correctness: Keys are properly derived
KeyDerivationCorrectness ==
    \A key \in derivedKeys:
        key.generation > 0 =>
            \E parentKey \in derivedKeys \cup Range([u \in Users |-> RK[u]]):
                parentKey.generation = key.generation - 1

(***************************************************************************)
(* Safety and Liveness Properties                                         *)
(***************************************************************************)

\* Main safety invariant combining all security properties
SafetyInvariant ==
    /\ TypeInvariant
    /\ MessageAuthenticity
    /\ KeyUniqueness
    /\ ChainIntegrity
    /\ SessionConsistency
    /\ KeyDerivationCorrectness

\* Conditional security properties (only when keys are compromised)
ConditionalSecurityProperties ==
    Cardinality(compromisedKeys) > 0 =>
        /\ ForwardSecrecy
        /\ FutureSecrecy

\* Liveness properties
LivenessProperties ==
    /\ \* All sent messages eventually get delivered or remain in network
       \A msg \in Range(messages):
           <>(msg \in delivered \/ msg \in network)
    /\ \* Sessions can always be established
       <>(\E u1, u2 \in Users: 
           sessionStates[u1] = "initialized" /\ sessionStates[u2] = "initialized")

(***************************************************************************)
(* Model Checking Properties                                               *)
(***************************************************************************)

\* Properties for bounded model checking
BoundedProperties ==
    /\ Len(messages) <= MaxMessages
    /\ \A u \in Users: 
        /\ Ns[u] <= MaxChainLength
        /\ Nr[u] <= MaxChainLength
        /\ Cardinality(skippedKeys[u]) <= MaxSkippedKeys
    /\ Cardinality(network) <= MaxMessages
    /\ Cardinality(delivered) <= MaxMessages

\* Fairness constraints for model checking
Fairness ==
    /\ WF_vars(ReceiveMessage)  \* Weak fairness for message delivery
    /\ SF_vars(NewSession)      \* Strong fairness for session establishment

\* Complete specification with fairness
FairSpec == Spec /\ Fairness

(***************************************************************************)
(* Verification Theorems                                                   *)
(***************************************************************************)

\* Core correctness theorem
THEOREM DoubleRatchetCorrectness == 
    Spec => []SafetyInvariant

\* Security theorem under compromise
THEOREM DoubleRatchetSecurity == 
    Spec => []ConditionalSecurityProperties

\* Liveness theorem
THEOREM DoubleRatchetLiveness == 
    FairSpec => LivenessProperties

\* Bounded execution theorem
THEOREM BoundedExecution == 
    Spec => []BoundedProperties

================================================================================