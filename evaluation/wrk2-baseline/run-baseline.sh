#!/usr/bin/env bash
# Run a wrk2 baseline benchmark for a single (app, scenario) combination.
#
# Usage: ./run-baseline.sh <app> <scenario> <phase> <run_number>
#   app:        spring | quarkus | quarkus-jvm
#   scenario:   read-heavy | mixed | lifecycle | post-create | single-endpoint
#   phase:      cold | steady
#   run_number: integer repetition index
#
# Reads shared parameters from ../config.env.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$EVAL_DIR/config.env"

APP="${1:?Usage: $0 <app> <scenario> <phase> <run_number>}"
SCENARIO="${2:?}"
PHASE="${3:?}"
RUN="${4:?}"

# Resolve app-specific settings
case "$APP" in
    spring)
        COMPOSE_FILE="$EVAL_DIR/$SPRING_COMPOSE"
        SERVICE_NAME="$SPRING_SERVICE_NAME"
        PORT="$SPRING_PORT"
        API_BASE="$SPRING_API_BASE"
        ;;
    quarkus)
        COMPOSE_FILE="$EVAL_DIR/$QUARKUS_COMPOSE"
        SERVICE_NAME="$QUARKUS_SERVICE_NAME"
        PORT="$QUARKUS_PORT"
        API_BASE="$QUARKUS_API_BASE"
        ;;
    quarkus-jvm)
        COMPOSE_FILE="$EVAL_DIR/$QUARKUS_JVM_COMPOSE"
        SERVICE_NAME="$QUARKUS_JVM_SERVICE_NAME"
        PORT="$QUARKUS_JVM_PORT"
        API_BASE="$QUARKUS_JVM_API_BASE"
        ;;
    *)
        echo "Unknown app: $APP (expected: spring|quarkus|quarkus-jvm)" >&2
        exit 1
        ;;
esac

# Resolve Lua script
case "$SCENARIO" in
    read-heavy)      LUA_SCRIPT="$SCRIPT_DIR/lua/read-list.lua" ;;
    mixed)           LUA_SCRIPT="$SCRIPT_DIR/lua/mixed-crud.lua" ;;
    lifecycle)       LUA_SCRIPT="$SCRIPT_DIR/lua/mixed-crud.lua" ;;
    post-create)     LUA_SCRIPT="$SCRIPT_DIR/lua/post-create.lua" ;;
    single-endpoint) LUA_SCRIPT="$SCRIPT_DIR/lua/single-endpoint.lua" ;;
    *)
        echo "Unknown scenario: $SCENARIO (expected: read-heavy|mixed|lifecycle|post-create|single-endpoint)" >&2
        exit 1
        ;;
esac

# Resolve duration
if [ "$PHASE" = "cold" ]; then
    DURATION="$DURATION_COLD"
else
    DURATION="$DURATION_STEADY"
fi

for RATE in $RATES; do
    RESULT_DIR="$EVAL_DIR/results/$APP/wrk2/$SCENARIO/$PHASE/R${RATE}/run-${RUN}"
    mkdir -p "$RESULT_DIR"

    echo "=== wrk2 | app=$APP scenario=$SCENARIO phase=$PHASE rate=$RATE run=$RUN ==="

    # Cold-start: cold-start-probe.sh handles the full compose lifecycle
    # (down + up + poll until first 200) and emits a JSON timing report
    if [ "$PHASE" = "cold" ]; then
        echo "  Cold-start restart via cold-start-probe.sh..."
        "$EVAL_DIR/scripts/cold-start-probe.sh" "$APP" > "$RESULT_DIR/first_response.json"
    fi

    # Steady-state warm-up
    if [ "$PHASE" = "steady" ]; then
        echo "  Warm-up: $WARMUP_DURATION at R=$WARMUP_RATE..."
        docker run --rm --network=host \
            -e BASE_PATH="$API_BASE" \
            -v "$LUA_SCRIPT:/scripts/bench.lua:ro" \
            "$WRK2_IMAGE" \
            -s /scripts/bench.lua \
            -t"$WRK2_THREADS" -c"$WRK2_CONNECTIONS" \
            -d"$WARMUP_DURATION" -R"$WARMUP_RATE" \
            "http://localhost:${PORT}/" \
            > /dev/null 2>&1 || true
    fi

    # Start docker stats collector in background
    "$EVAL_DIR/scripts/docker-stats-collector.sh" "$SERVICE_NAME" "$RESULT_DIR/container-stats.jsonl" &
    STATS_PID=$!

    # Run wrk2
    echo "  Running wrk2: threads=$WRK2_THREADS connections=$WRK2_CONNECTIONS duration=$DURATION rate=$RATE"
    docker run --rm --network=host \
        -e BASE_PATH="$API_BASE" \
        -v "$LUA_SCRIPT:/scripts/bench.lua:ro" \
        "$WRK2_IMAGE" \
        -s /scripts/bench.lua \
        -t"$WRK2_THREADS" -c"$WRK2_CONNECTIONS" \
        -d"$DURATION" -R"$RATE" \
        --latency \
        "http://localhost:${PORT}/" \
        > "$RESULT_DIR/wrk2_output.log" 2>&1 || true

    # Stop stats collector
    kill "$STATS_PID" 2>/dev/null || true
    wait "$STATS_PID" 2>/dev/null || true

    echo "  Results saved to $RESULT_DIR"
done

echo "=== wrk2 baseline complete for $APP/$SCENARIO/$PHASE/run-$RUN ==="
