--- @class b2.Polygon
b2.Polygon = meta.new_type("PhysicsPolygon", function()
    if _G._select == nil then _G._select = select end
    local n_points = _G._select("#", ...) + 3

    local points = {a_x, a_y, b_x, b_y, c_x, c_y, ...}
    assert(#points >= 6 and #points % 2 == 0)

    local vec2s = ffi.new("b2Vec2[" .. n_points .. "]")
    local ci = 0
    for i = 1, 2 * n_points, 2 do
        vec2s[ci] = ffi.typeof("b2Vec2")(points[i], points[i+1])
        ci = ci + 1
    end
    local hull = box2d.b2ComputeHull(vec2s, n_points)

    return meta.new(b2.Polygon, {
        _native = box2d.b2MakePolygon(hull, 0)
    })
end)

--- @brief
function b2.Rectangle(width, height, center_x, center_y, angle)
    if center_x == nil then center_x = 0 end
    if center_y == nil then center_y = 0 end
    if angle == nil then angle = 0 end

    return meta.new(b2.Polygon, {
        _native = box2d.b2MakeOffsetBox(
            width, height,
            ffi.typeof("b2Vec2")(center_x, center_y),
            angle
        )
    })
end

--- @brief
function b2.Polygon:set_corner_radius(r)
    self._native.radius = r
end

--- @brief
function b2.Polygon:get_corner_radius()
    return self._native.radius
end

--- @brief
function b2.Polygon:get_n_points()
    return self._native.count
end

--- @brief
function b2.Polygon:get_points()
    local n_points = self._native.count
    local out = {}
    for i = 1, n_points do
        local vec2 = self._native.vertices[i]
        table.insert(out, vec2.x)
        table.insert(out, vec2.y)
    end
    return out
end