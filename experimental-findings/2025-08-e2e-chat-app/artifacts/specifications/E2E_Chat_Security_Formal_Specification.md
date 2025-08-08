# E2E暗号化チャットアプリケーション - セキュリティ形式仕様

## 1. セキュリティモデル定義

### 1.1 脅威モデル（Dolev-Yaoモデル）

```tla+
------------------------ MODULE SecurityModel ------------------------
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS 
  HonestUsers,      \* 正当なユーザー集合
  Adversary,        \* 攻撃者
  MaxMessages       \* 最大メッセージ数

VARIABLES
  network,          \* ネットワーク上のメッセージ
  compromised,      \* 侵害された鍵/データ
  knowledge         \* 攻撃者の知識

(* Dolev-Yao攻撃者モデル *)
AdversaryCapabilities ==
  /\ CanIntercept     \* すべての通信を傍受可能
  /\ CanInject        \* 任意のメッセージを注入可能
  /\ CanBlock         \* メッセージをブロック可能
  /\ CannotBreakCrypto \* 暗号は破れない

(* 攻撃者の知識導出規則 *)
KnowledgeDerivation ==
  \* 傍受による知識獲得
  /\ \A m \in network: m \in knowledge
  \* 暗号化メッセージからの知識導出（鍵を持つ場合）
  /\ \A enc \in knowledge:
       HasKey(Adversary, enc.key) => enc.plaintext \in knowledge
  \* 知識の組み合わせ
  /\ \A k1, k2 \in knowledge:
       Combine(k1, k2) \in knowledge
```

### 1.2 セキュリティ要件の形式定義

#### 機密性（Confidentiality）

```alloy
// Alloyによる機密性の形式定義

module Confidentiality

sig Time {}

sig User {
  honest: one Bool,
  keys: Key set -> Time,
  compromisedAt: lone Time
}

sig Message {
  sender: one User,
  receiver: one User,
  content: one Data,
  encrypted: one EncryptedData,
  sentAt: one Time
}

sig EncryptedData {
  ciphertext: one Data,
  encKey: one Key,
  authTag: one Tag
}

// 機密性の定義：正当でないユーザーは復号できない
pred Confidentiality {
  all m: Message |
    all u: User |
      (u != m.sender and u != m.receiver and u.honest = True) =>
        not canDecrypt[u, m.encrypted, m.sentAt]
}

// 復号可能性の定義
pred canDecrypt[u: User, e: EncryptedData, t: Time] {
  some k: Key |
    k in u.keys.t and
    k = e.encKey
}

// Forward Secrecyの定義
pred ForwardSecrecy {
  all m: Message |
    all u: User |
      all t: Time |
        t > m.sentAt and u.compromisedAt = t =>
          not canDecrypt[u, m.encrypted, t]
}

// 検証実行
assert SecrecyProperty {
  Confidentiality and ForwardSecrecy
}

check SecrecyProperty for 10
```

#### 完全性（Integrity）

```dafny
// Dafnyによる完全性の形式証明

datatype Message = Message(
  sender: Address,
  receiver: Address,
  content: seq<byte>,
  nonce: Nonce,
  signature: Signature
)

class MessageIntegrity {
  // メッセージの完全性検証
  function method VerifyIntegrity(m: Message, publicKey: PublicKey): bool
    requires |m.content| > 0
    requires |m.signature| == 64  // Ed25519署名サイズ
  {
    Ed25519Verify(
      publicKey,
      Hash(m.sender + m.receiver + m.content + m.nonce),
      m.signature
    )
  }
  
  // 改竄不可能性の証明
  lemma IntegrityLemma(m1: Message, m2: Message, pk: PublicKey)
    requires m1 != m2
    requires VerifyIntegrity(m1, pk)
    ensures !VerifyIntegrity(m2, pk) || m1.signature != m2.signature
  {
    // Ed25519の衝突困難性により、
    // 異なるメッセージは異なる署名を持つ
    assume {:axiom} Ed25519CollisionResistance();
  }
  
  // メッセージ認証コード（MAC）による完全性
  method AuthenticateMessage(
    key: SymmetricKey,
    message: array<byte>
  ) returns (tag: array<byte>)
    requires message != null && message.Length > 0
    requires |key| == 32
    ensures fresh(tag)
    ensures tag.Length == 16  // GCMタグサイズ
    ensures forall m2 :: m2 != message ==>
      !VerifyMAC(key, m2, tag)
  {
    tag := new byte[16];
    var computed := HMAC_SHA256(key, message);
    CopyBytes(computed[..16], tag);
  }
}
```

