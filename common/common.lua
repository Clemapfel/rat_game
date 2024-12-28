-- luajit compat

if table.unpack == nil then table.unpack = unpack end
assert(table.unpack ~= nil)

if debug.setfenv == nil then debug.setfenv = setfenv end
assert(debug.setfenv ~= nil)

require("table.new")
assert(table.new ~= nil, "Unable to load table.new, is this LuaJIT?")

_G._pairs = pairs
_G._ipairs = ipairs


do
    local _noop = function() return nil end

    --[[
    function pairs(t)
        if t == nil then return _noop end
        return _G._pairs
    end

    function ipairs(t)
        if t == nil then return _noop end
        return _G._ipairs
    end
    ]]--

    local _keys_iterator = function(t, k)
        local next_key, _ = next(t, k)
        return next_key
    end

    --- @brief iterate all keys of a table
    function keys(t)
        if t == nil then return _noop end
        return _keys_iterator, t
    end

    --- @brief iterate all values of a table
    function values(t)
        if t == nil then return _noop end
        local k, v
        return function() -- impossible to do without closure
            k, v = next(t, k)
            return v
        end
    end

    local function _range_iterator(state)
        local next_i, out = next(state, state[1])
        state[1] = next_i
        return out, state
    end

    --- @brief iterate vararg
    function range(...)
        if select("#", ...) == 0 then return _noop end
        return _range_iterator, {1, ...} -- start at 1, because because actual table is by one
    end
end

function eachindex(t, size)
    if size == nil then
        local size = 0
        for _ in pairs(t) do size = size + 1 end
    end

    return function(arr, i)
        i = i + 1
        if i <= size then
            return i
        end
    end, t, 0
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

--- @brief positive infinity
INFINITY = 1/0

--- @brief positive infinity
POSITIVE_INFINITY = INFINITY

--- @brief negative infinity
NEGATIVE_INFINITY = -1/0

--- @brief nan
NAN = 0/0

--- @brief round to nearest integer
--- @param i number
--- @return number
function math.round(i)
    return math.floor(i + 0.5)
end

--- @brief
function math.sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
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
function utf8.size(str)
    return utf8.len(str)
end

--- @brife
function string.size(str)
    return #str
end

--- @brief concat respecting meta methods
function string.concat(delimiter, ...)
    local out = ""
    local n = select("#", ...)
    for i = 1, n do
        out = out .. select(i, ...)
        if i < n then
            out = out .. delimiter
        end
    end
    return out
end

--- @brief
function utf8.sub(s,i,j)
    -- src: http://lua-users.org/lists/lua-l/2014-04/msg00590.html
    i = i or 1
    j = j or -1
    if i<1 or j<1 then
        local n = utf8.len(s)
        if not n then return nil end
        if i<0 then i = n+1+i end
        if j<0 then j = n+1+j end
        if i<0 then i = 1 elseif i>n then i = n end
        if j<0 then j = 1 elseif j>n then j = n end
    end
    if j<i then return "" end
    i = utf8.offset(s,i)
    j = utf8.offset(s,j+1)
    if i and j then return string.sub(s, i,j-1)
    elseif i then return string.sub(s, i)
    else return ""
    end
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

