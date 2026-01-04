#!/bin/bash
set -e

# Start dummy workload in background
echo "Starting dummy workload process..."
/app/dummy_workload.sh > /tmp/dummy_workload.log 2>&1 &
DUMMY_PID=$!
echo "Dummy workload started with PID: $DUMMY_PID"

# Function to cleanup on exit
cleanup() {
    echo "Stopping dummy workload (PID: $DUMMY_PID)..."
    kill $DUMMY_PID 2>/dev/null || true
    wait $DUMMY_PID 2>/dev/null || true
}
trap cleanup EXIT

# Run the benchmark (use 'yes' to automatically answer 'y' to any prompts)
cd /app
yes | ./run_tika_benchmark.sh "$@"

