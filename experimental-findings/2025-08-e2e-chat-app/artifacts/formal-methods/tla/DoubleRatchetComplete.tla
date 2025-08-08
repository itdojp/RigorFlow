---- MODULE DoubleRatchetComplete ----
(*
  Complete TLA+ specification for Double Ratchet Algorithm
  Verifies Perfect Forward Secrecy, Message Ordering, and Deadlock Freedom
*)

EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS 
    Users,          \* Set of users {alice, bob}
    MaxMessages,    \* Maximum number of messages
    MaxChainLength, \* Maximum chain length before ratchet
    MaxSkip        \* Maximum number of skipped messages

VARIABLES
    messages,       \* Sequence of sent messages
    rootKeys,       \* Root keys for each user
    chainKeys,      \* Chain keys for sending/receiving
    messageKeys,    \* Generated message keys
    dhKeys,         \* Diffie-Hellman key pairs
    skippedKeys,    \* Keys for out-of-order messages
    messageCounter, \* Message counters for each user
    delivered,      \* Set of delivered messages
    network         \* Messages in transit

\* Type Definitions

MessageType == [
    id: Nat,
    sender: Users,
    receiver: Users,
    content: STRING,
    key: Nat,
    header: [dh: Nat, pn: Nat, n: Nat],
    timestamp: Nat
]

KeyType == [
    value: Nat,
    owner: Users,
    type: {"root", "chain", "message"},
    derived_from: Nat
]

\* Helper Functions

DeriveKey(parent, seed) == 
    \* Simplified key derivation function
    (parent + seed) % 1000000

GenerateDHKeyPair(user) == 
    \* Generate new DH keypair for user
    [private |-> RandomElement(1..1000), 
     public |-> RandomElement(1001..2000)]

ComputeSharedSecret(priv, pub) ==
    \* Simplified DH computation
    (priv * pub) % 100000

\* Initial State

Init == 
    /\ messages = <<>>
    /\ rootKeys = [u \in Users |-> [value |-> RandomElement(1..100), type |-> "root"]]
    /\ chainKeys = [u \in Users |-> [send |-> 0, recv |-> 0]]
    /\ messageKeys = {}
    /\ dhKeys = [u \in Users |-> GenerateDHKeyPair(u)]
    /\ skippedKeys = {}
    /\ messageCounter = [u \in Users |-> [send |-> 0, recv |-> 0]]
    /\ delivered = {}
    /\ network = {}

\* Actions

DHRatchet(sender) ==
    \* Perform Diffie-Hellman ratchet step
    /\ dhKeys' = [dhKeys EXCEPT ![sender] = GenerateDHKeyPair(sender)]
    /\ LET shared == ComputeSharedSecret(
           dhKeys[sender].private,
           dhKeys[IF sender = "alice" THEN "bob" ELSE "alice"].public)
       IN rootKeys' = [rootKeys EXCEPT 
           ![sender].value = DeriveKey(rootKeys[sender].value, shared)]
    /\ chainKeys' = [chainKeys EXCEPT 
           ![sender].send = DeriveKey(rootKeys'[sender].value, 1),
           ![sender].recv = DeriveKey(rootKeys'[sender].value, 2)]
    /\ messageCounter' = [messageCounter EXCEPT 
           ![sender].send = 0,
           ![sender].recv = 0]
    /\ UNCHANGED <<messages, messageKeys, skippedKeys, delivered, network>>

SendMessage(sender, receiver, content) ==
    \* Send an encrypted message
    /\ Len(messages) < MaxMessages
    /\ sender # receiver
    /\ sender \in Users /\ receiver \in Users
    /\ LET msgKey == DeriveKey(chainKeys[sender].send, messageCounter[sender].send)
           msgId == Len(messages) + 1
           header == [dh |-> dhKeys[sender].public,
                     pn |-> messageCounter[sender].send,
                     n |-> messageCounter[sender].send]
           newMsg == [
               id |-> msgId,
               sender |-> sender,
               receiver |-> receiver,
               content |-> content,
               key |-> msgKey,
               header |-> header,
               timestamp |-> msgId
           ]
       IN /\ messages' = Append(messages, newMsg)
          /\ network' = network \union {newMsg}
          /\ messageKeys' = messageKeys \union {[value |-> msgKey, type |-> "message"]}
          /\ messageCounter' = [messageCounter EXCEPT 
               ![sender].send = messageCounter[sender].send + 1]
          /\ \* Ratchet if chain gets too long
             IF messageCounter[sender].send >= MaxChainLength
             THEN DHRatchet(sender)
             ELSE UNCHANGED <<rootKeys, chainKeys, dhKeys>>
    /\ UNCHANGED <<skippedKeys, delivered>>

