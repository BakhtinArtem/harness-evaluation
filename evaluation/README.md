# Evaluation: `slsbench` vs `wrk2`

Comparative evaluation of scenario-based benchmarking with `slsbench` against traditional microbenchmark-style load testing with `wrk2` across Petclinic implementations in multiple ecosystems (Spring Boot, Quarkus native, Quarkus JVM, and a Go port).

## Thesis Context

> Meaningful performance evaluation of serverless applications requires benchmarks that reflect realistic usage patterns rather than isolated micro-level measurements.

This evaluation asks whether deriving workload scenarios from OpenAPI specifications and replaying them as stateful chains produces richer, more actionable performance insight than hitting isolated endpoints or Lua-scripted baselines with `wrk2`.

## What This Directory Contains

This directory is the canonical execution and analysis guide for the evaluation.

It contains:

- benchmark configuration in `config.env`,
- Docker/Compose definitions for the evaluated applications,
- Flow DSL files used by `slsbench`,
- `wrk2` baseline scripts,
- orchestration scripts for the full experiment matrix,
- the analysis notebook and thesis-oriented Markdown chapter drafts,
- optional measured results under `results/` when a replication-data bundle is prepared.

The committed `config.env` is the authoritative source for experiment parameters. If prose in older notes or thesis drafts disagrees with `config.env`, treat `config.env` as correct.

## Directory Structure

```text
evaluation/
├── README.md
├── REPRODUCIBILITY.md
├── config.env
├── docker/
│   ├── wrk2.Dockerfile
│   ├── spring-bench.yml
│   ├── quarkus-bench.yml
│   ├── quarkus-jvm-bench.yml
│   └── go-bench.yml
├── flows/
│   ├── spring/
│   │   ├── read-heavy.yaml
│   │   ├── mixed.yaml
│   │   └── lifecycle.yaml
│   ├── quarkus/
│   │   ├── read-heavy.yaml
│   │   ├── mixed.yaml
│   │   └── lifecycle.yaml
│   └── go/
│       ├── read-heavy.yaml
│       ├── mixed.yaml
│       └── lifecycle.yaml
├── wrk2-baseline/
│   ├── lua/
│   │   ├── read-list.lua
│   │   ├── post-create.lua
│   │   ├── mixed-crud.lua
│   │   └── single-endpoint.lua
│   └── run-baseline.sh
├── scripts/
│   ├── run-all.sh
│   ├── run-probe-all.sh
│   ├── run-slsbench.sh
│   ├── run-wrk2.sh
│   ├── cold-start-probe.sh
│   └── docker-stats-collector.sh
├── analysis/
│   ├── evaluation.ipynb
│   ├── evaluation-chapter.md
│   ├── slsbench-architecture-chapter.md
│   ├── requirements.txt
│   └── chart_*.pdf                 # generated after running the notebook
└── results/                        # gitignored, optional in release bundles
```

## Experiment Design

### Independent Variables

| Variable | Levels |
|---|---|
| Treatment | `slsbench` (scenario-based), `wrk2` (microbenchmark-style) |
| Framework | Spring Boot, Quarkus Native, Quarkus JVM |
| Phase | Cold start, steady state |
| Scenario | Read-heavy, mixed CRUD, lifecycle |
| Rate | 50, 200, 500, 1000 req/s |

Not every testing point requires the full cross-product. Each TP uses a focused slice of the variable space; the union of all TPs yields the evaluation matrix discussed below.

### Controlled Variables

- Same host machine for all experiments
- Same Docker resource constraints
- Same wrk thread/connection settings: 2 threads, 5 connections
- Same measurement durations as defined in `config.env`
- Applications use default Petclinic seed data

### Dependent Variables

| Metric | `wrk2` source | `slsbench` source |
|---|---|---|
| p50/p95/p99 latency | `--latency` HdrHistogram | `flow_stats_*.json` plus raw wrk logs |
| Throughput (req/s) | wrk summary | wrk summary in stage output logs |
| Error rate (non-2xx) | wrk non-2xx line | `flow_stats` summaries and response histograms |
| First response time | `cold-start-probe.sh` output | `first_request_result.json` |
| CPU / memory | `container-stats.jsonl` | `benchmark-container-stats.jsonl` |

## Configuration

All shared parameters live in `config.env`.

Key defaults from the current committed file are:

