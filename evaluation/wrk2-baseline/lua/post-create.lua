-- POST /owners with unique payloads per request.
-- Simulates a write-heavy microbenchmark.
--
-- Usage:  wrk2 -s post-create.lua -t2 -c5 -d30s -R200 --latency http://host:port
-- Set BASE_PATH env var for the API prefix (default: /api).

local base = os.getenv("BASE_PATH") or "/api"
local counter = 0

request = function()
    counter = counter + 1
    local body = string.format(
        '{"firstName":"Bench%d","lastName":"User%d","address":"%d Main St","city":"TestCity","telephone":"%010d"}',
        counter, counter, counter, counter % 10000000000
    )
    return wrk.format("POST", base .. "/owners", {["Content-Type"] = "application/json"}, body)
end
