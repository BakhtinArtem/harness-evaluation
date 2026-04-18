# go-petclinic

A Go port of [`spring-petclinic-rest`](../spring-petclinic-rest) that exposes the
**exact same HTTP contract** (same paths, operation IDs, and JSON schemas) so it
can be driven by the same OpenAPI document and the same `slsbench` flow files
as the Spring and Quarkus benchmark targets.

- **Framework**: [chi](https://github.com/go-chi/chi) router, [GORM](https://gorm.io/) ORM
- **Persistence**: PostgreSQL 14 (schema and seed data copied from Spring's
  `db/postgres/{schema,data}.sql`)
- **Base path**: `/petclinic/api` on port `9966` (identical to the Spring image,
  so the upstream Spring `openapi.yml` can be reused without edits)

## Layout

```
cmd/server/main.go         entrypoint
internal/config/           env parsing (PORT, API_BASE, DATABASE_URL)
internal/api/              chi router wiring
internal/api/handlers/     one file per resource (owners, pets, vets, ...)
internal/httpx/            shared JSON / ProblemDetail / ETag helpers
internal/models/           GORM entities + LocalDate wrapper
internal/store/            Open + Migrate + Seed (embedded SQL scripts)
db/                        Postgres schema.sql and data.sql
resources/openapi.yml      verbatim copy of the Spring OpenAPI spec
Dockerfile                 multi-stage build -> distroless image
```

## Environment

| Variable       | Default                                                                 | Purpose                     |
| -------------- | ----------------------------------------------------------------------- | --------------------------- |
| `PORT`         | `9966`                                                                  | HTTP listen port            |
| `API_BASE`     | `/petclinic/api`                                                        | Path prefix for all routes  |
| `DATABASE_URL` | `postgres://developer:developer@localhost:5432/mydb?sslmode=disable`    | GORM Postgres DSN           |

## Build and run locally

```
go mod tidy
go build ./...
# starts on :9966, expects a postgres reachable at DATABASE_URL
./cmd/server/server
```

## Build the Docker image

```
docker build -t go-petclinic:dev .
```

## Run the full stack via the evaluation compose file

```
docker compose -f ../../evaluation/docker/go-bench.yml up -d
curl -s http://localhost:9966/petclinic/api/owners | jq length   # -> 10
```

## Evaluation integration

This service is wired into the existing evaluation matrix as app `go`. It
reuses the Spring scenario flows verbatim because both services publish the
same operation IDs:

- `evaluation/flows/go/{read-heavy,mixed,lifecycle}.yaml` (copies of `flows/spring/*`)
- `evaluation/docker/go-bench.yml` (app + postgres on the shared `bench` network)
- `evaluation/config.env` exposes `GO_SERVICE_NAME`, `GO_PORT`, `GO_IMAGE`,
  `GO_API_BASE`, `GO_COMPOSE`, `GO_OPENAPI`
- `scripts/run-probe-all.sh`, `run-slsbench.sh`, `run-wrk2.sh`,
  `cold-start-probe.sh`, `run-all.sh`, and `wrk2-baseline/run-baseline.sh` all
  recognise `go` as an app value

Run a single slice:

```
cd ../../evaluation
./scripts/run-probe-all.sh --apps go --scenarios read-heavy
RATES=100 ./scripts/run-all.sh --apps go --scenarios read-heavy --phases steady --reps 1
```

## Contract notes

- Authentication is intentionally not enforced; Spring's benchmark image also
  runs with `DisableSecurityConfig`. The `POST /users` endpoint exists for
  OpenAPI parity but does not gate any other route.
- GET responses include a weak `ETag` (`W/"<md5>"`) for contract parity. The
  service does not implement `If-None-Match` negotiation; flows do not rely on
  `304` behaviour.
- `GET /oops` (operationId `failingRequest`) returns `200 text/plain` as a
  stable terminal node for benchmark chains, matching the Spring spec.
- `PUT`/`DELETE` endpoints return `200` with a body rather than `204`; both
  are allowed by the OpenAPI responses.
