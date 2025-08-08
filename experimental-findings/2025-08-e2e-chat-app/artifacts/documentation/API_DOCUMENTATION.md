# E2E Encrypted Chat API Documentation

## Base URL
```
http://localhost:8080/api/v1
```

## Authentication
All API requests require authentication via JWT tokens in the Authorization header:
```
Authorization: Bearer <token>
```

## Endpoints

### Health Check

#### GET /health
Check service health status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "database": "connected",
    "redis": "connected",
    "crypto": "operational"
  }
}
```

### User Management

#### POST /users/register
Register a new user with their public keys.

**Request:**
```json
{
  "username": "alice",
  "email": "alice@example.com",
  "publicKey": "base64_encoded_public_key",
  "identityKey": "base64_encoded_identity_key",
  "signedPreKeys": [
    {
      "keyId": 1,
      "publicKey": "base64_encoded_key",
      "signature": "base64_encoded_signature"
    }
  ],
  "oneTimePreKeys": [
    {
      "keyId": 1,
      "publicKey": "base64_encoded_key"
    }
  ]
}
```

**Response:**
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "username": "alice",
  "token": "jwt_token"
}
```

#### GET /users/{username}/prekey-bundle
Get a user's prekey bundle for initiating a session.

**Response:**
```json
{
  "identityKey": "base64_encoded_key",
  "signedPreKey": {
    "keyId": 1,
    "publicKey": "base64_encoded_key",
    "signature": "base64_encoded_signature"
  },
  "oneTimePreKey": {
    "keyId": 5,
    "publicKey": "base64_encoded_key"
  }
}
```

### Session Management

#### POST /sessions
Initialize a new Double Ratchet session.

**Request:**
```json
{
  "recipientUsername": "bob",
  "ephemeralPublicKey": "base64_encoded_key",
  "identityKey": "base64_encoded_key",
  "signedPreKeyId": 1,
  "oneTimePreKeyId": 5
}
```

**Response:**
```json
{
  "sessionId": "660e8400-e29b-41d4-a716-446655440001",
  "established": true
}
```

#### GET /sessions
Get all active sessions for the authenticated user.

**Response:**
```json
{
  "sessions": [
    {
      "sessionId": "660e8400-e29b-41d4-a716-446655440001",
      "participant": "bob",
      "createdAt": "2024-01-15T10:00:00Z",
      "lastActivity": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Message Operations

#### POST /messages
Send an encrypted message.

**Request:**
```json
{
  "sessionId": "660e8400-e29b-41d4-a716-446655440001",
  "header": {
    "dhPublic": "base64_encoded_key",
    "pn": 0,
    "n": 1
  },
  "ciphertext": "base64_encoded_ciphertext",
  "signature": "base64_encoded_signature"
}
```

**Response:**
```json
{
  "messageId": "770e8400-e29b-41d4-a716-446655440002",
  "timestamp": "2024-01-15T10:31:00Z",
  "delivered": false
}
```

#### GET /messages/{sessionId}
Retrieve messages for a session.

**Query Parameters:**
- `limit` (optional): Number of messages to retrieve (default: 50)
- `before` (optional): Retrieve messages before this timestamp
- `after` (optional): Retrieve messages after this timestamp

**Response:**
```json
{
  "messages": [
    {
      "messageId": "770e8400-e29b-41d4-a716-446655440002",
      "header": {
        "dhPublic": "base64_encoded_key",
        "pn": 0,
        "n": 1
      },
      "ciphertext": "base64_encoded_ciphertext",
      "signature": "base64_encoded_signature",
      "timestamp": "2024-01-15T10:31:00Z",
      "sender": "alice",
      "delivered": true,
      "read": false
    }
  ],
  "hasMore": false
}
```

#### PUT /messages/{messageId}/receipt
Update message receipt status.

**Request:**
```json
{
  "type": "delivered" | "read"
}
```

**Response:**
```json
{
  "success": true,
  "timestamp": "2024-01-15T10:32:00Z"
}
```

### WebSocket Connection

#### WS /ws
Establish WebSocket connection for real-time messaging.

**Connection URL:**
```
ws://localhost:8081/ws?token=<jwt_token>
```

**Message Types:**

1. **Handshake**
```json
{
  "type": "handshake",
  "user": "alice",
  "sessionId": "660e8400-e29b-41d4-a716-446655440001"
}
```

2. **Message**
```json
{
  "type": "message",
  "sessionId": "660e8400-e29b-41d4-a716-446655440001",
  "content": "encrypted_content",
  "header": {},
  "signature": "base64_signature"
}
```

3. **Receipt**
```json
{
  "type": "receipt",
  "messageId": "770e8400-e29b-41d4-a716-446655440002",
  "receiptType": "delivered"
}
```

4. **Typing Indicator**
```json
{
  "type": "typing",
  "sessionId": "660e8400-e29b-41d4-a716-446655440001",
  "isTyping": true
}
```

### Metrics

#### GET /metrics
Prometheus-compatible metrics endpoint.

**Response:**
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/health"} 42

# HELP message_sent_total Total messages sent
# TYPE message_sent_total counter
message_sent_total 1337

# HELP ws_connections_active Active WebSocket connections
# TYPE ws_connections_active gauge
ws_connections_active 5
```

## Error Responses

All errors follow this format:
```json
{
  "error": {
    "code": "INVALID_SESSION",
    "message": "Session not found or expired",
    "details": {}
  },
  "timestamp": "2024-01-15T10:33:00Z"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `INVALID_REQUEST` | 400 | Invalid request parameters |
| `INVALID_SESSION` | 400 | Session not found or expired |
| `KEY_EXCHANGE_FAILED` | 400 | Key exchange protocol failed |
| `ENCRYPTION_ERROR` | 500 | Encryption/decryption failed |
| `DATABASE_ERROR` | 500 | Database operation failed |
| `INTERNAL_ERROR` | 500 | Internal server error |

## Rate Limiting

API endpoints are rate-limited:
- Authentication endpoints: 5 requests per minute
- Message endpoints: 100 requests per minute
- Other endpoints: 30 requests per minute

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705318380
```

## Security Considerations

1. **TLS Required**: All production deployments must use HTTPS/WSS
2. **Token Expiry**: JWT tokens expire after 24 hours
3. **Key Rotation**: Ephemeral keys should be rotated regularly
4. **Message Retention**: Messages are deleted after 30 days
5. **Audit Logging**: All operations are logged for security auditing

## Double Ratchet Protocol

This API implements the Signal Protocol's Double Ratchet algorithm:

1. **X3DH Key Exchange**: Initial key agreement
2. **Double Ratchet**: Continuous key derivation
3. **Message Encryption**: AES-256-GCM with authentication
4. **Perfect Forward Secrecy**: Ephemeral keys for each message
5. **Future Secrecy**: Automatic key rotation

## Example Usage

### Initialize Session and Send Message

```bash
# 1. Get recipient's prekey bundle
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/v1/users/bob/prekey-bundle

# 2. Initialize session
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"recipientUsername":"bob","ephemeralPublicKey":"..."}' \
  http://localhost:8080/api/v1/sessions

# 3. Send encrypted message
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"...","header":{...},"ciphertext":"..."}' \
  http://localhost:8080/api/v1/messages
```

## SDK Support

Client SDKs are available for:
- JavaScript/TypeScript (Web, Node.js)
- Go
- Rust
- Python
- Swift (iOS)
- Kotlin (Android)

See individual SDK documentation for platform-specific implementation details.