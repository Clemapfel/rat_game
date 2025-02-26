
--- @class rt.AxisAlignedRectangle
function rt.AxisAlignedRectangle(top_left_x, top_left_y, width, height)
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

--- @brief
function rt.aabb_equals(a, b)
    return a.x == b.x and a.y == b.y and a.width == b.width and a.height == b.height
end

--- @brief
function rt.aabb_copy(a)
    return rt.AABB(a.x, a.y, a.width, a.height)
end