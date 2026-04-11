# Test Plan: Hypothesis-Driven Evaluation

Goal: demonstrate, through falsifiable hypotheses, that scenario-based benchmarking
derived from OpenAPI specifications produces richer and more actionable performance
insights than traditional microbenchmark-style load testing with wrk2.

Scope: JVM ecosystem only (Spring Boot, Quarkus Native, Quarkus JVM). Petclinic domain.

---

## TP1: Per-Operation Insight Depth

**Hypothesis:** OpenAPI-derived scenario benchmarks reveal per-operation performance
characteristics that aggregate microbenchmarks mask, making the aggregate misleading.

### Run

```bash
# slsbench -- lifecycle flow captures per-step latencies
./scripts/run-slsbench.sh spring lifecycle steady 1
./scripts/run-slsbench.sh quarkus lifecycle steady 1

# wrk2 -- single-endpoint: purest microbenchmark
./scripts/run-wrk2.sh spring single-endpoint steady 1
./scripts/run-wrk2.sh quarkus single-endpoint steady 1

# wrk2 -- mixed-crud: round-robins endpoints without state
./scripts/run-wrk2.sh spring lifecycle steady 1
./scripts/run-wrk2.sh quarkus lifecycle steady 1
```

### Compare results

| Source | File | What it tells you |
|--------|------|-------------------|
| slsbench | `flow_stats_*.json` -> `step_stats[].avg_us` | Per-operation latency: e.g. listPets 29ms, getVet 0.1ms |
| slsbench | `flow_stats_*.json` -> `step_status[]` | Per-operation success/failure rate |
| wrk2 | `wrk2_output.log` | Single aggregate: avg latency, p99, total non-2xx |

### Expected thesis output

Table: "Per-operation latency breakdown (lifecycle flow, R=500, steady state)"

| Operation | Avg latency (us) | % of total flow time |
|-----------|------------------|----------------------|
| addOwner | ... | ... |
| addPetToOwner | ... | ... |
| listPets | ... (expect highest) | ... |
| getVet | ... (expect lowest) | ... |

wrk2 reports a blended average of ~5ms. The aggregate is misleading because it hides
a ~290x variance between operations (listPets vs getVet). A developer relying on wrk2
would miss the listPets bottleneck entirely.

### Confirm or refute

Confirmed if slsbench per-step data reveals at least one operation with >10x latency
compared to the fastest operation in the same flow, while wrk2 reports a single number
that obscures this spread.

---

## TP2: Execution Phase Granularity

**Hypothesis:** Scenario-based benchmarking enables per-operation cold-start analysis,
revealing that cold-start penalty is not uniform across operations.

### Run

```bash
# slsbench -- cold vs steady on same flow
./scripts/run-slsbench.sh spring mixed cold 1
./scripts/run-slsbench.sh spring mixed steady 1
./scripts/run-slsbench.sh quarkus mixed cold 1
./scripts/run-slsbench.sh quarkus mixed steady 1

# wrk2 -- cold vs steady aggregate
./scripts/run-wrk2.sh spring mixed cold 1
./scripts/run-wrk2.sh spring mixed steady 1
./scripts/run-wrk2.sh quarkus mixed cold 1
./scripts/run-wrk2.sh quarkus mixed steady 1
```

### Compare results

| Source | Cold insight | Steady insight |
|--------|-------------|----------------|
| slsbench | `first_request_result.json` + per-step `flow_stats` during cold window | per-step `flow_stats` at warm regime |
| wrk2 | `first_response.json` + aggregate latency | aggregate latency |

### Expected thesis output

Chart: "Per-operation cold penalty ratio (cold avg / steady avg)"

| Operation | Cold avg (us) | Steady avg (us) | Cold penalty ratio |
|-----------|---------------|------------------|--------------------|
| addOwner | ... | ... | ~100x (first write, cold DB pool) |
| getVet | ... | ... | ~5x (read path warms faster) |
| deleteOwner | ... | ... | ... |

wrk2 shows one aggregate cold penalty (~10x) with no way to tell which operations
recover first. slsbench shows writes suffer far more than reads during cold start,
guiding optimization toward connection-pool warm-up rather than read caching.

### Confirm or refute

Confirmed if the cold penalty ratio varies by at least 5x across operations in the
same flow (e.g. write operations 50-100x vs read operations 5-10x), while wrk2
produces a single ratio that averages over this variance.

---

## TP3: Stateful Data Validity Under Load

**Hypothesis:** Scenario-based benchmarking produces higher measurement validity because
requests carry correct state (IDs derived from prior responses), while microbenchmarks
using hardcoded IDs generate artificial errors that corrupt the measurements.

### Run

