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
    assert(type(t) == "table")
    return table.unpack(t)
end

--- @brief wrap tuple in table
function slurp(...)
    return {...}
end

base_select = select

--- @brief get n-th element of varag
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
    return not string.is_lower(str)
end

--- @brief get last character
function string.last(str)
    return string.sub(str, #str, #str)
end

--- @brief get first character
function string.fisrt(str)
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
    return type(string.find(str, pattern)) ~= "nil"
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

--- @brief round to nearest integer
--- @param i number
--- @return number
function math.round(i)
    return math.floor(i + 0.5)
end

--- @brief get minimum and maximum of table
function table.min_max(t)
    local min, max = POSITIVE_INFINITY, NEGATIVE_INFINITY
    for key, value in pairs(t) do
        if value < min then min = value end
        if value > max then max = value end
    end
    return min, max
end