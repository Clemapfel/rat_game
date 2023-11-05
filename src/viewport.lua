--- @class rt.Viewport
rt.Viewport = meta.new_type("Viewport", function()
    local out = meta.new(rt.Viewport, {
        _child = {},
        _x_offset = 0,
        _y_offset = 0,
        _x_scale = 1,
        _y_scale = 1,
        _rotation = rt.Angle(),
        _propagate_width = false,
        _propagate_height = false,
        _width = 0,
        _height = 0
    }, rt.Widget, rt.Drawable)
    return out
end)

--- @overload rt.Drawable.draw
function rt.Viewport:draw()
    meta.assert_isa(self, rt.Viewport)
    if self:get_is_visible() and not meta.is_nil(self._child) then

        love.graphics.push()

        local x, y = self:get_position()
        love.graphics.setScissor(x, y, self._width, self._height)

        love.graphics.translate(self._x_offset, self._y_offset)
        love.graphics.scale(self._x_scale, self._y_scale)

        love.graphics.translate(self._width * 0.5, self._height * 0.5)
        love.graphics.rotate(self._rotation:as_radians())
        love.graphics.translate(self._width * -0.5, self._height * -0.5)

        self._child:draw()

        love.graphics.setScissor()
        love.graphics.pop()
    end
end

--- @overload rt.Widget.size_allocate
function rt.Viewport:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Viewport)
    self._width = width
    self._height = height

    if not meta.is_nil(self._child) and not meta.is_nil(self:get_parent()) then
        local w, h = self:get_parent():get_size()
        self._child:fit_into(rt.AABB(x, y, w, h))
    end
end

--- @overload rt.Widget.measure
function rt.Viewport:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return rt.Widget.measure(self)
end

--- @brief set singular child
--- @param child rt.Widget
function rt.Viewport:set_child(child)
    meta.assert_isa(self, rt.Viewport)
    meta.assert_isa(child, rt.Widget)

    if self._child == child then return end

    self._child = child
    child:set_parent(self)
    self:reformat()
end

--- @brief get child
--- @return rt.Widget
function rt.Viewport:get_child()
    meta.assert_isa(self, rt.Viewport)
    return self._child
end

--- @brief remove child
function rt.Viewport:remove_child()
    meta.assert_isa(self, rt.Viewport)
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
            self:reformat()
    end
end

--- @brief set whether viewport should assume width of its child
--- @param b Boolean
function rt.Viewport:set_propagate_width(b)
    meta.assert_isa(self, rt.Viewport)
    if self._propagate_width ~= b then
        self._propagate_width = b
        self:reformat()
    end
end

--- @brief get whether viewport assumes width of its child
--- @return Boolean
function rt.Viewport:get_propagate_width()
    meta.assert_isa(self, rt.Viewport)
    return self._propagate_width
end

--- @brief set whether viewport should assume height of its child
--- @param b Boolean
function rt.Viewport:set_propagate_height(b)
    meta.assert_isa(self, rt.Viewport)
    if self._propagate_height ~= b then
        self._propagate_height = b
        self:reformat()
    end
end

--- @brief get whether viewport assumes height of its child
--- @return Boolean
function rt.Viewport:get_propagate_height()
    meta.assert_isa(self, rt.Viewport)
    return self._propagate_height
end

--- @brief get scroll offset
--- @return (Number, Number)
function rt.Viewport:get_offset()
    meta.assert_isa(self, rt.Viewport)
    return self._x_offset, self._y_offset
end

--- @brief set scroll offset
--- @param x Number px
--- @param y Number px
function rt.Viewport:set_offset(x, y)
    meta.assert_isa(self, rt.Viewport)
    meta.assert_number(x, y)
    local before_x, before_y = self:get_offset()

    self._x_offset = x
    self._y_offset = y

    local after_x, after_y = self:get_offset()
end

--- @brief move scroll offset
--- @param x_offset Number px
--- @param y_offset Number px
function rt.Viewport:translate(x_offset, y_offset)
    meta.assert_isa(self, rt.Viewport)
    meta.assert_number(x_offset, y_offset)

    local current_x, current_y = self:get_offset()
    self:set_offset(current_x + x_offset, current_y + y_offset)
end

--- @brief set scroll scale
--- @param x Number factor
--- @param y Number factor
function rt.Viewport:set_scale(x, y)
    meta.assert_isa(self, rt.Viewport)
    meta.assert_number(x)
    if meta.is_nil(y) then y = x end
    meta.assert_number(y)

    self._x_scale = x
    self._y_scale = y
end

--- @brief get scroll scale
--- @return (Number, Number)
function rt.Viewport:get_scale()
    meta.assert_isa(self, rt.Viewport)
    return self._x_scale, self._y_scale
end

--- @brief apply scale factor
--- @param x Number factor
--- @param y Number factor
function rt.Viewport:scale(x, y)
    meta.assert_isa(self, rt.Viewport)
    meta.assert_number(x)
    if meta.is_nil(y) then y = x end
    meta.assert_number(y)

    self._x_scale = self._x_scale * x
    self._y_scale = self._y_scale * y
end

--- @brief override rotation
--- @param angle rt.Angle
function rt.Viewport:set_rotation(angle)
    meta.assert_isa(self, rt.Viewport)
    meta.assert_isa(angle, rt.Angle)

    self._rotation = angle
end

--- @brief get rotation
--- @return rt.Angle
function rt.Viewport:get_rotation()
    meta.assert_isa(self, rt.Viewport)
    return self._rotation
end

--- @brief add rotation
--- @param angle rt.Angle
function rt.Viewport:rotate(angle)
    meta.assert_isa(self, rt.Viewport)
    meta.assert_isa(angle, rt.Angle)
    self._rotation = self._rotation + angle
end

--- @brief test viewport
function rt.test.viewport()
    -- TODO
end
