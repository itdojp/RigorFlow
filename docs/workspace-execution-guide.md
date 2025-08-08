# ワークスペース実行環境ガイド

## 概要

Claude Code等のワークスペース実行環境を使用したAIチャット駆動開発のための追加ガイドです。ファイルシステム、実行環境、テスト自動化を活用した実践的な開発手法を説明します。

## 1. プロジェクト構造の標準化

### 1.1 基本ディレクトリ構造

```
project-root/
├── .ai/                    # AI開発用メタデータ
│   ├── diagnosis.yaml      # プロジェクト診断結果
│   ├── formal-specs/       # 形式的仕様（必要な場合）
│   │   ├── tla/           # TLA+仕様
│   │   └── dafny/         # Dafny仕様
│   └── decisions.md        # 設計決定記録
├── docs/
│   ├── requirements/       # 要求仕様
│   │   └── scenarios.feature  # BDDシナリオ
│   └── architecture/       # アーキテクチャ文書
├── src/                    # ソースコード
├── tests/                  # テストコード
│   ├── unit/              # ユニットテスト
│   ├── integration/       # 統合テスト
│   └── e2e/               # E2Eテスト
├── scripts/                # 開発支援スクリプト
│   ├── setup.sh           # 環境セットアップ
│   ├── test.sh            # テスト実行
│   └── verify.sh          # 仕様検証
├── .github/                # CI/CD設定
│   └── workflows/
└── README.md              # プロジェクト説明
```

### 1.2 初期セットアップコマンド

```bash
# AIへの指示例
「プロジェクトの初期構造を作成してください」

# AIが実行するコマンド
mkdir -p .ai/{formal-specs/{tla,dafny}} docs/{requirements,architecture}
mkdir -p src tests/{unit,integration,e2e} scripts
touch .ai/diagnosis.yaml .ai/decisions.md
touch docs/requirements/scenarios.feature
echo "# Project Name" > README.md
```

## 2. 診断結果の永続化

### 2.1 診断結果ファイル（.ai/diagnosis.yaml）

```yaml
# AIが生成・更新する診断ファイル
project:
  name: "zero-knowledge-janken"
  type: "web-application"
  created: "2024-01-01"
  
diagnosis:
  risk_level: "medium"
  complexity: "high"
  critical_features:
    - "cryptographic_operations"
    - "real_time_communication"
    
formal_methods:
  selected_levels:
    - level: 0
      scope: "all"
      reason: "baseline"
    - level: 1
      scope: "all"
      reason: "behavior specification"
    - level: 4
      scope: "crypto_module"
      reason: "cryptographic correctness"
      
implementation:
  languages:
    backend: "python"  # or any chosen language
    frontend: "typescript"
  frameworks:
    backend: "fastapi"
    frontend: "react"
    
testing_strategy:
  unit_test_framework: "pytest"
  e2e_framework: "playwright"
  coverage_target: 90
```

### 2.2 AIとの対話での活用

```markdown
「診断結果を確認して、現在の設定を教えてください」

AI: 「.ai/diagnosis.yaml を読み込みます...
    現在の設定：
    - 形式手法: Level 0,1（全体）、Level 4（暗号部分）
    - 実装言語: Python (FastAPI) + TypeScript (React)
    - テスト: pytest + playwright」
```

## 3. TDDサイクルの実行可能化

### 3.1 RED フェーズ（テスト作成と実行）

```markdown
## AIへの指示
「commitment作成機能のテストを作成して実行してください」

## AIの動作
1. テストファイル作成
2. テスト実行
3. 失敗確認
```

```python
# AIが生成: tests/unit/test_crypto.py
import pytest
from src.crypto import create_commitment  # まだ存在しない

def test_create_commitment():
    move = "rock"
    nonce = 12345
    
    commitment = create_commitment(move, nonce)
    
    assert len(commitment) == 64
    assert isinstance(commitment, str)
```

```bash
# AIが実行
$ python -m pytest tests/unit/test_crypto.py -v

# 結果をAIが解釈
FAILED: ImportError: cannot import name 'create_commitment'
→ 期待通りの失敗です。次は最小実装を作成します。
```

### 3.2 GREEN フェーズ（実装と成功確認）

```python
# AIが生成: src/crypto.py
def create_commitment(move: str, nonce: int) -> str:
    """最小実装：テストを通すだけ"""
    return "0" * 64
```

```bash
# AIが実行
$ python -m pytest tests/unit/test_crypto.py -v

# 結果
PASSED
→ テスト成功。次はより現実的なテストを追加します。
```

### 3.3 REFACTOR フェーズ（改善と再確認）

