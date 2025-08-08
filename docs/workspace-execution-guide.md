# Workspace Execution Environment Guide

## Overview

An additional guide for AI chat-driven development using workspace execution environments such as Claude Code. Explains practical development methods utilizing file systems, execution environments, and test automation.

## 1. Standardized Project Structure

### 1.1 Basic Directory Structure

```
project-root/
├── .ai/                    # AI development metadata
│   ├── diagnosis.yaml      # Project diagnosis results
│   ├── formal-specs/       # Formal specifications (when needed)
│   │   ├── tla/           # TLA+ specifications
│   │   └── dafny/         # Dafny specifications
│   └── decisions.md        # Design decision records
├── docs/
│   ├── requirements/       # Requirements specifications
│   │   └── scenarios.feature  # BDD scenarios
│   └── architecture/       # Architecture documents
├── src/                    # Source code
├── tests/                  # Test code
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   └── e2e/               # E2E tests
├── scripts/                # Development support scripts
│   ├── setup.sh           # Environment setup
│   ├── test.sh            # Test execution
│   └── verify.sh          # Specification verification
├── .github/                # CI/CD configuration
│   └── workflows/
└── README.md              # Project description
```

### 1.2 Initial Setup Commands

```bash
# AI instruction example
"Please create initial project structure"

# Commands AI executes
mkdir -p .ai/{formal-specs/{tla,dafny}} docs/{requirements,architecture}
mkdir -p src tests/{unit,integration,e2e} scripts
touch .ai/diagnosis.yaml .ai/decisions.md
touch docs/requirements/scenarios.feature
echo "# Project Name" > README.md
```

## 2. Persisting Diagnosis Results

### 2.1 Diagnosis Result File (.ai/diagnosis.yaml)

```yaml
# Diagnosis file generated and updated by AI
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

### 2.2 Utilizing in AI Dialogue

```markdown
"Please check diagnosis results and tell me current settings"

AI: "Loading .ai/diagnosis.yaml...
    Current settings:
    - Formal methods: Level 0,1 (overall), Level 4 (crypto parts)
    - Implementation language: Python (FastAPI) + TypeScript (React)
    - Testing: pytest + playwright"
```

## 3. Making TDD Cycles Executable

### 3.1 RED Phase (Test Creation and Execution)

```markdown
## AI Instruction
"Please create and run tests for commitment creation function"

## AI Actions
1. Create test file
2. Execute test
3. Confirm failure
```

```python
# AI generates: tests/unit/test_crypto.py
import pytest
from src.crypto import create_commitment  # doesn't exist yet

def test_create_commitment():
    move = "rock"
    nonce = 12345
    
    commitment = create_commitment(move, nonce)
    
    assert len(commitment) == 64
    assert isinstance(commitment, str)
```

```bash
# AI executes
$ python -m pytest tests/unit/test_crypto.py -v

# AI interprets result
FAILED: ImportError: cannot import name 'create_commitment'
→ Expected failure. Next, I'll create minimal implementation.
```

### 3.2 GREEN Phase (Implementation and Success Confirmation)

```python
# AI generates: src/crypto.py
def create_commitment(move: str, nonce: int) -> str:
    """Minimal implementation: just pass the test"""
    return "0" * 64
```

```bash
# AI executes
$ python -m pytest tests/unit/test_crypto.py -v

# Result
PASSED
→ Test successful. Next, I'll add more realistic tests.
```

### 3.3 REFACTOR Phase (Improvement and Re-confirmation)

```python
# AI improves: src/crypto.py
import hashlib
import json

def create_commitment(move: str, nonce: int) -> str:
    """Actual hash implementation"""
    data = json.dumps({"move": move, "nonce": nonce}, sort_keys=True)
    return hashlib.sha256(data.encode()).hexdigest()
```

```bash
# AI executes and confirms
$ python -m pytest tests/unit/test_crypto.py -v
PASSED

# Also check coverage
$ python -m pytest --cov=src --cov-report=term-missing
Coverage: 100%
```

## 4. Continuous Quality Checking

### 4.1 Automated Test Execution Script

```bash
# scripts/test.sh - Generated by AI
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

### 4.2 Watch Mode Development

```markdown
"Please set up file change monitoring for automatic test execution"

AI: "Setting up watch mode"
```

```bash
# AI executes
pip install pytest-watch

# Start watch mode
ptw -- --verbose

# Continue development in another terminal
# Tests automatically run on file save
```

## 5. Executable Verification of Formal Specifications

### 5.1 TLA+ Specification Verification (When Using Level 3)

