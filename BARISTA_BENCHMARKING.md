# Running Barista

To recreate barista benhcmarking execute following script './barista_evaluation.sh'

Barista can be benchmarked in two ways: using the default method or with 
dummy process simulation. 

## Deafult way

The following configuration shows the default settings
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
        ...
    }
}
```

Startup configuration remains unchanged. The warmup phase is disabled (set to zero)
in order to focus on measuring the time required for a serverless application to
scale up. The throughput phase is also set to zero, as it was previously measured
with an older version of wrk and overlaps with what the latency measurement—performed
with wrk2—now provides. Finally, latency_measuremnt remains default and it is
specific for each benchmark.

```bash
(cd ./barista/benchmarks/micronaut-shopcart/ && ./build.sh) 
./run_shopcart_benchmark.sh 5 --mode native
./run_shopcart_benchmark.sh 5 --mode jvm
(cd ./barista/benchmarks/spring-petclinic/ && ./build.sh) 
./run_petclinic_benchmark.sh 5 --mode native
./run_petclinic_benchmark.sh 5 --mode jvm
# WARNING: warning on quarkus side as NIB is stil experimental feature
# (cd ./barista/benchmarks/quarkus-tika/ && ./build.sh) 
# ./run_tika_benchmark.sh 5 --mode native
# ./run_tika_benchmark.sh 5 --mode jvm
```

## Process simulation

This mode contenerised barista with harness and additionaly runs dummy process
inside this container in order to simulate working processes on machine. Such
simulation shows how other runnning processes affects results of the
benchmarking.

```bash
# can be build or can be downloaded from register
# docker build -f Dockerfile.petclinic -t aape2k/petclinic-isolation-test:2.0.0 .
# docker build -f Dockerfile.shopcart -t aape2k/shopcart-isolation-test:2.0.0 .

docker run --rm \
  -e DUMMY_CPU_INTENSITY=0.8 \
  -e DUMMY_MEMORY_MB=200 \
  -v $(pwd)/results_shopcart-sim-native:/app/results-shopcart-native \
  aape2k/shopcart-isolation-test:2.0.0 5 --mode native

docker run --rm \
  -e DUMMY_CPU_INTENSITY=0.8 \
  -e DUMMY_MEMORY_MB=200 \
  -v $(pwd)/results_shopcart-sim-jvm:/app/results-shopcart-jvm \
  aape2k/shopcart-isolation-test:2.0.0 5 --mode jvm

docker run --rm \
  -e DUMMY_CPU_INTENSITY=0.8 \
  -e DUMMY_MEMORY_MB=200 \
  -v $(pwd)/results_petclinic-sim-native:/app/results-petclinic-native \
  aape2k/petclinic-isolation-test:2.0.0 5 --mode native

docker run --rm \
  -e DUMMY_CPU_INTENSITY=0.8 \
  -e DUMMY_MEMORY_MB=200 \
  -v $(pwd)/results_petclinic-sim-jvm:/app/results-petclinic-jvm \
  aape2k/petclinic-isolation-test:2.0.0 5 --mode jvm
```