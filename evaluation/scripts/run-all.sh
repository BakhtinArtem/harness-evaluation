#!/usr/bin/env bash
# Full experiment matrix runner.
# Iterates: app x scenario x phase x repetition, running both treatments.
#
# Usage: ./run-all.sh [--apps spring,quarkus] [--scenarios read-heavy,mixed]
#                     [--phases cold,steady] [--reps 3] [--rates "200 500"]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$EVAL_DIR/config.env"

APPS="spring quarkus quarkus-jvm go"
SCENARIOS="read-heavy mixed lifecycle"
PHASES="cold steady"
REPS="$REPETITIONS"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apps)       APPS="${2//,/ }"; shift 2 ;;
        --scenarios)  SCENARIOS="${2//,/ }"; shift 2 ;;
        --phases)     PHASES="${2//,/ }"; shift 2 ;;
        --reps)       REPS="$2"; shift 2 ;;
        --rates)      RATES="${2//,/ }"; shift 2 ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--apps spring,quarkus] [--scenarios read-heavy,mixed] [--phases cold,steady] [--reps N] [--rates \"200 500\"]" >&2
            exit 1
            ;;
    esac
done

# Export RATES so child scripts (run-slsbench.sh, run-baseline.sh) pick up overrides
# instead of re-reading the default from config.env.
export RATES

# Ensure wrk2 image exists
if ! docker image inspect "$WRK2_IMAGE" > /dev/null 2>&1; then
    echo "Building wrk2 Docker image ($WRK2_IMAGE)..."
    docker build -t "$WRK2_IMAGE" -f "$EVAL_DIR/docker/wrk2.Dockerfile" "$EVAL_DIR/docker"
fi

# Pre-generate probe-bodies for all unique flows (once per app+scenario).
# This avoids re-running the slow probe step on every phase/rep/rate combination.
echo "============================================================"
echo "  Pre-generating probe-bodies for all flows..."
echo "============================================================"
"$SCRIPT_DIR/run-probe-all.sh" --apps "$(echo $APPS | tr ' ' ',')" --scenarios "$(echo $SCENARIOS | tr ' ' ',')"
echo ""

TOTAL=0
DONE=0

for APP in $APPS; do
    for SCENARIO in $SCENARIOS; do
        for PHASE in $PHASES; do
            TOTAL=$((TOTAL + REPS * 2))
        done
    done
done

echo "============================================================"
echo "  Evaluation Matrix: $TOTAL experiment runs"
echo "  Apps: $APPS"
echo "  Scenarios: $SCENARIOS"
echo "  Phases: $PHASES"
echo "  Repetitions: $REPS"
echo "  Rates: $RATES"
echo "============================================================"
echo ""

for APP in $APPS; do
    # Resolve compose file for teardown
    case "$APP" in
        spring)      COMPOSE_FILE="$EVAL_DIR/$SPRING_COMPOSE" ;;
        quarkus)     COMPOSE_FILE="$EVAL_DIR/$QUARKUS_COMPOSE" ;;
        quarkus-jvm) COMPOSE_FILE="$EVAL_DIR/$QUARKUS_JVM_COMPOSE" ;;
        go)          COMPOSE_FILE="$EVAL_DIR/$GO_COMPOSE" ;;
    esac

    for SCENARIO in $SCENARIOS; do
        for PHASE in $PHASES; do
            for REP in $(seq 1 "$REPS"); do

                # Treatment A: wrk2 baseline
                DONE=$((DONE + 1))
                echo "[$DONE/$TOTAL] wrk2  | $APP / $SCENARIO / $PHASE / run-$REP"
                "$SCRIPT_DIR/run-wrk2.sh" "$APP" "$SCENARIO" "$PHASE" "$REP"

                # Tear down between treatments
                docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
                sleep 3

                # Treatment B: slsbench (manages its own compose lifecycle)
                DONE=$((DONE + 1))
                echo "[$DONE/$TOTAL] slsbench | $APP / $SCENARIO / $PHASE / run-$REP"
                "$SCRIPT_DIR/run-slsbench.sh" "$APP" "$SCENARIO" "$PHASE" "$REP"

            done
        done
    done
done

echo ""
echo "============================================================"
echo "  All $TOTAL experiments complete."
echo "  Results: $EVAL_DIR/results/"
echo "============================================================"
