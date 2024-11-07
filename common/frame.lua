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
    local out = meta.new(rt.Frame, {
        _type = type,
        _child = {},
        _child_valid = false,

        _aabb = rt.AABB(0, 0, 1, 1),

        _color = rt.Palette.FOREGROUND,
        _stencil_color = rt.Palette.BACKGROUND,
        _frame_color = rt.Palette.FOREGROUND,
        _outline_color = rt.Palette.BASE_OUTLINE,

        _thickness = rt.settings.frame.thickness,
        _corner_radius = rt.settings.frame.corner_radius,
        _selection_state = rt.SelectionState.INACTIVE
    })
    out:_update_draw()
    return out
end)

function rt.Frame:_update_draw()
    local x, y, w, h = rt.aabb_unpack(self._bounds)
    local stencil_r, stencil_g, stencil_b, stencil_a = rt.color_unpack(self._stencil_color)
    local frame_r, frame_g, frame_b, frame_a = rt.color_unpack(self._frame_color)
    local outline_r, outline_g, outline_b, outline_a = rt.color_unpack(self._outline_color)

    local opacity = self._opacity
    local thickness = self._thickness + ternary(self._selection_state == rt.SelectionState.ACTIVE, 2, 0)
    local corner_radius = self._corner_radius

    self.draw = function(self)
        love.graphics.setColor(stencil_r, stencil_g, stencil_b, opacity)
        love.graphics.rectangle(
            "fill",
            x, y, w, h,
            corner_radius, corner_radius
        )

        love.graphics.setLineWidth(thickness + 2)
        love.graphics.setColor(outline_r, outline_g, outline_b, opacity)
        love.graphics.rectangle(
            "line",
            x, y, w, h,
            corner_radius, corner_radius
        )

        love.graphics.setLineWidth(thickness)
        love.graphics.setColor(frame_r, frame_g, frame_b, opacity)
        love.graphics.rectangle(
            "line",
            x, y, w, h,
            corner_radius, corner_radius
        )

        love.graphics.setColor(1, 1, 1, 1)
    end
end

function rt.Frame:bind_stencil()
    local stencil_value = meta.hash(self) % 254 + 1
    love.graphics.setStencilMode("draw", stencil_value)
    local x, y, w, h = rt.aabb_unpack(self._bounds)
    local corner_radius = self._corner_radius
    love.graphics.rectangle(
        "fill",
        x, y, w, h,
        corner_radius, corner_radius
    )
    love.graphics.setStencilMode("test")
end

function rt.Frame:unbind_stencil()
    love.graphics.setStencilMode()
end

--- @overload rt.Widget.realize
function rt.Frame:realize()
    if self:already_realized() then return end
    if meta.is_widget(self._child) then
        self._child:realize()
    end
    rt.Widget.realize(self)
end

--- @override
function rt.Frame:size_allocate(x, y, w, h)
    self._aabb = rt.AABB(x, y, w, h)
    self:_update_draw()
end

--- @brief
function rt.Frame:set_color(color, base_color)
    if meta.is_hsva(color) then
        color = rt.rgba_to_hsva(color)
    end

    self._frame_color = color

    if base_color ~= nil then
        self._stencil_color = base_color
    else
        self._stencil_color = rt.Palette.BACKGROUND
    end

    self:_update_draw()
end

--- @brief
function rt.Frame:set_thickness(thickness)
    if thickness < 0 then
        rt.error("In rt.Frame.set_thickness: value `" .. tostring(thickness) .. "` is out of range")
    end

    if self._thickness ~= thickness then
        self._thickness = thickness
    end

    self:_update_draw()
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
    self:_update_draw()
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
    self:_update_draw()
end

--- @brief
function rt.Frame:set_selection_state(selection_state)
    self._selection_state = selection_state
    if self._selection_state == rt.SelectionState.INACTIVE then
        self._stencil_color = rt.Palette.BACKGROUND
        self._frame_color = self._color
    elseif self._selection_state == rt.SelectionState.ACTIVE then
        self._frame_color = rt.Palette.SELECTION
        self._stencil_color = rt.settings.frame.selected_base_color
    elseif self._selection_state == rt.SelectionState.UNSELECTED then
        self._stencil_color = rt.Palette.BACKGROUND
        self._frame_color = self._color
        self._opacity = 0.5
    end
    self:_update_draw()
end

--- @brief
function rt.Frame:get_selection_state()
    return self._selection_state
end