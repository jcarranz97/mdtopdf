# Architecture Overview

> **Author:** Bob Martínez — last updated 2026-04-11

## System Components

The platform is composed of four independently deployable services that
communicate over internal HTTP. The public internet reaches only the API
Gateway.

```
                    ┌─────────────┐
  Client ──HTTPS──► │  API Gateway│
                    └──────┬──────┘
                           │ internal HTTP
           ┌───────────────┼────────────────┐
           ▼               ▼                ▼
     ┌──────────┐   ┌────────────┐   ┌──────────────┐
     │  Auth    │   │  Resource  │   │  Notification│
     │  Service │   │  Service   │   │  Service     │
     └──────────┘   └─────┬──────┘   └──────────────┘
                          │
                    ┌─────▼──────┐
                    │ PostgreSQL  │
                    └────────────┘
```

### API Gateway

Responsibilities:

- TLS termination
- JWT validation (delegates to Auth Service on cache miss)
- Rate limiting (per-client token bucket, 1 000 req/min default)
- Request routing to downstream services
- Response envelope normalization

The gateway is stateless. Configuration lives in environment variables; no
database connection is required.

### Auth Service

Responsibilities:

- User registration and credential storage (Argon2ID hashing)
- JWT issuance and refresh
- OAuth2 provider integration (Google, GitHub)

Auth Service owns the `users` and `sessions` tables. No other service writes
to these tables directly.

### Resource Service

The core business logic layer. All domain entities (projects, assets, records)
are managed here. This service is the only one with write access to the main
`app` schema in PostgreSQL.

### Notification Service

Handles email and webhook delivery. Receives events via an internal HTTP
endpoint; does not call other services. Delivery state is stored in its own
`notifications` schema.

## Data Flow — Authenticated Request

```
1. Client sends:  POST /api/v1/resources  +  Authorization: Bearer <jwt>
2. Gateway validates JWT signature (public key, no network call)
3. Gateway forwards request to Resource Service with X-User-Id header
4. Resource Service performs business logic, writes to PostgreSQL
5. Resource Service optionally POSTs event to Notification Service
6. Resource Service returns JSON response to Gateway
7. Gateway wraps response in standard envelope, returns to client
```

## Technology Choices

| Component | Technology | Reason |
|---|---|---|
| API Gateway | Nginx + Lua | Mature, low-overhead, scriptable rate limiting |
| Auth Service | FastAPI (Python) | Rapid iteration, strong typing, async I/O |
| Resource Service | FastAPI (Python) | Consistent language across backend services |
| Notification Service | Go | High throughput, minimal memory footprint |
| Database | PostgreSQL 16 | JSONB for flexible config, strong ACID guarantees |
| Auth tokens | JWT (RS256) | Stateless verification; asymmetric keys |

## Failure Modes and Degradation

| Failure | Behaviour |
|---|---|
| Auth Service down | Gateway rejects new logins; existing valid JWTs still work (no revocation check) |
| Notification Service down | Resource writes succeed; events are queued in `pending_notifications` and retried |
| PostgreSQL down | Resource Service returns 503; Auth Service returns 503 |
| Gateway down | Full outage — single point of entry by design, mitigated by multi-instance deployment |