| Parameter | Default | Description |
|---|---|---|
| `REPETITIONS` | 3 | Runs per configuration |
| `RATES` | `50 200 500 1000` | Request-rate sweep |
| `DURATION_STEADY` | `30s` | Steady-state replay duration |
| `DURATION_COLD` | `30s` | Cold-phase replay duration |
| `WARMUP_DURATION` | `10s` | Warm-up duration before steady runs |
| `WARMUP_RATE` | `100` | Warm-up replay rate |
| `WRK2_THREADS` | `2` | wrk thread count |
| `WRK2_CONNECTIONS` | `5` | wrk connection count |
| `SLSBENCH_IMAGE` | `aape2k/slsbench:v3.0.0` | Image used by `run-probe-all.sh` and `run-slsbench.sh` |

If you change `config.env`, you are changing the experiment. Record that file alongside any published dataset.

## Dependencies

### Required tools

1. Docker
2. Docker Compose v2 plugin
3. Python 3 with PyYAML (`pip install pyyaml`) for notebook setup and warmup-injection in scripts

### `slsbench`

The evaluation uses the published `slsbench` Docker image:

```bash
docker pull aape2k/slsbench:v3.0.0
```

This is configured in `config.env` as `SLSBENCH_IMAGE="aape2k/slsbench:v3.0.0"`.

