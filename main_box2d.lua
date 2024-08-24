-- ### BENCHMARK CONFIG

local n_runs = 10             -- number of total runs
local n_vectors = 10e4        -- number of vectors per run
local n_adds = 200            -- number of operations per vector

io.stdout:setvbuf("no")

_global_01 = {}
_global_02 = {}
_global_03 = {}

local global_length = 100
for i = 1, global_length do
    _global_01[i] = love.math.random()
    _global_02[i] = love.math.random()
    _global_03[i] = love.math.random()
end

function call_global()
    for i = 1, n do
        _global_01[i] = _global_01[i] + _global_02[i] + _global_03[i]
    end
    return _global_01[]
end

-- ### NAIVE VECTOR ###

do
    local _vector_naive_metatable = {
        __add = function(self, other)
            return VectorNaive(self.x + other.x, self.y + other.y)
        end
    }

    VectorNaive = function(x, y)
        local out = {x = x, y = y}
        setmetatable(out, _vector_naive_metatable)
        return out
    end
end

-- ### NAIVE ARRAY VECTOR ###

do
    local _vector_naive_array_metatable = {
        __add = function(self, other)
            return VectorNaive(self[1] + other[1], self[2] + other[2])
        end
    }

    VectorNaiveArray = function(x, y)
        local out = {x, y}
        setmetatable(out, _vector_naive_array_metatable)
        return out
    end
end

-- ### POOLED VECTOR ###

require "table.new"

do
    local _vector_pool = table.new(2 * n_vectors * n_adds, 0)
    local _vector_pool_n = 1
    VectorPooled = function(x, y)
        local i = _vector_pool_n
        _vector_pool[i] = x
        _vector_pool[i + 1] = y
        _vector_pool_n = _vector_pool_n + 2
        return i
    end

    function pooled_add(a, b)
        return VectorPooled(_vector_pool[a] + _vector_pool[b], _vector_pool[a + 1] + _vector_pool[b + 1])
    end

    function pooled_get(a)
        return _vector_pool[a], _vector_pool[a+1]
    end

    function pool_reset()
        _vector_pool = table.new(2 * n_vectors * n_adds, 0)
        _vector_pool_n = 1
    end
end

_vector_pool_global = table.new(2 * n_vectors * n_adds, 0)
_vector_pool_global_n = 1
do
    VectorPooledGlobal = function(x, y)
        local i = _vector_pool_global_n
        _vector_pool_global[i] = x
        _vector_pool_global[i + 1] = y
        _vector_pool_global_n = _vector_pool_global_n + 2
        return i
    end

    function pool_globaled_add(a, b)
        return VectorPooledGlobal(_vector_pool_global[a] + _vector_pool_global[b], _vector_pool_global[a + 1] + _vector_pool_global[b + 1])
    end

    function pool_globaled_get(a)
        return _vector_pool_global[a], _vector_pool_global[a+1]
    end

    function pool_global_reset()
        _vector_pool_global = table.new(2 * n_vectors * n_adds, 0)
        _vector_pool_global_n = 1
    end
end

-- ### FFI METATYPE ###


do
    local _vector_ffi_metatable = {
        __add = function(self, other)
            return VectorMetatype(self.x + other.x, self.y + other.y)
        end
    }

    local ffi = require "ffi"
    ffi.cdef[[
        typedef struct Vec2 {
            float x;
            float y;
        } Vec2;
    ]]

    VectorMetatype = ffi.metatype("Vec2", _vector_ffi_metatable)
end

-- ### BENCHMARK ###

local naive_run = {}
local naive_array_run = {}
local pooled_run = {}
local pooled_global_run = {}
local metatype_run = {}

local res = 0 -- prevents optimizing out

function get_values()
    return love.math.random(), love.math.random()
end

io.write("Starting...\n")
collectgarbage("stop")

for run_i = 1, n_runs do
    io.write("\r", run_i)
    do
        local current = love.timer.getTime()
        local vec2 = VectorNaive
        for vec_i = 1, n_vectors do
            local a = vec2(get_values())
            local b = vec2(get_values())
            for i = 1, n_adds do
                local c = a + b
                res = res + c.x
                res = res + c.y
            end
        end
        table.insert(naive_run, love.timer.getTime() - current)
    end

    collectgarbage("collect")

    do
        local current = love.timer.getTime()
        local vec2 = VectorNaiveArray
        for vec_i = 1, n_vectors do
            local a = vec2(get_values())
            local b = vec2(get_values())
            for i = 1, n_adds do
                local c = a + b
                res = res + c.x
                res = res + c.y
            end
        end
        table.insert(naive_array_run, love.timer.getTime() - current)
    end

    collectgarbage("collect")

    do
        local current = love.timer.getTime()
        local add = pooled_add
        local get = pooled_get
        local vec2 = VectorPooled
        for vec_i = 1, n_vectors do
            local a = vec2(get_values())
            local b = vec2(get_values())
            for i = 1, n_adds do
                local c_x, c_y = get(add(a, b))
                res = res + c_x
                res = res + c_y
            end
        end
        table.insert(pooled_run, love.timer.getTime() - current)
    end

    pool_reset()
    collectgarbage("collect")

    do
        local current = love.timer.getTime()
        local add = pool_globaled_add
        local get = pool_globaled_get
        local vec2 = VectorPooledGlobal
        for vec_i = 1, n_vectors do
            local a = vec2(get_values())
            local b = vec2(get_values())
            for i = 1, n_adds do
                local c_x, c_y = get(add(a, b))
                res = res + c_x
                res = res + c_y
            end
        end
        table.insert(pooled_global_run, love.timer.getTime() - current)
    end

    pool_global_reset()
    collectgarbage("collect")

    do
        local current = love.timer.getTime()
        local vec2 = VectorMetatype
        for vec_i = 1, n_vectors do
            local a = vec2(get_values())
            local b = vec2(get_values())
            for i = 1, n_adds do
                local c = a + b
                res = res + c.x
                res = res + c.y
            end
        end
        table.insert(metatype_run, love.timer.getTime() - current)
    end

    collectgarbage("collect")
end

collectgarbage("restart")

function mean(t)
    local sum = 0
    for i = 1, #t do
        sum = sum + t[i]
    end
    return sum / #t
end

function median(t)
    table.sort(t)
    return t[math.floor(#t / 2)]
end

io.write("\r", res) -- print to force res to be kept around through all benchmarks

io.write("\n\n# Runs     : ", n_runs, "\n")
io.write("Naive          : ", mean(naive_run), " ", median(naive_run), "\n")
io.write("Naive Array    : ", mean(naive_array_run), " ", median(naive_array_run), "\n")
io.write("Pooled         : ", mean(pooled_run), " ", median(pooled_run), "\n")
io.write("Pooled Globals : ", mean(pooled_global_run), " ", median(pooled_global_run), "\n")
io.write("Metatype       : ", mean(metatype_run), " ", median(metatype_run), "\n")
