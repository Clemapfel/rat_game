--- @class b2.Circle
b2.Circle = meta.new_type("PhysicsCircle", function(radius, x, y)
    local scale = B2_PIXEL_TO_METER
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    return meta.new(b2.Circle, {
        _native = b2.Circle._create_native(
            b2.Vec2(x * scale, y * scale),
            radius * scale
        )
    })
end)

b2.Circle._create_native = ffi.metatype("b2Circle", {})

--- @brief
function b2.Circle:get_radius()
    return self._native.radius * B2_METER_TO_PIXEL
end

--- @brief
function b2.Circle:get_center()
    local scale = B2_METER_TO_PIXEL
    return self._native.center.x * scale, self._native.center.y * scale
end