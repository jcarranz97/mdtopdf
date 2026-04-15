# Document Variants

> **Author:** Alice Nguyen — last updated 2026-04-14

This chapter demonstrates conditional content — sections that are included or
excluded at build time based on the `DOC_TYPE` variable. The same source file
produces different output for each variant.

Build this document as a specific type:

```bash
# Pandoc
make DOC_TYPE=type1   # or type2, type3

# Quarto
make pdf DOC_TYPE=type2

# Sphinx
make html DOC_TYPE=type3
```

---

## Deployment Target

::: {.type1}
### On-Premises Deployment (TYPE1)

This variant is for teams running the platform on private infrastructure.

| Setting | Value |
|---|---|
| `DATABASE_URL` | Internal PostgreSQL cluster |
| `JWT_PUBLIC_KEY` | Managed by internal PKI |
| `CORS_ORIGINS` | Restricted to internal domains |

```yaml
# values.yaml — on-premises
environment: on-premises
ingress:
  host: platform.internal.example.com
  tls: true
database:
  host: pg-cluster.internal
  port: 5432
```
:::

::: {.type2}
### Cloud Deployment (TYPE2)

This variant is for teams deploying to a managed cloud environment.

| Setting | Value |
|---|---|
| `DATABASE_URL` | Managed cloud database (e.g. RDS, Cloud SQL) |
| `JWT_PUBLIC_KEY` | Stored in cloud secret manager |
| `CORS_ORIGINS` | Restricted to production domain |

```yaml
# values.yaml — cloud
environment: cloud
ingress:
  host: platform.example.com
  tls: true
  annotations:
    kubernetes.io/ingress.class: "nginx"
database:
  host: platform-db.us-east-1.rds.amazonaws.com
  port: 5432
```
:::

::: {.type3}
### Local Development Deployment (TYPE3)

This variant is for individual developers running the stack locally.

| Setting | Value |
|---|---|
| `DATABASE_URL` | `localhost:5432` |
| `JWT_PUBLIC_KEY` | Generated dev key (not for production) |
| `CORS_ORIGINS` | `*` (open, for local testing only) |

```yaml
# values.yaml — local dev
environment: development
ingress:
  host: localhost
  tls: false
database:
  host: localhost
  port: 5432
```
:::

---

## API Rate Limits

Rate limits differ between deployment tiers:

::: {.type1 .type2}
```json
{
  "rate_limit": {
    "requests_per_minute": 1000,
    "burst": 200,
    "scope": "per_token"
  }
}
```
:::

::: {.type3}
```json
{
  "rate_limit": {
    "requests_per_minute": 10000,
    "burst": 1000,
    "scope": "disabled_for_local_dev"
  }
}
```
:::

---

## Support Contact

::: {.type1}
For on-premises deployments, contact your internal platform team at
`platform-ops@internal.example.com`.
:::

::: {.type2}
For cloud deployments, file a ticket at the support portal or contact
`cloud-support@example.com`.
:::

::: {.type3}
For local development issues, check the runbook in chapter 4 or open a GitHub
issue in the internal repository.
:::
