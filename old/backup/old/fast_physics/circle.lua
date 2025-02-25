--- @class b2.Circle
b2.Circle = setmetatable({}, {
    __call = function(_, radius, x, y)
        return b2.Circle:new(radius, x, y)
    end
})

--- @brief
function b2.Circle:new(radius, x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    return b2.Circle:new_from_id(ffi.typeof("b2Circle")(
        ffi.typeof("b2Vec2")(x, y),
        radius
    ))
end

--- @brief
function b2.Circle:new_from_id(id)
    return setmetatable({
        _native = id
    }, {
        __index = b2.Circle
    })
end

--- @brief
function b2.Circle:get_radius()
    return self._native.radius
end

--- @brief
function b2.Circle:get_center()
    return self._native.center.x, self._native.center.y
end

--- @brief
function b2.Circle:draw()
    b2._draw_circle(self._native)
end