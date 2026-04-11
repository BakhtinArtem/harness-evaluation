-- Interleaved CRUD requests using fixed/pre-seeded IDs.
-- This is the closest wrk2 can get to a mixed scenario without stateful chaining.
-- It illustrates the limitation: IDs are hardcoded, not derived from responses.
--
-- Usage:  wrk2 -s mixed-crud.lua -t2 -c5 -d30s -R200 --latency http://host:port
-- Set BASE_PATH env var for the API prefix (default: /api).

local base = os.getenv("BASE_PATH") or "/api"
local json_ct = {["Content-Type"] = "application/json"}

local counter = 0

local actions = {
    function()
        return wrk.format("GET", base .. "/owners")
    end,
    function()
        counter = counter + 1
        local body = string.format(
            '{"firstName":"Mix%d","lastName":"Test%d","address":"%d Elm St","city":"Bench","telephone":"%010d"}',
            counter, counter, counter, counter % 10000000000
        )
        return wrk.format("POST", base .. "/owners", json_ct, body)
    end,
    function()
        return wrk.format("GET", base .. "/owners/1")
    end,
    function()
        local body = '{"firstName":"Updated","lastName":"Owner","address":"1 New St","city":"Changed","telephone":"1234567890"}'
        return wrk.format("PUT", base .. "/owners/1", json_ct, body)
    end,
    function()
        return wrk.format("GET", base .. "/vets")
    end,
    function()
        return wrk.format("GET", base .. "/pettypes")
    end,
    function()
        counter = counter + 1
        local body = string.format('{"name":"type%d"}', counter)
        return wrk.format("POST", base .. "/pettypes", json_ct, body)
    end,
    function()
        return wrk.format("GET", base .. "/specialties")
    end,
}

request = function()
    counter = counter + 1
    local idx = (counter % #actions) + 1
    return actions[idx]()
end
