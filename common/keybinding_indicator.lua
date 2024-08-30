rt.settings.keybinding_indicator = {
    font_path = "assets/fonts/Roboto/Roboto-Black.ttf"
}

--- @class rt.KeybindingIndicator
rt.KeybindingIndicator = meta.new_type("KeybindingIndicator", rt.Widget, function(key)
    if not (meta.is_enum_value(key, rt.KeyboardKey) or meta.is_enum_value(key, rt.GamepadButton)) then
        rt.error("In rt.KeybindingIndicator(): key `" .. key .. "` is not a valid keyboard key or gamepad button identifier")
    end
    return meta.new(rt.KeybindingIndicator, {
        _key = key,
        _font = nil, -- rt.Font
        _content = {}, -- Table<rt.Drawable>
    })
end, {
    font_size_to_font = {},
    foreground_color = rt.Palette.GRAY_3,
    background_color = rt.Palette.GRAY_4,
    outline_color = rt.Palette.GRAY_6,
    outline_outline_color = rt.Palette.TRUE_WHITE
})

--- @override
function rt.KeybindingIndicator:realize()
    if self:get_is_realized() == true then return end
    self._is_realized = true
end

--- @override
function rt.KeybindingIndicator:size_allocate(x, y, width, height)
    if meta.is_enum_value(self._key, rt.KeyboardKey) then
        self:_as_keyboard_key(rt.keyboard_key_to_string(self._key), height)
    elseif self._key == rt.GamepadButton.TOP or self._key == rt.GamepadButton.RIGHT or self._key == rt.GamepadButton.BOTTOM or self._key == rt.GamepadButton.LEFT then
        self:_as_button(self._key, height)
    end
end

--- @override
function rt.KeybindingIndicator:draw()
    rt.graphics.translate(self._bounds.x, self._bounds.y)
    for drawable in values(self._content) do
        drawable:draw()
    end
    rt.graphics.translate(-self._bounds.x, -self._bounds.y)
end

--- @brief
function rt.KeybindingIndicator:_as_keyboard_key(label, width)

    -- find appropriate font size
    local label_w
    local font_size = math.round(0.35 * width)
    local label_m = 10
    repeat
        local font = rt.KeybindingIndicator.font_size_to_font[font_size]
        if font == nil then
            rt.KeybindingIndicator.font_size_to_font[font_size] = rt.Font(font_size, rt.settings.keybinding_indicator.font_path)
            font = rt.KeybindingIndicator.font_size_to_font[font_size]
        end

        label_w, _ = font:measure_glyph(label)
        self._font = font

        font_size = font_size - 2
    until label_w < (width - 2 * label_m) or font_size < 12

    local x, y = 0, 0
    local height = width

    local glyph = rt.Label("<o>" .. label .. "</o>", self._font)
    glyph:set_justify_mode(rt.JustifyMode.CENTER)
    glyph:realize()
    local glyph_w, glyph_h = glyph:measure()

    local base_w, base_h = width - 2 * label_m, height - 2 * label_m
    local front_w, front_h = 0.8 * base_w, 0.8 * base_h
    local front_offset = (base_h - front_h) * 0.25
    local front_base, front_base_outline, base, base_outline = rt.Rectangle(), rt.Rectangle(), rt.Rectangle(), rt.Rectangle()

    glyph:fit_into(x, y + 0.5 * height - 0.5 * glyph_h - front_offset, width, height)

    local front_x, front_y = x + 0.5 * width - 0.5 * front_w, y + 0.5 * height - 0.5 * front_h - front_offset
    for shape in range(front_base, front_base_outline) do
        shape:resize(front_x, front_y, front_w, front_h)
    end

    local base_x, base_y =  x + 0.5 * width - 0.5 * base_w, y + 0.5 * height - 0.5 * base_h
    for shape in range(base, base_outline) do
        shape:resize(base_x, base_y, base_w, base_h)
    end

    local corner_radius = 2
    for shape in range(front_base, front_base_outline, base, base_outline) do
        shape:set_corner_radius(corner_radius)
    end

    base:set_color(self.background_color)
    front_base:set_color(self.foreground_color)
    local outline_color = self.outline_color

    local outline_width = width / 50
    for outline in range(front_base_outline, base_outline) do
        outline:set_is_outline(true)
        outline:set_color(outline_color)
        outline:set_line_width(outline_width)
    end

    local lines = {}
    table.insert(lines, rt.Line(
        front_x, front_y,
        base_x, base_y
    ))

    table.insert(lines, rt.Line(
        front_x + front_w, front_y,
        base_x + base_w, base_y
    ))

    table.insert(lines, rt.Line(
        front_x, front_y + front_h,
        base_x, base_y + base_h
    ))

    table.insert(lines, rt.Line(
        front_x + front_w, front_y + front_h,
        base_x + base_w, base_y + base_h
    ))

    for line in values(lines) do
        line:set_color(outline_color)
        line:set_line_width(outline_width)
    end

    local outline_outline_w = 2
    local outline_outline = rt.Rectangle(
        base_x - outline_outline_w,
        base_y - outline_outline_w,
        base_w + 2 * outline_outline_w,
        base_h + 2 * outline_outline_w
    )
    outline_outline:set_corner_radius(corner_radius)
    outline_outline:set_color(self.outline_outline_color)

    self._content = {
        outline_outline,
        base,
        base_outline,
        front_base,
        front_base_outline
    }

    outline_outline:draw()
    base:draw()
    base_outline:draw()
    front_base:draw()
    front_base_outline:draw()
    for line in values(lines) do
        table.insert(self._content, line)
    end

    table.insert(self._content, glyph)
