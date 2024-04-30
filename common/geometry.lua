--- @class rt.Direction
rt.Direction = meta.new_enum({
    UP = "up",
    RIGHT = "right",
    DOWN = "down",
    LEFT = "left",
    NONE = "none"
})

--- @class rt.AxisAlignedRectangle
function rt.AxisAlignedRectangle(top_left_x, top_left_y, width, height)
    if meta.is_nil(top_left_x) then
        top_left_x = 0
    end

    if meta.is_nil(top_left_y) then
        top_left_y = 0
    end

    if meta.is_nil(width) then
        width = 0
    end

    if meta.is_nil(height) then
        height = 0
    end

    return {
        x = top_left_x,
        y = top_left_y,
        width = width,
        height = height
    }
end

rt.AABB = rt.AxisAlignedRectangle

--- @brief
function meta.is_aabb(object)
    return sizeof(object) == 4 and meta.is_number(object.x) and meta.is_number(object.y) and meta.is_number(object.width) and meta.is_number(object.height)
end

--- @brief
function meta.assert_aabb(object)
    if not meta.is_aabb(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Expected `AxisAlignedRectangle`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @brief is point inside rectangles bounds
--- @param x Number
--- @param y Number
--- @return Boolean
function rt.aabb_contains(self, x, y)
    return x >= self.x and x <= (self.x + self.width) and y >= self.y and y <= (self.y + self.height)
end

--- @brief
--- @return x, y, w, h
function rt.aabb_unpack(self)
    return self.x, self.y, self.width, self.height
end

--- @brief translate point along vector with angle relative to x axis
function rt.translate_point_by_angle(point_x, point_y, distance, angle)
    return point_x + distance * math.cos(angle), point_y + distance * math.sin(angle)
end

--- @brief get angle of vector relative to x axis
function rt.angle(x, y)
    return math.atan2(y, x)
end

--- @brief
function rt.magnitude(x, y)
    return math.sqrt(x^2 + y^2)
end

--- @brief
function rt.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

--- @brief
function rt.normalize(x, y)
    local magnitude = rt.magnitude(x, y)
    if magnitude == 0 then return 0, 0 end
    return x / magnitude, y / magnitude
end

--- @brief
function rt.to_polar(x, y)
    return rt.magnitude(x, y), math.atan2(y, x)
end

--- @brief
function rt.from_polar(magnitude, angle)
    return rt.translate_point_by_angle(0, 0, magnitude, angle)
end

--- @brief convert radians to degrees
--- @param rads Number
--- @return Number
function rt.radians_to_degrees(rads)
    return rads * (180 / math.pi)
end

--- @brief convert degrees to radians
--- @param dgs Number
--- @return Number
function rt.degrees_to_radians(dgs)
    return dgs * (math.pi / 180)
end