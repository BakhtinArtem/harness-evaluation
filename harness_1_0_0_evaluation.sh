docker pull aape2k/workload-generator
docker pull aape2k/shopcart-jvm:1.0.0
docker pull aape2k/shopcart-native:1.0.0
docker pull aape2k/petclinic-jvm:1.0.0
docker pull aape2k/petclinic-native:1.0.0

for i in {1..5}; do
#   serverless-benchmarking-release-1_0_0/slsbench_1_0_0 --config-path $(pwd)/serverless-benchmarking-release-1_0_0/configs/micronaut-jvm-g1gc.json
#   serverless-benchmarking-release-1_0_0/slsbench_1_0_0 --config-path $(pwd)/serverless-benchmarking-release-1_0_0/configs/micronaut-jvm-shenandoah.json
#   serverless-benchmarking-release-1_0_0/slsbench_1_0_0 --config-path $(pwd)/serverless-benchmarking-release-1_0_0/configs/micronaut-native.json
  serverless-benchmarking-release-1_0_0/slsbench_1_0_0 --config-path $(pwd)/serverless-benchmarking-release-1_0_0/configs/petclinic-jvm-g1gc.json
  serverless-benchmarking-release-1_0_0/slsbench_1_0_0 --config-path $(pwd)/serverless-benchmarking-release-1_0_0/configs/petclinic-jvm-shenandoah.json
  serverless-benchmarking-release-1_0_0/slsbench_1_0_0 --config-path $(pwd)/serverless-benchmarking-release-1_0_0/configs/petclinic-native.json
done