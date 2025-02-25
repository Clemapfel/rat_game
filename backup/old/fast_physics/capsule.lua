--- @class b2.Capsule
b2.Capsule = setmetatable({}, {
    __call = function(_, a_x, a_y, b_x, b_y, radius)
        return b2.Capsule:new(a_x, a_y, b_x, b_y, radius)
    end
})

--- @brief
function b2.Capsule:new(a_x, a_y, b_x, b_y, radius)
    return b2.Capsule:new_from_id(
        ffi.typeof("b2Capsule")(
            ffi.typeof("b2Vec2")(a_x, a_y),
            ffi.typeof("b2Vec2")(b_x, b_y),
            radius
        )
    )
end

--- @brief
function b2.Capsule:new_from_id(id)
    return setmetatable({
       _native = id
    }, {
        __index = b2.Capsule
    })
end

--- @brief
function b2.Capsule:get_centers()
    return self._native.center1.x, self._native.center1.y, self._native.center2.x, self._native.center2.y
end

--- @brief
function b2.Capsule:get_radius()
    return self._native.radius
end

--- @brief
function b2.Capsule:draw()
    b2._draw_capsule(self._native)
end
