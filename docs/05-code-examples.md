# Code Examples

> **Author:** Carol Smith — last updated 2026-04-14

This chapter collects representative code samples for the Platform API across
several languages. It also serves as a syntax-highlighting reference for the
documentation toolchain.

## Configuration (YAML)

Service configuration is supplied via a YAML file. The following shows a
complete example for a production deployment:

```yaml
# platform-config.yaml
service:
  name: resource-service
  version: "1.4.2"
  environment: production

server:
  host: "0.0.0.0"
  port: 8002
  workers: 4
  timeout: 30

database:
  url: "postgresql+asyncpg://app:secret@db:5432/platform"
  pool_min: 2
  pool_max: 10
  pool_timeout: 30

auth:
  jwt_algorithm: RS256
  jwt_expiry_seconds: 900
  public_key_path: "/run/secrets/jwt_public.pem"

logging:
  level: INFO
  format: json
  fields:
    - timestamp
    - level
    - service
    - trace_id
```

## API Response (JSON)

A successful paginated response from `GET /api/v1/resources`:

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "019312ab-4f2e-7c1d-a8b3-0e5f6d7e8c9a",
        "name": "Q1 Financial Report",
        "type": "document",
        "active": true,
        "metadata": {
          "tags": ["finance", "quarterly"],
          "owner": "alice@example.com",
          "size_bytes": 204800
        },
        "created_at": "2026-04-01T09:00:00Z",
        "updated_at": "2026-04-10T14:32:11Z"
      },
      {
        "id": "019312ab-4f2e-7c1d-a8b3-0e5f6d7e8c9b",
        "name": "Architecture Diagram",
        "type": "image",
        "active": true,
        "metadata": {
          "tags": ["engineering"],
          "owner": "bob@example.com",
          "size_bytes": 512000
        },
        "created_at": "2026-04-05T11:15:00Z",
        "updated_at": "2026-04-05T11:15:00Z"
      }
    ],
    "total": 142,
    "page": 1,
    "per_page": 20
  }
}
```

## C Header — Client Library (`platform_client.h`)

The Platform API ships an optional C client library for embedded and
systems-level integrations:

```c
/* platform_client.h — Platform API C client library
 * Version: 1.4.2
 * License: MIT
 */

#ifndef PLATFORM_CLIENT_H
#define PLATFORM_CLIENT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ── Types ─────────────────────────────────────────────────────────────── */

/** Opaque handle returned by platform_client_new(). */
typedef struct platform_client platform_client_t;

/** HTTP response returned by every API call. Caller must free with
 *  platform_response_free(). */
typedef struct {
    int         status_code;  /**< HTTP status code (200, 201, 404, …) */
    char       *body;         /**< NUL-terminated JSON response body    */
    size_t      body_len;     /**< Length of body in bytes              */
} platform_response_t;

/** Error codes returned by library functions. */
typedef enum {
    PLATFORM_OK              =  0,
    PLATFORM_ERR_OOM         = -1,  /**< Out of memory                  */
    PLATFORM_ERR_INVALID_ARG = -2,  /**< NULL or malformed argument     */
    PLATFORM_ERR_NETWORK     = -3,  /**< TCP/TLS connection failure      */
    PLATFORM_ERR_TIMEOUT     = -4,  /**< Request exceeded timeout       */
    PLATFORM_ERR_AUTH        = -5,  /**< 401 — invalid or expired token */
} platform_err_t;

/* ── Lifecycle ──────────────────────────────────────────────────────────── */

/**
 * Create a new client instance.
 *
 * @param base_url  Base URL of the API gateway, e.g. "https://api.example.com"
 * @param token     Bearer token (copied internally — caller may free afterwards)
 * @param timeout_s Request timeout in seconds (0 = use default of 30 s)
 * @return          New client handle, or NULL on allocation failure
 */
platform_client_t *platform_client_new(const char *base_url,
                                       const char *token,
                                       uint32_t    timeout_s);

