# E2E Encrypted Chat - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Development Setup](#development-setup)
4. [Production Deployment](#production-deployment)
5. [Testing](#testing)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- **Podman** or Docker (v20.10+)
- **Go** (1.21+)
- **Rust** (1.75+)
- **PostgreSQL** (16+)
- **Redis** (7+)
- **Node.js** (18+) for frontend development

### System Requirements
- **CPU**: 2+ cores
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 10GB available space
- **OS**: Linux (Ubuntu 22.04+), macOS, or Windows with WSL2

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/RigorFlow_TEST01.git
cd RigorFlow_TEST01
```

### 2. Run with Script
```bash
chmod +x scripts/start.sh
./scripts/start.sh
```

### 3. Access Application
- Frontend: http://localhost:8000
- API: http://localhost:8080
- Health Check: http://localhost:8080/health
- Metrics: http://localhost:9090/metrics

## Development Setup

### 1. Install Dependencies

#### Rust Dependencies
```bash
cd src/crypto/rust
cargo build
cargo test
```

#### Go Dependencies
```bash
cd src/backend/message-service
go mod download
go test ./...
```

### 2. Database Setup
```bash
# Start PostgreSQL
podman run -d --name postgres \
  -e POSTGRES_PASSWORD=changeme \
  -p 5432:5432 \
  postgres:16-alpine

# Initialize database
psql -h localhost -U postgres -f scripts/init.sql
```

### 3. Start Services Individually

#### Start Redis
```bash
podman run -d --name redis \
  -p 6379:6379 \
  redis:7-alpine
```

#### Start Message Service
```bash
cd src/backend/message-service
go run .
```

#### Start Frontend
```bash
cd frontend
python3 -m http.server 8000
```

## Production Deployment

### 1. Using Podman Compose

```bash
# Build and start all services
podman-compose up -d

# Check status
podman-compose ps

# View logs
podman-compose logs -f message-service
```

### 2. Using Kubernetes

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-message-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: message-service
  template:
    metadata:
      labels:
        app: message-service
    spec:
      containers:
      - name: message-service
        image: e2e-chat:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: host
```

Apply configuration:
```bash
kubectl apply -f k8s/
```

### 3. Environment Variables

Create `.env` file:
```env
# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=chatdb
DB_USER=chatuser
DB_PASSWORD=your_secure_password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# Service
SERVICE_PORT=8080
METRICS_PORT=9090
LOG_LEVEL=info

# Security
JWT_SECRET=your_jwt_secret
ENCRYPTION_KEY=your_encryption_key
```

### 4. TLS/SSL Configuration

Generate certificates:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout server.key -out server.crt
```

Update nginx.conf:
```nginx
server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;
    
    location / {
        proxy_pass http://message-service:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Testing

### 1. Run Unit Tests
```bash
# Rust tests
cd src/crypto/rust
cargo test

# Go tests
cd src/backend/message-service
go test ./...

# Integration tests
cd tests/integration
go test -v
```

### 2. Run Load Tests
```bash
cd tests/load
go run load_test.go
```

### 3. Security Testing
```bash
# OWASP ZAP scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t http://localhost:8080

# TLS scan
testssl.sh localhost:443
```

## Monitoring

### 1. Prometheus Setup

Configure `prometheus.yml`:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'message-service'
    static_configs:
      - targets: ['message-service:9090']
```

### 2. Grafana Dashboards

Import dashboard:
1. Open Grafana at http://localhost:3000
2. Login (admin/admin)
3. Import dashboard from `config/grafana/dashboards/`

### 3. Logging

View logs:
```bash
# All services
podman-compose logs

# Specific service
podman logs message-service

# Follow logs
podman logs -f message-service
```

Configure log aggregation:
```yaml
# fluent-bit.conf
[INPUT]
    Name tail
    Path /var/log/containers/*.log
    Parser docker

[OUTPUT]
    Name elasticsearch
    Match *
    Host elasticsearch
    Port 9200
```

## Troubleshooting

### Common Issues

#### 1. Database Connection Failed
```bash
# Check PostgreSQL status
podman exec postgres pg_isready

# Check connectivity
nc -zv localhost 5432
```

#### 2. Redis Connection Issues
```bash
# Test Redis connection
redis-cli ping

# Check Redis logs
podman logs redis
```

#### 3. Port Already in Use
```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>
```

#### 4. Build Failures
```bash
# Clear cache and rebuild
cargo clean
go clean -cache
podman system prune -a
```

### Debug Mode

Enable debug logging:
```bash
export LOG_LEVEL=debug
export DEBUG=true
./scripts/start.sh
```

### Health Checks

Check service health:
```bash
# API health
curl http://localhost:8080/health

# Database health
podman exec postgres pg_isready

# Redis health
redis-cli ping
```

## Performance Tuning

### 1. Database Optimization
```sql
-- Add indexes
CREATE INDEX CONCURRENTLY idx_messages_timestamp 
ON messages(created_at DESC);

-- Vacuum and analyze
VACUUM ANALYZE messages;
```

### 2. Redis Configuration
```conf
# redis.conf
maxmemory 2gb
maxmemory-policy allkeys-lru
```

### 3. Service Scaling
```bash
# Scale horizontally
podman-compose up -d --scale message-service=3
```

## Backup and Recovery

### 1. Database Backup
```bash
# Backup
pg_dump -h localhost -U chatuser chatdb > backup.sql

# Restore
psql -h localhost -U chatuser chatdb < backup.sql
```

### 2. Redis Backup
```bash
# Save snapshot
redis-cli BGSAVE

# Copy dump file
podman cp redis:/data/dump.rdb ./redis-backup.rdb
```

## Security Checklist

- [ ] TLS/SSL enabled for all connections
- [ ] Strong passwords for all services
- [ ] JWT secrets rotated regularly
- [ ] Database encrypted at rest
- [ ] Regular security updates applied
- [ ] Rate limiting configured
- [ ] Input validation implemented
- [ ] Audit logging enabled
- [ ] Backup strategy in place
- [ ] Incident response plan ready

## Support

For issues or questions:
1. Check the [API Documentation](API_DOCUMENTATION.md)
2. Review [Test Report](TEST_REPORT.md)
3. Open an issue on GitHub
4. Contact the development team

## License

MIT License - See LICENSE file for details