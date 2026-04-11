#!/usr/bin/env bash
# Pre-generate probe-bodies results for each unique flow (app+scenario).
# probe-bodies output is flow-graph + OpenAPI dependent only; it is reusable
# across rates, phases, and repetitions.  quarkus-jvm shares quarkus flows.
#
# Cached at: results/<flow_app>/slsbench/<scenario>/probe-bodies/
#
# Usage: ./run-probe-all.sh [--apps spring,quarkus,quarkus-jvm] [--scenarios read-heavy,mixed,lifecycle]
#
# Typically called once before the experiment matrix.  run-slsbench.sh then
# discovers the cached result automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$EVAL_DIR/config.env"

APPS="spring quarkus quarkus-jvm"
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
            ;;
        quarkus)
            COMPOSE_FILE="$EVAL_DIR/$QUARKUS_COMPOSE"
            SERVICE_NAME="$QUARKUS_SERVICE_NAME"
            PORT="$QUARKUS_PORT"
            OPENAPI_PATH="$EVAL_DIR/$QUARKUS_OPENAPI"
            ;;
        quarkus-jvm)
            COMPOSE_FILE="$EVAL_DIR/$QUARKUS_JVM_COMPOSE"
            SERVICE_NAME="$QUARKUS_JVM_SERVICE_NAME"
            PORT="$QUARKUS_JVM_PORT"
            OPENAPI_PATH="$EVAL_DIR/$QUARKUS_JVM_OPENAPI"
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
        EXISTING=$(find "$PROBE_CACHE" -maxdepth 1 -type d -name 'probe-bodies-result-*' 2>/dev/null | head -1)
        if [ -n "$EXISTING" ]; then
            echo "=== probe-bodies SKIP (exists) | flow=$FLOW_KEY -> $EXISTING ==="
            DONE_FLOWS="$DONE_FLOWS $FLOW_KEY"
            continue
        fi

        mkdir -p "$PROBE_CACHE"

        # Build probe flow: MAX_RATE + DURATION_STEADY + warmup stage.
        # This produces enough iterations for every rate/phase combination.
        PROBE_FLOW="$PROBE_CACHE/probe-flow.yaml"
        sed "s|-t2 -c5 -d[^ ]* -R[0-9]*|-t${WRK2_THREADS} -c${WRK2_CONNECTIONS} -d${DURATION} -R${MAX_RATE}|" \
            "$FLOW_FILE" > "$PROBE_FLOW"

        python3 -c "
import yaml, sys, copy
with open(sys.argv[1]) as f:
    doc = yaml.safe_load(f)
sname = list(doc['stages'].keys())[0]
warmup = copy.deepcopy(doc['stages'][sname])
warmup['wrk2params'] = sys.argv[2]
doc['stages'] = {'00-warmup': warmup, **doc['stages']}
with open(sys.argv[1], 'w') as f:
    yaml.dump(doc, f, default_flow_style=False, sort_keys=False)
" "$PROBE_FLOW" "-t1 -c2 -d${WARMUP_DURATION} -R${WARMUP_RATE}"

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
