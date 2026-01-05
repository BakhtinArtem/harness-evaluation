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