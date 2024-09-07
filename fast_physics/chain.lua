--- @class b2.Chain
b2.Chain = setmetatable({}, {
    __call = function(_, a_x, a_y, b_x, b_y)
        return b2.Chain:new(a_x, a_y, b_x, b_y)
    end
})

--- @brief
function b2.Chain:new(a_x, a_y, b_x, b_y)
    return b2.Chain:new_from_id(ffi.typeof("b2Chain")(
        ffi.typeof("b2Vec2")(a_x, a_y),
        ffi.typeof("b2Vec2")(b_x, b_y)
    ))
end

--- @brief
function b2.Chain:new_from_id(id)
    return setmetatable({
        _native = id
    }, {
        __index = b2.Chain
    })
end

--- @brief
function b2.Chain:get_points()
    return self._native.center1.x, self._native.center1.y, self._native.center2.x, self._native.center2.y
end

--- @brief
function b2.Chain:draw()
    b2._draw_segment(self._native)
end