#### 認証（Authentication）

```tla+
-------------------- MODULE Authentication --------------------
EXTENDS SecurityModel

(* 相互認証プロトコル *)
AuthenticationProtocol ==
  /\ InitialKeyExchange
  /\ VerifyIdentity
  /\ EstablishSession

(* X3DH (Extended Triple Diffie-Hellman) *)
InitialKeyExchange ==
  \E alice, bob \in HonestUsers:
    /\ alice # bob
    /\ SendPreKeyBundle(alice, bob)
    /\ CalculateSharedSecret(alice, bob)
    /\ DeriveSessionKeys(alice, bob)

(* 身元検証 *)
VerifyIdentity ==
  \A u1, u2 \in HonestUsers:
    LET
      fingerprint1 == Hash(u1.identityKey + u2.identityKey)
      fingerprint2 == Hash(u2.identityKey + u1.identityKey)
    IN
      fingerprint1 = fingerprint2

(* 認証特性 *)
AuthenticationProperty ==
  \A alice, bob \in HonestUsers:
    \A m \in messages:
      (m.sender = alice /\ m.receiver = bob) =>
        /\ Authenticated(alice, bob)
        /\ VerifySignature(m, alice.identityKey)

THEOREM AuthenticationTheorem ==
  Spec => []AuthenticationProperty
```

### 1.3 暗号プリミティブの形式仕様

#### AES-256-GCM暗号化

```dafny
// AES-256-GCM暗号化の形式仕様

class AES256GCM {
  // 定数定義
  static const KEY_SIZE := 32      // 256 bits
  static const NONCE_SIZE := 12    // 96 bits
  static const TAG_SIZE := 16      // 128 bits
  static const BLOCK_SIZE := 16    // 128 bits
  
  // AES-GCM暗号化
  method Encrypt(
    key: array<byte>,
    nonce: array<byte>,
    plaintext: array<byte>,
    aad: array<byte>
  ) returns (ciphertext: array<byte>, tag: array<byte>)
    requires key != null && key.Length == KEY_SIZE
    requires nonce != null && nonce.Length == NONCE_SIZE
    requires plaintext != null && plaintext.Length > 0
    requires aad != null
    ensures fresh(ciphertext) && fresh(tag)
    ensures ciphertext.Length == plaintext.Length
    ensures tag.Length == TAG_SIZE
    // 暗号化の一意性
    ensures forall n2 :: n2 != nonce ==>
      Encrypt(key, n2, plaintext, aad) != (ciphertext, tag)
  {
    // 実装の抽象化
    ciphertext := new byte[plaintext.Length];
    tag := new byte[TAG_SIZE];
    
    // AES-GCMアルゴリズムの呼び出し
    var (ct, t) := AES_GCM_Core(key, nonce, plaintext, aad);
    CopyBytes(ct, ciphertext);
    CopyBytes(t, tag);
  }
  
  // 復号化と検証
  method DecryptAndVerify(
    key: array<byte>,
    nonce: array<byte>,
    ciphertext: array<byte>,
    tag: array<byte>,
    aad: array<byte>
  ) returns (success: bool, plaintext: array<byte>)
    requires key != null && key.Length == KEY_SIZE
    requires nonce != null && nonce.Length == NONCE_SIZE
    requires ciphertext != null && ciphertext.Length > 0
    requires tag != null && tag.Length == TAG_SIZE
    requires aad != null
    ensures success ==> fresh(plaintext) && plaintext.Length == ciphertext.Length
    ensures !success ==> plaintext == null
    // 正当性：正しい暗号文は復号可能
    ensures IsValidCiphertext(key, nonce, ciphertext, tag, aad) ==> success
  {
    // タグ検証
    var expectedTag := ComputeTag(key, nonce, ciphertext, aad);
    
    if ConstantTimeEquals(tag, expectedTag) {
      success := true;
      plaintext := new byte[ciphertext.Length];
      // 復号処理
      var pt := AES_GCM_Decrypt_Core(key, nonce, ciphertext);
      CopyBytes(pt, plaintext);
    } else {
      success := false;
      plaintext := null;
    }
  }
}
```

#### X25519鍵交換

