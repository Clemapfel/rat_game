--- @brief print, arguments are concatenated
--- @param vararg any
--- @return nil
function print(...)

    local values = {...}
    if #values == 0 then
        io.write("nil")
        return
    end

    for _, v in pairs({...}) do
        io.write(tostring(v))
    end
end

--- @brief print, arguments are concatenade with a newline in between each
--- @param vararg any
--- @return nil
function println(...)

    local values = {...}
    if #values == 0 then
        io.write("nil")
        return
    end

    for _, v in pairs(values) do
        io.write(tostring(v))
    end

    io.write("\n")
    io.flush()
end

function dbg(...)
    for _, x in pairs({...}) do
        io.write(tostring(x))
        io.write(" ")
    end

    io.write("\n")
    io.flush()
end

--- @brief print to stderr
--- @param str string
function printerr(message)
    io.stderr:write(string.format("\27[38;5;9m%s\27[38;5;7m", message), "\n")
    io.stderr:flush()
end

--- @brief concatenate vararg into string
function paste(...)
    local values = {...}
    local out = {}
    for _, v in pairs(values) do
        table.insert(out, tostring(v))
    end
    return table.concat(out)
end

--- @brief get number of elements in arbitrary object
--- @param x any
--- @return number
function sizeof(x)
    if type(x) == "table" then
        local n = 0
        for _ in pairs(x) do
            n = n + 1
        end
        return n
    elseif type(x) == "string" then
        return #x
    elseif type(x) == "nil" then
        return 0
    else
        return 1
    end
end

--- @brief is table empty
--- @param x any
--- @return boolean
function is_empty(x)
    if type(x) ~= "table" then
        return true
    else
        return next(x) == nil
    end
end

--- @brief clamp
--- @param x number
--- @param lower_bound number
--- @param upper_bound number
--- @return number
function clamp(x, lower_bound, upper_bound)

    if type(lower_bound) == "nil" then lower_bound = NEGATIVE_INFINITY end
    if type(upper_bound) == "nil" then upper_bound = POSITIVE_INFINITY end

    if x < lower_bound then
        x = lower_bound
    end

    if x > upper_bound then
        x = upper_bound
    end

    return x
end

--- @brief TODO
function project(value, lower, upper)
    return value * math.abs(upper - lower) + math.min(lower, upper);
end

--- @brief linear interpolate between two values
--- @param lower number
--- @param upper number
--- @param ratio number in [0, 1]
--- @return number
function mix(lower, upper, ratio)
    -- @see https://registry.khronos.org/OpenGL-Refpages/gl4/html/mix.xhtml
    local x = math.min(lower, upper)
    local y = math.max(lower, upper)
    return x * (1 - ratio) + y * ratio
end

--- @brief ternary
--- @param condition boolean
--- @param if_true any returned if condition == true
--- @param if_false any return if condition == false
function ternary(condition, if_true, if_false)
    if condition == true then
        return if_true
    elseif condition == false then
        return if_false
    else
        error("In ternary: argument #1 does not evaluate to boolean")
    end
end

--- @brief get first value, or `if_nil` if first value is nil
--- @param value any
--- @param if_nil any
function which(value, if_nil)
    if value == nil then return if_nil else return value end
end

--- @brief try-catch
--- @param to_try function
--- @param on_fail function
function try_catch(to_try, on_fail)
    local status, out = pcall(to_try)
    if status == true then
        return out
    else
        if type(on_fail) == "nil" then
            return nil
        else
            return on_fail(out)
        end
    end
end

--- @brief invoke function with arguments
function invoke(f, ...)
    assert(type(f) == "function")
    f(...)
end

--- @brief expand table to tuple
function splat(t)
    if table.unpack == nil then
        assert(unpack ~= nil)
        return unpack(t)
    else
        return table.unpack(t)
    end
end

--- @brief wrap tuple in table
function slurp(...)
    return {...}
end

_G._select = _G.select

--- @brief get n-th element of varag, overrides _G.select
--- @param n number
--- @vararg
function select(n, ...)
    return ({...})[n]
end

