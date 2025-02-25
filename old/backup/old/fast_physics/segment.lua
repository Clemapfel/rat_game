--- @class b2.Segment
b2.Segment = setmetatable({}, {
    __call = function(_, a_x, a_y, b_x, b_y)
        return b2.Segment:new(a_x, a_y, b_x, b_y)
    end
})

--- @brief
function b2.Segment:new(a_x, a_y, b_x, b_y)
    return b2.Segment:new_from_id(ffi.typeof("b2Segment")(
        ffi.typeof("b2Vec2")(a_x, a_y),
        ffi.typeof("b2Vec2")(b_x, b_y)
    ))
end

--- @brief
function b2.Segment:new_from_id(id)
    return setmetatable({
        _native = id
    }, {
        __index = b2.Segment
    })
end

--- @brief
function b2.Segment:get_points()
    return self._native.center1.x, self._native.center1.y, self._native.center2.x, self._native.center2.y
end

--- @brief
function b2.Segment:draw()
    b2._draw_segment(self._native)
end
