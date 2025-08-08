#!/bin/bash

# System integration test script
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== E2E Chat System Integration Test ===${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "✓ $1 installed"
    else
        echo -e "${RED}✗ $1 not installed${NC}"
        exit 1
    fi
}

check_command podman || check_command docker
check_command go
check_command psql || echo -e "${YELLOW}Warning: psql not found (optional)${NC}"
check_command redis-cli || echo -e "${YELLOW}Warning: redis-cli not found (optional)${NC}"

# Load environment variables
if [ -f .env ]; then
    echo -e "\n${YELLOW}Loading environment variables...${NC}"
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "✓ Environment variables loaded"
else
    echo -e "${RED}✗ .env file not found${NC}"
    exit 1
fi

# Start databases
echo -e "\n${YELLOW}Starting database services...${NC}"
./scripts/start_db.sh

# Run database tests
echo -e "\n${YELLOW}Running database connection tests...${NC}"
cd src/backend/message-service

# Install dependencies
~/go/bin/go mod tidy

# Run database tests
~/go/bin/go test -v ./database -run TestPostgreSQLConnection
~/go/bin/go test -v ./database -run TestRedisConnection

# Run config tests
echo -e "\n${YELLOW}Running configuration tests...${NC}"
~/go/bin/go test -v ./config

# Build and start service
echo -e "\n${YELLOW}Building message service...${NC}"
~/go/bin/go build -o message-service

echo -e "\n${YELLOW}Starting message service...${NC}"
./message-service &
SERVICE_PID=$!

# Wait for service to start
sleep 3

# Test health endpoint
echo -e "\n${YELLOW}Testing health endpoint...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed (HTTP $response)${NC}"
    kill $SERVICE_PID 2>/dev/null || true
    exit 1
fi

# Test API endpoint
echo -e "\n${YELLOW}Testing API endpoint...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/messages)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ API endpoint test passed${NC}"
else
    echo -e "${YELLOW}⚠ API endpoint returned HTTP $response${NC}"
fi

# Cleanup
echo -e "\n${YELLOW}Cleaning up...${NC}"
kill $SERVICE_PID 2>/dev/null || true

echo -e "\n${GREEN}=== System Integration Test Complete ===${NC}"
echo -e "${GREEN}Summary:${NC}"
echo "  ✓ Database services running"
echo "  ✓ Configuration loaded"
echo "  ✓ Service builds successfully"
echo "  ✓ Health check operational"
echo ""
echo -e "${YELLOW}To run the full system:${NC}"
echo "  ./scripts/start.sh"
echo ""
echo -e "${YELLOW}To stop databases:${NC}"
echo "  podman stop chat-postgres chat-redis"