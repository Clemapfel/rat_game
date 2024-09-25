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
        if _valid_vm_states[vmstate] then
            local data = profiler._data[profiler._current_zone]
            data.n_stacks = data.n_stacks + 1
            table.insert(data.stacks, profiler._jit.dumpstack(thread, _format, _infinity))
            table.insert(data.times, profiler._get_time())
            table.insert(data.vmstate, vmstate)
        end
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

    -- eliminate redundant stack prefix
    do
        local splits = {}
        local min_n = POSITIVE_INFINITY
        local counts = {}
        for i = 1, data.n_stacks do
            local to_push = {}
            for part, _ in string.gmatch(names[i], "([^".. ";" .."]+)") do -- split on ;
                table.insert(to_push, part)
                if counts[part] == nil then counts[part] = 0 end
                counts[part] = counts[part] + 1
            end
            if #to_push < min_n then min_n = #to_push end
            table.insert(splits, to_push)
        end

        for i = 1, data.n_stacks do
            local current_split = splits[i]
            local to_remove = {}
            for j = 1, #current_split do
                if counts[current_split[j]] >= data.n_stacks then
                    table.insert(to_remove, j)
                else
                    break
                end
            end

            table.sort(to_remove, function(a, b) return a > b end)
            for _, to_remove_i in pairs(to_remove) do
                table.remove(current_split, to_remove_i)
            end
        end

        for i = 1, data.n_stacks do
            local split = splits[i]
            names[i] = string.match(split[#split], ".*|(.*)$") -- everything after last |

            local callstack = {}

            for split_i = math.max(#split - shorten_callback + 1, 1), #split do
                local element = split[split_i]
                local sep_i = string.find(element, "|")
                table.insert(callstack, string.sub(element, sep_i+1, #element) .. "@" .. string.sub(element, 1, sep_i-1))
            end
            callstacks[i] = table.concat(callstack, " > ")
        end
    end

    -- calculate per-row width and format as string
    local rows = {
        names,
        percentages,
        durations,
        --types,
        callstacks
    }

    local row_headers = {
        "Name",
        "Percentage (%)",
        "Duration (ms)",
        --"Type",
        "Callstack (Last " .. shorten_callback .. ")"
    }

    local row_lengths = {}
    for row_i = 1, #rows do
        local row = rows[row_i]
        local row_length = #row_headers[row_i]
        for i = 1, data.n_stacks do
            row_length = math.max(row_length, #rows[row_i][i])
        end
        row_lengths[row_i] = row_length
    end

    local first_line =  {"| "}
    local second_line = {"|-"}
    for row_i = 1, #rows do
        local header = row_headers[row_i]
        table.insert(first_line, header .. string.rep(" ", row_lengths[row_i] - #header))
        table.insert(second_line, string.rep("-", row_lengths[row_i]))

        if row_i < #rows then
            table.insert(first_line, " | ")
            table.insert(second_line, "-|-")
        else
            table.insert(first_line, " |")
            table.insert(second_line, "-|")
        end
    end

    local lines = {
        table.concat(first_line, ""),
        table.concat(second_line, "")
    }

    local row_order = {}
    for i = 1, data.n_stacks do row_order[i] = i end
    table.sort(row_order, function(a_i, b_i)
        return durations[a_i] > durations[b_i]
    end)

    for _, line_i in pairs(row_order) do
        local line = {"| "}
        for row_i = 1, #rows do
            local value = rows[row_i][line_i]
            table.insert(line, value .. string.rep(" ", row_lengths[row_i] - #value))
            if row_i < #rows then
                table.insert(line, " | ")
            else
                table.insert(line, " |")
            end
        end
        table.insert(lines, table.concat(line, ""))
    end

   local out = "Total Duration: " .. total_duration * 1000 .. "ms\n" .. table.concat(lines, "\n")
    return out
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