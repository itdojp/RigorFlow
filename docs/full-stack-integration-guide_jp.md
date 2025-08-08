# フルスタック開発統合ガイド

## 概要

AIチャット駆動開発で見落としがちな要素（DB、フロントエンド、CI/CD等）を本開発フローに統合するためのガイドです。各要素を適切なフェーズに組み込み、TDDサイクルと連携させます。

## 1. 拡張されたプロジェクト構造

```
project-root/
├── .ai/
│   ├── diagnosis.yaml           # プロジェクト診断
│   ├── architecture.yaml        # アーキテクチャ決定
│   └── decisions.md             # 設計決定記録
├── backend/                     # バックエンド
│   ├── src/
│   ├── tests/
│   └── migrations/              # DB マイグレーション
├── frontend/                    # フロントエンド
│   ├── src/
│   ├── tests/
│   └── public/
├── database/                    # データベース
│   ├── schema/                 # スキーマ定義
│   ├── seeds/                   # シードデータ
│   └── migrations/              # マイグレーション
├── api/                         # API定義
│   ├── openapi.yaml            # OpenAPI仕様
│   └── postman/                # Postmanコレクション
├── infrastructure/              # インフラ
│   ├── docker/                 # Docker設定
│   ├── kubernetes/              # K8s設定
│   └── terraform/               # IaC設定
├── .github/                     # CI/CD
│   └── workflows/
├── docs/                        # ドキュメント
│   ├── architecture/
│   ├── api/
│   └── deployment/
└── scripts/                     # 補助スクリプト
    ├── setup-db.sh
    ├── setup-frontend.sh
    └── deploy.sh
```

## 2. フェーズ別統合方法

### Phase 0: 診断時の技術スタック決定

```yaml
# .ai/architecture.yaml - AIが生成
architecture:
  frontend:
    framework: "react"  # or vue, angular, svelte
    language: "typescript"
    testing: "jest + react-testing-library"
    build: "vite"
    
  backend:
    framework: "fastapi"  # or express, django, rails
    language: "python"
    testing: "pytest"
    
  database:
    type: "postgresql"  # or mysql, mongodb, dynamodb
    orm: "sqlalchemy"  # or prisma, typeorm
    migration: "alembic"
    
  api:
    style: "rest"  # or graphql, grpc
    documentation: "openapi"
    
  infrastructure:
    container: "docker"
    orchestration: "kubernetes"  # or docker-compose
    ci_cd: "github-actions"
    hosting: "aws"  # or gcp, azure, vercel
    
  monitoring:
    logging: "winston"  # or pino, bunyan
    apm: "datadog"  # or newrelic, sentry
    metrics: "prometheus"
```

#### AIへの診断拡張

```markdown
「プロジェクト診断を実施し、フルスタック構成を決定してください：

プロジェクト情報：[...]

以下も決定してください：
1. フロントエンドフレームワーク
2. データベース選択
3. API設計方針
4. デプロイ先
5. CI/CDツール」
```

### Phase 1: 要求定義での全体考慮

#### データベース要求の追加

```gherkin
# BDDシナリオにDB観点を追加
Feature: ゲームデータ永続化
  
  Scenario: ゲーム履歴の保存
    Given プレイヤーがゲームを完了
    When 結果が確定する
    Then ゲーム履歴がデータベースに保存される
    And プレイヤーの統計が更新される
    
  Scenario: データ整合性の保証
    Given 同時に複数のゲームが進行中
    When データベースに同時書き込みが発生
    Then トランザクションにより整合性が保たれる
```

#### フロントエンド要求の追加

```gherkin
Feature: ユーザーインターフェース
  
  Scenario: レスポンシブデザイン
    Given ユーザーがモバイルデバイスでアクセス
    When 画面を表示
    Then モバイル最適化されたUIが表示される
    
  Scenario: リアルタイム更新
    Given ゲーム進行中
    When 相手がアクションを実行
    Then 画面が自動的に更新される
```