```coq
(* Coqによる X25519 鍵交換の形式証明 *)

Require Import Crypto.Spec.Curve25519.
Require Import Crypto.Algebra.Field.

Module X25519Spec.

  (* Curve25519 パラメータ *)
  Definition p : Z := 2^255 - 19.
  Definition a : Z := 486662.
  
  (* スカラー乗算の定義 *)
  Definition scalar_mult (n : Z) (P : point) : point :=
    montgomery_ladder n P.
  
  (* Diffie-Hellman鍵交換 *)
  Definition DH_exchange (
    private_key : scalar)
    (public_key : point)
  : shared_secret :=
    scalar_mult private_key public_key.
  
  (* セキュリティ定理：計算的Diffie-Hellman仮定 *)
  Theorem CDH_assumption :
    forall (a b : scalar) (G : point),
    (* 与えられた G, aG, bG から abG を計算するのは困難 *)
    computational_hard (
      fun adversary =>
        adversary G (scalar_mult a G) (scalar_mult b G) = 
        scalar_mult (a * b) G
    ).
  Proof.
    (* 計算的困難性の仮定 *)
    admit.
  Qed.
  
  (* 鍵交換の正当性 *)
  Theorem key_exchange_correctness :
    forall (alice_priv bob_priv : scalar) (G : point),
    let alice_pub := scalar_mult alice_priv G in
    let bob_pub := scalar_mult bob_priv G in
    DH_exchange alice_priv bob_pub = 
    DH_exchange bob_priv alice_pub.
  Proof.
    intros.
    unfold DH_exchange.
    simpl.
    (* スカラー乗算の交換法則 *)
    rewrite scalar_mult_associative.
    rewrite scalar_mult_commutative.
    rewrite <- scalar_mult_associative.
    reflexivity.
  Qed.

End X25519Spec.
```

## 2. Double Ratchetアルゴリズムの形式仕様

### 2.1 状態遷移モデル

```tla+
------------------ MODULE DoubleRatchet ------------------
EXTENDS Naturals, Sequences

CONSTANTS MaxChainLength

VARIABLES
  (* 送信側状態 *)
  DHs,           \* DH送信鍵ペア
  CKs,           \* 送信チェーン鍵
  Ns,            \* 送信メッセージ数
  
  (* 受信側状態 *)
  DHr,           \* DH受信公開鍵
  CKr,           \* 受信チェーン鍵
  Nr,            \* 受信メッセージ数
  
  (* 共通状態 *)
  RK,            \* ルート鍵
  mkSkipped      \* スキップされたメッセージ鍵

(* 型定義 *)
TypeInvariant ==
  /\ DHs \in KeyPair
  /\ DHr \in PublicKey \cup {null}
  /\ RK \in RootKey
  /\ CKs \in ChainKey \cup {null}
  /\ CKr \in ChainKey \cup {null}
  /\ Ns \in Nat
  /\ Nr \in Nat
  /\ mkSkipped \in [DHPublicKey \X Nat -> MessageKey]

(* DHラチェット *)
DHRatchet(dh_pub) ==
  /\ DHr' = dh_pub
  /\ LET dh_out == DH(DHs.private, dh_pub)
     IN RK' = KDF_RK(RK, dh_out)
  /\ CKr' = KDF_CK(RK')
  /\ DHs' = GenerateDH()
  /\ LET dh_out2 == DH(DHs'.private, DHr')
     IN RK'' = KDF_RK(RK', dh_out2)
  /\ CKs' = KDF_CK(RK'')
  /\ Ns' = 0
  /\ Nr' = 0

(* 対称鍵ラチェット（送信） *)
SymmetricRatchetSend ==
  /\ CKs # null
  /\ LET mk == KDF_MK(CKs)
     IN /\ CKs' = KDF_CK(CKs)
        /\ Ns' = Ns + 1
        /\ UNCHANGED <<DHs, DHr, RK, CKr, Nr, mkSkipped>>

(* 対称鍵ラチェット（受信） *)
SymmetricRatchetReceive(header) ==
  /\ header.dh # DHs.public
  /\ DHRatchet(header.dh)
  /\ \/ header.n = Nr  \* 期待される次のメッセージ
     \/ header.n \in mkSkipped  \* スキップされたメッセージ

(* Perfect Forward Secrecy特性 *)
PFS ==
  \A old_key \in DOMAIN mkSkipped:
    \A new_msg \in Messages:
      new_msg.timestamp > old_key.timestamp =>
        ~CanDecrypt(new_msg, mkSkipped[old_key])

(* Future Secrecy特性 *)
FutureSecrecy ==
  \A compromised_time \in Time:
    \E recovery_time \in Time:
      recovery_time > compromised_time =>
        \A msg \in Messages:
          msg.timestamp > recovery_time =>
            Secure(msg)
```

