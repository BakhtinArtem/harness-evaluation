# Machine Specification

This evaluation harness has been tested on the following machine configuration:

## Hardware
- **CPU**: AMD EPYC 7B12 (4 cores, 8 threads)
- **Architecture**: x86_64
- **Memory**: 62 GB RAM
- **Storage**: 9.7 GB disk space (root filesystem)
- **Virtualization**: KVM (full virtualization)

## Operating System
- **OS**: Debian GNU/Linux 12 (bookworm)
- **Kernel**: 6.1.0-41-cloud-amd64
- **Hostname**: instance-20260104-231130

## Installed Software
- **Java/GraalVM**: GraalVM Community Edition 21.0.1 (OpenJDK 21.0.1)
  - Location: `/opt/graalvm`
  - Includes `native-image` tool for native compilation
- **Docker**: 29.1.3
- **Python**: 3.11.2
- **Build Tools**: gcc, make, git, build-essential
- **Development Libraries**: libssl-dev, zlib1g-dev

## Environment Configuration
- **JAVA_HOME**: `/opt/graalvm` (configured in `~/.bashrc`)
- **PATH**: Includes GraalVM binaries (`$JAVA_HOME/bin`)

---

# Prerequisites

Before using this evaluation harness, you should have the following prerequisites already installed:

## Will be installed by `install_prerequisites.sh`:
- **Python 3** - Will be installed automatically if not found
- **wrk** - Will be built from source and installed
- **wrk2** - Will be built from source and installed (automatically renamed from `wrk` to `wrk2`)
- **Build tools** - Will be installed automatically if needed (`make`, `gcc`, `git`, `build-essential`)

## Can be installed manually or using `install_java_docker.sh`:
- **Java/GraalVM** - JAVA_HOME environment variable must be set
  - For **JVM mode**: Requires a JVM with `java` executable
  - For **native mode**: Requires GraalVM with `native-image` tool
  - The `install_prerequisites.sh` script only checks for Java/GraalVM and provides setup instructions
  - **Automated installation**: Run `./install_java_docker.sh` to install GraalVM automatically
  - **Manual installation**: Download from https://www.graalvm.org/downloads/ or install OpenJDK
- **Docker** (optional) - Required only for running containerized benchmarks
  - **Automated installation**: Run `./install_java_docker.sh` to install Docker automatically
  - **Manual installation**: Install from https://docs.docker.com/get-docker/

# Installing Prerequisites

Before running the barista benchmark scripts, you need to install the required prerequisites. Automated installation scripts are provided:

## Install Java/GraalVM and Docker

To install Java/GraalVM (with native-image support) and Docker:

```bash
# Install both Java/GraalVM and Docker
./install_java_docker.sh

# Install only Java/GraalVM
./install_java_docker.sh --skip-docker

# Install only Docker
./install_java_docker.sh --skip-java

# Show help
./install_java_docker.sh --help
```

This script will:
- Download and install GraalVM Community Edition (includes native-image)
- Set JAVA_HOME in your `~/.bashrc`
- Install Docker Engine and related tools
- Add your user to the docker group
- Start and enable Docker service

**Note**: After installation, you may need to:
- Run `source ~/.bashrc` or start a new shell for JAVA_HOME to take effect
- Log out and log back in (or run `newgrp docker`) to use Docker without sudo

## Install Other Prerequisites

To install Python 3, wrk, and wrk2:

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
(cd ./barista/benchmarks/micronaut-shopcart/ && ./build.sh) 
./run_shopcart_benchmark.sh 5 --mode native
./run_shopcart_benchmark.sh 5 --mode jvm
(cd ./barista/benchmarks/spring-petclinic/ && ./build.sh) 
./run_petclinic_benchmark.sh 5 --mode native
./run_petclinic_benchmark.sh 5 --mode jvm
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