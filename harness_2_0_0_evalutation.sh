#pull images before
docker pull aape2k/workload-generator-sessions:latest
docker pull aape2k/shopcart-native:latest
docker pull aape2k/shopcart-jvm:latest
docker pull aape2k/petclinic-native:latest
docker pull aape2k/petclinic-jvm:latest

# for i in {1..5}; do
#   serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
#     -d $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/docker-compose-shopcart-jvm-g1gc.yml \
#     -c /app/logs -p 8001 -r $(pwd)/results-shopcart-harness_2_0_0-jvm-g1gc-run \
#     -s $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/scenario.json -n shopcart \
#     -w "-t16 -c16 -d30s -R800"
# done

# for i in {1..5}; do
#   serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
#     -d $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/docker-compose-shopcart-jvm-shenandoah.yml \
#     -c /app/logs -p 8001 -r $(pwd)/results-shopcart-harness_2_0_0-jvm-shenandoah-run \
#     -s $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/scenario.json -n shopcart \
#     -w "-t16 -c16 -d30s -R800"
# done

# for i in {1..5}; do
#   serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
#     -d $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/docker-compose-shopcart-native.yml \
#     -c /app/logs -p 8001 -r $(pwd)/results-shopcart-harness_2_0_0-native-run \
#     -s $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/scenario.json -n shopcart \
#     -w "-t16 -c16 -d30s -R800"
# done

for i in {1..5}; do
    serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
        -d $(pwd)/serverless-benchmarking-release-2_0_0/petclinic/docker-compose-petclinic-jvm-g1gc.yml \
        -c /app/logs -p 8006 -r $(pwd)/results-petclinic-harness_2_0_0-jvm-g1gc-run \
        -s $(pwd)/serverless-benchmarking-release-2_0_0/petclinic/scenario.json -n petclinic \
        -w "-t16 -c16 -d30s -R3000"
done

for i in {1..5}; do
    serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
        -d $(pwd)/serverless-benchmarking-release-2_0_0/petclinic/docker-compose-petclinic-jvm-shenandoah.yml \
        -c /app/logs -p 8006 -r $(pwd)/results-petclinic-harness_2_0_0-jvm-shenandoah-run \
        -s $(pwd)/serverless-benchmarking-release-2_0_0/petclinic/scenario.json -n petclinic \
        -w "-t16 -c16 -d30s -R3000"
done

# for i in {1..5}; do
#     serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
#         -d $(pwd)/serverless-benchmarking-release-2_0_0/petclinic/docker-compose-petclinic-native.yml \
#         -c /app/logs -p 8006 -r $(pwd)/results-petclinic-harness_2_0_0-native-run \
#         -s $(pwd)/serverless-benchmarking-release-2_0_0/petclinic/scenario.json -n petclinic \
#         -w "-t16 -c16 -d30s -R3000"
# done

for i in {1..5}; do
        serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
                -d $(pwd)/serverless-benchmarking-release-2_0_0/media/docker-compose.yml \
                -c /app/logs -p 8080 -r $(pwd)/results-media-harness_2_0_0-run \
                -s $(pwd)/serverless-benchmarking-release-2_0_0/media/scenario.json -n nginx-web-server \
                -w "-t16 -c16 -d30s -R800"
done