local profiler = {}
profiler._jit = require("jit.profile")
profiler._socket = require("socket")
profiler._run_i = 1
profiler._is_running = false


profiler._data = {}
profiler.n_samples = 0

profiler._zone_name_to_index = {}
profiler._zone_index_to_name = {}
profiler._zone_index = 1
profiler._current_zone_stack = {}
profiler._n_zones = 0
profiler._start_time = 0
profiler._start_date = nil

--- @brief [internal]
do
    local _infinity = 1 / 0
    local _format = "f @ plZ;" -- <function_name> @ <file>:<line>;
    profiler._sampling_callback = function(thread, n_samples, vmstate)
        local zones = {}
        for i = 1, profiler._n_zones do
            table.insert(zones, profiler._current_zone_stack[i])
        end

        local data = {}
        for _ = 1, n_samples do
            data.callstack = profiler._jit.dumpstack(thread, _format, _infinity)
            data.zones = zones
            data.vmstate = vmstate
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
        profiler._start_time = profiler._socket.gettime()
        profiler._start_date = os.date("%c")
    end
end

--- @brief
function profiler.pop()
    if profiler._n_zones >= 1 then
        table.remove(profiler._current_zone_stack, profiler._n_zones)
        profiler._n_zones = profiler._n_zones - 1

        if profiler._n_zones == 0 then
            --profiler._jit.stop()
        end
    end
end

--- @brief [internal]
function profiler._format_percentage(fraction)
    return clamp(math.floor(fraction * 10e3) / 10e3 * 100, 0, 100)
end

