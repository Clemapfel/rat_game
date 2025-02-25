--- @class b2.Segment
b2.Segment = meta.new_type("PhysicsSegment", function(a_x, a_y, b_x, b_y)
    local scale = B2_PIXEL_TO_METER
    return meta.new(b2.Segment, {
        _native = b2.Segment._create_native(
            b2.Vec2(a_x * scale, a_y * scale),
            b2.Vec2(b_x * scale, b_y * scale)
        )
    })
end)

b2.Segment._create_native = ffi.metatype("b2Segment", {})

--- @brief
function b2.Segment:get_points()
    local scale = B2_METER_TO_PIXEL
    return self._native.center1.x * scale, self._native.center1.y * scale,
        self._native.center2.x * scale, self._native.center2.y * scale
end