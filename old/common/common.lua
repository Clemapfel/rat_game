-- luajit compat
_G._pairs = pairs
function pairs(x)
    local meta = getmetatable(x)
    if meta ~= nil and meta.__pairs ~= nil then
        return meta.__pairs(x)
    else
        return _G._pairs(x)
    end
end

_G._ipairs = ipairs
function ipairs(x)
    local meta = getmetatable(x)
    if meta ~= nil and meta.__pairs ~= nil then
        return meta.__ipairs(x)
    else
        return _G._ipairs(x)
    end
end

if table.unpack == nil then table.unpack = unpack end
assert(table.unpack ~= nil)

if debug.setfenv == nil then debug.setfenv = setfenv end
assert(debug.setfenv ~= nil)

--- @brief iterate over values of table
function values(t)
    if t == nil then return function() return nil end end
    local k, v
    return function()
        k, v = next(t, k)
        return v
    end
end

--- @brief iterate over keys of tbale
function keys(t)
    if t == nil then return function() return nil end end
    local k, v
    return function()
        k, v = next(t, k)
        return k
    end
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

--- @brief print, arguments are concatenated
--- @param vararg any
--- @return nil
function print(...)
    local values = {...}
    if string.len(values) == 0 then
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
        io.write("nil\n")
        return
    end

    for _, v in pairs(values) do
        io.write(tostring(v))
    end

    io.write("\n")
    io.flush()
end

--- @brief
function dbg(...)
    for _, x in pairs({...}) do
        io.write(serialize(x))
        io.write(" ")
    end

    io.write("\n")
    io.flush()
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
table.sizeof = sizeof

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
table.is_empty = is_empty

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

--- @brief
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
    return lower * (1 - ratio) + upper * ratio
end

--- @brief
function smoothstep(lower, upper, ratio)
    local t = clamp((ratio - lower) / (upper - lower), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
end

--- @brief
function fract(x)
    return math.fmod(x, 1.0)
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
        local n = string.len(str_buffer)
        str_buffer[n] = string.sub(str_buffer[n], 1, string.len(str_buffer[n]) - 1)

        return table.concat(str_buffer)
    end

    _serialize_inner = function (buffer, object, n_indent_tabs, seen)

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

                    _serialize_inner(buffer, value, n_indent_tabs, seen)
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
    _serialize_inner(buffer, object, 0, seen)
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

--- @brief evaluate erf integral
--- @param x number
--- @return number
function math.erf(x)
    -- src: https://hewgill.com/picomath/lua/erf.lua.html
    local a1 =  0.254829592
    local a2 = -0.284496736
    local a3 =  1.421413741
    local a4 = -1.453152027
    local a5 =  1.061405429
    local p  =  0.3275911

    local sign = 1
    if x < 0 then
        sign = -1
    end
    x = math.abs(x)

    local t = 1.0 / (1.0 + p * x)
    local y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x)
    return sign * y
end

--- @brief hyperbolic tangent
--- @param x number
--- @return number
function math.tanh(x)
    -- src: http://lua-users.org/wiki/HyperbolicFunctions
    if x == 0 then return 0.0 end
    local neg = false
    if x < 0 then x = -x; neg = true end
    if x < 0.54930614433405 then
        local y = x * x
        x = x + x * y *
                ((-0.96437492777225469787e0 * y +
                        -0.99225929672236083313e2) * y +
                        -0.16134119023996228053e4) /
                (((0.10000000000000000000e1 * y +
                        0.11274474380534949335e3) * y +
                        0.22337720718962312926e4) * y +
                        0.48402357071988688686e4)
    else
        x = math.exp(x)
        x = 1.0 - 2.0 / (x * x + 1.0)
    end
    if neg then x = -x end
    return x
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

--- @brief
function table.push(t, v)
    table.insert(t, v)
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

--- @brief
function table.pop_front(t)
    local front = t[1]
    table.remove(t, 1)
    return front
end

--- @brief create a table with n copies of object
--- @param x any
--- @param n Number
--- @return table
function table.rep(x, n)
    local out = {}
    for i = 1, n do
        table.insert(out, x)
    end
    return out
end

--- @brief
function table.reverse(t)
    local out = {}
    local n = sizeof(table)
    for k, v in ipairs(t) do
        out[n + 1 - k] = v
    end
    return out
end

--- @brief
function table.seq(start, finish, step)
    local out = {}
    for x = start, finish, step do
        table.insert(out, x)
    end
    return out
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

--- @brief clear all values from table
--- @param t Table
--- @return nil
function table.clear(t)
    for key, _ in pairs(t) do
        t[key] = nil
    end
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

if utf8 == nil then utf8 = require "utf8" end

--- @brief
function utf8.sub(str, i, j)
    i = utf8.offset(str, i)
    j = utf8.offset(str,j + 1) - 1
    return string.sub(str, i, j)
end

--- @brief
function utf8.less_than(a, b)
    local a_len, b_len = utf8.len(a), utf8.len(b)
    for i = 1, math.min(a_len, b_len) do
        local ac, bc = utf8.codepoint(a, i), utf8.codepoint(b, i)
        if ac == bc then
            -- continue
        else
            return ac < bc
        end
    end

    -- codepoints equal, but possible different lengths
    if a_len ~= b_len then
        return utf8.len(a) < utf8.len(b)
    else
        return false
    end
end

--- @brief
function utf8.equal(a, b)
    if utf8.len(a) ~= utf8.len(b) then return false end
    for i = 1, utf8.len(a) do
        if utf8.codepoint(a, i) ~= utf8.codepoint(b, i) then
            return false
        end
    end
    return true
end

--- @brief
function utf8.greater_than(a, b)
    return not utf8.equal(a, b) and not utf8.less_than(a, b)
end


--- @brief make first letter capital
--- @param str string
function string.capitalize(str)
    assert(type(str) == "string")
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, string.len(str))
end

--- @brief check if character is upper case or non-letter
function string.is_lower(str)
    assert(type(str) == "string" and string.len(str) == 1)
    return string.find(str, "[a-z]") ~= nil
end

--- @brief check if character is lower case
function string.is_upper(str)
    assert(type(str) == "string" and string.len(str) == 1)
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

--- @brief get number of bits in string
function string.len(str)
    return #str
end

--- @brief
function string.at(str, i)
    return string.sub(str, i, i)
end

--- @brief
function exit(status)
    if status == nil then status = 0 end
    love.event.push("quit", status)
end

--- @brief hash string
function string.sha256(string)
    local hash
    if love.getVersion() >= 12 then
        hash = love.data.hash("string", "sha256", string)
    else
        hash = love.data.hash("sha256", string)
    end
    return hash
end

