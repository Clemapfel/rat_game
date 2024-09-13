--- @class b2.Segment
b2.Segment = meta.new_type("PhysicsSeg", function(a_x, a_y, b_x, b_y)
    return meta.new(b2.Segment, {
        _native = ffi.typeof("b2Segment")(
            b2.Vec2(a_x, a_y),
            b2.Vec2(b_x, b_y)
        )
    })
end)

--- @brief
function b2.Segment:get_points()
    return self._native.center1.x, self._native.center1.y, self._native.center2.x, self._native.center2.y
end