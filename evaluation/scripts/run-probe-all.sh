#!/usr/bin/env bash
# Pre-generate probe-bodies results for each unique flow (app+scenario).
# probe-bodies output is flow-graph + OpenAPI dependent only; it is reusable
# across rates, phases, and repetitions.  quarkus-jvm shares quarkus flows.
#
# Cached at: results/<flow_app>/slsbench/<scenario>/probe-bodies/
#
# Usage: ./run-probe-all.sh [--apps spring,quarkus,quarkus-jvm,go] [--scenarios read-heavy,mixed,lifecycle]
#
# Typically called once before the experiment matrix.  run-slsbench.sh then
# discovers the cached result automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$EVAL_DIR/config.env"

# `spring-native` is supported via the case blocks below (reuses `spring` flows)
# but is not part of the default APPS set; see run-all.sh for context.
APPS="spring quarkus quarkus-jvm go"
SCENARIOS="read-heavy mixed lifecycle"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apps)       APPS="${2//,/ }"; shift 2 ;;
        --scenarios)  SCENARIOS="${2//,/ }"; shift 2 ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--apps spring,quarkus,quarkus-jvm] [--scenarios read-heavy,mixed,lifecycle]" >&2
            exit 1
            ;;
    esac
done

MAX_RATE=$(echo "$RATES" | tr ' ' '\n' | sort -n | tail -1)
DURATION="$DURATION_STEADY"

DONE_FLOWS=""

for APP in $APPS; do
    case "$APP" in
        spring)
            COMPOSE_FILE="$EVAL_DIR/$SPRING_COMPOSE"
            SERVICE_NAME="$SPRING_SERVICE_NAME"
            PORT="$SPRING_PORT"
            OPENAPI_PATH="$EVAL_DIR/$SPRING_OPENAPI"
            READINESS_PATH="$SPRING_API_BASE/owners"
            ;;
        spring-native)
            COMPOSE_FILE="$EVAL_DIR/$SPRING_NATIVE_COMPOSE"
            SERVICE_NAME="$SPRING_NATIVE_SERVICE_NAME"
            PORT="$SPRING_NATIVE_PORT"
            OPENAPI_PATH="$EVAL_DIR/$SPRING_NATIVE_OPENAPI"
            READINESS_PATH="$SPRING_NATIVE_API_BASE/owners"
            ;;
        quarkus)
            COMPOSE_FILE="$EVAL_DIR/$QUARKUS_COMPOSE"
            SERVICE_NAME="$QUARKUS_SERVICE_NAME"
            PORT="$QUARKUS_PORT"
            OPENAPI_PATH="$EVAL_DIR/$QUARKUS_OPENAPI"
            READINESS_PATH="$QUARKUS_API_BASE/owners"
            ;;
        quarkus-jvm)
            COMPOSE_FILE="$EVAL_DIR/$QUARKUS_JVM_COMPOSE"
            SERVICE_NAME="$QUARKUS_JVM_SERVICE_NAME"
            PORT="$QUARKUS_JVM_PORT"
            OPENAPI_PATH="$EVAL_DIR/$QUARKUS_JVM_OPENAPI"
            READINESS_PATH="$QUARKUS_JVM_API_BASE/owners"
            ;;
        go)
            COMPOSE_FILE="$EVAL_DIR/$GO_COMPOSE"
            SERVICE_NAME="$GO_SERVICE_NAME"
            PORT="$GO_PORT"
            OPENAPI_PATH="$EVAL_DIR/$GO_OPENAPI"
            READINESS_PATH="$GO_API_BASE/owners"
            ;;
        *)
            echo "Unknown app: $APP" >&2
            exit 1
            ;;
    esac

    FLOW_APP="$APP"
    if [ "$APP" = "quarkus-jvm" ]; then
        FLOW_APP="quarkus"
    fi
    if [ "$APP" = "spring-native" ]; then
        FLOW_APP="spring"
    fi

    for SCENARIO in $SCENARIOS; do
        FLOW_KEY="${FLOW_APP}/${SCENARIO}"

        # Skip if this flow was already probed (quarkus-jvm reuses quarkus flows)
        if echo "$DONE_FLOWS" | grep -qF "$FLOW_KEY"; then
            echo "=== probe-bodies SKIP (cached) | flow=$FLOW_KEY (reused by $APP) ==="
            continue
        fi

        FLOW_FILE="$EVAL_DIR/flows/$FLOW_APP/$SCENARIO.yaml"
        if [ ! -f "$FLOW_FILE" ]; then
            echo "Flow file not found: $FLOW_FILE -- skipping" >&2
            continue
        fi

        PROBE_CACHE="$EVAL_DIR/results/$FLOW_APP/slsbench/$SCENARIO/probe-bodies"

        # Skip if result already exists
        EXISTING=$(find "$PROBE_CACHE" -maxdepth 1 -type d -name 'probe-bodies-result-*' 2>/dev/null | head -1 || true)
        if [ -n "$EXISTING" ]; then
            echo "=== probe-bodies SKIP (exists) | flow=$FLOW_KEY -> $EXISTING ==="
            DONE_FLOWS="$DONE_FLOWS $FLOW_KEY"
            continue
        fi

        mkdir -p "$PROBE_CACHE"

        # Build probe flow (no warmup — probes only need path coverage).
        PROBE_FLOW="$PROBE_CACHE/probe-flow.yaml"
        sed "s|-t2 -c5 -d[^ ]* -R[0-9]*|-t${WRK2_THREADS} -c${WRK2_CONNECTIONS} -d${DURATION} -R${MAX_RATE}|" \
            "$FLOW_FILE" > "$PROBE_FLOW"

        echo "=== probe-bodies | flow=$FLOW_KEY max_rate=$MAX_RATE ==="
        docker run --rm \
            --network=host \
            -v "$DOCKER_SOCKET:$DOCKER_SOCKET" \
            -v "$PROBE_FLOW:/workspace/flow.yaml:ro" \
            -v "$OPENAPI_PATH:/workspace/openapi.yaml:ro" \
            -v "$COMPOSE_FILE:/workspace/docker-compose.yml:ro" \
            -v "$PROBE_CACHE:/workspace/probe-result" \
            "$SLSBENCH_IMAGE" probe-bodies \
                --flow-path /workspace/flow.yaml \
                --openapi-link /workspace/openapi.yaml \
                --output-path /workspace/probe-result \
                --docker-compose-path /workspace/docker-compose.yml \
                --docker-socket-path "$DOCKER_SOCKET" \
                --service-name "$SERVICE_NAME" \
                --port "$PORT" \
                --readiness-path "$READINESS_PATH" \
                --max-probe-target 500 \
            2>&1 | tee "$PROBE_CACHE/probe-bodies.log"

        RESULT=$(find "$PROBE_CACHE" -maxdepth 1 -type d -name 'probe-bodies-result-*' | sort | tail -1)
        if [ -z "$RESULT" ]; then
            echo "ERROR: probe-bodies produced no result for $FLOW_KEY" >&2
            exit 1
        fi

        echo "  Cached: $RESULT"
        DONE_FLOWS="$DONE_FLOWS $FLOW_KEY"
    done
done

echo ""
echo "=== All probe-bodies complete. ==="
