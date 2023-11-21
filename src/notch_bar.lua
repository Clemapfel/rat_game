rt.settings.notch_bar = {
    notch_spacing = 0.1,              -- radius factor
    notch_center_radius_factor = 0.2, -- outer radius of middle peg
    notch_frame_radius_factor = 0.8,  -- inner radius of outer ring
    min_frame_thickness = 3,    -- minimum peg and ring thickness, px
    indicator_radius = 0.8,     -- times notch radius
}

--- @class rt.Notch
rt.Notch = meta.new_type("Notch", function()
    local out = meta.new(rt.Notch, {
        _center = rt.Circle(0, 0, 1),
        _center_outline = rt.Circle(0, 0, 1),
        _shape = rt.Circle(0, 0, 1),
        _frame = rt.Circle(0, 0, 1),
        _frame_outline_inner = rt.Circle(0, 0, 1),
        _frame_outline_outer = rt.Circle(0, 0, 1)
    }, rt.Drawable) -- sic, no widget

    out._center_outline:set_is_outline(true)
    out._frame_outline_inner:set_is_outline(true)
    out._frame_outline_outer:set_is_outline(true)

    out._center:set_color(rt.Palette.FOREGROUND)
    out._center_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)
    out._frame:set_color(rt.Palette.FOREGROUND)
    out._frame_outline_inner:set_color(rt.Palette.BASE_OUTLINE)
    out._frame_outline_inner:set_line_width(2)
    out._frame_outline_outer:set_color(rt.Palette.BASE_OUTLINE)

    out._shape:set_color(rt.Palette.BASE)
    return out
end)

function rt.Notch:set_color(color)
    meta.assert_rgba(color)
    meta.assert_isa(self, rt.Notch)
    self._shape:set_color(color)
end

--- @overload rt.Drawable.draw
function rt.Notch:draw()
    meta.assert_isa(self, rt.Notch)
    self._frame:draw()
    self._shape:draw()
    self._center:draw()
    self._center_outline:draw()
    self._frame_outline_inner:draw()
    self._frame_outline_outer:draw()
end

--- @overload rt.Widget.size_allocate
function rt.Notch:fit_into(x, y, width, height)
    meta.assert_isa(self, rt.Notch)

    local radius = math.min(width, height) / 2
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height

    local min_frame_thickness = rt.settings.notch_bar.min_frame_thickness
    local center_radius = math.max(rt.settings.notch_bar.notch_center_radius_factor * radius, min_frame_thickness)
    local frame_radius = math.min(rt.settings.notch_bar.notch_frame_radius_factor * radius, radius - min_frame_thickness) -- inner
    local eps = 1 / 400

    self._center:resize(center_x, center_y, center_radius)
    self._center_outline:resize(center_x, center_y, center_radius + eps)
    self._shape:resize(center_x, center_y, frame_radius)
    self._frame:resize(center_x, center_y, radius)
    self._frame_outline_inner:resize(center_x, center_y, frame_radius)
    self._frame_outline_outer:resize(center_x, center_y, radius)
end

--- @class rt.NotchBar
rt.NotchBar = meta.new_type("NotchBar", function(n_notches)
    if meta.is_nil(n_notches) then n_notches = 1 end
    meta.assert_number(n_notches)

    local out = meta.new(rt.NotchBar, {
        _notches = rt.List(),
        _left_indicator = rt.Circle(0, 0, 1, 3),
        _left_indicator_frame = rt.Circle(0, 0, 1, 3),
        _right_indicator = rt.Circle(0, 0, 1, 3),
        _right_indicator_frame = rt.Circle(0, 0, 1, 3),
        _base_color = rt.Palette.BACKGROUND,
        _highlight_color = rt.Palette.HIGHLIGHT
    }, rt.Drawable, rt.Widget)

    while out._notches:size() <= n_notches do
        out._notches:push_back(rt.Notch())
    end

    out._left_indicator:set_color(rt.Palette.FOREGROUND)
    out._left_indicator_frame:set_color(rt.Palette.BASE_OUTLINE)
    out._left_indicator_frame:set_is_outline(true)

    out._right_indicator:set_color(rt.Palette.FOREGROUND)
    out._right_indicator_frame:set_color(rt.Palette.BASE_OUTLINE)
    out._right_indicator_frame:set_is_outline(true)

    out:set_n_filled(0)
    return out
end)

