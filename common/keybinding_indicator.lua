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
        _snapshot = rt.RenderTexture(1, 1),
        _font = nil, -- rt.Font
        _glyph = nil, -- rt.Glyph
    })
end, {
    font_size_to_font = {}
})

--- @override
function rt.KeybindingIndicator:realize()
    if self:get_is_realized() == true then return end
    self._is_realized = true
end

--- @override
function rt.KeybindingIndicator:size_allocate(x, y, width, height)

    self._snapshot = rt.RenderTexture(width, height)
    self._snapshot:bind_as_render_target()
    if meta.is_enum_value(self._key, rt.KeyboardKey) then
        self:_draw_as_keyboard_key(rt.keyboard_key_to_string(self._key), height)
    end
    self._snapshot:unbind_as_render_target()
end

--- @override
function rt.KeybindingIndicator:draw()
    rt.graphics.translate(self._bounds.x, self._bounds.y)
    self._snapshot:draw()
    rt.graphics.translate(-self._bounds.x, -self._bounds.y)
end

--- @brief
function rt.KeybindingIndicator:_draw_as_keyboard_key(label, width)

    -- find appropriate font size
    local label_w
    local font_size = math.round(0.5 * width)a
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
    until label_w < (width - 2 * label_m)

    local x, y = 0, 0
    local height = width

    local glyph = rt.Label("<o>" .. label .. "</o>", self._font)
    glyph:set_justify_mode(rt.JustifyMode.CENTER)
    glyph:realize()
    local glyph_w, glyph_h = glyph:measure()
    glyph:fit_into(x, y + 0.5 * height - 0.5 * glyph_h, width, height)

    local base_w, base_h = width - 2 * label_m, height - 2 * label_m
    local front_w, front_h = 0.8 * base_w, 0.8 * base_h
    local front_offset = (base_h - front_h) * 0.25
    local front_base, front_base_outline, base, base_outline = rt.Rectangle(), rt.Rectangle(), rt.Rectangle(), rt.Rectangle()

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

    base:set_color(rt.Palette.GRAY_4)
    front_base:set_color(rt.Palette.GRAY_3)
    local outline_color = rt.Palette.GRAY_6

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

    outline_outline:draw()
    base:draw()
    base_outline:draw()
    front_base:draw()
    front_base_outline:draw()
    for line in values(lines) do
        line:draw()
    end

    glyph:draw()
end