### Phase 2-3: 設計・仕様でのDB/UI考慮

#### データベーススキーマ設計

```markdown
「データベーススキーマを設計してTDDで実装してください」

AI: 「まずスキーマテストから作成します」
```

```python
# AIが生成: backend/tests/test_models.py
import pytest
from sqlalchemy import create_engine
from backend.src.models import User, Game, Move

def test_user_model():
    """ユーザーモデルのテスト"""
    user = User(username="player1", email="player1@test.com")
    assert user.username == "player1"
    assert user.created_at is not None

def test_game_relationships():
    """ゲームと関連エンティティのテスト"""
    game = Game()
    player1 = User(username="player1")
    player2 = User(username="player2")
    
    game.player1 = player1
    game.player2 = player2
    
    assert game.player1.username == "player1"
    assert len(player1.games_as_player1) == 1

def test_database_constraints():
    """データベース制約のテスト"""
    # ユニーク制約、外部キー制約等のテスト
    pass
```

```python
# AIが生成: backend/src/models.py
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.src.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    games_as_player1 = relationship("Game", back_populates="player1", 
                                   foreign_keys="Game.player1_id")
    games_as_player2 = relationship("Game", back_populates="player2",
                                   foreign_keys="Game.player2_id")

class Game(Base):
    __tablename__ = "games"
    
    id = Column(Integer, primary_key=True)
    player1_id = Column(Integer, ForeignKey("users.id"))
    player2_id = Column(Integer, ForeignKey("users.id"))
    winner_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String(20), default="pending")
    
    # Relationships
    player1 = relationship("User", foreign_keys=[player1_id])
    player2 = relationship("User", foreign_keys=[player2_id])
    moves = relationship("Move", back_populates="game")
```

#### フロントエンドコンポーネント設計

```markdown
「フロントエンドコンポーネントをTDDで開発してください」

AI: 「コンポーネントテストから始めます」
```

```typescript
// AIが生成: frontend/tests/GameBoard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { GameBoard } from '../src/components/GameBoard';

describe('GameBoard Component', () => {
  test('displays game status', () => {
    render(<GameBoard status="waiting" />);
    expect(screen.getByText(/waiting for opponent/i)).toBeInTheDocument();
  });
  
  test('handles move selection', () => {
    const onMove = jest.fn();
    render(<GameBoard onMove={onMove} />);
    
    fireEvent.click(screen.getByRole('button', { name: /rock/i }));
    expect(onMove).toHaveBeenCalledWith('rock');
  });
  
  test('disables moves when game is over', () => {
    render(<GameBoard status="finished" />);
    
    const rockButton = screen.getByRole('button', { name: /rock/i });
    expect(rockButton).toBeDisabled();
  });
});
```

```tsx
// AIが生成: frontend/src/components/GameBoard.tsx
import React, { useState } from 'react';

interface GameBoardProps {
  status: 'waiting' | 'playing' | 'finished';
  onMove?: (move: string) => void;
}

export const GameBoard: React.FC<GameBoardProps> = ({ status, onMove }) => {
  const [selectedMove, setSelectedMove] = useState<string | null>(null);
  
  const handleMove = (move: string) => {
    if (status !== 'playing') return;
    setSelectedMove(move);
    onMove?.(move);
  };
  
  return (
    <div className="game-board">
      <div className="status">
        {status === 'waiting' && 'Waiting for opponent...'}
        {status === 'playing' && 'Make your move!'}
        {status === 'finished' && 'Game Over'}
      </div>
      
      <div className="moves">
        {['rock', 'paper', 'scissors'].map(move => (
          <button
            key={move}
            onClick={() => handleMove(move)}
            disabled={status !== 'playing'}
            className={selectedMove === move ? 'selected' : ''}
          >
            {move}
          </button>
        ))}
      </div>
    </div>
  );
};
```

### Phase 4-5: 統合テストでのフルスタック検証

#### データベース統合テスト