--- @brief
function profiler.report()
    if #profiler._data == 0 then return end
    local zone_data = {}
    for _, data in pairs(profiler._data) do
        for _, zone_i in pairs(data.zones) do
            local zone_name = profiler._zone_index_to_name[zone_i]
            local zone = zone_data[zone_name]
            if zone == nil then
                zone = {
                    function_to_count = {},
                    function_to_percentage = {},
                    n_samples = 0,
                    n_gc_samples = 0,
                    n_jit_samples = 0,
                    n_interpreted_samples = 0,
                    n_compiled_samples = 0,
                    n_c_code_samples = 0
                }
                zone_data[zone_name] = zone
            end

            if data.vmstate == "N" then
                zone.n_compiled_samples = zone.n_compiled_samples + 1
            elseif data.vmstate == "I" then
                zone.n_interpreted_samples = zone.n_interpreted_samples + 1
            elseif data.vmstate == "C" then
                zone.n_c_code_samples = zone.n_c_code_samples + 1
            elseif data.vmstate == "J" then
                zone.n_jit_samples = zone.n_jit_samples + 1
            elseif data.vmstate == "G" then
                zone.n_gc_samples = zone.n_gc_samples + 1
            else
                error("In profiler.report: unhandled vmstate `" .. data.vmstate .. "`")
            end

            if data.vmstate == "N" or data.vmstate == "J" or data.vmstate == "C" then
                for split in string.gmatch(data.callstack, "([^;]+)") do -- split into individual function names
                    if zone.function_to_count[split] == nil then
                        zone.function_to_count[split] = 1
                    else
                        zone.function_to_count[split] = zone.function_to_count[split] + 1
                    end
                end
            end

            zone.n_samples = zone.n_samples + 1
        end
    end

    for zone_name, entry in pairs(zone_data) do
        local names_in_order = {}
        for name, count in pairs(entry.function_to_count) do
            entry.function_to_percentage[name] = profiler._format_percentage(count / entry.n_samples)
            entry.function_to_count[name] = clamp(entry.function_to_count[name], 0, entry.n_samples)
            -- percentage may be > if function name occurs twice in same callstack
            table.insert(names_in_order, name)
        end

        table.sort(names_in_order, function(a, b)
            return entry.function_to_count[a] > entry.function_to_count[b]
        end)

        local cutoff_n = 0
        local cutoff_sample_count = 0
        for _, name in pairs(names_in_order) do
            if entry.function_to_percentage[name] >= 0.1 then
                cutoff_n = cutoff_n + 1
            else
                cutoff_sample_count = cutoff_sample_count + entry.function_to_count[name]
            end
        end

        local col_width = {}
        local columns = {
            {"Percentage (%)", entry.function_to_percentage },
            {"# Samples", entry.function_to_count },
            {"Name", names_in_order },
        }

        local col_lengths = {}
        for i, _ in ipairs(columns) do col_lengths[i] = #columns[i][1] end

        for col_i, column in ipairs(columns) do
            for i, value in ipairs(column[2]) do
                col_lengths[col_i] = math.max(col_lengths[col_i],  #tostring(value))
            end
        end
        col_lengths[2] = math.max(col_lengths[2], #tostring(cutoff_sample_count))

        local header = {" | "}
        local sub_header = {" |-"}
        for col_i, col in ipairs(columns) do
            table.insert(header, col[1] .. string.rep(" ", col_lengths[col_i] - #col[1]))
            table.insert(sub_header, string.rep("-", col_lengths[col_i]))
            if col_i < sizeof(columns) then
                table.insert(header, " | ")
                table.insert(sub_header, "-|-")
            end
        end

        table.insert(header, " |")
        table.insert(sub_header, "-|")

        local gc_percentage = profiler._format_percentage(entry.n_gc_samples / entry.n_samples)
        local jit_percentage = profiler._format_percentage(entry.n_jit_samples / entry.n_samples)
        local c_percentage = profiler._format_percentage(entry.n_c_code_samples / (entry.n_interpreted_samples + entry.n_compiled_samples + entry.n_c_code_samples))
        local interpreted_percentage = profiler._format_percentage(entry.n_interpreted_samples / (entry.n_interpreted_samples + entry.n_compiled_samples))

        local duration = profiler._socket.gettime() - profiler._start_time
        local samples_per_second = math.round(entry.n_samples / duration)

        local str = {
            " | Zone `" .. zone_name .. "` (" .. entry.n_samples .. " samples | " .. samples_per_second .. " samples/s)\n",
            " | Ran for " .. duration .. "s on `" .. profiler._start_date .. "`\n",
            " | GC  : " .. gc_percentage .. " % (" .. entry.n_gc_samples .. ")\n",
            " | JIT : " .. jit_percentage .. " % (" .. entry.n_jit_samples .. ")\n",
            --" | Compiled / Interpreted Ratio : " .. interpreted_percentage / 100 .. " (" .. entry.n_compiled_samples  .. " / " .. entry.n_interpreted_samples .. ")\n",
            " |\n",
            table.concat(header, "") .. "\n",
            table.concat(sub_header, "") .. "\n"
        }

        local rows_printed = 0
        for _, name in pairs(names_in_order) do
            if rows_printed < cutoff_n then
                for col_i = 1, sizeof(columns) do
                    local value
                    if col_i == 3 then
                        value = name
                    else
                        value = tostring(columns[col_i][2][name])
                    end
                    value = value .. string.rep(" ", col_lengths[col_i] - #value)
                    table.insert(str, " | " .. value)
                end
                table.insert(str, " |\n")
            else
                local last_row_percentage = "< 0.1"--tostring(cutoff_total_percentage)
                local last_row = {" | "}
                table.insert(last_row,  last_row_percentage .. string.rep(" ", col_lengths[1] - #last_row_percentage) .. " | ")
                table.insert(last_row,tostring(cutoff_sample_count) .. string.rep(" ", col_lengths[2] - #tostring(cutoff_n_samples)) .. " | ")
                table.insert(last_row, "..." .. string.rep(" ", col_lengths[3] - #("...")) .. " |")
                table.insert(str, table.concat(last_row, ""))
                break
            end

            rows_printed = rows_printed + 1
        end

        table.insert(str, "\n")
        dbg(table.concat(str, ""))
    end
end

return profiler