```python
# AIが改善: src/crypto.py
import hashlib
import json

def create_commitment(move: str, nonce: int) -> str:
    """実際のハッシュ実装"""
    data = json.dumps({"move": move, "nonce": nonce}, sort_keys=True)
    return hashlib.sha256(data.encode()).hexdigest()
```

```bash
# AIが実行して確認
$ python -m pytest tests/unit/test_crypto.py -v
PASSED

# カバレッジも確認
$ python -m pytest --cov=src --cov-report=term-missing
Coverage: 100%
```

## 4. 継続的な品質チェック

### 4.1 自動テスト実行スクリプト

```bash
# scripts/test.sh - AIが生成
#!/bin/bash
set -e

echo "=== Running Tests ==="

# Unit tests
echo "Unit tests..."
python -m pytest tests/unit/ -v

# Integration tests  
echo "Integration tests..."
python -m pytest tests/integration/ -v

# Coverage check
echo "Coverage check..."
python -m pytest --cov=src --cov-report=html --cov-fail-under=80

echo "=== All Tests Passed ==="
```

### 4.2 ウォッチモード開発

```markdown
「ファイル変更を監視して自動テストを実行する設定をしてください」

AI: 「watchモードを設定します」
```

```bash
# AIが実行
pip install pytest-watch

# ウォッチモード開始
ptw -- --verbose

# 別ターミナルで開発を継続
# ファイル保存時に自動でテスト実行
```

## 5. 形式的仕様の実行可能検証

### 5.1 TLA+仕様の検証（Level 3使用時）

```bash
# AIが .ai/formal-specs/tla/game.tla を作成後
$ tlc game.tla -config game.cfg

# AIが結果を解釈
「モデル検査完了：
 - 状態数: 1,234
 - デッドロック: なし
 - 不変条件違反: なし」
```

### 5.2 Property Based Testing の実行

```python
# AIが生成: tests/unit/test_properties.py
from hypothesis import given, strategies as st
from src.game import judge_winner

@given(
    move1=st.sampled_from(["rock", "paper", "scissors"]),
    move2=st.sampled_from(["rock", "paper", "scissors"])
)
def test_game_properties(move1, move2):
    result = judge_winner(move1, move2)
    
    # 対称性のチェック
    if move1 == move2:
        assert result == "draw"
    
    # 結果の妥当性
    assert result in ["player1", "player2", "draw"]
```

```bash
# AIが実行
$ python -m pytest tests/unit/test_properties.py --hypothesis-show-statistics
```

## 6. 統合テストの実行

### 6.1 ローカル環境での統合テスト

```python
# AIが生成: tests/integration/test_api.py
import pytest
from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_full_game_flow():
    # 1. Create game session
    response = client.post("/games")
    game_id = response.json()["id"]
    
    # 2. Player 1 commits
    response = client.post(f"/games/{game_id}/commit", 
                          json={"player": 1, "commitment": "..."})
    assert response.status_code == 200
    
    # 3. Player 2 commits
    response = client.post(f"/games/{game_id}/commit",
                          json={"player": 2, "commitment": "..."})
    assert response.status_code == 200
    
    # 4. Reveal and verify
    response = client.post(f"/games/{game_id}/reveal",
                          json={"player": 1, "move": "rock", "nonce": 123})
    assert response.status_code == 200
```

```bash
# AIが実行
$ python -m pytest tests/integration/ -v
```

### 6.2 Docker環境での統合テスト

```yaml
# AIが生成: docker-compose.test.yml
version: '3.8'
services:
  app:
    build: .
    environment:
      - TESTING=true
    ports:
      - "8000:8000"
      
  test-runner:
    build: .
    command: pytest tests/e2e/ -v
    depends_on:
      - app
    environment:
      - API_URL=http://app:8000
```

```bash
# AIが実行
$ docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## 7. 実行環境特有のAI対話パターン

### 7.1 エラー診断と修正

```markdown
ユーザー: 「テストを実行して」

AI: 「実行します...」
[実際にテスト実行]

AI: 「エラーが発生しました：
    ```
    AssertionError: Expected 64, got 32
    ```
    ハッシュ関数の出力長が間違っています。修正します...」
[ファイルを直接修正]

AI: 「修正完了。再実行します...」
[再度テスト実行]

AI: 「テスト成功しました。」
```

### 7.2 パフォーマンス分析

```markdown
「パフォーマンステストを実行してボトルネックを特定して」

AI: 「プロファイリングを実行します...」
```

```bash
# AIが実行
$ python -m cProfile -o profile.stats src/benchmark.py
$ python -m pstats profile.stats

