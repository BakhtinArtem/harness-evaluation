# Reproducibility and Dataset Packaging

This document explains how to rerun the evaluation, how to reuse an existing measured dataset, and how to package `evaluation/results/` for release.

## What Is in Git and What Is Not

By default, the repository includes:

- benchmark scripts,
- flow definitions,
- Docker/Compose files,
- analysis notebook and thesis-oriented chapter drafts,
- benchmark application source trees.

By default, the repository does **not** include:

- `evaluation/results/`

This is intentional. The results tree is large and is ignored by `.gitignore`, so a source checkout alone is a `source-only` artifact, not a `replication-data` artifact.

## Release Modes

### `source-only`

Use this mode when recipients are expected to rerun the benchmarks themselves.

Include:

- repository source,
- `evaluation/README.md`,
- this document,
- `evaluation/config.env`,
- `evaluation/analysis/evaluation.ipynb`.

Do not include:

- `evaluation/results/`

### `replication-data`

Use this mode when recipients should be able to regenerate notebook outputs and thesis figures without rerunning the benchmark suite.

Include:

- everything from `source-only`,
- archived `evaluation/results/`,
- optionally generated `analysis/chart_*.pdf` files,
- a small manifest describing software versions and the exact configuration used.

## Where the Measured Data Lives

The benchmark outputs live under:

```text
evaluation/results/
```

The notebook expects the following relative path:

```python
RESULTS_ROOT = Path("../results")
```

That means the safest archive layout preserves the repository structure so that:

- `evaluation/analysis/evaluation.ipynb`
- and `evaluation/results/`

stay siblings under the same `evaluation/` directory.

## Expected Results Layout

All runs are stored under:

```text
results/<app>/<treatment>/<scenario>/<phase>/R<rate>/run-<N>/
```

Typical `wrk2` outputs:

- `wrk2_output.log`
- `container-stats.jsonl`
- `first_response.json` for cold-phase runs

Typical `slsbench` outputs:

- `harness.log`
- `flow.yaml`
- `harness-result-<timestamp>/first_request_result.json`
- `harness-result-<timestamp>/benchmark-container-stats.jsonl`
- `harness-result-<timestamp>/wrk2-input/...`
- `harness-result-<timestamp>/wrk2-results/...`

Probe caches are stored separately and are reusable across rates, phases, and repetitions:

```text
results/<flow_app>/slsbench/<scenario>/probe-bodies/probe-bodies-result-<timestamp>/
```

## Recommended Dataset Bundle Contents

For a high-fidelity release bundle, include:

- the full `evaluation/results/` tree,
- probe caches under `results/*/slsbench/*/probe-bodies/`,
- raw replay logs and stats,
- `evaluation/config.env`,
- optionally generated analysis PDFs from `evaluation/analysis/`.

For a reduced bundle intended only for notebook reproduction, you may choose to omit some bulky intermediate artifacts, but do so carefully. The main space cost often comes from:

- `wrk2-input/**/iteration-*.json`

If you create a reduced bundle, document exactly what was removed and verify that the notebook still runs successfully on the reduced dataset.

## Pinned Image Versions (v1.0.0)

All Docker images are pinned in `config.env` and the compose files:

| Component | Image | Tag |
|---|---|---|
| Spring Petclinic REST | `aape2k/spring-petclinic-rest` | `v1.0.0` |
| Quarkus Petclinic (native) | `aape2k/quarkus-petclinic` | `v1.0.0` |
| Quarkus Petclinic (JVM) | `aape2k/quarkus-petclinic-jvm` | `v1.0.0` |
| slsbench (DooD) | `aape2k/slsbench` | `v3.0.0` |
| wrk2 | `eval-wrk2` | `latest` (built locally from `docker/wrk2.Dockerfile`) |

Pull all pre-built images:

```bash
docker pull aape2k/spring-petclinic-rest:v1.0.0
docker pull aape2k/quarkus-petclinic:v1.0.0
docker pull aape2k/quarkus-petclinic-jvm:v1.0.0
docker pull aape2k/slsbench:v3.0.0
```

## Record These Versions with Any Published Dataset

When publishing or sharing a measured dataset, record:

- host OS,
- Docker version,
- Docker Compose version,
- the exact `config.env` used,
- the `slsbench` image version (`aape2k/slsbench:v3.0.0`),
- benchmark application image tags (`v1.0.0` for all three Petclinic variants),
- date of execution,
- whether the dataset is full or reduced.

## How to Package the Dataset

The archive should preserve the `harness-evaluation/` directory structure.

### Create a `.tar.gz` bundle

Run this from the parent directory that contains `harness-evaluation/`:

```bash
tar -czf harness-evaluation-replication-data.tar.gz harness-evaluation
```

### Create a `.zip` bundle

Run this from the parent directory that contains `harness-evaluation/`:

```bash
zip -r harness-evaluation-replication-data.zip harness-evaluation
```

If you want to package only the evaluation subtree:

```bash
tar -czf harness-evaluation-evaluation-only.tar.gz \
  harness-evaluation/evaluation \
  harness-evaluation/benchmark-app
```

That narrower bundle is acceptable only if the included docs still explain the missing sibling repository dependency on `serverless-benchmarking`.

## Analysis-Only Reproduction

If you already have a populated `evaluation/results/` tree:

```bash
cd harness-evaluation/evaluation/analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
jupyter notebook evaluation.ipynb
```

The notebook will auto-discover runs under `../results` and write generated PDFs such as:

- `chart_a1_violin.pdf`
- `chart_a2_saturation.pdf`
- `chart_a3_cdf.pdf`
- `chart_b1_cold_penalty.pdf`
- `chart_b2_first_response.pdf`
- `chart_c1_scenario_sensitivity.pdf`
- `chart_d3_framework_comparison.pdf`

## Full Rerun Reproduction

If you want to regenerate the dataset from scratch:

```bash
cd harness-evaluation/evaluation
./scripts/run-all.sh
```

That script will:

1. ensure the `wrk2` image exists,
2. pre-generate reusable probe artifacts with `scripts/run-probe-all.sh`,
3. execute both `wrk2` and `slsbench` treatments across the requested matrix.

## Suggested Manifest for Released Datasets

It is strongly recommended to include a small text or JSON manifest alongside any published results archive, for example:

```text
dataset-name: harness-evaluation-replication-data
dataset-type: full | reduced
generated-at: 2026-04-14T12:00:00Z
docker-version: ...
docker-compose-version: ...
harness-evaluation-version: v1.0.0
slsbench-image: aape2k/slsbench:v3.0.0
spring-petclinic-image: aape2k/spring-petclinic-rest:v1.0.0
quarkus-native-image: aape2k/quarkus-petclinic:v1.0.0
quarkus-jvm-image: aape2k/quarkus-petclinic-jvm:v1.0.0
config-env: evaluation/config.env
notes: ...
```

This small addition makes later thesis review and third-party reproduction much easier.
