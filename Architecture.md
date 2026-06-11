# AgriMart — Architecture Decisions & Context

## What is AgriMart
High-performance, mobile-first B2B directory and discovery marketplace for agricultural
products (bulk crops, grains, fruits, vegetables, seeds). Connects local farmers (sellers)
with commercial buyers and mandi traders. Focuses on low-latency search, discovery, and
direct communication via phone or WhatsApp. No checkout, no payment escrow.

---

## Stack

| Layer | Choice | Reason |
|---|---|---|
| Language | Go | Low latency, goroutine concurrency, strong stdlib |
| Router | Chi (`github.com/go-chi/chi/v5`) | 100% net/http compatible, clean middleware chaining |
| Database | PostgreSQL + PostGIS | Structured data + proximity search |
| DB Driver | pgx/v5 + pgxpool | Native Postgres driver, faster than lib/pq, supports PG types |
| Query gen | sqlc | Type-safe queries, no ORM |
| Migrations | goose v3 | Single-file up/down, supports Go migration functions, clean embed support |
| Cache | Redis (`github.com/redis/go-redis/v9`) | Session, rate limiting, search result cache (5min TTL) |
| Search | Typesense | Fuzzy full-text search on crop names/locations. Faster than ILIKE at scale |
| Auth | Firebase OTP → own JWT | Phone-first OTP for Indian market. Firebase only in verification path |
| JWT | `github.com/golang-jwt/jwt/v5` | Minimal, well maintained |
| Object storage | Cloudflare R2 | Farm/crop photos. No egress fees |
| Logging | slog (stdlib) | Structured JSON logging, zero dependencies, Go 1.21+ |
| Validation | `github.com/go-playground/validator/v10` | Struct tag validation |
| Config | `github.com/joho/godotenv` + own helpers | Lightweight, no viper |
| Frontend | Next.js (App Router + RSC) | Mobile-first, SSR for SEO on listing pages |

---

## Project Structure

```
agrimart/
├── .gitignore
├── .env.example
├── DECISIONS.md
├── backend/
│   ├── cmd/
│   │   ├── server/
│   │   │   └── main.go          — bootstrap only: load config, init deps, call app.serve()
│   │   └── migrate/
│   │       └── main.go          — standalone migration binary, runs goose.Up then exits
│   ├── internal/
│   │   ├── api/
│   │   │   ├── application.go   — application struct, NewApplication, serve(), background()
│   │   │   ├── router.go        — app.routes(), middleware chain
│   │   │   ├── helpers.go       — readJSON, writeJSON (plain functions, not methods)
│   │   │   ├── response.go      — envelope types, ok/created/collection/serverError etc
│   │   │   └── params.go        — queryString, queryInt, mustQueryInt, pageParams
│   │   ├── config/
│   │   │   ├── config.go        — Config struct, Load(), validate(), secret type
│   │   │   └── config_test.go   — white-box tests for secret type (package config)
│   │   ├── database/
│   │   │   ├── database.go      — pgxpool Connect(), pool settings
│   │   │   ├── migrate.go       — goose runner wrapper (RunMigrations)
│   │   │   └── queries/         — sqlc generated, never edit manually
│   │   │       ├── db.go
│   │   │       ├── models.go
│   │   │       └── *.sql.go
│   │   └── logger/
│   │       ├── logger.go        — New(env), WithContext, FromContext, RequestAttrs
│   │       ├── middleware.go    — Chi middleware, request-scoped logger in context
│   │       └── logger_test.go
│   ├── migrations/
│   │   ├── queries/             — hand-written .sql files for sqlc
│   │   │   └── listings.sql
│   │   ├── 00001_extensions.sql
│   │   ├── 00002_users.sql
│   │   ├── 00003_profiles.sql
│   │   ├── 00004_categories.sql
│   │   ├── 00005_listings.sql
│   │   ├── 00006_enquiries.sql
│   │   ├── 00007_contact_events.sql
│   │   └── 00008_indexes.sql
│   └── sqlc.yaml
└── frontend/
    ├── app/
    │   ├── (public)/
    │   │   ├── page.tsx
    │   │   ├── listings/[id]/page.tsx
    │   │   └── search/page.tsx
    │   └── (dashboard)/
    │       ├── farmer/
    │       └── buyer/
    ├── components/
    │   ├── ListingCard.tsx
    │   ├── SearchBar.tsx
    │   └── ContactCTA.tsx        — WhatsApp + call buttons, the core lead gen component
    └── lib/
        └── api.ts
```

---

## Architectural Decisions

### Dependency management — Alex Edwards application struct
All dependencies (config, logger, db, redis) live on a central `application` struct in
`internal/api/application.go`. Handlers are methods on `app`. Plain utility functions
(readJSON, writeJSON, response helpers, param helpers) are package-level functions — not
methods — because they don't touch app's fields.

Rule: only add a receiver if the function needs app's fields.

### Two-binary setup (cmd/server + cmd/migrate)
Migrations run as a separate binary before the server starts. Avoids race condition when
running multiple server replicas that would all try to migrate simultaneously on startup.

