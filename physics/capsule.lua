--- @class b2.Capsule
b2.Capsule = meta.new_type("PhysicsCapsule", function(a_x, a_y, b_x, b_y, radius)
    return meta.new(b2.Capsule, {
        _native = b2.Capsule._create_native(
            b2.Vec2(a_x, a_y),
            b2.Vec2(b_x, b_y),
            radius
        )
    })
end)

b2.Capsule._create_native = ffi.metatype("b2Capsule", {})

--- @brief
function b2.Capsule:get_centers()
    return self._native.center1.x, self._native.center1.y, self._native.center2.x, self._native.center2.y
end

--- @brief
function b2.Capsule:get_radius()
    return self._native.radius
end