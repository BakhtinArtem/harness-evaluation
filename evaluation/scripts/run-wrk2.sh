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
    go)          COMPOSE_FILE="$EVAL_DIR/$GO_COMPOSE" ;;
    *)
        echo "Unknown app: $APP" >&2
        exit 1
        ;;
esac

# Resolve app port and readiness endpoint
case "$APP" in
    spring)      APP_PORT="$SPRING_PORT"; READINESS_URL="http://localhost:$SPRING_PORT$SPRING_API_BASE/owners" ;;
    quarkus)     APP_PORT="$QUARKUS_PORT"; READINESS_URL="http://localhost:$QUARKUS_PORT$QUARKUS_API_BASE/owners" ;;
    quarkus-jvm) APP_PORT="$QUARKUS_JVM_PORT"; READINESS_URL="http://localhost:$QUARKUS_JVM_PORT$QUARKUS_JVM_API_BASE/owners" ;;
    go)          APP_PORT="$GO_PORT"; READINESS_URL="http://localhost:$GO_PORT$GO_API_BASE/owners" ;;
esac

# For steady-state, ensure app is running before handing off
if [ "$PHASE" = "steady" ]; then
    docker compose -f "$COMPOSE_FILE" up -d
    echo "Waiting for app readiness at $READINESS_URL ..."
    for i in $(seq 1 120); do
        if curl -sf "$READINESS_URL" > /dev/null 2>&1; then
            echo "  App ready after ~${i}s"
            break
        fi
        sleep 1
    done
fi

exec "$EVAL_DIR/wrk2-baseline/run-baseline.sh" "$APP" "$SCENARIO" "$PHASE" "$RUN"
