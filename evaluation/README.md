# Evaluation: slsbench vs wrk2

Comparative evaluation of **scenario-based benchmarking** (slsbench) against **traditional microbenchmark-style load testing** (wrk2) across JVM-based Petclinic implementations.

## Thesis Context

> Meaningful performance evaluation of serverless applications requires benchmarks that reflect realistic usage patterns rather than isolated micro-level measurements.

This evaluation answers: **does deriving workload scenarios from OpenAPI specifications produce richer, more actionable performance insights than hitting individual endpoints with wrk2?**

## Experiment Design

### Independent Variables

| Variable   | Levels                          |
|------------|---------------------------------|
| Treatment  | slsbench (scenario-based), wrk2 (microbenchmark) |
| Framework  | Spring Boot, Quarkus Native, Quarkus JVM |
| Phase      | Cold start, Steady state        |
| Scenario   | Read-heavy, Mixed CRUD, Lifecycle |
| Rate       | 50, 200, 500, 1000 req/s        |

Full matrix: 2 treatments x 3 frameworks x 2 phases x 3 scenarios x 4 rates = **144 configurations**, each repeated 3 times = **432 runs**.

### Controlled Variables

- Same host machine for all experiments
- Same Docker resource constraints
- Same wrk2 thread/connection settings (2 threads, 5 connections)
- Same measurement durations (30s steady, 15s cold)
- Applications use default Petclinic seed data

### Dependent Variables (Metrics)

| Metric | wrk2 source | slsbench source |
|--------|-------------|-----------------|
| p50/p95/p99 latency | `--latency` HdrHistogram | `flow_stats_*.json` per-step + `wrk_output_*.log` |
| Throughput (req/s) | wrk2 summary | wrk2 summary in `wrk_output_*.log` |
| Error rate (non-2xx %) | wrk2 Non-2xx line | `flow_stats` summary `responses_non2xx` |
| First response time | `cold-start-probe.sh` | `first_request_result.json` |
| CPU / memory | `docker-stats-collector.sh` | `benchmark-container-stats.jsonl` |

## Directory Structure

```
evaluation/
├── README.md                        # This file
├── config.env                       # Shared parameters
├── docker/
│   ├── wrk2.Dockerfile              # Vanilla wrk2 image
│   ├── spring-bench.yml             # Spring Petclinic compose
│   ├── quarkus-bench.yml            # Quarkus Native compose
│   └── quarkus-jvm-bench.yml        # Quarkus JVM compose
├── flows/
│   ├── spring/
│   │   ├── read-heavy.yaml          # slsbench flow: create-then-read chains
│   │   ├── mixed.yaml               # slsbench flow: full CRUD lifecycle chains
│   │   └── lifecycle.yaml           # slsbench flow: deep entity-dependency chain
│   └── quarkus/
│       ├── read-heavy.yaml          # slsbench flow (Quarkus operationIds)
│       ├── mixed.yaml               # slsbench flow (Quarkus operationIds)
│       └── lifecycle.yaml           # slsbench flow: deep chain (Quarkus operationIds)
├── wrk2-baseline/
│   ├── lua/
│   │   ├── read-list.lua            # Round-robin GET across list endpoints
│   │   ├── post-create.lua          # POST /owners with varying payloads
│   │   ├── mixed-crud.lua           # Interleaved GET/POST/PUT/DELETE
│   │   └── single-endpoint.lua      # Single GET /owners (purest microbenchmark)
│   └── run-baseline.sh              # wrk2 baseline runner
├── scripts/
│   ├── run-all.sh                   # Full matrix runner
│   ├── run-slsbench.sh              # Single slsbench experiment
│   ├── run-wrk2.sh                  # Single wrk2 experiment
│   ├── cold-start-probe.sh          # First-response-time measurement
│   └── docker-stats-collector.sh    # Container stats JSONL collector
├── tests/
│   └── first/
│       └── README.md                # Hypothesis-driven test plan (TP1-TP6)
└── results/                         # Output (git-ignored)
```

## Prerequisites

1. **Docker and Docker Compose** (v2 plugin)
2. **slsbench DooD image**: build from the serverless-benchmarking repo:
   ```bash
   cd /path/to/serverless-benchmarking
   docker build -t slsbench:dood .
   ```
