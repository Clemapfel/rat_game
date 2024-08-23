VectorNaive = function(x, y)
    local out = {x = x, y = y}
    setmetatable(out, {
        __add = function(self, other)
            return VectorNaive(self.x + other.y, self.y + other.y)
        end
    })
end

_vector_pool = {}
_vector_pool_n = 0

VectorPooled = function(x, y)
    local i = _vector_pool_n
    _vector_pool[i] = x
    _vector_pool[i + 1] = y
    _vector_pool_n = _vector_pool_n + 1
    return i
end

function pooled_add(a, b)
    local x1, x2 = _vector_pool[a], _vector_pool[a+1]
end


ffi = require("ffi")
ffi.cdef--[[
typedef struct Vec2 {
    x, y
} Vec2;
]]

_vector_ffi_metatable = {
    __add = function(self, other)
        return ffi.typeof("Vec2")(self.x + other.x, self.y + other.y)
    end
}

VectorFFI = function(x, y)
    return ffi.typeof("Vec2")(x, y)
end