```bash
# Both treatments on the mixed scenario at high load
./scripts/run-slsbench.sh spring mixed steady 1
./scripts/run-wrk2.sh spring mixed steady 1

./scripts/run-slsbench.sh quarkus mixed steady 1
./scripts/run-wrk2.sh quarkus mixed steady 1
```

### Compare results

| Source | File | Metric |
|--------|------|--------|
| slsbench | `flow_stats_*.json` -> `responses_non2xx` | Per-step non-2xx count (expect near 0) |
| wrk2 | `wrk2_output.log` -> `Non-2xx or Errors` | Aggregate non-2xx (expect elevated) |

### Expected thesis output

Table: "Data validity comparison (mixed scenario, R=500, steady state)"

| Treatment | Total requests | Non-2xx responses | Error rate (%) |
|-----------|---------------|-------------------|----------------|
| slsbench | ... | ... (near 0) | ~0% |
| wrk2 | ... | ... (elevated) | >0% |

wrk2's `mixed-crud.lua` uses `PUT /owners/1` and `GET /owners/1` with hardcoded ID 1.
Under concurrent load, other threads create entities at higher IDs, and the fixed ID
may refer to stale or deleted state. slsbench chains use freshly created IDs per
iteration, maintaining valid state across all steps.

This is not just "less insight" -- it is **wrong data**. Latency measurements that
include 4xx error responses are not measuring application performance; they are
measuring error-handling paths.

### Confirm or refute

Confirmed if wrk2 non-2xx rate exceeds 1% on the mixed scenario at R>=500, while
slsbench non-2xx rate stays below 0.5% on the same scenario and rate.

---

## TP4: Scenario Shape Sensitivity

**Hypothesis:** Different usage patterns (read-heavy, mixed CRUD, deep lifecycle)
produce meaningfully different performance profiles that scenario-based benchmarking
captures, while microbenchmarks flatten the differences.

### Run

```bash
# All three scenarios on the same app, same rate, same phase
./scripts/run-slsbench.sh spring read-heavy steady 1
./scripts/run-slsbench.sh spring mixed steady 1
./scripts/run-slsbench.sh spring lifecycle steady 1

./scripts/run-wrk2.sh spring read-heavy steady 1
./scripts/run-wrk2.sh spring mixed steady 1
./scripts/run-wrk2.sh spring lifecycle steady 1
```

### Compare results

| Source | read-heavy | mixed | lifecycle |
|--------|-----------|-------|-----------|
| slsbench | Low latency across board (mostly GETs) | Moderate, DELETE slowest | High variance, cascading writes + joins |
| wrk2 | Aggregate ~Xms | Aggregate ~Yms | Aggregate ~Zms |

### Expected thesis output

Heatmap: "Per-operation latency by scenario (Spring, R=500, steady state)"

Rows = operations (addOwner, getVet, listPets, deletePet, ...).
Columns = scenarios (read-heavy, mixed, lifecycle).
Cell values = avg latency from `flow_stats`.

wrk2's three Lua scripts (`read-list.lua`, `mixed-crud.lua`, `single-endpoint.lua`)
all produce similar aggregate latencies because they lack dependency chains. slsbench
shows clearly distinct performance signatures per scenario, validating the thesis premise
that different usage patterns reveal different performance truths.

### Confirm or refute

Confirmed if the coefficient of variation across slsbench per-operation latencies
differs by >50% between scenarios, while the wrk2 aggregate latency across its
corresponding Lua scripts differs by <20%.

---

## TP5: Cross-Framework Decision Quality

**Hypothesis:** Scenario-based benchmarking enables more nuanced framework selection
decisions than aggregate throughput comparisons, potentially changing the recommendation
depending on the workload type.

### Run

```bash
# lifecycle on Spring vs Quarkus Native vs Quarkus JVM, steady state
./scripts/run-slsbench.sh spring lifecycle steady 1
./scripts/run-slsbench.sh quarkus lifecycle steady 1
./scripts/run-slsbench.sh quarkus-jvm lifecycle steady 1

./scripts/run-wrk2.sh spring lifecycle steady 1
./scripts/run-wrk2.sh quarkus lifecycle steady 1
./scripts/run-wrk2.sh quarkus-jvm lifecycle steady 1

# Cold start comparison (Quarkus Native vs JVM)
./scripts/run-slsbench.sh quarkus lifecycle cold 1
./scripts/run-slsbench.sh quarkus-jvm lifecycle cold 1
./scripts/run-wrk2.sh quarkus lifecycle cold 1
./scripts/run-wrk2.sh quarkus-jvm lifecycle cold 1
```

### Compare results

| Source | What it reveals |
|--------|-----------------|
| slsbench (steady) | Per-step: "Quarkus faster for reads, Spring faster for write chains" |
| slsbench (cold) | `first_request_result.json`: native 0.5s vs JVM 5s; per-step cold penalties differ |
| slsbench | `benchmark-container-stats.jsonl`: CPU/memory per framework |
| wrk2 | Aggregate: "Quarkus is 20% faster" with no per-operation breakdown |

