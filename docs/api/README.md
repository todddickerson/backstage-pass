# API Documentation

The Backstage Pass API provides programmatic access to platform features for mobile apps and third-party integrations.

## Table of Contents

- [Authentication](#authentication)
- [Base URL](#base-url)
- [Rate Limiting](#rate-limiting)
- [Response Format](#response-format)
- [Endpoints](#endpoints)
- [Webhooks](#webhooks)
- [SDKs](#sdks)

## Authentication

The API uses token-based authentication with support for multiple methods:

### API Tokens

Generate API tokens in your account settings:

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     https://api.backstagepass.app/v1/spaces
```

### OAuth 2.0 (Coming Soon)

For third-party applications, OAuth 2.0 flow will be available:

```bash
# Authorization
GET https://backstagepass.app/oauth/authorize?
    client_id=YOUR_CLIENT_ID&
    redirect_uri=YOUR_REDIRECT_URI&
    response_type=code&
    scope=read:spaces,write:streams

# Token exchange
POST https://backstagepass.app/oauth/token
Content-Type: application/json

{
  "grant_type": "authorization_code",
  "code": "AUTHORIZATION_CODE",
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET"
}
```

## Base URL

```
Production: https://api.backstagepass.app
Staging:    https://api-staging.backstagepass.app
```

All API requests must be made over HTTPS.

## Rate Limiting

API requests are rate limited:

- **Authenticated**: 100 requests per minute
- **Unauthenticated**: 20 requests per minute

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Response Format

All responses use JSON format:

### Success Response

```json
{
  "data": {
    "id": "123",
    "type": "space",
    "attributes": {
      "name": "Creator Space",
      "slug": "creator-space"
    }
  },
  "meta": {
    "total": 1,
    "page": 1,
    "per_page": 20
  }
}
```

### Error Response

```json
{
  "errors": [
    {
      "status": "404",
      "title": "Resource not found",
      "detail": "The requested space could not be found",
      "source": {
        "pointer": "/data/attributes/space_id"
      }
    }
  ]
}
```

## Endpoints

### Spaces

#### List Spaces

```bash
GET /v1/spaces
```

**Response:**
```json
{
  "data": [
    {
      "id": "123",
      "type": "space",
      "attributes": {
        "name": "Creator Space",
        "slug": "creator-space",
        "description": "Exclusive content for fans",
        "created_at": "2025-01-01T00:00:00Z"
      },
      "relationships": {
        "experiences": {
          "data": [
            {"id": "456", "type": "experience"}
          ]
        }
      }
    }
  ]
}
```

#### Get Space

```bash
GET /v1/spaces/{id}
```

**Parameters:**
- `include` (optional): Include related resources (`experiences`, `access_passes`)

#### Create Space

```bash
POST /v1/spaces
Content-Type: application/json

{
  "data": {
    "type": "space",
    "attributes": {
      "name": "New Space",
      "slug": "new-space",
      "description": "Description here"
    }
  }
}
```

### Experiences

#### List Experiences

```bash
GET /v1/spaces/{space_id}/experiences
```

**Query Parameters:**
- `filter[type]`: Filter by experience type (`live_stream`, `course`, etc.)
- `sort`: Sort order (`created_at`, `-created_at`, `name`)
- `page[number]`: Page number
- `page[size]`: Page size (max 100)

#### Get Experience

```bash
GET /v1/experiences/{id}
```

#### Create Experience

```bash
POST /v1/spaces/{space_id}/experiences
Content-Type: application/json

{
  "data": {
    "type": "experience",
    "attributes": {
      "name": "Live Coding Session",
      "description": "Learn Rails development",
      "experience_type": "live_stream",
      "price_cents": 2999
    }
  }
}
```

### Streams

#### List Streams

```bash
GET /v1/experiences/{experience_id}/streams
```

**Query Parameters:**
- `filter[status]`: Filter by status (`scheduled`, `live`, `ended`)
- `filter[upcoming]`: Only future streams

#### Get Stream

```bash
GET /v1/streams/{id}
```

**Response:**
```json
{
  "data": {
    "id": "789",
    "type": "stream",
    "attributes": {
      "title": "Building a SaaS App",
      "description": "Live coding session",
      "status": "scheduled",
      "scheduled_at": "2025-01-15T20:00:00Z",
      "viewer_count": 0
    },
    "relationships": {
      "experience": {
        "data": {"id": "456", "type": "experience"}
      }
    }
  }
}
```

#### Start Stream

```bash
POST /v1/streams/{id}/start
```

#### End Stream

```bash
POST /v1/streams/{id}/end
```

#### Join Stream

```bash
POST /v1/streams/{id}/join
```

**Response:**
```json
{
  "data": {
    "token": "livekit_jwt_token_here",
    "room_url": "wss://livekit.backstagepass.app",
    "room_name": "stream_789",
    "can_publish": false
  }
}
```

### Access Passes

#### List Access Passes

```bash
GET /v1/spaces/{space_id}/access_passes
```

#### Purchase Access Pass

```bash
POST /v1/access_passes/{id}/purchase
Content-Type: application/json

{
  "data": {
    "type": "purchase",
    "attributes": {
      "payment_method": "card",
      "success_url": "https://yourapp.com/success",
      "cancel_url": "https://yourapp.com/cancel"
    }
  }
}
```

**Response:**
```json
{
  "data": {
    "checkout_url": "https://checkout.stripe.com/session_123",
    "session_id": "cs_test_123"
  }
}
```

### User Profile

#### Get Current User

```bash
GET /v1/me
```

#### Update Profile

```bash
PATCH /v1/me
Content-Type: application/json

{
  "data": {
    "type": "user",
    "attributes": {
      "first_name": "John",
      "last_name": "Doe",
      "bio": "Content creator"
    }
  }
}
```

## Webhooks

Configure webhooks to receive real-time notifications about platform events.

### Setup

1. Navigate to **Settings → Webhooks**
2. Add endpoint URL
3. Select events to receive
4. Save webhook secret for verification

### Events

#### Stream Events

```json
{
  "event": "stream.started",
  "data": {
    "stream_id": "789",
    "experience_id": "456",
    "started_at": "2025-01-15T20:00:00Z"
  },
  "timestamp": "2025-01-15T20:00:01Z"
}
```

#### Payment Events

```json
{
  "event": "access_grant.created",
  "data": {
    "access_grant_id": "999",
    "user_id": "111",
    "access_pass_id": "888",
    "amount_cents": 2999
  },
  "timestamp": "2025-01-15T19:55:00Z"
}
```

### Verification

Verify webhook authenticity using the signature:

```python
import hmac
import hashlib

def verify_webhook(payload, signature, secret):
    expected = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)
```

### Event Types

- `stream.scheduled`
- `stream.started`
- `stream.ended`
- `access_grant.created`
- `access_grant.expired`
- `experience.created`
- `space.created`

## SDKs

### JavaScript/Node.js (Coming Soon)

```javascript
import { BackstagePass } from '@backstagepass/sdk';

const client = new BackstagePass({
  apiKey: 'your_api_key',
  environment: 'production' // or 'staging'
});

// List spaces
const spaces = await client.spaces.list();

// Join stream
const streamToken = await client.streams.join('stream_id');
```

### iOS/Swift (Coming Soon)

```swift
import BackstagePassSDK

let client = BackstagePassClient(apiKey: "your_api_key")

// List experiences
client.experiences.list(spaceId: "space_id") { result in
    switch result {
    case .success(let experiences):
        print("Found \(experiences.count) experiences")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Android/Kotlin (Coming Soon)

```kotlin
import com.backstagepass.sdk.BackstagePassClient

val client = BackstagePassClient("your_api_key")

// Get stream details
client.streams.get("stream_id") { result ->
    result.onSuccess { stream ->
        println("Stream: ${stream.title}")
    }.onFailure { error ->
        println("Error: ${error.message}")
    }
}
```

## Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `authentication_required` | 401 | API key missing or invalid |
| `access_denied` | 403 | Insufficient permissions |
| `not_found` | 404 | Resource not found |
| `rate_limit_exceeded` | 429 | Too many requests |
| `validation_failed` | 422 | Invalid request data |
| `server_error` | 500 | Internal server error |

## Testing

### Postman Collection

Import our Postman collection for easy API testing:

```bash
curl -o backstagepass-api.json \
     https://api.backstagepass.app/postman/collection.json
```

### Test Environment

Use our staging API for development:

```
Base URL: https://api-staging.backstagepass.app
Test API Key: Available in staging dashboard
```

## Support

For API support:
- **Documentation**: [docs.backstagepass.app](https://docs.backstagepass.app)
- **Discord**: [Join Developer Community](https://discord.gg/backstagepass-dev)
- **Email**: developers@backstagepass.app
- **GitHub**: [Open an Issue](https://github.com/backstagepass/api-issues)

---

Happy building! 🚀