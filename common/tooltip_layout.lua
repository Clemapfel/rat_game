rt.settings.tooltip = {
    frame_width = 3,
    frame_outline_width = 3 + 2
}

--- @class rt.TooltipLayout
--- @brief single-child contianer that allows showing showing a widget in a separate tooltip window
--- @param child rt.Widget
rt.TooltipLayout = meta.new_type("TooltipLayout", rt.Widget, function(child)
    local out = meta.new(rt.TooltipLayout, {
        _tooltip = {},
        _tooltip_backdrop = rt.Rectangle(0, 0, 1, 1),
        _tooltip_frame = rt.Rectangle(0, 0, 1, 1),
        _tooltip_frame_outline = rt.Rectangle(0, 0, 1, 1),
        _show_tooltip = false,
        _child = ternary(meta.is_nil(child), {}, child),
        _input = {}
    })

    out._tooltip_backdrop:set_color(rt.Palette.BACKGROUND)
    out._tooltip_backdrop:set_corner_radius(rt.settings.margin_unit)

    out._tooltip_frame:set_color(rt.Palette.BASE)
    out._tooltip_frame_outline:set_color(rt.Palette.BASE_OUTLINE)

    for frame in range(out._tooltip_frame, out._tooltip_frame_outline) do
        frame:set_corner_radius(rt.settings.margin_unit)
        frame:set_is_outline(true)
    end

    out._tooltip_frame:set_line_width(rt.settings.tooltip.frame_width)
    out._tooltip_frame_outline:set_line_width(rt.settings.tooltip.frame_outline_width)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("enter", function(_, x, y, self)
        self:set_tooltip_visible(true)
    end, out)
    out._input:signal_connect("motion", function(_, x, y, dx, dy, self)
        self:set_tooltip_visible(true)
    end, out)
    out._input:signal_connect("leave", function(_, x, y, self)
        self:set_tooltip_visible(false)
    end, out)
    return out
end)

--- @brief
function rt.TooltipLayout:_set_tooltip_opacity(alpha)
    for shape in range(self._tooltip_backdrop, self._tooltip_frame, self._tooltip_frame_outline) do
        local color = shape:get_color()
        color.a = alpha
        shape:set_color(color)
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.TooltipLayout:set_child(child)
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
function rt.TooltipLayout:get_child()
    return self._child
end

--- @brief remove child
function rt.TooltipLayout:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.TooltipLayout:set_tooltip(child)
    if not meta.is_nil(self._tooltip) and meta.isa(self._tooltip, rt.Widget) then
        self._tooltip:set_parent(nil)
    end

    self._tooltip = child
    child:set_parent(self)

    if self:get_is_realized() then
        self._tooltip:realize()
        self:reformat()
    end
end

--- @brief get singular child
--- @return rt.Widget
function rt.TooltipLayout:get_tooltip()
    return self._tooltip
end

--- @brief remove child
function rt.TooltipLayout:remove_tooltip()
    if not meta.is_nil(self._tooltip) then
        self._tooltip:set_parent(nil)
        self._tooltip = nil
    end
end

--- @overload rt.Drawable.draw
function rt.TooltipLayout:draw()
    if not self:get_is_visible() then return end
    if meta.isa(self._child, rt.Widget) then
        self._child:draw()
    end

    if meta.isa(self._tooltip, rt.Widget) and self._show_tooltip then
        self._tooltip_backdrop:draw()
        self._tooltip_frame_outline:draw()
        self._tooltip_frame:draw()
        self._tooltip:draw()
    end
end

--- @brief
function rt.TooltipLayout:set_tooltip_visible(b)
    self._show_tooltip = b
    local visible = self._show_tooltip
    if not meta.is_widget(self._tooltip) then return end

    if visible == true and not self._tooltip:get_is_realized() then
        self._tooltip:realize()
    end

    if meta.isa(self._tooltip, rt.Widget) then
        self._tooltip:set_is_visible(visible)
    end
    self._tooltip_backdrop:set_is_visible(visible)
    self._tooltip_frame:set_is_visible(visible)
    self._tooltip_frame_outline:set_is_visible(visible)
end

--- @brief
function rt.TooltipLayout:get_tooltip_visible()
    return self._show_tooltip
end

--- @overload rt.Widget.size_allocate
function rt.TooltipLayout:size_allocate(x, y, width, height)
    local child_x, child_y = x, y
    local child_w, child_h = 0, 0

    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
        child_x, child_y = self._child:get_position()
        child_w, child_h = self._child:measure()
    end

    if meta.isa(self._tooltip, rt.Widget) then
        local frame_thickness = self._tooltip_frame:get_line_width()
        local tooltip_w, tooltip_h = self._tooltip:measure()
        local tooltip_x, tooltip_y = child_x + child_w + rt.settings.margin_unit + frame_thickness, child_y --+ frame_thickness

        -- prefer right of chlid, if not enough space, display left of child
        local space_right = (tooltip_x + tooltip_w + rt.settings.margin_unit + 2 * frame_thickness) < love.graphics.getWidth()
        if not space_right then
            tooltip_x = child_x - tooltip_w - rt.settings.margin_unit - 2 * frame_thickness
        end

        -- prefer top left of tooltip aligned with child_y, if not enough space, shift tooltip up
        local space_bottom = tooltip_y + tooltip_h + rt.settings.margin_unit + frame_thickness < love.graphics.getHeight()
        if not space_bottom then
            tooltip_y = child_y - ((tooltip_y + tooltip_h + 2 * frame_thickness + rt.settings.margin_unit) - love.graphics.getHeight())
        end

        local margin = 0
        local frame_width = rt.settings.tooltip.frame_outline_width
        local backdrop_area = rt.AABB(
            tooltip_x,
            tooltip_y,
            tooltip_w + 2 * margin + 2 * frame_width,
            tooltip_h + 2 * margin + 2 * frame_width
        )

        self._tooltip:fit_into(rt.AABB(tooltip_x + margin + frame_thickness, tooltip_y + margin + frame_thickness, tooltip_w, tooltip_h))
        self._tooltip_backdrop:resize(backdrop_area)
        self._tooltip_frame:resize(backdrop_area)
        self._tooltip_frame_outline:resize(backdrop_area)
    end
end

--- @overload rt.Widget.measure
function rt.TooltipLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.TooltipLayout:realize()
    if self:get_is_realized() then return end

    if meta.is_widget(self._child) then
        self._child:realize()
    end

    if meta.is_widget(self._tooltip) and self._show_tooltip then
        self._tooltip:realize()
    end

    rt.Widget.realize(self)
end

--- @overload rt.Widget.set_is_selected
function rt.TooltipLayout:set_is_selected(b)

    rt.Widget.set_is_selected(b)
    self:set_tooltip_visible(b)
end

--- @brief test Tooltip
function rt.test.tooltip()
    error("TODO")
end

