local profiler = {}
profiler._jit = require("jit.profile")

profiler._run_i = 1
profiler._is_running = false


profiler._data = {}
profiler.n_samples = 0

profiler._zone_name_to_index = {}
profiler._zone_index_to_name = {}
profiler._zone_index = 1
profiler._current_zone_stack = {}
profiler._n_zones = 0

--- @brief [internal]
do
    local _infinity = 1 / 0
    local _format = "f@plZ;" -- <path>:<line_number> <function_name>;
    profiler._sampling_callback = function(thread, n_samples, vmstate)
        local zones = {}
        for i = 1, profiler._n_zones do
            table.insert(zones, profiler._current_zone_stack[i])
        end

        local data = {}
        for _ = 1, n_samples do
            data.callstack = profiler._jit.dumpstack(thread, _format, _infinity)
            data.zones = zones
            table.insert(profiler._data, data)
        end

        table.insert(profiler._data, data)
        profiler.n_samples = profiler.n_samples + n_samples
    end
end

--- @brief
function profiler.push(name)
    if name == nil then
        name = "Run #" .. profiler._run_i
        profiler._run_i = profiler._run_i + 1
    end

    assert(type(name) == "string")

    local zone_index = profiler._zone_name_to_index[name]
    if zone_index == nil then
        zone_index = profiler._zone_index
        profiler._zone_index = profiler._zone_index + 1

        profiler._zone_name_to_index[name] = zone_index
        profiler._zone_index_to_name[zone_index] = name
    end

    table.insert(profiler._current_zone_stack, zone_index)
    profiler._n_zones = profiler._n_zones + 1

    if profiler._is_running == false then
        profiler._is_running = true
        profiler._jit.start("i0", profiler._sampling_callback)
    end
end

--- @brief
function profiler.pop()
    if profiler._n_zones >= 1 then
        table.remove(profiler._current_zone_stack, profiler._n_zones)
        profiler._n_zones = profiler._n_zones - 1

        if profiler._n_zones == 0 then
            profiler._jit.stop()
        end
    end
end

---- @brief [internal]
function profiler._format_callstack(stack)
    return stack
end

--- @brief
function profiler.report()
    if #profiler._data == 0 then return end

    local all_zones = {}

    -- organize by zone
    local zone_to_callback_counts = {}
    local zone_to_total_count = {}
    for _, data in pairs(profiler._data) do
        for _, zone_i in pairs(data.zones) do
            local zone_name = profiler._zone_index_to_name[zone_i]
            all_zones[zone_name] = true

            local callstack = data.callstack
            local callback_counts = zone_to_callback_counts[zone_name]
            if callback_counts == nil then
                zone_to_callback_counts[zone_name] = {
                    [callstack] = 1
                }
            else
                if callback_counts[callstack] == nil then
                    callback_counts[callstack] = 1
                else
                    callback_counts[callstack] = callback_counts[callstack] + 1
                end
            end

            if zone_to_total_count[zone_name] == nil then
                zone_to_total_count[zone_name] = 1
            else
                zone_to_total_count[zone_name] = zone_to_total_count[zone_name] + 1
            end
        end
    end

    local stack_depth = 3
    local percentage_cutoff = 0.1

    for zone, _ in pairs(all_zones) do
        local names = {}
        local paths = {}
        local counts = {}
        local percentages = {}
        local n_rows = 0

        local splits = {}
        local split_to_split_count = {}

        local total_count = 0
        for callstack, count in pairs(zone_to_callback_counts[zone]) do
            local to_insert = {}
            for word in string.gmatch(callstack, "([^;]+)") do
                table.insert(to_insert, word)
                if split_to_split_count[word] == nil then
                    split_to_split_count[word] = 1
                else
                    split_to_split_count[word] = split_to_split_count[word] + 1
                end
            end

            table.insert(splits, to_insert)

            table.insert(counts, count)
            total_count = total_count + count
            n_rows = n_rows + 1
        end

        -- filter common prefixes
        for row_i = 1, n_rows do
            local split = splits[row_i]
            local to_skip = 0
            for i = 1, #split do
                if split_to_split_count[split[i]] >= n_rows then
                    to_skip = to_skip + 1
                else
                    break
                end
            end

            local path = {}
            for i = math.max(to_skip, #split - stack_depth), #split do
                table.insert(path, split[i])
            end

            table.insert(names, split[#split])
            table.remove(split, #split)
            table.insert(paths, table.concat(path, " > "))
            table.insert(percentages, math.floor(counts[row_i] / total_count * 10e3) / 10e3 * 100)
        end

        local indices_in_order = {}
        for i = 1, n_rows do table.insert(indices_in_order, i) end
        table.sort(indices_in_order, function(a_i, b_i)
            return counts[a_i] > counts[b_i]
        end)

        local col_width = {}
        local columns = {
            {"Percentage %", percentages },
            {"Samples", counts },
            {"Name", names },
            {"Callstack", paths}
        }

        local col_lenghts = {}
        for _, header_values in pairs(columns) do

        end

        local str = {zone .. " (" .. total_count .. " samples)" .. ":\n"}
        for _, row_i in pairs(indices_in_order) do
            if percentages[row_i] < percentage_cutoff then break end

            table.insert(str, "\t" .. percentages[row_i])
            table.insert(str, "\t" .. counts[row_i])
            table.insert(str, "\t\t" .. names[row_i])
            table.insert(str, "\t" .. paths[row_i])
            table.insert(str, "\n")
        end
        table.insert(str, "\n")

        dbg(table.concat(str, ""))
    end
end

return profiler


