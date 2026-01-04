# Running DeathStarBench benchmarking

Navigate into `DeathStarBench/mediaMicroservices` and run `docker compose up`.
This would would statred media microservices benchmarking application. After that
navigate into `/DeathStarBench/wrk2` directory and execute `make` to build wrk
executable. Copy wrk executable to the root folder by executing `mv wrk ../../`
Navigate back to root folder. And run following script to benchmark media microservices `./run_media_benchmark.sh`

# Installing Prerequisites

Before running the barista benchmark scripts, you need to install the required prerequisites. An automated installation script is provided:

```bash
# Install all prerequisites
./install_prerequisites.sh

# Skip specific components if already installed
./install_prerequisites.sh --skip-java  # Skip Java/GraalVM checks
./install_prerequisites.sh --skip-wrk   # Skip wrk installation
./install_prerequisites.sh --skip-wrk2  # Skip wrk2 installation

# Show help
./install_prerequisites.sh --help
```

The installation script will:
- Install Python 3 (if not already installed)
- Check for Java/GraalVM and provide setup instructions
- Build and install `wrk` from source
- Build and install `wrk2` from source (automatically renamed from `wrk` to `wrk2`)
- Verify the barista directory exists

**Note**: The script builds `wrk` and `wrk2` in `.prerequisites/` directory. To make them available permanently, add them to your PATH in `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$PATH:$(pwd)/.prerequisites/wrk"
export PATH="$PATH:$(pwd)/.prerequisites/wrk2"
```

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