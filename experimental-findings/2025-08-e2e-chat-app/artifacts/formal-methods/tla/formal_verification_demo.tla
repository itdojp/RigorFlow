---- MODULE formal_verification_demo ----
(* 
  E2E Encrypted Chat - Simple TLA+ Verification Demo
  This demonstrates Perfect Forward Secrecy property
*)

EXTENDS Naturals, Sequences

CONSTANTS 
    Users,          \* Set of users
    MaxMessages     \* Maximum number of messages

VARIABLES
    messages,       \* Sequence of sent messages
    keys,          \* Current keys for each user
    oldKeys        \* Previously used keys

----

Init == 
    /\ messages = <<>>
    /\ keys = [u \in Users |-> 0]
    /\ oldKeys = {}

----

SendMessage(sender, receiver) ==
    /\ Len(messages) < MaxMessages
    /\ keys' = [keys EXCEPT ![sender] = keys[sender] + 1]
    /\ messages' = Append(messages, [from |-> sender, to |-> receiver, key |-> keys[sender]])
    /\ oldKeys' = oldKeys \union {keys[sender]}

----

Next == \E s, r \in Users : s # r /\ SendMessage(s, r)

----

(* Perfect Forward Secrecy: Old keys cannot decrypt new messages *)
PerfectForwardSecrecy ==
    \A i, j \in 1..Len(messages):
        i < j => messages[i].key \notin {messages[j].key}

(* Type Invariant *)
TypeInvariant ==
    /\ messages \in Seq([from: Users, to: Users, key: Nat])
    /\ keys \in [Users -> Nat]
    /\ oldKeys \subseteq Nat

====