--- @class rt.AxisAlignedRectangle
rt.AxisAlignedRectangle = meta.new_type("AxisAlignedRectangle", function(top_left_x, top_left_y, width, height)

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

    meta.assert_number(top_left_x)
    meta.assert_number(top_left_y)
    meta.assert_number(width)
    meta.assert_number(height)

    return meta.new(rt.AxisAlignedRectangle, {
        x = top_left_x,
        y = top_left_y,
        width = width,
        height = height
    })
end)

--- @brief get size
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_size(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.width, self.height
end

--- @brief get top left
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_top_left(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x, self.y
end

--- @brief get top center
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_top_center(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return (self.x + 0.5 * self.width), self.x
end

--- @brief get top right
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_top_right(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x + self.width, self.y
end

--- @brief get center left
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_center_left(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x, self.y + self.height * 0.5
end

--- @brief get center center
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_center(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x + self.width * 0.5, self.y + self.height * 0.5
end

--- @brief get center right
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_center_right(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x + self.width, self.y + self.height * 0.5
end

--- @brief get bottom left
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_bottom_left(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x, self.y + self.height
end

--- @brief get bottom center
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_bottom_center(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x + self.width * 0.5, self.y + self.height
end

--- @brief get bottom right
--- @param self rt.AxisAlignedRectangle
--- @return (Number, Number)
function rt.AxisAlignedRectangle.get_bottom_right(self)
    meta.assert_isa(self, rt.AxisAlignedRectangle)
    return self.x + self.width, self.y + self.height
end

--- @brief is point inside rectangles bounds
--- @param self rt.AxisAlignedRectangle
--- @param x Number
--- @param y Number
--- @return Boolean
function rt.AxisAlignedRectangle.contains(self, x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height;
end