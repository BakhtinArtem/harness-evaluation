# `harness-evaluation`

Release-oriented evaluation artifact for the thesis experiments comparing scenario-based benchmarking with `slsbench` against microbenchmark-style load testing with `wrk2`.

## Overview

This repository contains everything needed to understand, rerun, analyze, and package the thesis evaluation around the Petclinic benchmark applications. It is organized around three main concerns:

- `benchmark-app/`: benchmarked applications and their OpenAPI specifications.
- `evaluation/`: scripts, flows, configs, analysis notebook, and measured results.
- `../serverless-benchmarking`: the `slsbench` implementation used by the evaluation workflow.

The evaluation is built around a two-phase scenario-based workflow:

1. generate reusable replay artifacts once with `slsbench probe-bodies`,
2. replay them under measurement-oriented load with `slsbench harness`.

Alongside that workflow, the repository also contains a `wrk2` baseline path for comparison.

## Repository Layout

```text
harness-evaluation/
├── README.md
├── benchmark-app/
│   ├── spring-petclinic-rest/
│   └── quarkus-petclinic/
└── evaluation/
    ├── README.md
    ├── REPRODUCIBILITY.md
    ├── config.env
    ├── docker/
    ├── flows/
    ├── scripts/
    ├── wrk2-baseline/
    ├── analysis/
    │   ├── evaluation.ipynb
    │   ├── evaluation-chapter.md
    │   └── slsbench-architecture-chapter.md
    └── results/   # gitignored, optional in release bundles
```

## Read This First

- Start with `evaluation/README.md` if you want to rerun benchmarks.
- Start with `evaluation/REPRODUCIBILITY.md` if you already have measured data and want to package or reuse it.
- Start with `evaluation/analysis/evaluation.ipynb` if you want to regenerate tables and figures from an existing dataset.
- Read `evaluation/analysis/evaluation-chapter.md` and `evaluation/analysis/slsbench-architecture-chapter.md` if you want the thesis-oriented narrative behind the measurements and tooling.

## Quick Start Paths

### Full benchmark rerun

Use this when you want to regenerate the dataset from scratch.

```bash
cd harness-evaluation/evaluation
./scripts/run-all.sh
```

This path expects:

- Docker and Docker Compose,
- benchmark application images or local builds,
- an `slsbench` image available under the name configured in `evaluation/config.env`.

### Analysis only

Use this when you already have `evaluation/results/` populated.

```bash
cd harness-evaluation/evaluation/analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
jupyter notebook evaluation.ipynb
```

The notebook expects results at `../results` relative to `analysis/`.

### Share measured data

Use this when you want to publish or hand off the measured dataset without asking someone else to rerun the benchmarks.

See `evaluation/REPRODUCIBILITY.md` for:

- source-only vs replication-data release modes,
- archive layout,
- zip/tar commands,
- minimum metadata to record with the dataset.

## Release Artifact Contents

Two release modes are supported by the documentation:

- `source-only`: repository code, flows, scripts, notebook, docs, but no `evaluation/results/`.
- `replication-data`: source plus an archived `evaluation/results/` dataset for analysis-only reproduction.

By default, the repository only contains the source-oriented release contents. The measured dataset is excluded from git by `.gitignore`.

## Pinned Docker Image Versions

All Docker images used by the evaluation are pinned to explicit version tags for reproducibility:

| Component | Image | Tag |
|---|---|---|
| Spring Petclinic REST | `aape2k/spring-petclinic-rest` | `v1.0.0` |
| Quarkus Petclinic (native) | `aape2k/quarkus-petclinic` | `v1.0.0` |
| Quarkus Petclinic (JVM) | `aape2k/quarkus-petclinic-jvm` | `v1.0.0` |
| slsbench (DooD) | `aape2k/slsbench` | `v3.0.0` |
| wrk2 | `eval-wrk2` | `latest` (built locally) |

Pull the pre-built images before running the evaluation:

```bash
docker pull aape2k/spring-petclinic-rest:v1.0.0
docker pull aape2k/quarkus-petclinic:v1.0.0
docker pull aape2k/quarkus-petclinic-jvm:v1.0.0
docker pull aape2k/slsbench:v3.0.0
```

The `eval-wrk2` image is built automatically by the runner scripts from `evaluation/docker/wrk2.Dockerfile` if it does not already exist locally.

## Dependencies and Related Repositories

This repository depends on the `slsbench` project ([serverless-benchmarking](https://github.com/BakhtinArtem/serverless-benchmarking)):

- Published image: `aape2k/slsbench:v3.0.0` (configured in `evaluation/config.env`)
- Source repository: `../serverless-benchmarking` (sibling checkout, only needed for development)

The benchmark application sources are included locally under `benchmark-app/`, including:

- Spring Petclinic REST,
- Quarkus Petclinic, used for both native and JVM evaluation variants.

## Recommended Release Contents

For a release intended to reproduce thesis figures without rerunning the benchmark suite, include:

- this repository,
- `evaluation/results/`,
- the committed `evaluation/config.env`,
- optional generated `analysis/chart_*.pdf` outputs.

For a lightweight release intended only for rerunning from source, omit `evaluation/results/` and clearly state that the dataset must be generated locally.
