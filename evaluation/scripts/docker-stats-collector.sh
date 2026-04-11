#!/usr/bin/env bash
# Stream docker container stats to a JSONL file at regular intervals.
# Runs until killed (designed to be backgrounded).
#
# Usage: ./docker-stats-collector.sh <container_name_or_id> <output_file>

set -euo pipefail

CONTAINER="${1:?Usage: $0 <container_name_or_id> <output_file>}"
OUTPUT="${2:?}"
INTERVAL="${STATS_INTERVAL_S:-1}"

> "$OUTPUT"

while true; do
    docker stats --no-stream --format '{{json .}}' "$CONTAINER" >> "$OUTPUT" 2>/dev/null || true
    sleep "$INTERVAL"
done
