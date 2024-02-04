--- @class rt.FrameType
rt.FrameType = meta.new_enum({
    RECTANGULAR = 1,
    CIRCULAR = 2,
    ELLIPTICAL = 3
})

rt.settings.frame = {
    thickness = 4, -- px
    corner_radius = 10
}

--- @class rt.Frame
rt.Frame = meta.new_type("Frame", function(type)
    if meta.is_nil(type) then type = rt.FrameType.RECTANGULAR end

    local out = meta.new(rt.Frame, {
        _type = type,
        _child = {},
        _stencil_mask = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
        _frame_thickness = rt.settings.frame.thickness,
        _frame = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
        _frame_outline = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
        _color = rt.Palette.FOREGROUND,
        _thickness = rt.settings.frame.thickness,
        _corner_radius = rt.settings.frame.corner_radius
    }, rt.Drawable, rt.Widget)

    out._frame:set_is_outline(true)
    out._frame:set_line_width(out._frame_thickness)
    out._frame_outline:set_line_width(rt.settings.frame.thickness + 2)
    out._frame_outline:set_is_outline(true)

    out._frame:set_color(out._color)
    out._frame_outline:set_color(rt.Palette.BASE_OUTLINE)

    out._frame:set_line_width(out._thickness)
    if out._type == rt.FrameType.RECTANGULAR and out._corner_radius ~= radius then
        local corner_radius = out._corner_radius
        out._frame:set_corner_radius(corner_radius)
        out._frame_outline:set_corner_radius(corner_radius)
        out._stencil_mask:set_corner_radius(corner_radius)
    end
    return out
end)

--- @overload rt.Drawable.draw
function rt.Frame:draw()

    if not self:get_is_visible() then return end

    if meta.is_widget(self._child) then

        local pos_x, pos_y = self._child:get_position()
        local w, h = self._child:get_size()
        local thickness = rt.settings.frame.thickness

        -- draw child with corners masked away
        local stencil_value = 255
        love.graphics.stencil(function()
            self._stencil_mask:draw()
        end, "replace", stencil_value, true)
        love.graphics.setStencilTest("equal", stencil_value)

        self._child:draw()

        love.graphics.stencil(function() end, "replace", 0, false) -- reset stencil value
        love.graphics.setStencilTest()

        if self._thickness > 0 then
            if self._thickness > 1 then
                self._frame_outline:draw()
            end
            self._frame:draw()
        end
    end
end

--- @overload rt.Widget.size_allocate
function rt.Frame:size_allocate(x, y, width, height)
    if not meta.is_widget(self._child) then
        return
    end

    self._child:fit_into(rt.AABB(x, y, width, height))

    local pos_x, pos_y = self._child:get_position()
    local w, h = self._child:get_size()

    w = math.max(w, select(1, self:get_minimum_size()))
    h = math.max(h, select(2, self:get_minimum_size()))

    local thickness = self._thickness

    if self._type == rt.FrameType.RECTANGULAR then
        self._frame:resize(rt.AABB(pos_x + 0.5 * thickness, pos_y + 0.5 * thickness, w - thickness, h - thickness))
        self._frame_outline:resize(rt.AABB(pos_x + 0.5 * thickness, pos_y + 0.5 * thickness, w - thickness, h - thickness))
        self._stencil_mask:resize(rt.AABB(pos_x + 0.5 * thickness, pos_y + 0.5 * thickness, w - thickness, h - thickness))
    elseif self._type == rt.FrameType.CIRCULAR then
        local radius = math.min(w, h) / 2 - 0.5 * thickness
        self._frame:resize(pos_x + 0.5 * w, pos_y + 0.5 * h, radius)
        self._frame_outline:resize(pos_x + 0.5 * w, pos_y + 0.5 * h, radius)
        self._stencil_mask:resize(pos_x + 0.5 * w, pos_y + 0.5 * h, radius)
    elseif self._type == rt.FrameType.ELLIPTICAL then
        local x_radius = w / 2 - 0.5 * thickness
        local y_radius = h / 2 - 0.5 * thickness
        self._frame:resize(pos_x + 0.5 * w, pos_y + 0.5 * h, x_radius, y_radius)
        self._frame_outline:resize(pos_x + 0.5 * w, pos_y + 0.5 * h, x_radius, y_radius)
        self._stencil_mask:resize(pos_x + 0.5 * w, pos_y + 0.5 * h, x_radius, y_radius)
    end
end

--- @overload rt.Widget.realize
function rt.Frame:realize()
    if meta.is_widget(self._child) then
        self._child:realize()
    end
    rt.Widget.realize(self)
end

--- @brief set singular child
--- @param child rt.Widget
function rt.Frame:set_child(child)
    meta.assert_widget(child)
    if not meta.is_nil(self._child) and meta.is_widget(self._child) then
        self._child:set_parent(nil)
    end

    self._child = child
    child:set_parent(self)

    if self:get_is_realized() then
        self._child:realize()
        self:reformat()
    end
end

--- @brief get singular child
--- @return rt.Widget
function rt.Frame:get_child()
    return self._child
end

--- @brief remove child
function rt.Frame:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @brief
function rt.Frame:set_color(color)
    if meta.is_hsva(color) then
        color = rt.rgba_to_hsva(color)
    end

    self._color = color
    self._frame:set_color(self._color)
end

--- @brief
function rt.Frame:get_color()
    return self._frame
end

--- @brief
function rt.Frame:set_thickness(thickness)
    if thickness < 0 then
        rt.error("In rt.Frame.set_thickness: value `" .. tostring(thickness) .. "` is out of range")
    end

    if self._thickness ~= thickness then
        self._thickness = thickness
        self._frame:set_line_width(self._thickness)
        self:reformat()
    end
end

--- @brief
function rt.Frame:get_thickness()
    return self._thickness
end

--- @brief
function rt.Frame:set_corner_radius(radius)
    if radius < 0 then
        rt.error("In rt.Frame.set_corner_radius: value `" .. tostring(radius) .. "` is out of range")
    end
    self._corner_radius = radius

    if self._type == rt.FrameType.RECTANGULAR and self._corner_radius ~= radius then
        local corner_radius = self._corner_radius
        self._frame:set_corner_radius(corner_radius)
        self._frame_outline:set_corner_radius(corner_radius)
        self._stencil_mask:set_corner_radius(corner_radius)
    end
end

--- @overload rt.Widget.measure
function rt.Frame:measure()
    if meta.is_widget(self._child) then
        local w, h = self._child:measure()
        w = math.max(w, select(1, self:get_minimum_size()))
        h = math.max(h, select(2, self:get_minimum_size()))

        return w + self._thickness * 2, h + self._thickness * 2
    else
        return rt.Widget.measure(self)
    end
end