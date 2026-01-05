# Running Harness 2.0.0

To recreate barista benhcmarking execute following script `./harness_2_0_0_evaluation.sh`.
More info on running info can be found [in this file](HARNESS_2_0_0_BENCHMARKING.md).

To run Harness 2.0.0:

1. First, enrich all OpenAPI specifications.
2. Next, extract the initial scenario intention.
3. Finally, use these to create a real scenario in Harness 2.0.0.

## Enriching and generating scenarios

First and second step are mannual. You can use already prepared `scenario.json`
for each benchmark and skip this step or enrich all specifications mannualy by
executing following script: 

```bash
# enriching micronaut
./serverless-benchmarking-release-2_0_0/slsbench_2_0_0 enrich --specification-path \
./serverless-benchmarking-release-2_0_0/micronaut/openapi.yaml  --output-path \
./serverless-benchmarking-release-2_0_0/micronaut/
# enriching petclinic
./serverless-benchmarking-release-2_0_0/slsbench_2_0_0 enrich --specification-path \
./serverless-benchmarking-release-2_0_0/petclinic/openapi.yaml  --output-path \
./serverless-benchmarking-release-2_0_0/petclinic/
# enriching media
./serverless-benchmarking-release-2_0_0/slsbench_2_0_0 enrich --specification-path \
./serverless-benchmarking-release-2_0_0/media/openapi.yaml  --output-path \
./serverless-benchmarking-release-2_0_0/media/
```

Next create scenario simmular to
`barista/benchmarks/*/workloads/mixed-requests.lua` for barista and 
`DeathStarBench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua`

```bash
# scenario micronaut
./serverless-benchmarking-release-2_0_0/slsbench_2_0_0 scenario --enriched-specification-path \
./serverless-benchmarking-release-2_0_0/micronaut/enriched-spec.yaml  --output-path \
./serverless-benchmarking-release-2_0_0/micronaut/
# scenario petclinic
./serverless-benchmarking-release-2_0_0/slsbench_2_0_0 scenario --enriched-specification-path \
./serverless-benchmarking-release-2_0_0/petclinic/enriched-spec.yaml  --output-path \
./serverless-benchmarking-release-2_0_0/petclinic/
# scenario media
./serverless-benchmarking-release-2_0_0/slsbench_2_0_0 scenario --enriched-specification-path \
./serverless-benchmarking-release-2_0_0/media/enriched-spec.yaml  --output-path \
./serverless-benchmarking-release-2_0_0/media/
```

Bellow is output of scenario cli for each benchmark:

