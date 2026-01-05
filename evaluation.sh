#!/bin/bash

# defualt barista
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