# 形式手法検証ファイル

## 📁 ディレクトリ構成

```
formal-methods/
├── dafny/                    # Dafny検証ファイル
│   ├── CryptoVerification.dfy
│   ├── DoubleRatchet.dfy
│   └── DoubleRatchetProof.dfy
├── alloy/                    # Alloyモデルファイル
│   ├── SecurityModel.als
│   ├── DoubleRatchetModel.als
│   └── DoubleRatchet.als
├── tla/                      # TLA+仕様ファイル
│   ├── DoubleRatchet.tla
│   ├── DoubleRatchetComplete.tla
│   └── formal_verification_demo.tla
├── reports/                  # 検証レポート（空）
└── FORMAL_VERIFICATION_SUMMARY.md  # 検証結果サマリー
```

## 🔬 検証ツール別ファイル

### Dafny (3ファイル)
プログラム検証用の言語で、暗号化アルゴリズムの正当性を証明

1. **CryptoVerification.dfy**
   - AES-GCM暗号化の仕様と証明
   - 暗号化/復号化の可逆性証明
   - 鍵サイズ不変条件の検証

2. **DoubleRatchet.dfy**
   - Double Ratchetアルゴリズムの基本実装
   - 前方秘匿性の仕様記述
   - メッセージキー導出の検証

3. **DoubleRatchetProof.dfy**
   - Double Ratchetの形式的証明
   - セキュリティプロパティの証明
   - 状態遷移の正当性検証

### Alloy (3ファイル)
関係論理に基づくモデル検査ツール

1. **SecurityModel.als**
   - システム全体のセキュリティモデル
   - アクセス制御の仕様
   - 権限管理の検証

2. **DoubleRatchetModel.als**
   - Double Ratchetの抽象モデル
   - 状態遷移の可視化
   - 不変条件の検証

3. **DoubleRatchet.als**
   - Double Ratchet実装の詳細モデル
   - メッセージ順序の保証
   - 鍵管理の一貫性検証

### TLA+ (3ファイル)
時相論理による並行システムの仕様記述

1. **DoubleRatchet.tla**
   - Double Ratchetプロトコルの時相仕様
   - 安全性（Safety）プロパティ
   - 活性（Liveness）プロパティ

2. **DoubleRatchetComplete.tla**
   - 完全版Double Ratchetの仕様
   - メッセージ配信の保証
   - デッドロック検証

3. **formal_verification_demo.tla**
   - 簡易デモ用仕様
   - 基本的な状態遷移
   - 検証手法の例示

## 📊 検証カバレッジ

| 検証項目 | Dafny | Alloy | TLA+ |
|---------|-------|-------|------|
| 暗号化正当性 | ✅ | - | - |
| 鍵管理 | ✅ | ✅ | ⚠️ |
| 状態遷移 | ⚠️ | ✅ | ✅ |
| 並行性 | - | - | ✅ |
| セキュリティ | ✅ | ✅ | ⚠️ |

## 🎯 検証結果

### 証明された性質
- ✅ 暗号化/復号化の可逆性
- ✅ 前方秘匿性（Forward Secrecy）
- ✅ メッセージの完全性
- ✅ デッドロックフリー
- ✅ アクセス制御の健全性

### 発見された問題
- ⚠️ 5接続以上での鍵不整合（Alloyで発見、修正済み）
- ⚠️ ノンス再利用の可能性（TLA+で発見、修正済み）
- ⚠️ 非決定的鍵導出（Dafnyで発見、修正済み）

## 📝 使用方法

### Dafny検証実行
```bash
dafny /compile:0 /print:- CryptoVerification.dfy
```

### Alloyモデル検査
```bash
# Alloy Analyzerで開いて実行
# Run -> Execute でモデル検査
```

### TLA+モデル検査
```bash
# TLC Model Checkerで実行
tlc DoubleRatchet.tla
```

## 🔗 参考資料
- [Dafny Documentation](https://dafny.org/)
- [Alloy Documentation](https://alloytools.org/)
- [TLA+ Documentation](https://lamport.azurewebsites.net/tla/tla.html)

---
*最終更新: 2025年8月9日*