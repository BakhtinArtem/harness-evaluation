# Barista Benchmark Runners

This repository contains three benchmark runner scripts for barista benchmarks:
- `run_petclinic_benchmark.sh` - Spring PetClinic benchmark
- `run_shopcart_benchmark.sh` - Micronaut Shopcart benchmark  
- `run_tika_benchmark.sh` - Quarkus Tika benchmark

## Barista Shopcart Benchmark Runner

This script runs the barista shopcart benchmark with mixed requests and saves results in separate timestamped folders.

## Prerequisites

The script automatically checks for all required prerequisites before running:

- **Python 3**: Required to run the barista harness
- **Java/GraalVM**: JAVA_HOME environment variable must be set
  - For **JVM mode**: Requires a JVM with `java` executable
  - For **native mode**: Requires GraalVM with `native-image` tool
- **wrk**: Load testing tool for throughput measurements
- **wrk2**: Latency testing tool (must be renamed from `wrk` to `wrk2`)
- **Barista directory**: The barista benchmark suite must be present
- **Application artifacts**: 
  - **JVM mode**: Application JAR file (will be built automatically if missing)
  - **native mode**: Native executable or NIB file (will be built automatically if missing)
- **Disk space**: At least 1GB free space recommended (more for native mode builds)

If any critical prerequisites are missing, the script will exit with an error message. Warnings (like missing JAR/native image) will prompt for confirmation before continuing.

## Usage

```bash
# Run benchmark once in JVM mode (default)
./run_shopcart_benchmark.sh

# Run benchmark 3 times in JVM mode
./run_shopcart_benchmark.sh 3

# Run benchmark 5 times in native mode
./run_shopcart_benchmark.sh 5 --mode native

# Run benchmark 5 times without outputting results to stdout (faster)
./run_shopcart_benchmark.sh 5 --no-output

# Run in native mode without stdout output
./run_shopcart_benchmark.sh 3 --mode native --no-output

# Show help
./run_shopcart_benchmark.sh --help
```

## Arguments

- `number_of_runs` (optional): Number of times to run the benchmark (default: 1)
- `--mode jvm|native` (optional): Execution mode - JVM or native (default: jvm)
- `--no-output` (optional): Skip outputting raw results to stdout, only save to files

## Results Structure

Each run creates a separate timestamped directory:

```
results/
├── run_1_2026-01-03_23-30-15/
│   ├── barista-results.json
│   ├── barista_startup_results.csv
│   ├── barista_warmup_results.csv
│   ├── barista_throughput_results.csv
│   ├── final_measurements-barista_latency_results.csv
│   ├── barista_resource_usage.csv
│   ├── app-dump.txt
│   ├── barista.log
│   ├── warmup-*.txt
│   ├── throughput-*.txt
│   ├── *-latency-*.txt
│   └── run_info.txt
├── run_2_2026-01-03_23-35-20/
│   └── ...
└── run_3_2026-01-03_23-40-25/
    └── ...
```

## Output Files

Each run directory contains:

- **barista-results.json**: Complete JSON with all metrics
- **barista_startup_results.csv**: Startup response times
- **barista_warmup_results.csv**: Warmup throughput iterations
- **barista_throughput_results.csv**: Peak throughput measurement
- **final_measurements-barista_latency_results.csv**: Latency percentiles
- **barista_resource_usage.csv**: Time-series resource usage (RSS, VMS, CPU)
- **app-dump.txt**: Application output logs
- **barista.log**: Complete benchmark execution log
- **warmup-*.txt**: Raw wrk output for each warmup iteration
- **throughput-*.txt**: Raw wrk output for throughput measurement
- ***-latency-*.txt**: Raw wrk2 output for latency measurement
- **run_info.txt**: Metadata about the run (timestamp, run number, etc.)

## Examples

### Single run in JVM mode (default)
```bash
./run_shopcart_benchmark.sh
```

### Multiple runs in JVM mode (3 times)
```bash
./run_shopcart_benchmark.sh 3
```

### Run in native mode
```bash
./run_shopcart_benchmark.sh --mode native
```

### Multiple runs in native mode
```bash
./run_shopcart_benchmark.sh 5 --mode native
```

### Multiple runs without stdout output (faster for many runs)
```bash
./run_shopcart_benchmark.sh 10 --no-output
```

### Native mode without stdout output
```bash
./run_shopcart_benchmark.sh 3 --mode native --no-output
```

## Notes