### Two-layer search
- Typesense: fuzzy text matching ("tamato" → "tomato"), crop name search
- PostGIS: hard geo constraints, proximity filter, price range
Sync listings to Typesense via background goroutine on insert/update.

### IP strategy is configurable
Infrastructure not decided yet (Nginx vs Cloudflare vs other). IP strategy is a config
value so the decision is deferred to an env var with zero code changes needed.

```
IP_STRATEGY=remote_addr      # local dev, no proxy
IP_STRATEGY=xff_trusted      # nginx / cloud LB, set TRUSTED_PROXY_CIDRS too
IP_STRATEGY=cloudflare       # behind Cloudflare, uses CF-Connecting-IP
IP_STRATEGY=custom_header    # anything else, set CLIENT_IP_HEADER too
```

### secret type in config
Unexported `secret` type wraps sensitive string values (DatabaseURL, JWTSecret).
Implements `slog.LogValuer` and `fmt.Stringer` — both return "********".
Only exposed via `.Reveal()` method, making accidental leaks into logs impossible.
Tested in `config_test.go` using white-box testing (package config, not package config_test).

### Logger pattern
- `logger.New(env)` creates the base logger (JSON in prod, text in dev)
- `slog.SetDefault(log)` set in main.go so package-level slog calls use the same handler
- `logger.WithContext` / `logger.FromContext` for request-scoped loggers
- Middleware attaches request_id, method, path, ip to every log line in a request
- Inside handlers: always use `logger.FromContext(r.Context())`
- Inside background(): use `app.logger` (no request context available)
- In main.go before server starts: use `slog.Info/Error` directly

### Response envelope
```
Single resource:  { "data": {...} }
Collection:       { "data": [...], "meta": { total, page_size, page_offset, page_count } }
Error:            { "error": { "message": "...", "code": "machine_readable_string" } }
```
Error codes are constants in response.go (ErrCodeNotFound, ErrCodeUnauthorized etc).
HTTP status codes are never repeated in the body.

### Graceful shutdown
Uses shutdownErr channel pattern. ListenAndServe blocks on main goroutine.
Signal handling in a goroutine. app.wg.Wait() before signalling shutdown complete.
30 second shutdown timeout.

### background() helper
On application struct in application.go. Wraps wg.Add/Done and panic recovery.
All background goroutines go through this — never spin a raw goroutine in a handler.

---

## Packages

```
github.com/go-chi/chi/v5
github.com/go-chi/cors
github.com/jackc/pgx/v5
github.com/redis/go-redis/v9
github.com/typesense/typesense-go
github.com/golang-jwt/jwt/v5
firebase.google.com/go/v4
github.com/go-playground/validator/v10
github.com/joho/godotenv
github.com/pressly/goose/v3
github.com/stretchr/testify       (test only)
golang.org/x/time                 (rate limiting)
```

---

## Current .env (development)

```
APP_ENV=development
DATABASE_URL=postgres://postgres:password@localhost:5432/agrimart_dev?sslmode=disable
PORT=8080
IP_STRATEGY=remote_addr
```

These are intentionally deferred (uncomment as integrations are built):
```
# REDIS_URL=
# JWT_SECRET=
# TYPESENSE_API_KEY=
# FIREBASE_PROJECT_ID=
# TRUSTED_PROXY_CIDRS=
# CLIENT_IP_HEADER=
```

---

## Database Schema (planned, not yet migrated)

### Tables
- `users` — single table for farmers and buyers, role field differentiates
- `farmer_profiles` — farm name, village, district, state, PostGIS location, verified flag
- `buyer_profiles` — business name, GST, buyer_type (trader|processor|retailer|exporter)
- `categories` — self-referential parent/child, two levels (Grains → Rice)
- `listings` — core table, PostGIS location, tsvector for FTS, expires_at, photos as TEXT[]
- `enquiries` — buyer messages through platform (status: pending|read|replied|closed)
- `contact_events` — every WhatsApp/call tap. Core analytics. buyer_id nullable (unauthed)

### Key indexes planned
- listings: (status, expires_at), GIST(location), GIN(search_vector), (category_id)
- contact_events: (listing_id, created_at) for lead analytics
- farmer_profiles: GIST(location), (district, state)

### sqlc.yaml
```yaml
version: "2"
sql:
  - engine: "postgresql"
    queries: "./migrations/queries/"
    schema: "./migrations/"
    gen:
      go:
        package: "queries"
        out: "./internal/database/queries"
        sql_package: "pgx/v5"
```

---

## What was written but not yet tested
- readJSON error cases (body too large, unknown fields, malformed JSON)
- pageParams clamping logic
- background() panic recovery
- config.Load() and validate()

secret type IS tested in config_test.go.

---

## What is NOT built yet (next steps in order)
1. Migration SQL files
2. sqlc generate
3. Wire pgxpool into application struct
4. Health check endpoint GET /health
5. CORS configuration
6. Auth middleware (JWT validation, currentUser helper)
7. First real handler (listings search)
8. Tests against real handlers