end

--- @brief
function rt.KeybindingIndicator:_as_button(which, width)
    local total_w = width
    local button_outer_m = 0.225 * width
    local button_inner_m = button_outer_m
    local button_r = (width - 2 * button_outer_m - button_inner_m) / 2

    local x, y = 0, 0
    local height = width

    local center_offset_x, center_offset_y = 0.5 * button_inner_m + button_r, 0.5 * button_inner_m + button_r
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local top_x, top_y = center_x, center_y - center_offset_y
    local right_x, right_y = center_x + center_offset_x, center_y
    local bottom_x, bottom_y = center_x, center_y + center_offset_y
    local left_x, left_y = center_x - center_offset_x, center_y

    local top_base, top_outline = rt.Circle(top_x, top_y, button_r), rt.Circle(top_x, top_y, button_r)
    local right_base, right_outline = rt.Circle(right_x, right_y, button_r), rt.Circle(right_x, right_y, button_r)
    local bottom_base, bottom_outline = rt.Circle(bottom_x, bottom_y, button_r), rt.Circle(bottom_x, bottom_y, button_r)
    local left_base, left_outline = rt.Circle(left_x, left_y, button_r), rt.Circle(left_x, left_y, button_r)

    local back_x_offset, back_y_offset = 5, 2
    local top_back, top_back_outline = rt.Circle(top_x + back_x_offset, top_y + back_y_offset, button_r), rt.Circle(top_x + back_x_offset, top_y + back_y_offset, button_r)
    local right_back, right_back_outline = rt.Circle(right_x + back_x_offset, right_y + back_y_offset, button_r), rt.Circle(right_x + back_x_offset, right_y + back_y_offset, button_r)
    local bottom_back, bottom_back_outline = rt.Circle(bottom_x + back_x_offset, bottom_y + back_y_offset, button_r), rt.Circle(bottom_x + back_x_offset, bottom_y + back_y_offset, button_r)
    local left_back, left_back_outline = rt.Circle(left_x + back_x_offset, left_y + back_y_offset, button_r), rt.Circle(left_x + back_x_offset, left_y + back_y_offset, button_r)

    local outline_outline_width = 5
    local top_outline_outline = rt.Circle(top_x, top_y, button_r + outline_outline_width)
    local right_outline_outline = rt.Circle(right_x, right_y, button_r + outline_outline_width)
    local bottom_outline_outline = rt.Circle(bottom_x, bottom_y, button_r + outline_outline_width)
    local left_outline_outline = rt.Circle(left_x, left_y, button_r + outline_outline_width)

    for base in range(top_base, right_base, bottom_base, left_base) do
        base:set_color(self.foreground_color)
    end

    for back in range(top_back, right_back, bottom_back, left_back) do
        back:set_color(self.background_color)
    end

    local outline_width = width / 50 * 1.5
    for outline in range(top_outline, right_outline, bottom_outline, left_outline, top_back_outline, right_back_outline, bottom_back_outline, left_back_outline) do
        outline:set_color(self.outline_color)
        outline:set_is_outline(true)
        outline:set_line_width(outline_width)
    end

    local active_button_color = rt.Palette.WHITE
    if which == rt.GamepadButton.TOP then
        top_base:set_color(active_button_color)
    elseif which == rt.GamepadButton.RIGHT then
        right_base:set_color(active_button_color)
    elseif which == rt.GamepadButton.BOTTOM then
        bottom_base:set_color(active_button_color)
    elseif which == rt.GamepadButton.LEFT then
        left_base:set_color(active_button_color)
    end

    self._content = {
        top_outline_outline,
        right_outline_outline,
        bottom_outline_outline,
        left_outline_outline,
        top_back,
        right_back,
        bottom_back,
        left_back,
        top_back_outline,
        right_back_outline,
        bottom_back_outline,
        left_back_outline,
        top_base,
        right_base,
        bottom_base,
        left_base,
        top_outline,
        right_outline,
        bottom_outline,
        left_outline
    }
end