/** Release all resources associated with a client handle. */
void platform_client_free(platform_client_t *client);

/* ── Resources ──────────────────────────────────────────────────────────── */

/**
 * List resources (GET /api/v1/resources).
 *
 * @param client    Client handle
 * @param page      1-indexed page number
 * @param per_page  Items per page (1–100)
 * @param out       Populated on success; free with platform_response_free()
 * @return          PLATFORM_OK on success, error code otherwise
 */
platform_err_t platform_list_resources(platform_client_t    *client,
                                       int                   page,
                                       int                   per_page,
                                       platform_response_t **out);

/**
 * Get a single resource by ID (GET /api/v1/resources/{id}).
 */
platform_err_t platform_get_resource(platform_client_t    *client,
                                     const char           *id,
                                     platform_response_t **out);

/** Free a response previously returned by a library function. */
void platform_response_free(platform_response_t *resp);

#ifdef __cplusplus
}
#endif

#endif /* PLATFORM_CLIENT_H */
```

## C Implementation (`platform_client.c`)

Core implementation of the resource listing function:

```c
/* platform_client.c */

#include "platform_client.h"

#include <curl/curl.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ── Internal structures ────────────────────────────────────────────────── */

struct platform_client {
    char    *base_url;
    char    *auth_header;   /* "Authorization: Bearer <token>" */
    uint32_t timeout_s;
    CURL    *curl;
};

typedef struct {
    char  *data;
    size_t len;
} write_buf_t;

/* ── Helpers ────────────────────────────────────────────────────────────── */

static size_t write_callback(char *ptr, size_t size, size_t nmemb, void *ud)
{
    size_t      bytes = size * nmemb;
    write_buf_t *buf  = (write_buf_t *)ud;

    char *tmp = realloc(buf->data, buf->len + bytes + 1);
    if (!tmp) return 0;   /* signals error to libcurl */

    buf->data = tmp;
    memcpy(buf->data + buf->len, ptr, bytes);
    buf->len += bytes;
    buf->data[buf->len] = '\0';
    return bytes;
}

/* ── Public API ─────────────────────────────────────────────────────────── */

platform_client_t *platform_client_new(const char *base_url,
                                       const char *token,
                                       uint32_t    timeout_s)
{
    if (!base_url || !token) return NULL;

    platform_client_t *c = calloc(1, sizeof(*c));
    if (!c) return NULL;

    c->base_url  = strdup(base_url);
    c->timeout_s = timeout_s ? timeout_s : 30;
    c->curl      = curl_easy_init();

    /* Build Authorization header value once and reuse it */
    size_t hlen      = strlen("Authorization: Bearer ") + strlen(token) + 1;
    c->auth_header   = malloc(hlen);
    snprintf(c->auth_header, hlen, "Authorization: Bearer %s", token);

    if (!c->base_url || !c->auth_header || !c->curl) {
        platform_client_free(c);
        return NULL;
    }
    return c;
}