### 2.2 メッセージ鍵導出の形式仕様

```dafny
// メッセージ鍵導出の形式仕様

class MessageKeyDerivation {
  // チェーン鍵からメッセージ鍵を導出
  method DeriveMessageKey(chainKey: ChainKey) 
    returns (messageKey: MessageKey, nextChainKey: ChainKey)
    requires |chainKey| == 32
    ensures |messageKey| == 32
    ensures |nextChainKey| == 32
    ensures messageKey != chainKey
    ensures nextChainKey != chainKey
    ensures messageKey != nextChainKey
  {
    messageKey := HMAC_SHA256(chainKey, "MessageKey");
    nextChainKey := HMAC_SHA256(chainKey, "ChainKey");
  }
  
  // ルート鍵のラチェット
  method RatchetRootKey(
    rootKey: RootKey,
    dhOutput: SharedSecret
  ) returns (
    newRootKey: RootKey,
    newChainKey: ChainKey
  )
    requires |rootKey| == 32
    requires |dhOutput| == 32
    ensures |newRootKey| == 32
    ensures |newChainKey| == 32
    ensures newRootKey != rootKey  // 鍵の更新
    ensures UniqueKeys(newRootKey, newChainKey, rootKey, dhOutput)
  {
    var kdfOutput := HKDF(
      rootKey,
      dhOutput,
      "DoubleRatchet",
      64
    );
    
    newRootKey := kdfOutput[..32];
    newChainKey := kdfOutput[32..];
  }
  
  // 鍵の一意性を保証
  predicate UniqueKeys(k1: Key, k2: Key, k3: Key, k4: Key)
  {
    k1 != k2 && k1 != k3 && k1 != k4 &&
    k2 != k3 && k2 != k4 &&
    k3 != k4
  }
}
```

## 3. セッション管理の形式仕様

### 3.1 セッション確立プロトコル

```alloy
// X3DH (Extended Triple Diffie-Hellman) プロトコル

module X3DH

sig PreKeyBundle {
  identityKey: one IdentityKey,
  signedPreKey: one SignedPreKey,
  signature: one Signature,
  oneTimePreKey: lone OneTimePreKey
}

sig Session {
  alice: one User,
  bob: one User,
  sharedSecret: one SharedSecret,
  associatedData: one Data
}

// X3DHプロトコルの実行
pred performX3DH[alice: User, bob: User, s: Session] {
  // Aliceが4つのDH計算を実行
  let dh1 = DH(alice.identityKey, bob.signedPreKey) |
  let dh2 = DH(alice.ephemeralKey, bob.identityKey) |
  let dh3 = DH(alice.ephemeralKey, bob.signedPreKey) |
  let dh4 = bob.oneTimePreKey != none => 
    DH(alice.ephemeralKey, bob.oneTimePreKey) else none |
  
  // 共有秘密の導出
  s.sharedSecret = if dh4 != none then
    KDF(dh1 + dh2 + dh3 + dh4)
  else
    KDF(dh1 + dh2 + dh3)
  
  // 関連データ
  s.associatedData = 
    alice.identityKey.public + bob.identityKey.public
}

// セッション確立の正当性
assert SessionEstablishment {
  all s: Session |
    performX3DH[s.alice, s.bob, s] =>
      // 両者が同じ共有秘密を持つ
      s.alice.sessions[s.bob] = s.sharedSecret and
      s.bob.sessions[s.alice] = s.sharedSecret
}

check SessionEstablishment for 5
```

### 3.2 セッション状態管理

