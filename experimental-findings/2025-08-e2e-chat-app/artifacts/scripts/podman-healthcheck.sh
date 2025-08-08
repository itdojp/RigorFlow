#!/bin/bash

# Podmanコンテナヘルスチェックスクリプト

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   Podman Container Health Check          ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Podmanが利用可能かチェック
check_podman() {
    if ! command -v podman &> /dev/null; then
        echo -e "${RED}❌ Podman is not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Podman version: $(podman --version)${NC}"
}

# コンテナの状態チェック
check_containers() {
    echo -e "\n${YELLOW}Checking container status...${NC}"
    
    # PostgreSQLチェック
    if podman ps | grep -q securechat-postgres; then
        echo -e "${GREEN}✅ PostgreSQL container is running${NC}"
        
        # 接続テスト
        if podman exec securechat-postgres pg_isready -U securechat &> /dev/null; then
            echo -e "${GREEN}   ✓ PostgreSQL is accepting connections${NC}"
        else
            echo -e "${RED}   ✗ PostgreSQL is not accepting connections${NC}"
        fi
    else
        echo -e "${RED}❌ PostgreSQL container is not running${NC}"
    fi
    
    # Redisチェック
    if podman ps | grep -q securechat-redis; then
        echo -e "${GREEN}✅ Redis container is running${NC}"
        
        # 接続テスト
        if podman exec securechat-redis redis-cli --pass securechat123 ping &> /dev/null; then
            echo -e "${GREEN}   ✓ Redis is responding to PING${NC}"
        else
            echo -e "${RED}   ✗ Redis is not responding${NC}"
        fi
    else
        echo -e "${RED}❌ Redis container is not running${NC}"
    fi
    
    # Cassandraチェック
    if podman ps | grep -q securechat-cassandra; then
        echo -e "${GREEN}✅ Cassandra container is running${NC}"
        
        # ノードステータスチェック
        if podman exec securechat-cassandra nodetool status 2>/dev/null | grep -q "UN"; then
            echo -e "${GREEN}   ✓ Cassandra node is UP and Normal${NC}"
        else
            echo -e "${YELLOW}   ⚠ Cassandra is starting up...${NC}"
        fi
    else
        echo -e "${RED}❌ Cassandra container is not running${NC}"
    fi
}

# ネットワークチェック
check_network() {
    echo -e "\n${YELLOW}Checking network configuration...${NC}"
    
    if podman network exists securechat &> /dev/null; then
        echo -e "${GREEN}✅ SecureChat network exists${NC}"
        
        # ネットワーク詳細
        podman network inspect securechat --format '{{range .Subnets}}{{.Subnet}}{{end}}' | while read subnet; do
            echo -e "${GREEN}   ✓ Subnet: $subnet${NC}"
        done
    else
        echo -e "${YELLOW}⚠️  SecureChat network not found (using default)${NC}"
    fi
}

# ボリュームチェック
check_volumes() {
    echo -e "\n${YELLOW}Checking volumes...${NC}"
    
    # PostgreSQLボリューム
    if podman volume exists postgres_data &> /dev/null; then
        SIZE=$(podman volume inspect postgres_data --format '{{.Mountpoint}}' | xargs du -sh 2>/dev/null | cut -f1)
        echo -e "${GREEN}✅ PostgreSQL volume: ${SIZE:-N/A}${NC}"
    else
        echo -e "${YELLOW}⚠️  PostgreSQL volume not found${NC}"
    fi
    
    # Cassandraボリューム
    if podman volume exists cassandra_data &> /dev/null; then
        SIZE=$(podman volume inspect cassandra_data --format '{{.Mountpoint}}' | xargs du -sh 2>/dev/null | cut -f1)
        echo -e "${GREEN}✅ Cassandra volume: ${SIZE:-N/A}${NC}"
    else
        echo -e "${YELLOW}⚠️  Cassandra volume not found${NC}"
    fi
}

# ポート確認
check_ports() {
    echo -e "\n${YELLOW}Checking exposed ports...${NC}"
    
    # PostgreSQL port 5432
    if ss -tulpn 2>/dev/null | grep -q :5432; then
        echo -e "${GREEN}✅ PostgreSQL port 5432 is listening${NC}"
    else
        echo -e "${RED}❌ PostgreSQL port 5432 is not available${NC}"
    fi
    
    # Redis port 6379
    if ss -tulpn 2>/dev/null | grep -q :6379; then
        echo -e "${GREEN}✅ Redis port 6379 is listening${NC}"
    else
        echo -e "${RED}❌ Redis port 6379 is not available${NC}"
    fi
    
    # Cassandra port 9042
    if ss -tulpn 2>/dev/null | grep -q :9042; then
        echo -e "${GREEN}✅ Cassandra port 9042 is listening${NC}"
    else
        echo -e "${YELLOW}⚠️  Cassandra port 9042 is not available yet${NC}"
    fi
}

# リソース使用状況
check_resources() {
    echo -e "\n${YELLOW}Resource usage...${NC}"
    
    echo -e "${BLUE}Container statistics:${NC}"
    podman stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || true
}

# サービス起動提案
suggest_startup() {
    local all_running=true
    
    if ! podman ps | grep -q securechat-postgres; then
        all_running=false
    fi
    if ! podman ps | grep -q securechat-redis; then
        all_running=false
    fi
    if ! podman ps | grep -q securechat-cassandra; then
        all_running=false
    fi
    
    if [ "$all_running" = false ]; then
        echo -e "\n${YELLOW}==========================================${NC}"
        echo -e "${YELLOW}Some services are not running.${NC}"
        echo -e "${YELLOW}To start all services, run:${NC}"
        echo -e "${GREEN}  podman-compose -f podman-compose.yml up -d${NC}"
        echo -e "${YELLOW}==========================================${NC}"
    else
        echo -e "\n${GREEN}==========================================${NC}"
        echo -e "${GREEN}✅ All services are running properly!${NC}"
        echo -e "${GREEN}==========================================${NC}"
    fi
}

# メイン実行
main() {
    check_podman
    check_containers
    check_network
    check_volumes
    check_ports
    check_resources
    suggest_startup
}

main "$@"