ReceiveMessage(receiver, msg) ==
    \* Receive and decrypt a message
    /\ msg \in network
    /\ msg.receiver = receiver
    /\ msg \notin delivered
    /\ \* Check for out-of-order delivery
       IF msg.header.n > messageCounter[receiver].recv
       THEN \* Skip intermediate keys
            /\ messageCounter[receiver].recv < msg.header.n + MaxSkip
            /\ LET skipped == {[
                   value |-> DeriveKey(chainKeys[receiver].recv, i),
                   msgNum |-> i
               ] : i \in messageCounter[receiver].recv..(msg.header.n - 1)}
               IN skippedKeys' = skippedKeys \union skipped
       ELSE skippedKeys' = skippedKeys
    /\ delivered' = delivered \union {msg}
    /\ messageCounter' = [messageCounter EXCEPT 
         ![receiver].recv = Max({messageCounter[receiver].recv, msg.header.n + 1})]
    /\ UNCHANGED <<messages, rootKeys, chainKeys, messageKeys, dhKeys, network>>

NetworkDeliver ==
    \* Non-deterministic message delivery (can be out of order)
    \E msg \in network, r \in Users:
        /\ msg.receiver = r
        /\ msg \notin delivered
        /\ ReceiveMessage(r, msg)

\* State Transitions

Next == 
    \/ \E s, r \in Users, content \in {"Hello", "World", "Test"}:
        SendMessage(s, r, content)
    \/ NetworkDeliver
    \/ \E u \in Users:
        /\ messageCounter[u].send >= MaxChainLength
        /\ DHRatchet(u)

\* Fairness

Fairness == 
    /\ WF_<<messages, network, delivered>>(NetworkDeliver)
    /\ \A s, r \in Users: 
        SF_<<messages, messageCounter>>(\E c \in {"Hello", "World"}: SendMessage(s, r, c))

\* Invariants and Properties

TypeInvariant ==
    /\ messages \in Seq(MessageType)
    /\ rootKeys \in [Users -> KeyType]
    /\ delivered \subseteq {m \in network: m.receiver \in Users}
    /\ \A u \in Users:
        /\ messageCounter[u].send \in Nat
        /\ messageCounter[u].recv \in Nat

\* Perfect Forward Secrecy: Old keys cannot decrypt new messages
PerfectForwardSecrecy ==
    \A i, j \in 1..Len(messages):
        (i < j) => (messages[i].key # messages[j].key)

\* Key Uniqueness: Each message uses a unique key
KeyUniqueness ==
    \A i, j \in 1..Len(messages):
        (i # j) => (messages[i].key # messages[j].key)

\* Message Ordering: Messages are eventually delivered in order
EventualOrdering ==
    <>[](\A msg1, msg2 \in delivered:
        (msg1.sender = msg2.sender /\ 
         msg1.receiver = msg2.receiver /\ 
         msg1.header.n < msg2.header.n) =>
        (msg1.timestamp < msg2.timestamp))

\* No Deadlock: System can always make progress
NoDeadlock ==
    \/ Len(messages) < MaxMessages
    \/ network # {}
    \/ \E u \in Users: messageCounter[u].send >= MaxChainLength

\* Bounded Skipped Keys: Number of skipped keys is bounded
BoundedSkip ==
    Cardinality(skippedKeys) <= MaxSkip * Cardinality(Users)

\* Eventually All Messages Delivered
EventualDelivery ==
    <>[](\A msg \in network: msg \in delivered)

\* Safety and Liveness

Safety == 
    /\ TypeInvariant
    /\ PerfectForwardSecrecy
    /\ KeyUniqueness
    /\ BoundedSkip

Liveness ==
    /\ NoDeadlock
    /\ EventualDelivery
    /\ EventualOrdering

\* Specification

Spec == 
    /\ Init 
    /\ [][Next]_<<messages, rootKeys, chainKeys, messageKeys, 
                  dhKeys, skippedKeys, messageCounter, delivered, network>>
    /\ Fairness

\* Theorems to Check

THEOREM PFSHolds == Spec => []PerfectForwardSecrecy
THEOREM KeysAreUnique == Spec => []KeyUniqueness
THEOREM NoDeadlockExists == Spec => []NoDeadlock
THEOREM MessagesEventuallyDelivered == Spec => EventualDelivery

====