```bash
# shopcart graph
Finished building scenario graph.

========== SCENARIO GRAPH ==========

--- VERTICES ---
  [6] GET /cart/{cid} [200]
  [7] DELETE /cart [200]
  [0] POST / [200]
  [1] POST /cart [200]
  [2] POST /cart [200]
  [3] POST /cart [200]
  [4] POST /cart [200]
  [5] POST /cart [200]

--- EDGES ---
  [0] POST / [200] -> [1] POST /cart [200]
    Mappings:
      body.username -> body.username
  [0] POST / [200] -> [2] POST /cart [200]
    Mappings:
      body.username -> body.username
  [0] POST / [200] -> [3] POST /cart [200]
    Mappings:
      body.username -> body.username
  [0] POST / [200] -> [4] POST /cart [200]
    Mappings:
      body.username -> body.username
  [0] POST / [200] -> [5] POST /cart [200]
    Mappings:
      body.username -> body.username
  [1] POST /cart [200] -> [6] GET /cart/{cid} [200]
    Mappings:
      body.username -> path.cid
  [2] POST /cart [200] -> [6] GET /cart/{cid} [200]
  [3] POST /cart [200] -> [6] GET /cart/{cid} [200]
  [4] POST /cart [200] -> [6] GET /cart/{cid} [200]
  [5] POST /cart [200] -> [6] GET /cart/{cid} [200]
  [6] GET /cart/{cid} [200] -> [7] DELETE /{cid} [200]
    Mappings:
      path.cid -> path.cid
=====================================
2026/01/05 11:55:10 Topological order of endpoints:
2026/01/05 11:55:10   1. [0] POST / [200]
2026/01/05 11:55:10   2. [1] POST /cart [200]
2026/01/05 11:55:10   3. [2] POST /cart [200]
2026/01/05 11:55:10   4. [3] POST /cart [200]
2026/01/05 11:55:10   5. [4] POST /cart [200]
2026/01/05 11:55:10   6. [5] POST /cart [200]
2026/01/05 11:55:10   7. [6] GET /cart/{cid} [200]
2026/01/05 11:55:10   8. [7] DELETE /{cid} [200]
#petclinic graph
Finished building scenario graph.

========== SCENARIO GRAPH ==========

--- VERTICES ---
  [4] GET /owners [200]
  [5] POST /owners/{ownerId}/edit [200]
  [6] POST /owners/{ownerId}/pets/{petId}/edit [200]
  [0] POST /owners/new [200]
  [1] POST /owners/{ownerId}/pets/new [200]
  [2] GET /owners [200]
  [3] POST /owners/{ownerId}/pets/{petId}/visits/new [200]

--- EDGES ---
  [0] POST /owners/new [200] -> [1] POST /owners/{ownerId}/pets/new [200]
    Mappings:
      body.firstName -> body.name
  [1] POST /owners/{ownerId}/pets/new [200] -> [2] GET /owners [200]
  [2] GET /owners [200] -> [3] POST /owners/{ownerId}/pets/{petId}/visits/new [200]
  [3] POST /owners/{ownerId}/pets/{petId}/visits/new [200] -> [4] GET /owners [200]
  [4] GET /owners [200] -> [5] POST /owners/{ownerId}/edit [200]
  [5] POST /owners/{ownerId}/edit [200] -> [6] POST /owners/{ownerId}/pets/{petId}/edit [200]
=====================================
2026/01/05 17:46:10 Topological order of endpoints:
2026/01/05 17:46:10   1. [0] POST /owners/new [200]
2026/01/05 17:46:10   2. [1] POST /owners/{ownerId}/pets/new [200]
2026/01/05 17:46:10   3. [2] GET /owners [200]
2026/01/05 17:46:10   4. [3] POST /owners/{ownerId}/pets/{petId}/visits/new [200]
2026/01/05 17:46:10   5. [4] GET /owners [200]
2026/01/05 17:46:10   6. [5] POST /owners/{ownerId}/edit [200]
2026/01/05 17:46:10   7. [6] POST /owners/{ownerId}/pets/{petId}/edit [200]
#media graph
Finished building scenario graph.

========== SCENARIO GRAPH ==========

--- VERTICES ---
  [0] POST /wrk2-api/user/register [200]
  [1] POST /wrk2-api/movie/register [200]
  [2] POST /wrk2-api/movie-info/write [200]
  [3] POST /wrk2-api/review/compose [200]

--- EDGES ---
  [1] POST /wrk2-api/movie/register [200] -> [2] POST /wrk2-api/movie-info/write [200]
    Mappings:
      body.movie_id -> body.movie_id
  [2] POST /wrk2-api/movie-info/write [200] -> [3] POST /wrk2-api/review/compose [200]
    Mappings:
      body.title -> body.title
  [0] POST /wrk2-api/user/register [200] -> [3] POST /wrk2-api/review/compose [200]
    Mappings:
      body.username -> body.username
      body.password -> body.password
=====================================
2026/01/05 21:11:40 Topological order of endpoints:
2026/01/05 21:11:40   1. [0] POST /wrk2-api/user/register [200]
2026/01/05 21:11:40   2. [1] POST /wrk2-api/movie/register [200]
2026/01/05 21:11:40   3. [2] POST /wrk2-api/movie-info/write [200]
2026/01/05 21:11:40   4. [3] POST /wrk2-api/review/compose [200]
```
Next step is actually running harness:

```bash
#pull images before
docker pull aape2k/workload-generator-sessions:latest
docker pull aape2k/shopcart-native:latest
docker pull aape2k/shopcart-jvm:latest
docker pull aape2k/petclinic-native:latest
docker pull aape2k/petclinic-jvm:latest

for i in {1..5}; do
  serverless-benchmarking-release-2_0_0/slsbench_2_0_0 harness \
    -d $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/docker-compose-jvm.yml \
    -c /app/logs -p 8001 -r $(pwd)/results-shopcart-harness_2_0_0-jvm-run${i} \
    -s $(pwd)/serverless-benchmarking-release-2_0_0/micronaut/scenario.json -n shopcart \
    -w "-t16 -c16 -d30s -R800"
done
```
