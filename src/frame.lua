--- @class rt.FrameType
rt.FrameType = meta.new_enum({
    RECTANGULAR = 1,
    CIRCULAR = 2
})

rt.settings.frame = {
    thickness = 5, -- px
    corner_radius = 10
}

--- @class rt.Frame
rt.Frame = meta.new_type("Frame", function(type)
    if meta.is_nil(type) then type = rt.FrameType.RECTANGULAR end
    meta.assert_enum(type, rt.FrameType)

    local out = meta.new(rt.Frame, {
        _type = type,
        _child = {},
        _frame_thickness = rt.settings.frame.thickness,
        _frame = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
        _frame_outline = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
    }, rt.Drawable, rt.Widget)

    out._frame:set_is_outline(true)
    out._frame:set_line_width(out._frame_thickness)
    out._frame_outline:set_line_width(rt.settings.frame.thickness + 2)
    out._frame_outline:set_is_outline(true)

    out._frame:set_color(rt.Palette.FOREGROUND)
    out._frame_outline:set_color(rt.Palette.BASE_OUTLINE)

    local corner_radius = rt.settings.frame.corner_radius
    out._frame:set_corner_radius(corner_radius)
    out._frame_outline:set_corner_radius(corner_radius)
    return out
end)


--- @overload rt.Drawable.draw
function rt.Frame:draw()
    meta.assert_isa(self, rt.Frame)
    if not self:get_is_visible() then return end

    if meta.is_widget(self._child) then

        local pos_x, pos_y = self._child:get_position()
        local w, h = self._child:get_size()
        local thickness = rt.settings.frame.thickness


        love.graphics.stencil(function()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("fill", 225, 200, 350, 300)
        end, "replace", 255)
        love.graphics.setStencilTest("less", 255)

        self._child:draw()
        self._frame_outline:draw()
        self._frame:draw()

        love.graphics.setStencilTest()
    end
end

--- @overload rt.Widget.size_allocate
function rt.Frame:size_allocate(x, y, width, height)
    if not meta.is_widget(self._child) then
        return
    end

    self._child:fit_into(rt.AABB(x, y, width, height))
    if self._type == rt.FrameType.RECTANGULAR then
        local pos_x, pos_y = self._child:get_position()
        local w, h = self._child:get_size()

        local thickness = rt.settings.frame.thickness
        self._frame:resize(rt.AABB(pos_x + 0.5 * thickness, pos_y + 0.5 * thickness, w - thickness, h - thickness))
        self._frame_outline:resize(rt.AABB(pos_x + 0.5 * thickness, pos_y + 0.5 * thickness, w - thickness, h - thickness))
    end
end

--- @overload rt.Widget.realize
function rt.Frame:realize()
    meta.assert_isa(self, rt.Frame)
    if meta.is_widget(self._child) then
        self._child:realize()
    end
    rt.Widget.realize(self)
end

--- @brief set singular child
--- @param child rt.Widget
function rt.Frame:set_child(child)
    meta.assert_isa(self, rt.Frame)
    meta.assert_isa(child, rt.Widget)

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
    meta.assert_isa(self, rt.Frame)
    return self._child
end

--- @brief remove child
function rt.Frame:remove_child()
    meta.assert_isa(self, rt.Frame)
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end