### Expected thesis output

Table: "Framework comparison -- per-operation latency (lifecycle, R=500, steady)"

| Operation | Spring (us) | Quarkus Native (us) | Quarkus JVM (us) |
|-----------|-------------|---------------------|-------------------|
| addOwner | ... | ... | ... |
| addPetToOwner | ... | ... | ... |
| listPets | ... | ... | ... |
| getVet | ... | ... | ... |

Table: "Cold-start first-response time by runtime"

| Runtime | First response (ms) | Attempts |
|---------|---------------------|----------|
| Quarkus Native | ... (~500) | ... |
| Quarkus JVM | ... (~5000) | ... |

wrk2 says "pick Quarkus, it's 20% faster." slsbench shows "Quarkus is faster for reads
but Spring is faster for write-heavy chains" -- the recommendation depends on the
workload type. This is the strongest thesis contribution: scenario-based data doesn't
just give more data, it gives different answers to the framework selection question.

### Confirm or refute

Confirmed if there exists at least one operation category (reads vs writes) where the
faster framework flips between Spring and Quarkus, making a blanket "X is faster"
statement from wrk2 incomplete or misleading.

---

## TP6: Per-Operation Saturation Detection

**Hypothesis:** Under increasing load, individual operations saturate at different rates;
scenario-based benchmarking reveals these per-operation saturation points while aggregate
throughput curves miss them.

### Run

```bash
# Load sweep on lifecycle -- all four rates run automatically
./scripts/run-slsbench.sh spring lifecycle steady 1
./scripts/run-wrk2.sh spring lifecycle steady 1

./scripts/run-slsbench.sh quarkus lifecycle steady 1
./scripts/run-wrk2.sh quarkus lifecycle steady 1
```

(Each run iterates over RATES="50 200 500 1000" from config.env.)

### Compare results

| Source | File | What it reveals |
|--------|------|-----------------|
| slsbench | `flow_stats_*.json` per rate | Per-operation p99 at each rate level |
| wrk2 | `wrk2_output.log` per rate | Single aggregate p99 at each rate level |

### Expected thesis output

Line chart: "Per-operation p99 latency vs request rate (lifecycle, Spring, steady)"

X-axis: rate (50, 200, 500, 1000).
Lines: one per operation (addOwner, listPets, getVet, ...).

wrk2 produces one line (aggregate p99) showing a smooth plateau around R=800.
slsbench shows `listPets` p99 spiking at R=500 while `getVet` stays flat through
R=1000. This identifies exactly which operation to optimize to increase overall capacity.

### Confirm or refute

Confirmed if at least one operation's p99 latency increases by >3x between two
consecutive rate steps while another operation's p99 stays within 1.5x across the
same rate range, demonstrating per-operation saturation that the aggregate curve
cannot reveal.

---

## Full Matrix Command

Run everything with default settings (3 apps x 3 scenarios x 2 phases x 3 reps):

```bash
./scripts/run-all.sh
```

Or focused subsets matching individual TPs:

```bash
# TP1: Per-operation insight depth
./scripts/run-all.sh --apps spring,quarkus --scenarios lifecycle --phases steady --reps 1

# TP2: Execution phase granularity
./scripts/run-all.sh --apps spring,quarkus --scenarios mixed --phases cold,steady --reps 3

# TP3: Stateful data validity
./scripts/run-all.sh --apps spring,quarkus --scenarios mixed --phases steady --reps 3

# TP4: Scenario shape sensitivity
./scripts/run-all.sh --apps spring --scenarios read-heavy,mixed,lifecycle --phases steady --reps 1

# TP5: Cross-framework decision quality
./scripts/run-all.sh --apps spring,quarkus,quarkus-jvm --scenarios lifecycle --phases cold,steady --reps 3

# TP6: Per-operation saturation detection
./scripts/run-all.sh --apps spring,quarkus --scenarios lifecycle --phases steady --reps 3
```

## Threats to Validity

- Results are limited to JVM-based implementations and the Petclinic domain.
- Spring uses H2 (in-memory DB); Quarkus uses PostgreSQL -- this is deliberate (each
  framework's typical config) but affects absolute numbers. Relative comparisons across
  operations within the same app are unaffected.
- Quarkus JVM Dockerfile uses Java 11; Spring uses Java 21. Control for this in analysis.
- Cross-language generalization is future work.
- TP3 error rates depend on wrk2 Lua script design (hardcoded IDs). This is the
  realistic baseline: wrk2 has no mechanism for stateful chaining, so hardcoded IDs
  are the standard approach.
- TP4 scenario shapes are designed by the author, not derived from production traces.
  The point is that the tooling supports scenario differentiation, not that these
  specific scenarios match real-world traffic distributions.