Source repository: [serverless-benchmarking](https://github.com/BakhtinArtem/serverless-benchmarking) (only needed for development).

### Benchmark application images

All benchmark images for the active runtime matrix are pinned and published:

```bash
docker pull aape2k/spring-petclinic-rest:v2.0.0           # Spring Boot (JVM) + PostgreSQL
docker pull aape2k/quarkus-petclinic:v1.0.0               # Quarkus (GraalVM Native)
docker pull aape2k/quarkus-petclinic-jvm:v1.0.0           # Quarkus (JVM)
docker pull aape2k/go-petclinic:v1.0.0                    # Go + chi router + GORM
```

The Spring Boot JVM image was rebuilt at `v2.0.0` because the configuration
was switched from the original H2 in-memory database to a PostgreSQL sidecar
so that every evaluated system shares the same storage backend. The Go image
is a new addition for the extended runtime-class matrix.

A fifth runtime, **Spring Boot (GraalVM Native)**, is scaffolded but deferred
to a follow-up campaign. The build pipeline (`benchmark-app/spring-petclinic-rest/Dockerfile.native`),
the compose file (`docker/spring-native-bench.yml`), and the runner-script
branching are all in place, but the Spring Boot 4 + GraalVM CE native-image
analysis stage requires more RAM than the reference evaluation host can
reliably provide. To build and run `aape2k/spring-petclinic-rest-native:v1.0.0`
on a larger builder, see the notes in that Dockerfile and then re-run the
evaluation with `--apps spring-native`.

The application source trees also exist locally under `../benchmark-app/`, which is useful when rebuilding images or inspecting OpenAPI files.

## Rerun Workflows

### 1. Full rerun from scratch

Use this when you want to regenerate the full benchmark dataset.

```bash
cd evaluation
./scripts/run-all.sh
```

What happens:

1. the `wrk2` image is built if missing,
2. `scripts/run-probe-all.sh` generates probe caches once per unique flow,
3. `scripts/run-wrk2.sh` and `scripts/run-slsbench.sh` execute the matrix,
4. results are written under `results/`.

### 2. Pre-generate reusable probe artifacts only

Use this when you want to separate the slow `probe-bodies` step from later replay runs.

```bash
cd evaluation
./scripts/run-probe-all.sh
```

This script:

- generates probe caches once per unique `app + scenario` flow,
- stores them under `results/<flow_app>/slsbench/<scenario>/probe-bodies/`,
- allows later `slsbench harness` runs to reuse the same replay artifacts across rates, phases, and repetitions.

This is the recommended path before running large benchmark matrices.

### 3. Run one `slsbench` experiment

```bash
cd evaluation
./scripts/run-slsbench.sh spring lifecycle steady 1
```

This expects probe caches to exist already. If they do not, run `./scripts/run-probe-all.sh` first.

### 4. Run one `wrk2` baseline experiment

```bash
cd evaluation
./scripts/run-wrk2.sh quarkus single-endpoint steady 1
```

### 5. Analysis only with an existing results tree

```bash
cd evaluation/analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
jupyter notebook evaluation.ipynb
```

The notebook:

- expects `../results`,
- auto-discovers runs,
- emits generated PDFs such as `chart_a1_violin.pdf`, `chart_a2_saturation.pdf`, `chart_b1_cold_penalty.pdf`, and `chart_d3_framework_comparison.pdf`.

### 6. Cold-start probe only

```bash
cd evaluation
./scripts/cold-start-probe.sh spring
./scripts/cold-start-probe.sh quarkus
./scripts/cold-start-probe.sh quarkus-jvm
```

## Results Layout

All runs live under:

```text
results/<app>/<treatment>/<scenario>/<phase>/R<rate>/run-<N>/
```

### `wrk2` run contents

| File | Description |
|---|---|
| `wrk2_output.log` | Full wrk output with latency distribution |
| `container-stats.jsonl` | Docker container CPU/memory snapshots |
| `first_response.json` | Cold-phase first-response timing |

### `slsbench` run contents

At the run root:

| File | Description |
|---|---|
| `harness.log` | Full harness execution log |
| `flow.yaml` | Flow file used for the specific rate/phase/run |

Inside `harness-result-<timestamp>/`:

| File or directory | Description |
|---|---|
| `first_request_result.json` | Time to first successful response |
| `benchmark-container-stats.jsonl` | Streaming container resource usage |
| `wrk2-input/` | Stage-local replay inputs |
| `wrk2-results/` | Stage-local replay outputs |

Inside `wrk2-results/<stage>/`, typical outputs include:

| File | Description |
|---|---|
| `response_histogram.json` | Aggregated status-code distribution |
| `wrk_container.log` | Raw wrk container stdout/stderr |
| `exit_code.txt` | Container exit code |

Probe generation caches are stored separately under:

```text
results/<flow_app>/slsbench/<scenario>/probe-bodies/
```

## Analysis and Thesis Artifacts

The `analysis/` subtree contains:

- `evaluation.ipynb`: notebook that parses `results/` and regenerates charts/tables.
- `evaluation-chapter.md`: thesis-oriented evaluation chapter draft.
- `slsbench-architecture-chapter.md`: thesis-oriented architecture chapter draft for the tool itself.
- `requirements.txt`: Python dependencies for the notebook.
- `chart_*.pdf`: generated outputs after notebook execution.

These files are part of the release story even if `results/` is omitted, because they define how the published claims are reproduced from measured data.

## Scenario Design

### Read-heavy

Entry point: `addOwner` to seed IDs, then mostly read-dominant chains.

### Mixed CRUD

Entry point: `addOwner`, followed by balanced CRUD-style branches across owners, pet types, specialties, vets, and pets.

### Lifecycle

Entry point: `addOwner`, followed by deeper dependency chains intended to expose bottlenecks and maximize per-step latency variance.

### OperationId mapping

The Spring and Quarkus applications share the same domain but use slightly different operation names. The flow files in `flows/spring/` and `flows/quarkus/` capture those differences, while `quarkus-jvm` reuses the `quarkus` flow files. The `go` app is a Go port of `spring-petclinic-rest` with an identical OpenAPI contract, so `flows/go/` is a verbatim copy of `flows/spring/`.

## Testing Points

The detailed narrative now lives in:

- `analysis/evaluation.ipynb`
- `analysis/evaluation-chapter.md`

The practical purpose of the four testing points is:

- TP-A: per-operation characterization and saturation behavior
- TP-B: cold vs steady execution-phase granularity
- TP-C: scenario-shape sensitivity
- TP-D: framework and runtime decision quality

## Release and Packaging Notes

This repository supports two release modes:

- `source-only`: no `results/`, intended for users who will rerun the experiments.
- `replication-data`: source plus archived `results/`, intended for users who want to reproduce figures and tables without rerunning benchmarks.

See `REPRODUCIBILITY.md` for:

- how to zip or tar the dataset,
- which metadata to record,
- how to preserve the notebook path assumptions,
- what to include in a full versus reduced results bundle.

## Threats to Validity

- Results are limited to JVM-based implementations and the Petclinic domain.
- Spring and Quarkus use different persistence/runtime stacks, which affects absolute numbers.
- Cross-language generalization remains future work.
- The `wrk2` baseline depends on Lua-script design and therefore does not model stateful chaining as directly as `slsbench`.
- Scenario shapes are authored workloads, not production-trace reconstructions. The point is to test scenario sensitivity and scenario-based tooling, not to claim these exact distributions are universal.