3. **wrk2 image**: built automatically on first run, or manually:
   ```bash
   docker build -t eval-wrk2:latest -f evaluation/docker/wrk2.Dockerfile evaluation/docker/
   ```
4. **Application images** pulled or built:
   - `aape2k/spring-petclinic-rest` (Docker Hub)
   - `aape2k/quarkus-petclinic` -- Quarkus Native (Docker Hub)
   - `aape2k/quarkus-petclinic-jvm` -- Quarkus JVM (build from `benchmark-app/quarkus-petclinic` with `Dockerfile.jvm`)

## Quick Start

### Run the full experiment matrix

```bash
cd evaluation
./scripts/run-all.sh
```

### Run a subset

```bash
# Only Spring, lifecycle scenario, steady-state, 1 repetition
./scripts/run-all.sh --apps spring --scenarios lifecycle --phases steady --reps 1

# Compare Quarkus Native vs JVM on cold start
./scripts/run-all.sh --apps quarkus,quarkus-jvm --scenarios lifecycle --phases cold --reps 3
```

### Run a single experiment

```bash
# slsbench lifecycle on Spring, steady state
./scripts/run-slsbench.sh spring lifecycle steady 1

# wrk2 single-endpoint on Quarkus (purest microbenchmark contrast)
./scripts/run-wrk2.sh quarkus single-endpoint steady 1
```

### Measure cold-start time only

```bash
./scripts/cold-start-probe.sh spring
./scripts/cold-start-probe.sh quarkus
./scripts/cold-start-probe.sh quarkus-jvm
```

## Results Layout

```
results/<app>/<treatment>/<scenario>/<phase>/R<rate>/run-<N>/
```

### wrk2 results contain

| File | Description |
|------|-------------|
| `wrk2_output.log` | Full wrk2 output with HdrHistogram latency distribution |
| `container-stats.jsonl` | Docker container CPU/memory snapshots |
| `first_response.json` | Cold-start first-response measurement (cold phase only) |

### slsbench results contain

| File | Description |
|------|-------------|
| `first_request_result.json` | Time to first successful response |
| `benchmark-container-stats.jsonl` | Streaming container resource usage |
| `wrk2-results/<stage>/flow_stats_*.json` | Per-step counts, latencies, status codes |
| `wrk2-results/<stage>/wrk_output_*.log` | Raw wrk2 latency distribution |
| `wrk2-input/<stage>/iteration-*.json` | Request templates used |
| `probe-bodies.log` | Probe generation log |
| `harness.log` | Harness execution log |
| `flow.yaml` | Actual flow file used (with substituted rate) |

## Configuration

All parameters are in `config.env`. Key settings:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `REPETITIONS` | 3 | Runs per configuration |
| `RATES` | 50 200 500 1000 | Request rates for load sweep |
| `DURATION_STEADY` | 30s | Benchmark duration (steady state) |
| `DURATION_COLD` | 15s | Benchmark duration (cold start) |
| `WARMUP_DURATION` | 10s | Warm-up before steady-state measurement |
| `WRK2_THREADS` | 2 | wrk2 thread count |
| `WRK2_CONNECTIONS` | 5 | wrk2 connection count |

## Scenario Design

### Read-heavy

Entry point: `addOwner` (creates one entity to seed IDs).
Branches: 40% `getOwner`, 25% create+read pet, 20% create+read vet, 15% create+read petType.
All chains terminate on a GET operation. Models a browsing-dominant usage pattern.

### Mixed CRUD

Entry point: `addOwner`.
Equal-weight (20% each) branches to full create-get-update-delete chains for:
owners, pet types, specialties, vets, and pets.
Models a management/admin usage pattern with complete entity lifecycles.

### Lifecycle (bottleneck detection)

Entry point: `addOwner`.
Deep entity-dependency chain: addOwner -> addPetToOwner -> addVisit (cascading writes),
plus parallel branches to listPets (expensive join) and listVets/getVet (cheap reads).
Designed to maximize per-step latency variance so slsbench's `flow_stats` reveals
which operation is the actual bottleneck. wrk2 baseline uses `mixed-crud.lua` for this
scenario, which can only report aggregate latency.

### OperationId Mapping

Both apps implement the same domain but with slightly different operation names:

| Operation | Spring | Quarkus |
|-----------|--------|---------|
| Get pet by ID | `getOwnersPet` | `getPet` |
| Update pet | `updateOwnersPet` | `updatePet` |
| Add visit | `addVisitToOwner` | `addVisitToOwnerPet` |
| List owner's pets | `listPets` | `listOwnerPets` |
| List pet's visits | `listVisits` | `listPetVisits` |

