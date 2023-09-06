--- @class Rectangle
rt.Rectangle = meta.new_type("Rectangle", function(top_left_x, top_left_y, width, height)

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

    return meta.new(rt.Rectangle, {
        x = top_left_x,
        y = top_left_y,
        width = width,
        height = height
    })
end)

--- @brief get size
--- @return (Number, Number)
function rt.Rectangle.get_size(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.width, self.height
end

--- @brief get top left
--- @return (Number, Number)
function rt.Rectangle.get_top_left(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x, self.y
end

--- @brief get top center
--- @return (Number, Number)
function rt.Rectangle.get_top_center(self)
    meta.assert_isa(self, rt.Rectangle)
    return (self.x + 0.5 * self.width), self.x
end

--- @brief get top right
--- @return (Number, Number)
function rt.Rectangle.get_top_right(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x + self.width, self.y
end

--- @brief get center left
--- @return (Number, Number)
function rt.Rectangle.get_center_left(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x, self.y + self.height * 0.5
end

--- @brief get center center
--- @return (Number, Number)
function rt.Rectangle.get_center(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x + self.width * 0.5, self.y + self.height * 0.5
end

--- @brief get center right
--- @return (Number, Number)
function rt.Rectangle.get_center_right(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x + self.width, self.y + self.height * 0.5
end

--- @brief get bottom left
--- @return (Number, Number)
function rt.Rectangle.get_bottom_left(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x, self.y + self.height
end

--- @brief get bottom center
--- @return (Number, Number)
function rt.Rectangle.get_bottom_center(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x + self.width * 0.5, self.y + self.height
end

--- @brief get bottom right
--- @return (Number, Number)
function rt.Rectangle.get_bottom_right(self)
    meta.assert_isa(self, rt.Rectangle)
    return self.x + self.width, self.y + self.height
end

--- @brief is point inside rectangles bounds
--- @param x Number
--- @param y Number
--- @return Boolean
function rt.Rectangle.contains(self, x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height;
end