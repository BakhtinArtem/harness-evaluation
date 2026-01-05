#!/bin/bash

# Install prerequisites (wrk2) if not already installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "${SCRIPT_DIR}/.prerequisites/wrk2/wrk2" ]; then
    echo "Installing prerequisites (wrk2)..."
    "${SCRIPT_DIR}/install_prerequisites.sh" --skip-java --skip-wrk
fi

# Add wrk2 to PATH
WRK2_DIR="${SCRIPT_DIR}/.prerequisites/wrk2"
export PATH="${WRK2_DIR}:$PATH"

# Verify wrk2 is available
if ! command -v wrk2 &> /dev/null && [ ! -f "${WRK2_DIR}/wrk2" ]; then
    echo "Error: wrk2 is not installed. Please run install_prerequisites.sh manually."
    exit 1
fi

# Use wrk2 from .prerequisites if not in PATH
WRK2_CMD="wrk2"
if ! command -v wrk2 &> /dev/null; then
    WRK2_CMD="${WRK2_DIR}/wrk2"
fi

URLS=("http://localhost:8080")                            # List your target URLs here
THREADS=16                                                 # Number of threads per URL
CONNECTIONS=16                                           # Number of connections per URL
DURATION="30s"                                            # Test duration for each run
RATE=800                                                 # Requests per second per URL
RUNS=5                                                    # Number of iterations for benchmarking
OUTPUT_DIR="results-media"

mkdir -p "$OUTPUT_DIR"

for url in "${URLS[@]}"; do
    for i in $(seq 1 $RUNS); do
        output_file="${OUTPUT_DIR}/$(echo $url | sed 's#http[s]*://##;s#/#_#g')_run${i}.txt"
        echo "Running wrk2 to benchmark $url (run $i)..."
        "${WRK2_CMD}" -t${THREADS} -c${CONNECTIONS} -d${DURATION} -R${RATE} --latency -s DeathStarBench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua "$url" > "$output_file"
        echo "Results saved to $output_file"
    done
done

echo "Benchmarking completed. Results are saved in the $OUTPUT_DIR directory."