The flow files in `flows/spring/` and `flows/quarkus/` account for these differences.
`quarkus-jvm` reuses the `quarkus` flow files (same API, different runtime).

## Testing Points

See `tests/first/README.md` for the full hypothesis-driven test plan with commands,
expected outputs, confirmation criteria, and thesis table/chart structures.

### TP1: Per-Operation Insight Depth

Run `lifecycle` at R=500 steady-state. slsbench `flow_stats` reveals per-operation
latencies (e.g. listPets 29ms vs getVet 0.1ms -- a 290x spread). wrk2 reports a
single blended average (~5ms) that masks this variance. The aggregate is misleading:
a developer would miss the listPets bottleneck entirely.

### TP2: Execution Phase Granularity

Run `mixed` cold vs steady. slsbench shows cold-start penalty is non-uniform:
write operations (addOwner) suffer ~100x while read operations (getVet) suffer ~5x.
wrk2 shows one aggregate cold penalty (~10x) with no per-operation breakdown, hiding
which operations to optimize for cold-start scenarios.

### TP3: Stateful Data Validity Under Load

Run `mixed` at R=500 steady. Compare non-2xx error rates: wrk2's hardcoded IDs in
`mixed-crud.lua` produce 4xx errors from stale state, while slsbench's stateful chains
use freshly created IDs per iteration. This is not just "less insight" -- it is wrong
data. Latency measurements including error responses measure error-handling paths, not
application performance.

### TP4: Scenario Shape Sensitivity

Run all three scenarios on the same app at the same rate. slsbench reveals distinct
per-operation signatures per scenario (read-heavy is fast, mixed has slow deletes,
lifecycle shows cascading write latency). wrk2's Lua scripts produce similar aggregate
numbers because they lack dependency chains, flattening the differences that
scenario-aware tooling captures.

### TP5: Cross-Framework Decision Quality

Run `lifecycle` on Spring vs Quarkus vs Quarkus JVM (steady + cold). wrk2 says
"Quarkus is 20% faster." slsbench shows "Quarkus is faster for reads, Spring is
faster for write chains" -- the recommendation depends on the workload type.
Scenario-based data doesn't just give more data; it gives different answers to the
framework selection question.

### TP6: Per-Operation Saturation Detection

Load sweep (50, 200, 500, 1000 R/s) on `lifecycle`. wrk2 shows a smooth aggregate
throughput plateau. slsbench shows `listPets` p99 spiking at R=500 while `getVet`
stays flat through R=1000, identifying exactly which operation to optimize to
increase overall capacity.

## What This Demonstrates

### wrk2 (microbenchmark) limitations

- Aggregate metrics mask per-operation variance by up to 290x (TP1)
- Single cold-start penalty number hides non-uniform recovery across operations (TP2)
- Hardcoded IDs produce invalid measurements under concurrent load -- wrong data, not just less data (TP3)
- Different Lua scripts produce similar aggregate latencies, unable to distinguish scenario shapes (TP4)
- Single "X is faster" verdict misses operation-level trade-offs that change the recommendation (TP5)
- Smooth throughput plateau hides per-operation saturation points (TP6)

### slsbench (scenario-based) advantages

- OpenAPI-driven flows traverse realistic multi-step operation chains with per-step metrics
- Stateful body generation via Schemathesis ensures valid request payloads across transitions, eliminating artificial errors (TP3)
- Per-step latency breakdown reveals hidden bottlenecks (TP1) and non-uniform cold penalties (TP2)
- Distinct performance signatures per scenario validate that usage patterns matter (TP4)
- Per-operation framework comparisons enable workload-dependent recommendations (TP5)
- Per-operation load curves reveal individual saturation points invisible to aggregate throughput (TP6)

## Threats to Validity

- Results are limited to JVM-based implementations and the Petclinic domain
- Spring uses H2 (in-memory DB); Quarkus uses PostgreSQL -- this is deliberate (each framework's typical config) but affects absolute numbers
- Quarkus JVM Dockerfile uses Java 11; Spring uses Java 21 -- control for this in analysis
- Cross-language generalization is future work
- Network effects are minimized by using `--network=host` but not eliminated
