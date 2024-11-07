--- @class rt.FrameType
rt.FrameType = meta.new_enum("FrameType", {
    RECTANGULAR = 1,
    CIRCULAR = 2,
    ELLIPTICAL = 3
})

rt.settings.frame = {
    thickness = 2, -- px
    corner_radius = 10,
    selected_base_color = (function()
        local a = rt.Palette.GRAY_5
        local b = rt.Palette.BACKGROUND
        local weight = 0.25
        return rt.RGBA(
            mix(a.r, b.r, weight),
            mix(a.g, b.g, weight),
            mix(a.b, b.b, weight),
            math.max(a.a, b.a)
        )
    end)()
}

--- @class rt.Frame
rt.Frame = meta.new_type("Frame", rt.Widget, function(type)
    if type == nil then type = rt.FrameType.RECTANGULAR end
    local out = meta.new(rt.Frame, {
        _type = type,
        _child = {},
        _child_valid = false,
        _stencil_mask = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
        _stencil_mask_stencil_value = rt.Frame.stencil_id,
        _frame = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
        _frame_outline = ternary(type == rt.FrameType.RECTANGULAR, rt.Rectangle(0, 0, 1, 1), rt.Circle(0, 0, 1)),
        _color = rt.Palette.FOREGROUND,
        _thickness = rt.settings.frame.thickness,
        _corner_radius = rt.settings.frame.corner_radius,
        _selection_state = rt.SelectionState.INACTIVE
    })

    rt.Frame.stencil_id = rt.Frame.stencil_id + 1

    out._frame:set_is_outline(true)
    out._frame_outline:set_line_width(rt.settings.frame.thickness + 2)
    out._frame_outline:set_is_outline(true)

    out._frame:set_color(out._color)
    out._frame_outline:set_color(rt.Palette.BASE_OUTLINE)

    out._frame:set_line_width(out._thickness)
    out._stencil_mask:set_color(rt.Palette.BACKGROUND)
    if out._type == rt.FrameType.RECTANGULAR then
        local corner_radius = out._corner_radius
        out._frame:set_corner_radius(corner_radius)
        out._frame_outline:set_corner_radius(corner_radius)
        out._stencil_mask:set_corner_radius(corner_radius - 2)
    end
    return out
end, {
    stencil_id = 128
})

function rt.Frame:_bind_stencil()
    local stencil_value = meta.hash(self._stencil_mask) -- draw child with corners masked away
    rt.graphics.stencil(stencil_value, self._stencil_mask)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
end

function rt.Frame:_unbind_stencil()
    rt.graphics.set_stencil_test()
end

--- @overload rt.Drawable.draw
function rt.Frame:draw()
    self._stencil_mask:draw()
    if self._child_valid then
        self:_bind_stencil()
        self._child:draw()
        self:_unbind_stencil()
    end

    self._frame_outline:draw()
    self._frame:draw()
end

--rt.Frame.draw = function()  end

--- @overload rt.Widget.size_allocate
function rt.Frame:size_allocate(x, y, width, height)
    local pos_x, pos_y, w, h = x, y, width, height

    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
        self._child:set_opacity(self._opacity)
    end

    local thickness = self._thickness + 2
    if self._type == rt.FrameType.RECTANGULAR then
        self._frame:resize(rt.AABB(pos_x + 0.5 * thickness, pos_y + 0.5 * thickness, w - thickness, h - thickness))
        self._frame_outline:resize(rt.AABB(pos_x + 0.5 * thickness, pos_y + 0.5 * thickness, w - thickness, h - thickness))
        self._stencil_mask:resize(rt.AABB(pos_x + thickness, pos_y + thickness, w - 2 * thickness, h - 2 * thickness))
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

    self._frame:set_opacity(self._opacity)
    self._frame_outline:set_opacity(self._opacity)
end

--- @overload rt.Widget.realize
function rt.Frame:realize()
    if self:already_realized() then return end
    if meta.is_widget(self._child) then
        self._child:realize()
    end
    rt.Widget.realize(self)
end

--- @brief set singular child
--- @param child rt.Widget
function rt.Frame:set_child(child)
    meta.assert_widget(child)
    self._child = child
    self._child_valid = true

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
    if not (self._child == nil) then
        self._child = {}
        self._child_valid = false
    end
end

--- @brief
function rt.Frame:set_color(color, base_color)
    if meta.is_hsva(color) then
        color = rt.rgba_to_hsva(color)
    end

    self._color = color
    self._frame:set_color(self._color)

    if base_color ~= nil then
        self._stencil_mask:set_color(base_color)
    else
        self._stencil_mask:set_color(rt.Palette.BACKGROUND)
    end
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
        self._frame_outline:set_line_width(self._thickness + 2)
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

--- @brief
function rt.Frame:get_corner_radius()
    return self._corner_radius
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

--- @override
function rt.Frame:set_opacity(alpha)
    self._opacity = alpha
    if meta.is_widget(self._child) then self._child:set_opacity(self._opacity) end
    self._frame:set_opacity(self._opacity)
    self._frame_outline:set_opacity(self._opacity)
    self._stencil_mask:set_opacity(self._opacity)
end

--- @brief
function rt.Frame:set_type(type)
    if type ~= self._type then
        self._type = type
        self:reformat()
    end
end

--- @brief
function rt.Frame:get_type()
    return self._type
end

--- @brief
function rt.Frame:set_selection_state(selection_state)
    self._selection_state = selection_state
    if self._selection_state == rt.SelectionState.INACTIVE then
        self._frame:set_line_width(self._thickness)
        self._frame_outline:set_line_width(self._thickness + 2)
        self._frame:set_color(self._color)
        for shape in range(self._frame, self._frame_outline) do
            shape:set_opacity(1)
        end
        self._stencil_mask:set_color(rt.Palette.BACKGROUND)
    elseif self._selection_state == rt.SelectionState.ACTIVE then
        self._frame:set_line_width(self._thickness + 2)
        self._frame_outline:set_line_width(self._thickness + 2 + 2)
        self._frame:set_color(rt.Palette.SELECTION)
        for shape in range(self._frame, self._frame_outline) do
            shape:set_opacity(1)
        end
        self._stencil_mask:set_color(rt.settings.frame.selected_base_color)
    elseif self._selection_state == rt.SelectionState.UNSELECTED then
        self._frame:set_line_width(self._thickness)
        self._frame_outline:set_line_width(self._thickness + 2)
        self._frame:set_color(self._color)
        for shape in range(self._frame, self._frame_outline) do
            shape:set_opacity(rt.settings.selection_state.unselected_opacity)
        end
    end
end

--- @brief
function rt.Frame:get_selection_state()
    return self._selection_state
end
