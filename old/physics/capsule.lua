--- @class b2.Capsule
b2.Capsule = meta.new_type("PhysicsCapsule", function(a_x, a_y, b_x, b_y, radius)
    local scale = B2_PIXEL_TO_METER
    return meta.new(b2.Capsule, {
        _native = b2.Capsule._create_native(
            b2.Vec2(a_x * scale, a_y * scale),
            b2.Vec2(b_x * scale, b_y * scale),
            radius * scale
        )
    })
end)

b2.Capsule._create_native = ffi.metatype("b2Capsule", {})

--- @brief
function b2.Capsule:get_centers()
    local scale = B2_METER_TO_PIXEL
    return
    self._native.center1.x * scale,
    self._native.center1.y * scale,
    self._native.center2.x * scale,
    self._native.center2.y * scale
end

--- @brief
function b2.Capsule:get_radius()
    return self._native.radius
end