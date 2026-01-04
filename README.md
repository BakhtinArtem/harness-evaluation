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

# Running Barista

Barista can be benchmarked in two ways: using the default method or with 
dummy process simulation. The following configuration shows the default settings
used for all Barista benchmarks participating in the evaluation:

```json
{
    "endpoint": "http://127.0.0.1:8006",
    "output_dir": "logs/",
    "load_testing":{
        "lua_script": "mixed-requests.lua",
        "connections": 16,
        "threads": 16,
        "startup":{
            "iterations": 10,
            "timeout": 300,
            "cmd_app_prefix": ["taskset", "-c", "0-3"]
        },
        "warmup":{
            "iterations": 0,
            "iteration_time_seconds": 15
        },
        "throughput":{
            "iterations": 0,
            "iteration_time_seconds": 30
        },
        "latency_measurement":{
            "iterations": 1,
            "iteration_time_seconds": 30,
            "search_strategy": "FIXED",
            "rates": 3000
        }
    }
}
```

Startup configuration remains unchanged. The warmup phase is disabled (set to zero)
in order to focus on measuring the time required for a serverless application to
scale up. The throughput phase is also set to zero, as it was previously measured
with an older version of wrk and overlaps with what the latency measurement—performed
with wrk2—now provides. Finally, the benchmark runs a latency phase using wrk2
for 30 seconds, with 16 threads, 16 connections, and a request rate of 3000
requests per second.

```bash
(cd ./barista/benc && ./build micronout-shopcart quarkus-tika spring-petclinic) 
./run_shopcart_benchmark.sh 5 --mode native
./run_shopcart_benchmark.sh 5 --mode jvm
(cd ./barista/benc && ./build micronout-shopcart quarkus-tika spring-petclinic) 
./run_tika_benchmark.sh 5 --mode native
```
## Deafult way

## Process simulation

```bash
docker run --rm \
  -e DUMMY_CPU_INTENSITY=0.8 \
  -e DUMMY_MEMORY_MB=200 \
  shopcart-isolation-test 5 --mode native
```

# Running DeathStarBench benchmarking

Navigate into `DeathStarBench/mediaMicroservices` and run `docker compose up`.
This would would statred media microservices benchmarking application. After that
navigate into `/DeathStarBench/wrk2` directory and execute `make` to build wrk
executable. Copy wrk executable to the root folder by executing `mv wrk ../../`
Navigate back to root folder. And run following script to benchmark media 
microservices `./run_media_benchmark.sh`