# Deployment

> **Author:** Alice Nguyen — last updated 2026-04-13

## Prerequisites

| Tool | Minimum Version | Purpose |
|---|---|---|
| Docker | 24.x | Container runtime |
| Docker Compose | 2.x | Local orchestration |
| GNU Make | 3.81 | Build automation |
| `curl` / `jq` | any | Smoke-test scripts |

For production, a Kubernetes 1.28+ cluster is assumed. The same container
images are used in all environments; configuration is injected via environment
variables.

## Environment Variables

All services are configured through environment variables. A `.env.example`
file at the repository root lists every variable with descriptions.

### Required Variables

| Variable | Service | Description |
|---|---|---|
| `DATABASE_URL` | Resource | PostgreSQL connection string |
| `SECRET_KEY` | Auth | 32-byte random secret for JWT signing |
| `JWT_PUBLIC_KEY` | Gateway | RS256 public key (PEM format) |
| `JWT_PRIVATE_KEY` | Auth | RS256 private key (PEM format) |
| `SMTP_HOST` | Notification | SMTP relay hostname |
| `SMTP_PORT` | Notification | SMTP port (usually `587`) |

### Optional Variables

| Variable | Default | Description |
|---|---|---|
| `LOG_LEVEL` | `INFO` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `RATE_LIMIT_RPM` | `1000` | Requests per minute per client token |
| `JWT_EXPIRY_SECONDS` | `900` | Access token lifetime (15 min) |
| `CORS_ORIGINS` | `*` | Comma-separated allowed origins |

## Local Development

```bash
# 1. Copy and fill in the environment file
cp .env.example .env

# 2. Start all services
docker compose up --build

# 3. Apply database migrations
docker compose exec resource-service uv run alembic upgrade head

# 4. Smoke test — should return {"success": true, "data": {"status": "ok"}}
curl http://localhost:8000/api/v1/health | jq
```

Services and ports in local mode:

| Service | Port | URL |
|---|---|---|
| API Gateway | 8000 | `http://localhost:8000` |
| Auth Service | 8001 | internal only |
| Resource Service | 8002 | internal only |
| Notification Service | 8003 | internal only |
| PostgreSQL | 5432 | `localhost:5432` |

## Production Deployment

### Building Images

```bash
make build TAG=v1.4.2
# Equivalent to:
# docker build -t platform/auth:v1.4.2 ./auth-service
# docker build -t platform/resource:v1.4.2 ./resource-service
# docker build -t platform/notification:v1.4.2 ./notification-service
```

### Running Database Migrations

Migrations **must** run before the new application version starts serving
traffic. In the deployment pipeline this is enforced by a `migrate` init
container that runs `alembic upgrade head` and exits before the application
container starts.

```yaml
# Kubernetes init container pattern
initContainers:
  - name: migrate
    image: platform/resource:v1.4.2
    command: ["uv", "run", "alembic", "upgrade", "head"]
    envFrom:
      - secretRef:
          name: resource-service-secrets
```

### Health Checks

Each service exposes `GET /health` returning `200 OK` when ready. The
Kubernetes readiness probe should target this endpoint with a 5-second timeout
and 3 failure threshold before marking a pod unready.

## Rollback Procedure

1. Identify the last stable image tag from the CI registry.
2. Update the Kubernetes deployment image tag:

   ```bash
   kubectl set image deployment/resource-service \
     resource=platform/resource:v1.4.1 -n platform
   ```

3. Monitor rollout:

   ```bash
   kubectl rollout status deployment/resource-service -n platform
   ```

4. If the deployment involved a **schema migration**, assess whether the
   previous version is compatible with the new schema before rolling back the
   application. Schema rollbacks require a separate Alembic downgrade step and
   should be coordinated with the on-call DBA.

## Runbook — Common Issues

### Service Returns 503

1. Check pod status: `kubectl get pods -n platform`
2. Inspect logs: `kubectl logs -n platform deploy/resource-service --tail=100`
3. Common causes: database unreachable, missing environment variable, OOM kill.

### JWT Validation Failures After Deployment

Key rotation may have invalidated cached public keys in the Gateway. Trigger a
rolling restart:

```bash
kubectl rollout restart deployment/api-gateway -n platform
```

### Database Connection Pool Exhaustion

Symptom: `asyncpg.exceptions.TooManyConnectionsError` in Resource Service logs.

Reduce `DB_POOL_MAX` or scale down the number of replicas until the next
maintenance window. Long-term fix: add PgBouncer in front of PostgreSQL.