platform_err_t platform_list_resources(platform_client_t    *client,
                                       int                   page,
                                       int                   per_page,
                                       platform_response_t **out)
{
    if (!client || !out) return PLATFORM_ERR_INVALID_ARG;

    /* Build URL: <base>/api/v1/resources?page=N&per_page=N */
    char url[512];
    snprintf(url, sizeof(url), "%s/api/v1/resources?page=%d&per_page=%d",
             client->base_url, page, per_page);

    write_buf_t buf = { .data = NULL, .len = 0 };

    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, client->auth_header);
    headers = curl_slist_append(headers, "Accept: application/json");

    curl_easy_setopt(client->curl, CURLOPT_URL,            url);
    curl_easy_setopt(client->curl, CURLOPT_HTTPHEADER,     headers);
    curl_easy_setopt(client->curl, CURLOPT_WRITEFUNCTION,  write_callback);
    curl_easy_setopt(client->curl, CURLOPT_WRITEDATA,      &buf);
    curl_easy_setopt(client->curl, CURLOPT_TIMEOUT,        (long)client->timeout_s);

    CURLcode res  = curl_easy_perform(client->curl);
    curl_slist_free_all(headers);

    if (res != CURLE_OK) {
        free(buf.data);
        return (res == CURLE_OPERATION_TIMEDOUT)
               ? PLATFORM_ERR_TIMEOUT
               : PLATFORM_ERR_NETWORK;
    }

    platform_response_t *resp = calloc(1, sizeof(*resp));
    curl_easy_getinfo(client->curl, CURLINFO_RESPONSE_CODE, &resp->status_code);
    resp->body     = buf.data;
    resp->body_len = buf.len;
    *out = resp;

    return PLATFORM_OK;
}
```

## Python Client (`platform_client.py`)

A lightweight Python wrapper around the REST API using only the standard
library:

```python
"""platform_client.py — Minimal Platform API client (stdlib only)."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from typing import Any


@dataclass
class Resource:
    id: str
    name: str
    type: str
    active: bool
    metadata: dict[str, Any] = field(default_factory=dict)
    created_at: str = ""
    updated_at: str = ""

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Resource":
        return cls(
            id=data["id"],
            name=data["name"],
            type=data["type"],
            active=data["active"],
            metadata=data.get("metadata", {}),
            created_at=data.get("created_at", ""),
            updated_at=data.get("updated_at", ""),
        )


class PlatformAPIError(Exception):
    def __init__(self, status_code: int, code: str, message: str) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.code = code


class PlatformClient:
    """Thread-safe, stateless REST client for the Platform API."""

    def __init__(self, base_url: str, token: str, timeout: int = 30) -> None:
        self._base = base_url.rstrip("/")
        self._token = token
        self._timeout = timeout

    # ── Internal helpers ──────────────────────────────────────────────────

    def _request(
        self,
        method: str,
        path: str,
        body: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        url = f"{self._base}{path}"
        data = json.dumps(body).encode() if body else None
        req = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "Authorization": f"Bearer {self._token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=self._timeout) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as exc:
            payload = json.loads(exc.read())
            error = payload.get("error", {})
            raise PlatformAPIError(
                exc.code,
                error.get("code", "UNKNOWN"),
                error.get("message", str(exc)),
            ) from exc

    # ── Resources ─────────────────────────────────────────────────────────

    def list_resources(
        self,
        page: int = 1,
        per_page: int = 20,
        query: str | None = None,
    ) -> tuple[list[Resource], int]:
        """Return (items, total) for the given page."""
        qs = f"?page={page}&per_page={per_page}"
        if query:
            qs += f"&q={urllib.parse.quote(query)}"
        data = self._request("GET", f"/api/v1/resources{qs}")["data"]
        items = [Resource.from_dict(r) for r in data["items"]]
        return items, data["total"]

    def get_resource(self, resource_id: str) -> Resource:
        data = self._request("GET", f"/api/v1/resources/{resource_id}")
        return Resource.from_dict(data["data"])

    def create_resource(
        self,
        name: str,
        type_: str,
        metadata: dict[str, Any] | None = None,
    ) -> Resource:
        payload = {"name": name, "type": type_}
        if metadata:
            payload["metadata"] = metadata
        data = self._request("POST", "/api/v1/resources", body=payload)
        return Resource.from_dict(data["data"])

    def delete_resource(self, resource_id: str) -> None:
        """Soft-delete a resource (sets active=False server-side)."""
        self._request("DELETE", f"/api/v1/resources/{resource_id}")


# ── Example usage ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    client = PlatformClient(
        base_url="http://localhost:8000",
        token="eyJhbGciOiJSUzI1NiJ9...",
    )

    resources, total = client.list_resources(page=1, per_page=5)
    print(f"Total resources: {total}")
    for r in resources:
        print(f"  [{r.type}] {r.name} ({r.id})")
```
