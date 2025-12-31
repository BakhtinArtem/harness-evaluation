#!/bin/bash

# Simple script to start media microservices and run wrk2 100 times

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIA_DIR="$SCRIPT_DIR/DeathStarBench/mediaMicroservices"
WRK2_DIR="$SCRIPT_DIR/DeathStarBench/wrk2"
COMPOSE_SCRIPT="$MEDIA_DIR/wrk2/scripts/media-microservices/compose-review.lua"
BASE_URL="http://localhost:8080"
ITERATIONS=100

echo "Starting media microservices..."
cd "$MEDIA_DIR"
docker-compose up -d

echo "Waiting for services to be ready..."
sleep 30

# Wait for nginx to be ready
for i in {1..60}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo "Services are ready!"
        break
    fi
    sleep 1
done

# Build wrk2 if needed
if [ ! -f "$WRK2_DIR/wrk" ]; then
    echo "Building wrk2..."
    cd "$WRK2_DIR"
    make
fi

# Create wrapper script for lua
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<EOF
url = "$BASE_URL"
dofile("$COMPOSE_SCRIPT")
EOF

echo "Running wrk2 $ITERATIONS times..."
cd "$MEDIA_DIR"

for i in $(seq 1 $ITERATIONS); do
    echo "[$i/$ITERATIONS] Running wrk2..."
    "$WRK2_DIR/wrk" \
        -D exp \
        -t 2 \
        -c 100 \
        -d 30s \
        -L \
        -s "$TEMP_SCRIPT" \
        -R 1000 \
        "$BASE_URL/wrk2-api/review/compose" > /dev/null 2>&1 || true
done

rm -f "$TEMP_SCRIPT"
echo "Done! Completed $ITERATIONS iterations."

