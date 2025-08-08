#!/bin/bash

# Database startup script with health checks
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starting Database Services ===${NC}"

# Configuration
DB_NAME="${DB_NAME:-chatdb}"
DB_USER="${DB_USER:-chatuser}"
DB_PASSWORD="${DB_PASSWORD:-changeme}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"

# Check if podman is available, otherwise use docker
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
else
    CONTAINER_CMD="docker"
fi

echo -e "${YELLOW}Using container runtime: $CONTAINER_CMD${NC}"

# Function to wait for PostgreSQL
wait_for_postgres() {
    echo -n "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if $CONTAINER_CMD exec chat-postgres pg_isready -U $DB_USER &>/dev/null; then
            echo -e " ${GREEN}Ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo -e " ${RED}Timeout!${NC}"
    return 1
}

# Function to wait for Redis
wait_for_redis() {
    echo -n "Waiting for Redis to be ready..."
    for i in {1..30}; do
        if $CONTAINER_CMD exec chat-redis redis-cli ping &>/dev/null; then
            echo -e " ${GREEN}Ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo -e " ${RED}Timeout!${NC}"
    return 1
}

# Stop and remove existing containers
echo -e "${YELLOW}Cleaning up existing containers...${NC}"
$CONTAINER_CMD stop chat-postgres chat-redis 2>/dev/null || true
$CONTAINER_CMD rm chat-postgres chat-redis 2>/dev/null || true

# Start PostgreSQL
echo -e "${YELLOW}Starting PostgreSQL...${NC}"
$CONTAINER_CMD run -d \
    --name chat-postgres \
    -e POSTGRES_DB=$DB_NAME \
    -e POSTGRES_USER=$DB_USER \
    -e POSTGRES_PASSWORD=$DB_PASSWORD \
    -p 5432:5432 \
    -v postgres_data:/var/lib/postgresql/data \
    postgres:16-alpine

# Wait for PostgreSQL to be ready
if ! wait_for_postgres; then
    echo -e "${RED}PostgreSQL failed to start${NC}"
    exit 1
fi

# Initialize database schema
echo -e "${YELLOW}Initializing database schema...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if init.sql exists
if [ -f "$SCRIPT_DIR/init.sql" ]; then
    # Run initialization script
    PGPASSWORD=$DB_PASSWORD $CONTAINER_CMD exec -i chat-postgres \
        psql -U $DB_USER -d $DB_NAME < "$SCRIPT_DIR/init.sql" 2>/dev/null || {
        echo -e "${YELLOW}Note: Some tables may already exist (this is normal)${NC}"
    }
    echo -e "${GREEN}Database schema initialized${NC}"
else
    echo -e "${YELLOW}Warning: init.sql not found at $SCRIPT_DIR/init.sql${NC}"
fi

# Start Redis
echo -e "${YELLOW}Starting Redis...${NC}"
if [ -n "$REDIS_PASSWORD" ]; then
    $CONTAINER_CMD run -d \
        --name chat-redis \
        -p 6379:6379 \
        -v redis_data:/data \
        redis:7-alpine \
        redis-server --requirepass $REDIS_PASSWORD --appendonly yes
else
    $CONTAINER_CMD run -d \
        --name chat-redis \
        -p 6379:6379 \
        -v redis_data:/data \
        redis:7-alpine \
        redis-server --appendonly yes
fi

# Wait for Redis to be ready
if ! wait_for_redis; then
    echo -e "${RED}Redis failed to start${NC}"
    exit 1
fi

# Test connections
echo -e "${YELLOW}Testing connections...${NC}"

# Test PostgreSQL
echo -n "PostgreSQL connection: "
if PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Test Redis
echo -n "Redis connection: "
if [ -n "$REDIS_PASSWORD" ]; then
    if redis-cli -a $REDIS_PASSWORD ping &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
    fi
else
    if redis-cli ping &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
    fi
fi

# Show connection info
echo -e "\n${GREEN}=== Database Services Started ===${NC}"
echo -e "${GREEN}PostgreSQL:${NC}"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"

echo -e "\n${GREEN}Redis:${NC}"
echo "  Host: localhost"
echo "  Port: 6379"
if [ -n "$REDIS_PASSWORD" ]; then
    echo "  Password: $REDIS_PASSWORD"
else
    echo "  Password: (none)"
fi

echo -e "\n${YELLOW}To stop the services, run:${NC}"
echo "  $CONTAINER_CMD stop chat-postgres chat-redis"
echo -e "\n${YELLOW}To view logs, run:${NC}"
echo "  $CONTAINER_CMD logs chat-postgres"
echo "  $CONTAINER_CMD logs chat-redis"