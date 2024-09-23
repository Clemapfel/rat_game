--- @class b2.Circle
b2.Circle = meta.new_type("PhysicsCircle", function(radius, x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    return meta.new(b2.Circle, {
        _native = b2.Circle._create_native(
            b2.Vec2(x, y),
            radius
        )
    })
end)

b2.Circle._create_native = ffi.metatype("b2Circle", {})

--- @brief
function b2.Circle:get_radius()
    return self._native.radius
end

--- @brief
function b2.Circle:get_center()
    return self._native.center.x, self._native.center.y
end