# AIが結果を分析
「ボトルネック発見：
 - create_commitment: 45% の時間
 - 最適化案：ハッシュ計算をキャッシュ」
```

### 7.3 継続的な監視

```markdown
「開発を監視モードで進めたい」

AI: 「以下を並行実行します：
    1. テストウォッチャー
    2. タイプチェッカー
    3. リンター
    4. カバレッジ監視」
```

```bash
# Terminal 1: Test watcher
$ ptw

# Terminal 2: Type checker (TypeScript/Python)
$ mypy --watch src/

# Terminal 3: Linter
$ flake8 --watch src/

# Terminal 4: Coverage
$ python -m pytest --cov --cov-report=html --watch
```

## 8. CI/CD との連携

### 8.1 GitHub Actions 設定

```yaml
# AIが生成: .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
          
      - name: Run tests
        run: |
          python -m pytest --cov --cov-report=xml
          
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### 8.2 ローカルでのCI確認

```bash
# AIが実行（CI実行前の確認）
$ act  # GitHub Actions をローカルで実行

# または
$ ./scripts/ci-check.sh  # CI相当のチェック
```

## 9. プロジェクト状態の可視化

### 9.1 進捗ダッシュボード

```markdown
「現在のプロジェクト状態をサマリーして」

AI: 「プロジェクト状態を分析します...」
```

```python
# AIが実行して結果表示
import os
import subprocess

def project_summary():
    # Test coverage
    coverage = subprocess.run(["pytest", "--cov", "--co"], 
                            capture_output=True, text=True)
    
    # Line count
    loc = subprocess.run(["cloc", "src/"], 
                        capture_output=True, text=True)
    
    # TODO count
    todos = subprocess.run(["grep", "-r", "TODO", "src/"], 
                          capture_output=True, text=True)
    
    print(f"""
    📊 Project Status
    ================
    Coverage: 87%
    Tests: 45 passed, 0 failed
    Code: 1,234 lines
    TODOs: 3
    
    ✅ Ready for next phase
    """)

project_summary()
```

## 10. ベストプラクティス

### 10.1 ファイル変更の追跡

```yaml
# .ai/decisions.md に自動記録
## 2024-01-15: TDD Cycle 1
- Added: tests/unit/test_crypto.py
- Added: src/crypto.py
- Reason: Implementing commitment creation
- Test-first approach confirmed

## 2024-01-15: Refactoring
- Modified: src/crypto.py
- Reason: Replaced mock with actual SHA256
- All tests still passing
```

### 10.2 バージョン管理との統合

```bash
# AIが適切にコミット
$ git add -A
$ git commit -m "feat: Add commitment creation with TDD

- Add unit test for create_commitment
- Implement minimal passing solution
- Refactor to use actual SHA256
- Coverage: 100%"
```

### 10.3 環境の再現性確保

```dockerfile
# AIが生成: Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements*.txt ./
RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt

COPY . .

CMD ["pytest", "--cov"]
```

## 11. フルスタック開発への拡張

本ガイドは基本的な実行環境を扱っていますが、実際のプロジェクトでは以下の要素も必要です：

### 統合が必要な要素
- **データベース永続化**: スキーマ設計、マイグレーション、トランザクション
- **フロントエンド開発**: UI/UXテスト、コンポーネント開発、状態管理
- **CI/CDパイプライン**: 自動テスト、ビルド、デプロイ
- **API設計**: OpenAPI/GraphQL仕様、認証・認可
- **運用考慮**: ロギング、モニタリング、パフォーマンス

これらの詳細は「**フルスタック開発統合ガイド**」を参照してください。

### AIへの指示例
```markdown
「フルスタック構成で開発を始めたい」

AI: 「フルスタック開発統合ガイドに基づいて、
    以下を設定します：
    - データベース（PostgreSQL）
    - フロントエンド（React + TypeScript）
    - バックエンド（FastAPI）
    - CI/CD（GitHub Actions）」
```

## まとめ

ワークスペース実行環境により：

1. **実際の実行とフィードバック**: テスト結果を即座に確認
2. **TDDサイクルの完全実施**: RED-GREEN-REFACTORを実際に体験
3. **継続的な品質監視**: カバレッジ、パフォーマンスをリアルタイム確認
4. **エラーの即座の修正**: 実行結果を見て即座に対応
5. **CI/CDの事前確認**: プッシュ前にローカルで完全検証
6. **フルスタック対応**: DB、フロントエンド、インフラまで統合可能

これらにより、AIとの対話がより実践的で生産的になります。