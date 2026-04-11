-- Round-robin GET requests across list endpoints.
-- Simulates a read-heavy microbenchmark without stateful chaining.
--
-- Usage:  wrk2 -s read-list.lua -t2 -c5 -d30s -R200 --latency http://host:port
-- Set BASE_PATH env var for the API prefix (default: /api).

local base = os.getenv("BASE_PATH") or "/api"

local endpoints = {
    base .. "/owners",
    base .. "/pets",
    base .. "/vets",
    base .. "/pettypes",
    base .. "/specialties",
    base .. "/visits",
}

local counter = 0

request = function()
    counter = counter + 1
    local idx = (counter % #endpoints) + 1
    return wrk.format("GET", endpoints[idx])
end