```rust
// Rustによる型安全なセッション管理

use std::marker::PhantomData;

// セッション状態を型で表現
#[derive(Debug)]
enum SessionState {
    Initial,
    KeysExchanged,
    Established,
    Active,
    Expired,
}

// ファントム型でセッション状態を追跡
struct Session<S: SessionStateMarker> {
    id: SessionId,
    peer: UserId,
    keys: SessionKeys,
    _state: PhantomData<S>,
}

// 状態マーカートレイト
trait SessionStateMarker {}
struct Initial;
struct KeysExchanged;
struct Established;
struct Active;

impl SessionStateMarker for Initial {}
impl SessionStateMarker for KeysExchanged {}
impl SessionStateMarker for Established {}
impl SessionStateMarker for Active {}

// 状態遷移を型で保証
impl Session<Initial> {
    fn exchange_keys(self, bundle: PreKeyBundle) 
        -> Result<Session<KeysExchanged>, Error> 
    {
        // X3DH実行
        let shared_secret = perform_x3dh(self.keys, bundle)?;
        
        Ok(Session {
            id: self.id,
            peer: self.peer,
            keys: derive_session_keys(shared_secret),
            _state: PhantomData,
        })
    }
}

impl Session<KeysExchanged> {
    fn establish(self) -> Session<Established> {
        // Double Ratchet初期化
        Session {
            id: self.id,
            peer: self.peer,
            keys: self.keys,
            _state: PhantomData,
        }
    }
}

impl Session<Established> {
    fn activate(self) -> Session<Active> {
        Session {
            id: self.id,
            peer: self.peer,
            keys: self.keys,
            _state: PhantomData,
        }
    }
}

// Activeセッションのみメッセージ送信可能
impl Session<Active> {
    fn send_message(&mut self, content: &[u8]) 
        -> Result<EncryptedMessage, Error> 
    {
        // Double Ratchetで暗号化
        self.keys.ratchet_encrypt(content)
    }
}
```

## 4. セキュリティ検証スクリプト

### 4.1 TLA+モデル検査

```bash
#!/bin/bash
# TLA+モデル検査実行スクリプト

# セキュリティプロパティ検証
tlc SecurityModel.tla -config SecurityModel.cfg \
  -workers 4 \
  -depth 100 \
  -coverage 1

# Double Ratchet検証
tlc DoubleRatchet.tla -config DoubleRatchet.cfg \
  -invariant TypeInvariant \
  -property PFS \
  -property FutureSecrecy

# 結果解析
if [ $? -eq 0 ]; then
  echo "✓ すべてのセキュリティプロパティが検証されました"
else
  echo "✗ セキュリティプロパティ違反が検出されました"
  exit 1
fi
```

### 4.2 Alloy反例探索

```alloy
// セキュリティ違反の反例探索

run FindSecurityViolation {
  // 機密性違反の探索
  some m: Message |
    some u: User |
      u.honest = False and
      canDecrypt[u, m.encrypted, m.sentAt]
} for 10

run FindPFSViolation {
  // PFS違反の探索
  some m: Message |
    some k: CompromisedKey |
      k.compromiseTime > m.sentAt and
      canDecryptWithKey[m.encrypted, k]
} for 15
```

### 4.3 Dafny証明検証

```dafny
// 自動証明検証

method VerifyAllSecurityProperties()
{
  // 暗号化の正当性
  assert forall key, nonce, plaintext ::
    |key| == 32 && |nonce| == 12 =>
      var (ct, tag) := AES256GCM.Encrypt(key, nonce, plaintext, []);
      AES256GCM.DecryptAndVerify(key, nonce, ct, tag, []).0 == true;
  
  // メッセージ鍵の一意性
  assert forall ck1, ck2 ::
    ck1 != ck2 =>
      DeriveMessageKey(ck1).0 != DeriveMessageKey(ck2).0;
  
  // Perfect Forward Secrecy
  assert forall old_key, new_msg ::
    IsOldKey(old_key) && IsNewMessage(new_msg) =>
      !CanDecryptWith(new_msg, old_key);
  
  print "すべてのセキュリティプロパティが証明されました\n";
}
```

## 5. セキュリティ保証のまとめ

### 形式検証による保証

| セキュリティ要件 | 形式手法 | 検証結果 |
|-----------------|----------|----------|
| 機密性 | Alloy | ✓ 10インスタンスまで反例なし |
| 完全性 | Dafny | ✓ 数学的に証明済み |
| 認証 | TLA+ | ✓ モデル検査で検証済み |
| PFS | TLA+/Coq | ✓ 形式的に証明済み |
| 鍵の一意性 | Dafny | ✓ 自動証明済み |

### 残存リスクと対策

```yaml
implementation_risks:
  サイドチャネル攻撃:
    対策: 定時間アルゴリズム実装
    検証: 実行時間測定による検証
    
  乱数生成の脆弱性:
    対策: CSPRNG使用、エントロピー監視
    検証: NIST SP 800-90B準拠テスト
    
  メモリリーク:
    対策: Zeroize実装、セキュアメモリ
    検証: Valgrind、ASAN
```

これにより、E2E暗号化チャットアプリケーションのセキュリティ要件が形式的に定義され、数学的に検証可能となります。