--- @brief convert arbitrary object to string
--- @param id string
--- @param object any
--- @return string
function serialize(object_identifier, object, inject_sourcecode)

    if inject_sourcecode == nil then
        inject_sourcecode = false
    end

    local get_indent = function (n_indent_tabs)

        local tabspace = "    "
        local buffer = {""}

        for i = 1, n_indent_tabs do
            table.insert(buffer, tabspace)
        end

        return table.concat(buffer)
    end

    local insert = function (buffer, ...)

        for i, value in pairs({...}) do
            table.insert(buffer, value)
        end
    end

    local get_source_code = function (func)

        local info = debug.getinfo(func);

        if string.sub(info.source, 1, 1) ~= "@" then
            return "[" .. tostring(func) .. "]"
        end

        local file = io.open(string.sub(info.source, 2), "r");

        if file == nil then return "" end

        local str_buffer = {}
        local i = 1
        local end_i = 1

        local first_line = true
        local single_line_comment_active = false
        local multi_line_comment_active = false

        for line in file:lines("L") do

            if end_i == 0 then break end

            if (i >= info.linedefined) then

                if not first_line then

                    local first_word = true;
                    for word in line:gmatch("%g+") do

                        if string.find(word, "%-%-%[%[") then
                            multi_line_comment_active = true
                        elseif string.find(word, "%-%-]]") then
                            multi_line_comment_active = false
                        elseif string.find(word, "%-%-") then
                            single_line_comment_active = true
                        end

                        if not (single_line_comment_active or multi_line_comment_active) then

                            if word == "if" or word == "for" or word == "while" or word == "function" then
                                end_i = end_i + 1
                            elseif word == "do" and first_word then     -- do ... end block
                                end_i = end_i + 1
                            elseif word == "end" or word == "end," then
                                end_i = end_i - 1
                            end
                        end

                        first_word = false
                    end
                end

                table.insert(str_buffer, line)
                first_line = false
            end

            single_line_comment_active = false;
            i = i + 1
        end

        file:close()

        -- remove last newline
        local n = #str_buffer
        str_buffer[n] = string.sub(str_buffer[n], 1, string.len(str_buffer[n]) - 1)

        return table.concat(str_buffer)
    end

    serialize_inner = function (buffer, object, n_indent_tabs, seen)

        if type(object) == "number" then
            insert(buffer, object)

        elseif type(object) == "boolean" then
            if (object) then insert(buffer, "true") else insert(buffer, "false") end

        elseif type(object) == "string" then
            insert(buffer, string.format("%q", object))

        elseif type(object) == "table" then

            -- saveguard against cyclic tables
            if type(seen[object]) ~= "nil" then
                insert(buffer, " { ...")
                return
            end
            seen[object] = true

            if sizeof(object) > 0 then
                insert(buffer, "{\n")
                n_indent_tabs = n_indent_tabs + 1

                local n_entries = sizeof(object)
                local index = 0
                for key, value in pairs(object) do

                    if type(key) == "number" then

                        if key ~= index+1 then
                            insert(buffer, get_indent(n_indent_tabs), "[", key, "] = ")
                        else
                            insert(buffer, get_indent(n_indent_tabs))
                        end
                    else
                        insert(buffer, get_indent(n_indent_tabs), tostring(key), " = ")
                    end

                    serialize_inner(buffer, value, n_indent_tabs, seen)
                    index = index +1

                    if index < n_entries then
                        insert(buffer, ",\n")
                    else
                        insert(buffer, "\n")
                    end
                end

                insert(buffer, get_indent(n_indent_tabs-1), "}")
            else
                insert(buffer, "{}")
            end

        elseif type(object) == "function" and inject_sourcecode then
            insert(buffer, string.dump(object))
        elseif type(object) == "nil" then
            insert(buffer, "nil")
        else
            insert(buffer, "[" .. tostring(object) .. "]")
        end
    end

    if object == nil then
        return serialize("", object_identifier)
    end

    local buffer = {""}

    if object_identifier ~= "" then
        table.insert(buffer, object_identifier .. " = ")
    end

    local seen = {}
    serialize_inner(buffer, object, 0, seen)
    return table.concat(buffer, "")
end

--- @brief positive infinity
INFINITY = 1/0

--- @brief positive infinity
POSITIVE_INFINITY = INFINITY

--- @brief negative infinity
NEGATIVE_INFINITY = -1/0

--- @brief round to nearest integer
--- @param i number
--- @return number
function math.round(i)
    return math.floor(i + 0.5)
end

--- @brief get minimum and maximum of table
function table.min_max(t)
    local min, max = POSITIVE_INFINITY, NEGATIVE_INFINITY
    for _, value in pairs(t) do
        if value < min then min = value end
        if value > max then max = value end
    end
    return min, max
end

--- @brief get first element of table, in iteration order
--- @param t table
function table.first(t)
    for _, v in pairs(t) do return v end
end

--- @brief get last element of table, in iteration order
--- @param t table
function table.last(t)
    local last = nil
    for _, v in pairs(t) do
        last = v
    end
    return last
end

--- @brief check if two tables have contents that compare equally
--- @param left table
--- @param right table
--- @return boolean
function table.compare(left, right)
    if #left ~= #right then return false end

    for key, value in pairs(left) do
        if right[key] ~= value then return false end
    end

    return true
end

--- @brief iterate integer range
--- @param range_start number
--- @param range_end number
--- @param increment number or nil
function step_range(range_start, range_end, step)
    if step == nil then step = 1 end

    local start = range_start
    if step == 0 then start = nil end -- causes _range_iterator to drop out before the first iteration

    local state = {range_start, range_end, step, start}
    return _step_range_iterator, state