```python
# AIが生成: backend/tests/integration/test_db_operations.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture
def db_session():
    """テスト用DBセッション"""
    engine = create_engine("postgresql://test@localhost/test_db")
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    session.rollback()
    session.close()

def test_concurrent_game_creation(db_session):
    """並行ゲーム作成のテスト"""
    # トランザクション分離レベルのテスト
    pass

def test_cascade_delete(db_session):
    """カスケード削除のテスト"""
    user = User(username="test_user")
    game = Game(player1=user)
    
    db_session.add(user)
    db_session.commit()
    
    db_session.delete(user)
    db_session.commit()
    
    # ゲームも削除されることを確認
    assert db_session.query(Game).filter_by(player1_id=user.id).first() is None
```

#### フロントエンド統合テスト

```typescript
// AIが生成: frontend/tests/integration/game-flow.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { App } from '../../src/App';
import { server } from '../mocks/server';

describe('Complete Game Flow', () => {
  beforeAll(() => server.listen());
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
  
  test('full game from start to finish', async () => {
    const user = userEvent.setup();
    render(<App />);
    
    // 1. ログイン
    await user.type(screen.getByLabelText(/username/i), 'player1');
    await user.click(screen.getByRole('button', { name: /login/i }));
    
    // 2. ゲーム開始
    await user.click(screen.getByRole('button', { name: /start game/i }));
    
    // 3. マッチング待機
    await waitFor(() => {
      expect(screen.getByText(/opponent found/i)).toBeInTheDocument();
    });
    
    // 4. 手を選択
    await user.click(screen.getByRole('button', { name: /rock/i }));
    
    // 5. 結果確認
    await waitFor(() => {
      expect(screen.getByText(/you won|you lost|draw/i)).toBeInTheDocument();
    });
    
    // 6. DB保存確認（MSWでモック）
    expect(screen.getByText(/game saved/i)).toBeInTheDocument();
  });
});
```

### Phase 6: CI/CDパイプライン統合

#### GitHub Actions設定

```yaml
# AIが生成: .github/workflows/full-stack-ci.yml
name: Full Stack CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
          
      - name: Run migrations
        run: |
          cd backend
          alembic upgrade head
          
      - name: Run tests
        run: |
          cd backend
          pytest --cov=src --cov-report=xml
          
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  frontend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: |
          cd frontend
          npm ci
          
      - name: Run tests
        run: |
          cd frontend
          npm test -- --coverage --watchAll=false
          
      - name: Build
        run: |
          cd frontend
          npm run build

  e2e-test:
    needs: [backend-test, frontend-test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Start services
        run: |
          docker-compose up -d
          
      - name: Wait for services
        run: |
          npx wait-on http://localhost:3000 http://localhost:8000/health
          
      - name: Run E2E tests
        run: |
          npx playwright test
          
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/

  deploy:
    needs: [e2e-test]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to staging
        run: |
          # デプロイスクリプト実行
          ./scripts/deploy.sh staging
```

## 3. 見落としがちな要素と統合方法

### 3.1 API設計・ドキュメント

```markdown
「OpenAPI仕様を作成してください」

AI: 「APIエンドポイントを設計します」
```

```yaml
# AIが生成: api/openapi.yaml
openapi: 3.0.0
info:
  title: Janken Game API
  version: 1.0.0

paths:
  /games:
    post:
      summary: Create new game
      responses:
        '201':
          description: Game created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Game'
                
  /games/{gameId}/moves:
    post:
      summary: Submit move
      parameters:
        - name: gameId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Move'
```

### 3.2 認証・認可

```python
# AIが生成: backend/tests/test_auth.py
def test_jwt_authentication():
    """JWT認証のテスト"""
    token = create_jwt_token(user_id=1)
    decoded = decode_jwt_token(token)
    assert decoded['user_id'] == 1

def test_authorization():
    """認可のテスト"""
    user1 = User(id=1)
    user2 = User(id=2)
    game = Game(player1=user1)
    
    assert can_modify_game(user1, game) == True
    assert can_modify_game(user2, game) == False
```

