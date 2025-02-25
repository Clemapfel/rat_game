profiler = {}

-- cf. https://luajit.org/ext_profiler.html
profiler._native = require "jit.profile"
profiler._precision = "i0" -- max resolution tick rate

--- @class profiler.VMState
profiler.VMState = meta.new_enum({
    NATIVE_CODE = "N",
    INTERPRETED_CODE = "I",
    C_CODE = "C",
    COLLECT_GARBAGE = "G",
    JIT_COMPILER = "J"
})

profiler._log_vm_state = {
    [profiler.VMState.NATIVE_CODE] = false,
    [profiler.VMState.INTERPRETED_CODE] = true,
    [profiler.VMState.C_CODE] = false,
    [profiler.VMState.COLLECT_GARBAGE] = false,
    [profiler.VMState.JIT_COMPILER] = false,
}

profiler._is_active = false
profiler._stacks = {}
profiler._clock_before = 0
profiler._stacktrace_reversed = false
profiler._delimiter = ";"
profiler._zone_stack = {} -- Stack<String>
profiler._stack_order_reversed = true

profiler._native_cb = function(thread, n_samples, state)
    local stackdepth
    if profiler._stacktrace_reversed == true then
        stackdepth = -1 * (1 / 0)   -- negative infinity
    else
        stackdepth = (1 / 0)        -- positive infinity
    end

    local now = love.timer.getTime()
    local zone = profiler.get_current_zone()
    if zone ~= nil then
        if profiler._stacks[zone] == nil then
            profiler._stacks[zone] = {}
        end

        local stack = profiler._native.dumpstack(thread, "pFZ" .. profiler._delimiter, stackdepth)
        table.insert(profiler._stacks[zone], {
            state,                          -- vm state
            now - profiler._clock_before,   -- time since last frame
            stack                           -- stackdump
        })
    end
    profiler._clock_before = love.timer.getTime()
end

--- @brief
function profiler.activate()
    profiler._is_active = true
    profiler._clock_before = love.timer.getTime()
    profiler._native.start(profiler._precision, profiler._native_cb)
end

--- @brief
function profiler.deactivate()
    profiler._native.stop()
    profiler._is_active = false
end

--- @brief
function profiler.get_is_active()
    return profiler._is_active
end

--- @brief
--- @return String (or nil, if no zone is active)
function profiler.get_current_zone()
    return profiler._zone_stack[#profiler._zone_stack]
end

--- @brief
function profiler.push(zone_name)
    if not type(zone_name) == "string" then
        error("[rt][ERROR] In profiler.push: for argument #1: expected `string`, got `" .. typeof(zone_name) .. "`")
        return
    end

    table.insert(profiler._zone_stack, zone_name)
end

--- @brief
function profiler.pop()
    if #profiler._zone_stack == 0 then
        error("[rt][ERROR] In profiler.pop: trying to pop profiler zone, but none is currently pushed")
        return
    end
    table.remove(profiler._zone_stack)
end

--- @brief
--- @param zone_name String (or nil, to dump all frames)
function profiler.dump(zone_name)
    local function dump_entry(entry)
        local vm_state = entry[1]
        local time_since_last_stack = entry[2]
        local dump = entry[3]

        if profiler._log_vm_state[vm_state] ~= nil then
            dbg(time_since_last_stack, string.split(dump, profiler._delimiter))
        end
    end

    if zone_name == nil then
        for zone, stack in pairs(profiler._stacks) do
            for _, entry in pairs(stack) do
                dump_entry(entry)
            end
        end
    else
        local stacks = profiler._stacks[zone_name]
        if stacks == nil then
            return
        end

        for _, entry in pairs(stacks) do
            dump_entry(entry)
        end
    end
end
