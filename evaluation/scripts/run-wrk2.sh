#!/usr/bin/env bash
# Run a wrk2 baseline benchmark for a single (app, scenario, phase, run) combination.
# Thin wrapper that delegates to wrk2-baseline/run-baseline.sh after ensuring
# the app is running and the wrk2 image is built.
#
# Usage: ./run-wrk2.sh <app> <scenario> <phase> <run_number>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$EVAL_DIR/config.env"

APP="${1:?Usage: $0 <app> <scenario> <phase> <run_number>}"
SCENARIO="${2:?}"
PHASE="${3:?}"
RUN="${4:?}"

# Ensure wrk2 image exists
if ! docker image inspect "$WRK2_IMAGE" > /dev/null 2>&1; then
    echo "Building wrk2 Docker image ($WRK2_IMAGE)..."
    docker build -t "$WRK2_IMAGE" -f "$EVAL_DIR/docker/wrk2.Dockerfile" "$EVAL_DIR/docker"
fi

# Resolve compose file
case "$APP" in
    spring)      COMPOSE_FILE="$EVAL_DIR/$SPRING_COMPOSE" ;;
    quarkus)     COMPOSE_FILE="$EVAL_DIR/$QUARKUS_COMPOSE" ;;
    quarkus-jvm) COMPOSE_FILE="$EVAL_DIR/$QUARKUS_JVM_COMPOSE" ;;
    *)
        echo "Unknown app: $APP" >&2
        exit 1
        ;;
esac

# For steady-state, ensure app is running before handing off
if [ "$PHASE" = "steady" ]; then
    docker compose -f "$COMPOSE_FILE" up -d
    echo "Waiting for app readiness..."
    sleep 10
fi

exec "$EVAL_DIR/wrk2-baseline/run-baseline.sh" "$APP" "$SCENARIO" "$PHASE" "$RUN"