```bash
# After AI creates .ai/formal-specs/tla/game.tla
$ tlc game.tla -config game.cfg

# AI interprets results
"Model checking complete:
 - States: 1,234
 - Deadlocks: none
 - Invariant violations: none"
```

### 5.2 Property Based Testing Execution

```python
# AI generates: tests/unit/test_properties.py
from hypothesis import given, strategies as st
from src.game import judge_winner

@given(
    move1=st.sampled_from(["rock", "paper", "scissors"]),
    move2=st.sampled_from(["rock", "paper", "scissors"])
)
def test_game_properties(move1, move2):
    result = judge_winner(move1, move2)
    
    # Symmetry check
    if move1 == move2:
        assert result == "draw"
    
    # Result validity
    assert result in ["player1", "player2", "draw"]
```

```bash
# AI executes
$ python -m pytest tests/unit/test_properties.py --hypothesis-show-statistics
```

## 6. Integration Test Execution

### 6.1 Local Environment Integration Tests

```python
# AI generates: tests/integration/test_api.py
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
# AI executes
$ python -m pytest tests/integration/ -v
```

### 6.2 Docker Environment Integration Tests

```yaml
# AI generates: docker-compose.test.yml
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
# AI executes
$ docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## 7. AI Dialogue Patterns Specific to Execution Environment

### 7.1 Error Diagnosis and Correction

```markdown
User: "Please run the tests"

AI: "Executing..."
[Actually run tests]

AI: "Error occurred:
    ```
    AssertionError: Expected 64, got 32
    ```
    Hash function output length is wrong. Correcting..."
[Directly modify files]

AI: "Correction complete. Re-running..."
[Run tests again]

AI: "Tests successful."
```

### 7.2 Performance Analysis

```markdown
"Please run performance tests and identify bottlenecks"

AI: "Running profiling..."
```

```bash
# AI executes
$ python -m cProfile -o profile.stats src/benchmark.py
$ python -m pstats profile.stats

# AI analyzes results
"Bottleneck found:
 - create_commitment: 45% of time
 - Optimization suggestion: cache hash calculations"
```

### 7.3 Continuous Monitoring

```markdown
"I want to proceed with development in monitoring mode"

AI: "Running the following in parallel:
    1. Test watcher
    2. Type checker
    3. Linter
    4. Coverage monitor"
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

## 8. CI/CD Integration

### 8.1 GitHub Actions Configuration

```yaml
# AI generates: .github/workflows/test.yml
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

### 8.2 Local CI Verification

```bash
# AI executes (pre-CI verification)
$ act  # Run GitHub Actions locally

# Or
$ ./scripts/ci-check.sh  # CI-equivalent checks
```

## 9. Project State Visualization

### 9.1 Progress Dashboard

```markdown
"Please summarize current project status"

AI: "Analyzing project status..."
```

```python
# AI executes and displays results
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

## 10. Best Practices

### 10.1 File Change Tracking

```yaml
# Auto-recorded in .ai/decisions.md
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

### 10.2 Version Control Integration

```bash
# AI commits appropriately
$ git add -A
$ git commit -m "feat: Add commitment creation with TDD

- Add unit test for create_commitment
- Implement minimal passing solution
- Refactor to use actual SHA256
- Coverage: 100%"
```

### 10.3 Environment Reproducibility

```dockerfile
# AI generates: Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements*.txt ./
RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt

COPY . .

CMD ["pytest", "--cov"]
```

## 11. Full Stack Development Extension

This guide covers basic execution environments, but actual projects also need the following elements:

### Elements Requiring Integration
- **Database persistence**: Schema design, migrations, transactions
- **Frontend development**: UI/UX testing, component development, state management
- **CI/CD pipeline**: Automated testing, builds, deployment
- **API design**: OpenAPI/GraphQL specifications, authentication/authorization
- **Operations consideration**: Logging, monitoring, performance

For details on these, refer to the **"Full Stack Development Integration Guide"**.

### AI Instruction Example
```markdown
"I want to start development with full stack configuration"

AI: "Based on the Full Stack Development Integration Guide,
    I will set up:
    - Database (PostgreSQL)
    - Frontend (React + TypeScript)
    - Backend (FastAPI)
    - CI/CD (GitHub Actions)"
```

## Summary

Workspace execution environments enable:

1. **Actual execution and feedback**: Immediate test result confirmation
2. **Complete TDD cycle implementation**: Actually experience RED-GREEN-REFACTOR
3. **Continuous quality monitoring**: Real-time coverage and performance confirmation
4. **Immediate error correction**: Immediate response based on execution results
5. **Pre-CI/CD verification**: Complete local verification before pushing
6. **Full stack support**: Integration from DB to frontend to infrastructure

This makes AI dialogue more practical and productive.