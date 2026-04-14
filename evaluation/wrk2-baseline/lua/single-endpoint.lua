-- Hit a single GET endpoint repeatedly.
-- The purest microbenchmark: measures one endpoint in isolation.
-- Demonstrates wrk2's blind spot -- no per-operation breakdown,
-- no inter-step dependency visibility, no flow context.
--
-- Usage:  wrk2 -s single-endpoint.lua -t2 -c5 -d30s -R200 --latency http://host:port
-- Set BASE_PATH env var for the API prefix (default: /api).

local base = os.getenv("BASE_PATH") or "/api"

request = function()
    return wrk.format("GET", base .. "/owners")
end
