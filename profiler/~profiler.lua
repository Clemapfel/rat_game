local profiler = {}
profiler._jit = require("jit.profile")
profiler._socket = require "socket"
profiler._run_i = 1
profiler._is_running = false
profiler._current_zone = nil
profiler._data = {} -- cf. profiler.start for layout

assert(profiler._jit ~= nil, "[FATAL] In profiler/profiler.lua: `jit.profile` not available, make sure you are running this file using luajit")
assert(profiler._socket ~= nil, "[FATAL] In profiler/profiler.lua: `socket` not found, make sure you are using Love2D")

--- @brief [internal] get timestamp with nanosecond precision
function profiler._get_time()
    return profiler._socket.gettime()
end

--- @class profiler.VMState
profiler.VMState = {
    COMPILED_CODE = "N",
    INTERPRETED_CODE = "I",
    C_CODE = "C",
    GARBAGE_COLLECTION = "G",
    JIT_COMPILER = "J"
}

do
    local _infinity = 1 / 0
    local _valid_vm_states = {
        [profiler.VMState.INTERPRETED_CODE] = true,
        [profiler.VMState.COMPILED_CODE] = true,
        [profiler.VMState.C_CODE] = true,
        [profiler.VMState.GARBAGE_COLLECTION] = true,
        [profiler.VMState.JIT_COMPILER] = false
    }
    local _format = "pl|fZ;" -- <path>:<line_number> <function_name>;

    --- @brief [internal]
    profiler._sampling_callback = function(thread, n_samples, vmstate)
        local data = profiler._data[profiler._current_zone]
        data.n_stacks = data.n_stacks + 1
        table.insert(data.stacks, profiler._jit.dumpstack(thread, _format, _infinity))
        table.insert(data.times, profiler._get_time())
        table.insert(data.vmstate, vmstate)
    end
end

--- @brief
--- @param name String name of zone
--- @param mode profiler.SamplingMode mode
function profiler.start(name)
    if profiler._is_running then
        error("In profiler.start: profiler is already running, zone `" .. profiler._current_zone .. "` is active")
    end

    if name == nil then
        name = "Zone #" .. profiler._run_i
        profiler._run_i = profiler._run_i + 1
    end
    assert(type(name) == "string", "In profiler.start: name `" .. tostring(name) .. "` is not a string")

    profiler._is_running = true
    profiler._current_zone = name

    if profiler._data[name] ~= nil then
        error("In profiler.start: zone name `" .. name .. "` was already used, each zone name has to be unique")
    end

    profiler._data[name] = {
        zone = name,
        start_time = profiler._get_time(),
        end_time = 0,
        n_stacks = 0,
        stacks = {},
        times = {},
        vmstate = {}
    }
    profiler._data[name].start_time = profiler._get_time()
    profiler._jit.start("i0", profiler._sampling_callback) -- i0 = highest resolution sampling possible
end

--- @brief
function profiler.stop()
    if profiler._is_running then
        profiler._jit.stop()
        local data = profiler._data[profiler._current_zone]
        if data ~= nil then
            data.end_time = profiler._get_time()
        end
        profiler._is_running = false
    end
end

--- @brief
--- @param name String? name of zone, if not specified, dumps all information collected so far
function profiler.report(name, shorten_callback)
    if name == nil then name = profiler._current_zone end
    if shorten_callback == nil then shorten_callback = 3 end -- infinity

    if name == nil or profiler._data[name] == nil then
        io.write(io.stderr, "[WARNING] In profiler.report: no zone with name `" .. name .. "`, returning no data")
        return {}
    end

    local vmstate_to_label = {
        [profiler.VMState.INTERPRETED_CODE] = "INTERPRETED",
        [profiler.VMState.COMPILED_CODE] = "COMPILED",
        [profiler.VMState.C_CODE] = "C CODE",
        [profiler.VMState.GARBAGE_COLLECTION] = "GC",
        [profiler.VMState.JIT_COMPILER] = "JIT COMPILATION"
    }

    local data = profiler._data[name]

    local callstacks = {}
    local names = data.stacks
    local durations = {}
    local types = {}
    local percentages = {}
    local last_duration = data.start_time
    local total_duration = data.end_time - data.start_time

    for i = 1, data.n_stacks do
        -- sanitize durations
        local duration = data.times[i] - last_duration
        local duration_ms = duration * 1000
        durations[i] = tostring(math.floor(duration_ms * 10e4) / 10e4)

        -- sanitize percentage
        local fraction = duration / total_duration
        local fraction_percentage = math.floor(fraction * 10e5) / 10e5 * 100
        local percentage_prefix = ""
        if fraction_percentage < 10 then
            percentage_prefix = "0"
        end

        percentages[i] = percentage_prefix .. tostring(fraction_percentage)

        types[i] = vmstate_to_label[data.vmstate[i]]
        last_duration = data.times[i]
    end

    for i = 1, data.n_stacks do
        dbg(durations[i], names[i])
    end

    return
end

--- @brief
function profiler.is_running()
    return profiler._is_running
end

--- @brief
function profiler.free_zone(name)
    if profiler._current_zone == name then
        if profiler._is_running then
            io.write(io.stderr, "[WARNING] In profiler.free_zone: attempint to free zone `" .. name .. "` but it is currently active and profiling. No operation will be performed.")
            return
        end
        profiler._current_zone = nil
    end

    profiler._data[name] = nil
    collectgarbage("collect")
end

return profiler