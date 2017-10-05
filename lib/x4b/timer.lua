local _VERSION = '1.0.0'
local M = {}
local os = require "os"
local math = require "math"
local stagger

local timer_at
local function handle_timer(premature, dofunc, time, name, ...)
    local sched = dofunc(premature, ...)

    if not premature and not sched then
        timer_at(time, time, dofunc, name, ...)
    end

    if ngx.shared.timers then
        ngx.shared.timers:set(name, ngx.now(), 1200)
    end
end

timer_at = function (nexttime, time, dofunc, name, ...)
    local ok, err = ngx.timer.at(nexttime, handle_timer, dofunc, time, name, ...)

    if not ok then
        ngx.log(ngx.ERR, "failed to create " .. (name or "un-named") .. " timer: ", err)
        return
    end
end
M.at = timer_at

function M.repeatat(time, dofunc, name)
    if not stagger then
        math.randomseed((os.time() * ngx.worker.pid()) % 4294967295)
        stagger = math.random()
    end
    timer_at(time + (stagger * time), time, dofunc, (name or "un-named"))
end

if ngx.shared.timers then
    function M.get_timers()
        local timers = {}

        local keys = ngx.shared.timers:get_keys()
        for i = 1, #keys do
            local key = keys[i]
            timers[key] = ngx.shared.timers:get(key)
        end

        return timers
    end
end

return M