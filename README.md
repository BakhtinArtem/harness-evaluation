# Media Microservices wrk2 Testing

Simple script to run performance tests against DeathStarBench Media Microservices.

## Prerequisites

- Docker and Docker Compose
- Port 8080 available

## Usage

```bash
./run_wrk2_media.sh
```

The script will:
1. Start all media microservices using docker-compose
2. Wait for services to be ready
3. Build wrk2 if needed
4. Run wrk2 100 times against the media microservices

## What it does

- Starts services from `DeathStarBench/mediaMicroservices/docker-compose.yml`
- Uses wrk2 script from `DeathStarBench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua`
- Runs 100 iterations with:
  - 2 threads
  - 100 connections
  - 30 second duration per iteration
  - 1000 requests per second

## Stopping Services

To stop the services after testing:

```bash
cd DeathStarBench/mediaMicroservices
docker-compose down
```

