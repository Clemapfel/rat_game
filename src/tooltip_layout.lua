rt.settings.tooltip = {
    frame_width = 3,
    frame_outline_width = 3 + 2,
    margin = rt.settings.margin_unit * 1.5,
    delay = 1 -- seconds
}

--- @class rt.TooltipLayout
rt.TooltipLayout = meta.new_type("TooltipLayout", function(child)
    local out = meta.new(rt.TooltipLayout, {
        _tooltip = {},
        _tooltip_backdrop = rt.Rectangle(0, 0, 1, 1),
        _tooltip_frame = rt.Rectangle(0, 0, 1, 1),
        _tooltip_frame_outline = rt.Rectangle(0, 0, 1, 1),
        _show_tooltip = true,
        _child = child,
        _input = {}
    }, rt.Drawable, rt.Widget)

    out._tooltip_backdrop:set_color(rt.Palette.BACKGROUND)
    out._tooltip_backdrop:set_corner_radius(rt.settings.margin_unit)

    out._tooltip_frame:set_color(rt.Palette.BASE)
    out._tooltip_frame_outline:set_color(rt.Palette.BASE_OUTLINE)

    for _, frame in pairs({out._tooltip_frame, out._tooltip_frame_outline}) do
        frame:set_corner_radius(rt.settings.margin_unit)
        frame:set_is_outline(true)
    end

    out._tooltip_frame:set_line_width(rt.settings.tooltip.frame_width)
    out._tooltip_frame_outline:set_line_width(rt.settings.tooltip.frame_outline_width)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("enter", function(_, x, y, self)
        self:set_show_tooltip(true)
    end, out)
    out._input:signal_connect("motion", function(_, x, y, dx, dy, self)
        self:set_show_tooltip(true)
    end, out)
    out._input:signal_connect("leave", function(_, x, y, self)
        self:set_show_tooltip(false)
    end, out)
    return out
end)

--- @brief
function rt.TooltipLayout:_set_tooltip_opacity(alpha)
    meta.assert_isa(self, rt.TooltipLayout)
    for _, shape in pairs({self._tooltip_backdrop, self._tooltip_frame, self._tooltip_frame_outline}) do
        local color = shape:get_color()
        color.a = alpha
        shape:set_color(color)
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.TooltipLayout:set_tooltip(child)
    meta.assert_isa(self, rt.TooltipLayout)
    meta.assert_isa(child, rt.Widget)

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
    meta.assert_isa(self, rt.TooltipLayout)
    return self._tooltip
end

--- @brief remove child
function rt.TooltipLayout:remove_tooltip()
    meta.assert_isa(self, rt.TooltipLayout)
    if not meta.is_nil(self._tooltip) then
        self._tooltip:set_parent(nil)
        self._tooltip = nil
    end
end

--- @overload rt.Drawable.draw
function rt.TooltipLayout:draw()
    meta.assert_isa(self, rt.TooltipLayout)
    if not self:get_is_visible() then return end

    if meta.isa(self._tooltip, rt.Widget) then
        self._child:draw()
    end

    if meta.isa(self._tooltip, rt.Widget) and self:get_is_visible() and self._show_tooltip then
        self._tooltip_backdrop:draw()
        self._tooltip:draw()
        self._tooltip_frame_outline:draw()
        self._tooltip_frame:draw()
    end
end

--- @brief
function rt.TooltipLayout:set_show_tooltip(b)
    meta.assert_isa(self, rt.TooltipLayout)
    meta.assert_boolean(b)

    self._show_tooltip = b
    local visible = self._show_tooltip
    if meta.isa(self._tooltip, rt.Widget) then
        self._tooltip:set_is_visible(visible)
    end
    self._tooltip_backdrop:set_is_visible(visible)
    self._tooltip_frame:set_is_visible(visible)
    self._tooltip_frame_outline:set_is_visible(visible)
end

--- @brief
function rt.TooltipLayout:get_show_tooltip()
    meta.assert_isa(self, rt.TooltipLayout)
    return self._show_tooltip
end

--- @overload rt.Widget.size_allocate
function rt.TooltipLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.TooltipLayout)
    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end

    meta.assert_isa(self, rt.TooltipLayout)
    meta.assert_number(x, y)

    if meta.isa(self._tooltip, rt.Widget) then
        local tooltip_w, tooltip_h = self._tooltip:measure()
        local tooltip_x, tooltip_y = x + 0.5 * width - 0.5 * tooltip_w, y + 0.5 * height - 0.5 * tooltip_h

        local margin = rt.settings.tooltip.margin
        local frame_width = rt.settings.tooltip.frame_outline_width
        local backdrop_area = rt.AABB(
                tooltip_x - margin - frame_width ,
                tooltip_y - margin - frame_width,
                tooltip_w + 2 * margin + 2 * frame_width,
                tooltip_h + 2 * margin + 2 * frame_width
        )

        self._tooltip:fit_into(rt.AABB(tooltip_x, tooltip_y, tooltip_w, tooltip_h))
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
    self._child:realize()
    self._tooltip:realize()
    rt.Widget.realize(self)
end

--- @overload rt.Widget.set_is_selected
function rt.TooltipLayout:set_is_selected(b)
    meta.assert_isa(self, rt.TooltipLayout)
    rt.Widget.set_is_selected(b)
    self:set_show_tooltip(b)
end

--- @brief test Tooltip
function rt.test.bin_layout()
    error("TODO")
end