end

_step_range_iterator = function(state)
    local range_start, range_end, step, current = state[1], state[2], state[3], state[4]
    if current == nil then return nil end

    local next = current + step
    if (step > 0 and next > range_end) or (step < 0 and next < range_end) then
        next = nil
    end

    state[4] = next
    return current, state
end

--- @brief iterate arbitrary number of elements, if vararg contains nils, they will be skipped
--- @vararg any
function range(...)
    local elements = {...}
    local n_elements = _G._select('#', ...)

    local state = {}
    for i = 1, n_elements do
        state[i] = elements[i]
    end

    state.index = 1
    state.n_elements = n_elements

    return _range_iterator, state
end

_range_iterator = function(state)
    local index, n_elements = state.index, state.n_elements
    if index > n_elements then return nil end

    while state[index] == nil and index <= n_elements do
        index = index + 1
    end
    state.index = index + 1
    return state[index], state
end

--- @brief
function utf8.sub(str, i, j)
    i = utf8.offset(str, i)
    j = utf8.offset(str,j + 1) - 1
    return string.sub(str, i, j)
end

--- @brief make first letter capital
--- @param str string
function string.capitalize(str)
    assert(type(str) == "string")
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, string.len(str))
end

--- @brief check if character is upper case or non-letter
function string.is_lower(str)
    assert(type(str) == "string" and #str == 1)
    return string.find(str, "[a-z]") ~= nil
end

--- @brief check if character is lower case
function string.is_upper(str)
    assert(type(str) == "string" and #str == 1)
    return string.find(str, "[A-Z1-9]") ~= nil
end

--- @brief get last character
function string.last(str)
    return string.sub(str, #str, #str)
end

--- @brief get first character
function string.first(str)
    return string.sub(str, 1, 1)
end

--- @brief convert snake_case to CamelCase

--- @brief split along character
function string.split(str, separator)
    assert(type(str) == "string")
    assert(type(separator) == "string")

    local out = {}
    for word, _ in string.gmatch(str, "([^".. separator .."]+)") do
        table.insert(out, word)
    end
    return out
end

--- @brief check if pattern occurrs in string
--- @param str string
--- @param pattern string
--- @return boolean
function string.contains(str, pattern)
    return string.find(str, pattern) ~= nil
end

--- @brief replace expression in string
function string.replace(str, pattern, replacement)
    return string.gsub(str, pattern, replacement)
end

--- @brief map string to 64-bit signed integer
--- @param str string
--- @return number
function string.hash(str)
    -- see: https://stackoverflow.com/a/7666577
    local hash = 5381
    for i = 1, #str do
        hash = (bit.lshift(hash, 5) + hash) + string.byte(string.sub(str, i, i))
    end
    return hash
end

--- @brief evalue all substrings of the form `$(statement)` as code and replace the sequence with the result. If `environment` is specified, that able will be used as each sequences entire environment, otherwise _G is used
--- @param str string
--- @param environment table or nil
function string.interpolate(str, environment)

    local values = {}
    local formatted_string = {}
    local i = 1

    while i < #str do
        local c = string.sub(str, i, i)

        if c == string._interpolation_escape_character then
            i = i + 1
            table.insert(formatted_string, string.sub(str, i, i))
        elseif c == string._interpolation_character then
            local start = i

            i = i + 1
            if string.sub(str, i, i) ~= "(" then
                error("In string.interpolate: Invalid interpolation sequence, expected `(`, got `" .. string.sub(str, i, i)  .. "`")
            end

            -- find last bracket of expression
            local bracket_weight = 0
            while true do
                local current = string.sub(str, i, i)

                if current == string._interpolation_escape_character then
                    -- continue
                elseif current == ")" then
                    bracket_weight = bracket_weight - 1
                elseif current == "(" then
                    bracket_weight = bracket_weight + 1
                end

                if bracket_weight <= 0 then break end

                i = i + 1
                if i > #str then
                    error("In string.interpolate: Unfinished interpolation sequence, missing `)` in `" .. string.sub(str, start, #str) .. "`")
                end
            end

            local expression = string.sub(str, start + 2, i - 1)
            local run, error_maybe = load("return " .. expression)
            if error_maybe ~= nil then
                error("In string.interpolate: Error evaluating expression `" .. expression .. "`: " .. error_maybe)
            end

            if environment ~= nil then
                debug.setfenv(run, environment)
            end

            local value = run()
            if value ~= nil then
                table.insert(values, value)
                table.insert(formatted_string, "%s")
            end
        else
            table.insert(formatted_string, c)
        end
        i = i + 1
    end

    return string.format(table.concat(formatted_string), splat(values))
end

string._interpolation_character = "$"
string._interpolation_escape_character = "//"