### 3.3 環境変数管理

```python
# AIが生成: backend/src/config.py
from pydantic import BaseSettings

class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    redis_url: str = "redis://localhost"
    cors_origins: list[str] = ["http://localhost:3000"]
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
```

```bash
# AIが生成: .env.example
DATABASE_URL=postgresql://user:pass@localhost/dbname
JWT_SECRET=your-secret-key
REDIS_URL=redis://localhost:6379
CORS_ORIGINS=["http://localhost:3000"]
```

### 3.4 ロギング・モニタリング

```python
# AIが生成: backend/src/logging_config.py
import logging
import structlog

def setup_logging():
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

logger = structlog.get_logger()
```

### 3.5 パフォーマンステスト

```python
# AIが生成: backend/tests/performance/test_load.py
import pytest
from locust import HttpUser, task, between

class GameUser(HttpUser):
    wait_time = between(1, 3)
    
    @task
    def create_game(self):
        self.client.post("/games")
    
    @task(3)
    def make_move(self):
        self.client.post("/games/123/moves", json={"move": "rock"})
    
    @task
    def get_game_status(self):
        self.client.get("/games/123")

# 実行: locust -f test_load.py --host=http://localhost:8000
```

## 4. 統合されたTDDサイクル

### 拡張TDDサイクル

```mermaid
graph LR
    A[要求定義] --> B[DB設計テスト]
    B --> C[APIテスト]
    C --> D[バックエンド実装]
    D --> E[フロントエンドテスト]
    E --> F[フロントエンド実装]
    F --> G[統合テスト]
    G --> H[パフォーマンステスト]
    H --> I[デプロイ]
    
    G -->|失敗| D
    H -->|問題| D
```

### AIへの統合指示例

```markdown
「フルスタックTDDサイクルを開始します。
ユーザー登録機能を実装してください：

1. DBスキーマテストから開始
2. APIエンドポイントテスト
3. バックエンド実装
4. フロントエンドコンポーネントテスト
5. フロントエンド実装
6. E2Eテスト
7. CI/CDパイプライン更新」

AI: 「フルスタックTDDを開始します...」
[各層のテストと実装を順次実行]
```

## 5. プロジェクトテンプレート

### 初期化スクリプト

```bash
#!/bin/bash
# AIが生成: scripts/init-fullstack.sh

echo "🚀 Initializing Full Stack Project"

# Create directory structure
mkdir -p backend/{src,tests,migrations}
mkdir -p frontend/{src,tests,public}
mkdir -p database/{schema,seeds,migrations}
mkdir -p api
mkdir -p infrastructure/{docker,kubernetes,terraform}
mkdir -p .github/workflows
mkdir -p docs/{architecture,api,deployment}

# Initialize backend
cd backend
python -m venv venv
source venv/bin/activate
pip install fastapi sqlalchemy alembic pytest pytest-cov

# Initialize frontend
cd ../frontend
npm init -y
npm install react typescript vite @testing-library/react

# Initialize database
cd ../database
cat > docker-compose.yml << EOF
version: '3.8'
services:
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: gamedb
      POSTGRES_USER: gameuser
      POSTGRES_PASSWORD: gamepass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
EOF

echo "✅ Full Stack Project Initialized"
```

## まとめ

このガイドにより、以下が本開発フローに統合されます：

1. **データベース**: スキーマ設計からマイグレーションまでTDDで実装
2. **フロントエンド**: コンポーネントテストから始まるTDD開発
3. **CI/CD**: 各フェーズで自動実行される品質チェック
4. **API設計**: OpenAPI仕様からの開発
5. **認証・認可**: セキュリティをテストファーストで実装
6. **環境管理**: 設定の外部化と環境別管理
7. **監視・ログ**: 本番運用を考慮した実装
8. **パフォーマンス**: 負荷テストの組み込み

すべてがTDDサイクルと統合され、AIが主導して開発を進められます。