--- @overload rt.Drawable.draw
function rt.NotchBar:draw()
    meta.assert_isa(self, rt.NotchBar)
    for _, notch in pairs(self._notches) do
        notch:draw()
    end

    -- rotate so it points to the left
    love.graphics.push()
    local x, y = self._left_indicator:get_center()
    love.graphics.translate(x, y)
    love.graphics.rotate(rt.degrees(180):as_radians())
    love.graphics.translate(-x, -y)

    self._left_indicator:draw()
    self._left_indicator_frame:draw()

    love.graphics.pop()

    self._right_indicator:draw()
    self._right_indicator_frame:draw()
end

--- @overload rt.Widget.size_allocate
function rt.NotchBar:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.NotchBar)
    local n_notches = self._notches:size()
    local notch_diameter = width / (n_notches + 2)

    local margin = rt.settings.notch_bar.notch_spacing * (notch_diameter / 2)
    local notch_x = x + 0.5 * width - 0.5 * (notch_diameter * n_notches + n_notches * margin) + 0.5 * notch_diameter
    local notch_y = y + 0.5 * height - 0.5 * notch_diameter

    local indicator_radius = rt.settings.notch_bar.indicator_radius * (notch_diameter / 2)
    self._left_indicator:resize(notch_x - 0.5 * notch_diameter + indicator_radius * 0.25, notch_y + 0.5 * notch_diameter, indicator_radius)
    self._left_indicator_frame:resize(notch_x - 0.5 * notch_diameter + indicator_radius * 0.25, notch_y + 0.5 * notch_diameter, indicator_radius)

    for i, notch in pairs(self._notches) do
        notch:fit_into(notch_x, notch_y, notch_diameter, notch_diameter)
        notch_x = notch_x + notch_diameter + margin
    end

    self._right_indicator:resize(notch_x + 0.5 * notch_diameter - indicator_radius * 0.25, notch_y + 0.5 * notch_diameter, indicator_radius)
    self._right_indicator_frame:resize(notch_x + 0.5 * notch_diameter - indicator_radius * 0.25, notch_y + 0.5 * notch_diameter, indicator_radius)
end

--- @brief fill all notches up to position
function rt.NotchBar:set_n_filled(n)
    meta.assert_isa(self, rt.NotchBar)
    meta.assert_number(n)

    n = clamp(n, 0, self._notches:size())

    local i = 1
    for _, notch in pairs(self._notches) do
        if i + 1 > n then
            notch._shape:set_color(self._base_color)
        else
            notch._shape:set_color(self._highlight_color)
        end
        i = i + 1
    end
end

--- @brief fill notch at position
--- @param index Number or 0 for none filled
function rt.NotchBar:set_filled(index)
    meta.assert_isa(self, rt.NotchBar)
    meta.assert_number(index)
    index = clamp(index, 0, self._notches:size() - 1)

    local i = 1
    for _, notch in pairs(self._notches) do
        if i == index then
            notch._shape:set_color(self._highlight_color)
        else
            notch._shape:set_color(self._base_color)
        end
        i = i + 1
    end
end

--- @brief
function rt.NotchBar:set_fill_color(color)
    meta.assert_isa(self, rt.NotchBar)

    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end

    for _, notch in pairs(self._notches) do
        if notch._shape:get_color() == self._highlight_color then
            notch._shape:set_color(color)
        end
    end

    self._highlight_color = color
end

--- @brief [internal]
function rt.test.notch_bar()
    error("TODO")
end