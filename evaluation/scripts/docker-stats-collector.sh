#!/usr/bin/env bash
# Stream docker container stats to a JSONL file at regular intervals.
# Runs until killed (designed to be backgrounded).
#
# Usage: ./docker-stats-collector.sh <service_or_container> <output_file> [compose_file]
#
# If a compose_file is provided, the first argument is treated as a service
# name and resolved to the actual container ID via docker compose ps.

set -euo pipefail

SERVICE_OR_CONTAINER="${1:?Usage: $0 <service_or_container> <output_file> [compose_file]}"
OUTPUT="${2:?}"
COMPOSE_FILE="${3:-}"
INTERVAL="${STATS_INTERVAL_S:-1}"

CONTAINER="$SERVICE_OR_CONTAINER"
if [ -n "$COMPOSE_FILE" ]; then
    RESOLVED=$(docker compose -f "$COMPOSE_FILE" ps -q "$SERVICE_OR_CONTAINER" 2>/dev/null | head -1 || true)
    if [ -n "$RESOLVED" ]; then
        CONTAINER="$RESOLVED"
    fi
fi

> "$OUTPUT"

while true; do
    docker stats --no-stream --format '{{json .}}' "$CONTAINER" >> "$OUTPUT" 2>/dev/null || true
    sleep "$INTERVAL"
done
