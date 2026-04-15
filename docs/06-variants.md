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

---

## If / Else Conditional Content

The examples above use one div per type — each type gets its own block. The
filter also supports a **negation syntax** (`.not-typeN`) that lets you write
a true if/else without listing every other type explicitly.

### Basic if / else

The text inside `.type1` appears only for `DOC_TYPE=type1`. The text inside
`.not-type1` appears for every other type (type2, type3, …).

::: {.type1}
**Authentication:** This build uses certificate-based authentication managed
by the internal PKI. No API keys are issued.
:::

::: {.not-type1}
**Authentication:** This build uses API key authentication. Keys are issued
through the developer portal and rotate every 90 days.
:::

### Else spanning multiple excluded types

You can stack multiple `.not-typeN` classes on one div. The div is shown
unless the current type matches *any* of the listed exclusions.

::: {.type3}
> **Warning:** This configuration is for local development only. Do not use
> these settings in a production or staging environment.
:::

::: {.not-type1 .not-type2}
> **Note:** This message appears only when the build is neither type1 nor
> type2 — in this project that means type3. Equivalent to `.type3` here,
> but written as a negation to show the syntax.
:::

### Three-way if / else-if / else

Combine positive and negation divs to express three distinct branches. Only
one of the three blocks below appears in any given build.

::: {.type1}
**Logging level:** `ERROR` — production on-premises deployments log errors
only to minimise storage overhead on the private infrastructure.
:::

::: {.type2}
**Logging level:** `WARN` — cloud deployments forward structured logs to the
central SIEM. Warnings and above are retained for 90 days.
:::

::: {.not-type1 .not-type2}
**Logging level:** `DEBUG` — local development builds enable verbose logging.
All request and response bodies are printed to stdout.
:::

### Negation with shared content

Content outside any div always appears. Use this to write the common parts
once and only branch the parts that differ.

The platform exposes a REST API on port 8080. All endpoints require a valid
bearer token except `/healthz`.

::: {.type1}
Tokens are issued by the internal identity provider at
`https://idp.internal.example.com/token`.
:::

::: {.not-type1}
Tokens are issued via the developer portal at
`https://portal.example.com/api-keys`.
:::

The token must be passed in the `Authorization: Bearer <token>` header on
every request.

---

## Inline Conditionals (Within Table Cells)

Block-level divs (`:::`) cannot go inside a table cell — table cells are
inline contexts in Markdown. For **cell-level** conditional content, use
**inline spans** instead:

```
[conditional text]{.type1}
```

The same include and negation classes work: `.typeN` to include, `.not-typeN`
to exclude. The span is unwrapped (span markers removed, content kept) when
the condition is met, and removed entirely when it is not.

### Primary use-case: same table, different cell text per type

Wrap the whole table in a div so it appears in both types, then use spans
inside cells to vary only the parts that differ:

::: {.type1 .type2}
| Setting | Value |
|---|---|
| Deployment mode | on-premises[ + edge cache]{.type1} |
| Database backend | PostgreSQL[ (HA cluster)]{.type1} |
| Credential store | internal PKI[ with auto-rotation]{.type1} |
| Support SLA | 99.5 % uptime[ / 99.9 % with premium]{.type1} |
:::

In a **type1** build the cells read: "on-premises + edge cache",
"PostgreSQL (HA cluster)", "internal PKI with auto-rotation",
"99.5 % uptime / 99.9 % with premium".

In a **type2** build the spans are stripped and the cells read:
"on-premises", "PostgreSQL", "internal PKI", "99.5 % uptime".

### Inline negation

Use `.not-typeN` to include text for every type except the listed ones:

::: {.type1 .type2}
| Feature | Status |
|---|---|
| Rate limiting | enabled[ (burst: 500 req/s)]{.not-type2} |
| Debug logging | disabled[ (contact support to enable)]{.type2} |
:::

In type1: "enabled (burst: 500 req/s)" and "disabled".
In type2: "enabled" and "disabled (contact support to enable)".

### Inline span authoring tips

**Put spaces inside the span, not outside.**
The space before the conditional text must be inside the brackets so that
removing the span leaves clean text with no double space:

```markdown
<!-- Correct: space is inside the span -->
text1[ and text2]{.type1}     → type1: "text1 and text2"  type2: "text1"

<!-- Avoid: space is outside, removal leaves "text1 " with trailing space -->
text1 [and text2]{.type1}     → type2: "text1 " (trailing space)
```

**Replacing text entirely** (not just appending) uses two adjacent spans:

```markdown
[on-premises]{.type1}[cloud]{.type2}
```

type1: "on-premises"   type2: "cloud"

**Works in headings and paragraphs too**, not just table cells:

```markdown
## Deployment Guide[ — On-Premises Edition]{.type1}[ — Cloud Edition]{.type2}
```

### Span vs. div: choosing the right construct

| Need | Use |
|---|---|
| Entire paragraph / block only in one type | `::: {.typeN}` div |
| Multiple paragraphs only in one type | `::: {.typeN}` div |
| Part of a table cell differs per type | `[…]{.typeN}` span |
| Part of a heading or sentence differs | `[…]{.typeN}` span |
| Whole table row differs per type | Duplicate the row, wrap in a div above/below the table — or split into two tables, one per type |
