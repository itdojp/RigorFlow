#!/bin/bash

# E2E Encrypted Chat Application Startup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting E2E Encrypted Chat Application...${NC}"

# Check for required tools
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
check_command podman
check_command go
check_command cargo

# Build Rust crypto library
echo -e "${YELLOW}Building Rust crypto library...${NC}"
cd src/crypto/rust
~/.cargo/bin/cargo build --release
cd ../../..

# Build Go message service
echo -e "${YELLOW}Building Go message service...${NC}"
cd src/backend/message-service
~/go/bin/go build -o message-service
cd ../../..

# Start services with Podman
echo -e "${YELLOW}Starting services with Podman...${NC}"

# Start PostgreSQL
podman run -d --name chat-postgres \
    -e POSTGRES_DB=chatdb \
    -e POSTGRES_USER=chatuser \
    -e POSTGRES_PASSWORD=changeme \
    -p 5432:5432 \
    -v postgres_data:/var/lib/postgresql/data \
    postgres:16-alpine

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL...${NC}"
sleep 5

# Initialize database
echo -e "${YELLOW}Initializing database...${NC}"
PGPASSWORD=changeme psql -h localhost -U chatuser -d chatdb -f scripts/init.sql 2>/dev/null || true

# Start Redis
podman run -d --name chat-redis \
    -p 6379:6379 \
    redis:7-alpine

# Start the message service
echo -e "${YELLOW}Starting message service...${NC}"
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=chatdb
export DB_USER=chatuser
export DB_PASSWORD=changeme
export REDIS_HOST=localhost
export REDIS_PORT=6379

cd src/backend/message-service
./message-service &
MESSAGE_SERVICE_PID=$!
cd ../../..

# Start simple HTTP server for frontend
echo -e "${YELLOW}Starting frontend server...${NC}"
cd frontend
python3 -m http.server 8000 &
FRONTEND_PID=$!
cd ..

echo -e "${GREEN}✓ Application started successfully!${NC}"
echo -e "${GREEN}Frontend: http://localhost:8000${NC}"
echo -e "${GREEN}API: http://localhost:8080${NC}"
echo -e "${GREEN}Health: http://localhost:8080/health${NC}"

# Trap to cleanup on exit
trap cleanup EXIT

cleanup() {
    echo -e "${YELLOW}Shutting down services...${NC}"
    kill $MESSAGE_SERVICE_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    podman stop chat-postgres chat-redis 2>/dev/null || true
    podman rm chat-postgres chat-redis 2>/dev/null || true
}

# Keep script running
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
wait