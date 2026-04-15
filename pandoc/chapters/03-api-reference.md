# API Reference

> **Author:** Carol Smith — last updated 2026-04-12

All endpoints are prefixed with `/api/v1/`. Requests and responses use
`Content-Type: application/json`. Authenticated endpoints require an
`Authorization: Bearer <token>` header.

## Response Envelope

Every response — success or error — is wrapped in a standard envelope:

```json
{
  "success": true,
  "data": { }
}
```

On error:

```json
{
  "success": false,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested resource does not exist."
  }
}
```

## Authentication

### Register

```
POST /api/v1/auth/register
```

**Request body:**

```json
{
  "email": "alice@example.com",    // required
  "password": "s3cur3P@ssword",    // required, min 12 chars
  "name": "Alice Nguyen"           // required
}
```

**Response `201 Created`:**

```json
{
  "success": true,
  "data": {
    "id": "019312ab-...",
    "email": "alice@example.com",
    "name": "Alice Nguyen",
    "created_at": "2026-04-13T10:00:00Z"
  }
}
```

### Login

```
POST /api/v1/auth/login
```

**Request body:**

```json
{
  "email": "alice@example.com",
  "password": "s3cur3P@ssword"
}
```

**Response `200 OK`:**

```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "bearer",
    "expires_in": 900
  }
}
```

## Resources

### List Resources

```
GET /api/v1/resources
```

**Query parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | integer | `1` | Page number (1-indexed) |
| `per_page` | integer | `20` | Items per page (max 100) |
| `sort` | string | `created_at` | Sort field |
| `order` | string | `desc` | `asc` or `desc` |
| `q` | string | — | Full-text search query |

**Response `200 OK`:**

```json
{
  "success": true,
  "data": {
    "items": [ { "id": "...", "name": "..." } ],
    "total": 142,
    "page": 1,
    "per_page": 20
  }
}
```

### Create Resource

```
POST /api/v1/resources
```

**Request body:**

```json
{
  "name": "My Resource",      // required
  "type": "document",         // required: document | image | dataset
  "metadata": {               // optional, arbitrary JSON
    "tags": ["alpha", "beta"]
  }
}
```

**Response `201 Created`** — returns the full resource object.

### Get Resource

```
GET /api/v1/resources/{id}
```

**Response `200 OK`:**

```json
{
  "success": true,
  "data": {
    "id": "019312ab-...",
    "name": "My Resource",
    "type": "document",
    "metadata": { "tags": ["alpha", "beta"] },
    "created_at": "2026-04-13T10:00:00Z",
    "updated_at": "2026-04-13T10:00:00Z"
  }
}
```

**Response `404 Not Found`:**

```json
{
  "success": false,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Resource 019312ab-... does not exist."
  }
}
```

### Update Resource

```
PATCH /api/v1/resources/{id}
```

Partial update — only include fields you want to change.

### Delete Resource (Soft)

```
DELETE /api/v1/resources/{id}
```

Sets `active = false`. The record is retained for audit purposes and does not
appear in list responses. Returns `204 No Content` on success.

## Error Codes Reference

| Code | HTTP Status | Description |
|---|---|---|
| `VALIDATION_ERROR` | 422 | Request body failed schema validation |
| `UNAUTHORIZED` | 401 | Missing or invalid JWT |
| `FORBIDDEN` | 403 | Valid JWT but insufficient permissions |
| `RESOURCE_NOT_FOUND` | 404 | Entity does not exist or is soft-deleted |
| `CONFLICT` | 409 | Duplicate unique field (e.g., email already registered) |
| `RATE_LIMITED` | 429 | Client exceeded the rate limit |
| `INTERNAL_ERROR` | 500 | Unhandled server-side error |
