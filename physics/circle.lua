--- @class b2.Circle
b2.Circle = meta.new_type("PhysicsCircle", function(radius, x, y)
    return meta.new(b2.Circle, {
        _native = ffi.typeof("b2Circle")(
            ffi.typeof("b2Vec2")(x, y),
            radius
        )
    })
end)

--- @brief
function b2.Circle:get_radius()
    return self._native.radius
end

--- @brief
function b2.Circle:get_center()
    return self._native.center.x, self._native.center.y
end