- Each run is saved in a separate timestamped folder to avoid overwriting results
- The timestamp format is: `YYYY-MM-DD_HH-MM-SS`
- There's a 2-second delay between runs to ensure clean separation
- All results are saved regardless of the `--no-output` flag

# Docker Benchmark Containers

This repository includes Dockerfiles for containerizing barista benchmarks with dummy background workloads. This allows you to run benchmarks in isolated containers with simulated background work.

## Available Dockerfiles

- `Dockerfile.petclinic` - Spring PetClinic benchmark
- `Dockerfile.tika` - Quarkus Tika benchmark  
- `Dockerfile.shopcart` - Micronaut Shopcart benchmark

## Building the Images

### Build PetClinic Benchmark Image
```bash
docker build -f Dockerfile.petclinic -t aape2k/petclinic-isolation-test:2.0.0 .
```

### Build Tika Benchmark Image
```bash
docker build -f Dockerfile.tika -t aape2k/tika-isolation-test:2.0.0 .
```

### Build Shopcart Benchmark Image
```bash
docker build -f Dockerfile.shopcart -t aape2k/shopcart-isolation-test:2.0.0 .
```

## Running the Containers

### Basic Usage

Run a single benchmark in JVM mode (default):
```bash
docker run --rm aape2k/petclinic-isolation-test:2.0.0
```

Run multiple iterations:
```bash
docker run --rm aape2k/petclinic-isolation-test:2.0.0 5
```

Run in native mode:
```bash
docker run --rm aape2k/petclinic-isolation-test:2.0.0 3 --mode native
```

Run without stdout output (faster):
```bash
docker run --rm aape2k/petclinic-isolation-test:2.0.0 5 --no-output
```

### Mounting Results Directory

To persist results outside the container:
```bash
docker run --rm -v $(pwd)/results:/app/results-petclinic-jvm aape2k/petclinic-isolation-test:2.0.0 3
```

For Tika:
```bash
docker run --rm -v $(pwd)/results:/app/results-tika-jvm aape2k/tika-isolation-test:2.0.0 3
```

For Shopcart:
```bash
docker run --rm -v $(pwd)/results:/app/results-shopcart-jvm aape2k/shopcart-isolation-test:2.0.0 3
```

### Customizing Dummy Workload

Each container runs a dummy background process that simulates other work happening on the container. The dummy workload can be customized using environment variables:

- `DUMMY_CPU_INTENSITY` - CPU usage intensity (0.0 to 1.0, default: 0.1)
- `DUMMY_MEMORY_MB` - Memory allocation in MB (default: 100)
- `DUMMY_INTERVAL` - Sleep interval in seconds (default: 1)

Example:
```bash
docker run --rm \
  -e DUMMY_CPU_INTENSITY=0.2 \
  -e DUMMY_MEMORY_MB=200 \
  aape2k/petclinic-isolation-test:2.0.0 3
```

The dummy workload:
- Consumes CPU based on `DUMMY_CPU_INTENSITY` (default: 10%)
- Allocates memory based on `DUMMY_MEMORY_MB` (default: 100MB)
- Performs periodic I/O operations
- Runs in the background and is automatically stopped when the benchmark completes

### Resource Limits

You can set resource limits to control container resources:
```bash
docker run --rm \
  --cpus="2.0" \
  --memory="4g" \
  aape2k/petclinic-isolation-test:2.0.0 3
```

## Results in Docker Containers

Results are saved in the following directories inside the container:
- PetClinic: `/app/results-petclinic/`
- Tika: `/app/results-tika/`
- Shopcart: `/app/results/`

Mount these directories as volumes to persist results on the host.

## Example: Complete Docker Benchmark Run

```bash
# Build the image
docker build -f Dockerfile.petclinic -t petclinic-benchmark .

# Run 5 iterations in JVM mode with results saved to host
docker run --rm \
  -v $(pwd)/benchmark-results:/app/results-petclinic \
  -e DUMMY_CPU_INTENSITY=0.15 \
  -e DUMMY_MEMORY_MB=150 \
  petclinic-benchmark 5 --no-output

# Results will be in ./benchmark-results/ on the host
```

## Docker Notes

- The containers include GraalVM with native-image support for both JVM and native modes
- All required tools (wrk, wrk2, Python3) are pre-installed
- The barista suite and benchmark scripts are copied into the container
- Applications will be built automatically if not already built
- The dummy workload simulates realistic background work for more accurate benchmarking