#!/bin/bash

URLS=("http://localhost:8080")                            # List your target URLs here
THREADS=2                                                 # Number of threads per URL
CONNECTIONS=100                                           # Number of connections per URL
DURATION="30s"                                            # Test duration for each run
RATE=2000                                                 # Requests per second per URL
RUNS=5                                                    # Number of iterations for benchmarking
OUTPUT_DIR="media_benchmark_results"

mkdir -p "$OUTPUT_DIR"

for url in "${URLS[@]}"; do
    for i in $(seq 1 $RUNS); do
        output_file="${OUTPUT_DIR}/$(echo $url | sed 's#http[s]*://##;s#/#_#g')_run${i}.txt"
        echo "Running wrk2 to benchmark $url (run $i)..."
        ./wrk -t${THREADS} -c${CONNECTIONS} -d${DURATION} -R${RATE} --latency -s DeathStarBench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua "$url" > "$output_file"
        echo "Results saved to $output_file"
    done
done

echo "Benchmarking completed. Results are saved in the $OUTPUT_DIR directory."