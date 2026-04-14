#!/usr/bin/env bash
# Restart a benchmark app container and measure time to first successful HTTP 200.
# Outputs a JSON object compatible with slsbench's first_request_result.json.
#
# Usage: ./cold-start-probe.sh <app>
#   app: spring | quarkus | quarkus-jvm
#
# Reads parameters from ../config.env.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$EVAL_DIR/config.env"

APP="${1:?Usage: $0 <app>}"

case "$APP" in
    spring)
        PORT="$SPRING_PORT"
        PROBE_PATH="$SPRING_API_BASE/owners"
        COMPOSE_FILE="$EVAL_DIR/$SPRING_COMPOSE"
        ;;
    quarkus)
        PORT="$QUARKUS_PORT"
        PROBE_PATH="$QUARKUS_API_BASE/owners"
        COMPOSE_FILE="$EVAL_DIR/$QUARKUS_COMPOSE"
        ;;
    quarkus-jvm)
        PORT="$QUARKUS_JVM_PORT"
        PROBE_PATH="$QUARKUS_JVM_API_BASE/owners"
        COMPOSE_FILE="$EVAL_DIR/$QUARKUS_JVM_COMPOSE"
        ;;
    *)
        echo '{"error":"unknown app"}' >&2
        exit 1
        ;;
esac

TARGET_URL="http://localhost:${PORT}${PROBE_PATH}"
TIMEOUT="${FIRST_RESPONSE_TIMEOUT:-120}"
INTERVAL_MS="${FIRST_RESPONSE_INTERVAL_MS:-200}"
INTERVAL_S=$(LC_NUMERIC=C awk "BEGIN{printf \"%.3f\", $INTERVAL_MS / 1000}")

docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
docker compose -f "$COMPOSE_FILE" up -d

START_TS=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
START_EPOCH_NS=$(date +%s%N)
ATTEMPTS=0
STATUS=0
DEADLINE=$(($(date +%s) + TIMEOUT))

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$TARGET_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        STATUS=200
        break
    fi
    sleep "$INTERVAL_S"
done

END_EPOCH_NS=$(date +%s%N)
END_TS=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
DURATION_MS=$(( (END_EPOCH_NS - START_EPOCH_NS) / 1000000 ))
DURATION_S=$(LC_NUMERIC=C awk "BEGIN{printf \"%.3f\", $DURATION_MS / 1000}")

cat <<EOF
{
  "targetUrl": "$TARGET_URL",
  "startedAt": "$START_TS",
  "finishedAt": "$END_TS",
  "durationSeconds": $DURATION_S,
  "durationMillis": $DURATION_MS,
  "attempts": $ATTEMPTS,
  "statusCode": $STATUS,
  "resolvedPathUsed": "$PROBE_PATH"
}
EOF
