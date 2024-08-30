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
    elseif self._key == rt.GamepadButton.DPAD_UP or self._key == rt.GamepadButton.DPAD_RIGHT or self._key == rt.GamepadButton.DPAD_DOWN or self._key == rt.GamepadButton.DPAD_LEFT then
        self:_as_dpad(
            self._key == rt.GamepadButton.DPAD_UP,
            self._key == rt.GamepadButton.DPAD_RIGHT,
            self._key == rt.GamepadButton.DPAD_DOWN,
            self._key == rt.GamepadButton.DPAD_LEFT,
            height
        )
    elseif self._key == rt.GamepadButton.START or self._key == rt.GamepadButton.SELECT then
        self:_as_start_select(self._key == rt.GamepadButton.START, height)
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

    local glyph = rt.Label("<o>" .. label .. "</o>")--, self._font)
    glyph:set_justify_mode(rt.JustifyMode.CENTER)
    glyph:realize()
    local glyph_w, glyph_h = glyph:measure()

    local base_w, base_h = width - 2 * label_m, height - 2 * label_m
    local front_w, front_h = 0.75 * base_w, 0.75 * base_h
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

    local corner_radius = 5
    for shape in range(front_base, front_base_outline, base, base_outline) do
        shape:set_corner_radius(corner_radius)
    end

    base:set_color(self.background_color)
    front_base:set_color(self.foreground_color)
    local outline_color = self.outline_color

    local outline_width = 2
    for outline in range(front_base_outline, base_outline) do
        outline:set_is_outline(true)
        outline:set_color(outline_color)
        outline:set_line_width(outline_width)
    end

    local lines = {}
    local offset = corner_radius * 0.4
    table.insert(lines, rt.Line(
        front_x + offset, front_y + offset,
        base_x + offset, base_y + offset
    ))

    table.insert(lines, rt.Line(
        front_x + front_w - offset, front_y + offset,
        base_x + base_w - offset, base_y + offset
    ))

    table.insert(lines, rt.Line(
        front_x + offset, front_y + front_h - offset,
        base_x + offset, base_y + base_h - offset
    ))

    table.insert(lines, rt.Line(
        front_x + front_w - offset, front_y + front_h - offset,
        base_x + base_w - offset, base_y + base_h - offset
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

    local n_outer_vertices = 32

    local top_base, top_outline = rt.Circle(top_x, top_y, button_r), rt.Circle(top_x, top_y, button_r)
    local right_base, right_outline = rt.Circle(right_x, right_y, button_r), rt.Circle(right_x, right_y, button_r)
    local bottom_base, bottom_outline = rt.Circle(bottom_x, bottom_y, button_r), rt.Circle(bottom_x, bottom_y, button_r)
    local left_base, left_outline = rt.Circle(left_x, left_y, button_r), rt.Circle(left_x, left_y, button_r)

    local back_x_offset, back_y_offset = 3, 3
    local top_back, top_back_outline = rt.Circle(top_x + back_x_offset, top_y + back_y_offset, button_r), rt.Circle(top_x + back_x_offset, top_y + back_y_offset, button_r)
    local right_back, right_back_outline = rt.Circle(right_x + back_x_offset, right_y + back_y_offset, button_r), rt.Circle(right_x + back_x_offset, right_y + back_y_offset, button_r)
    local bottom_back, bottom_back_outline = rt.Circle(bottom_x + back_x_offset, bottom_y + back_y_offset, button_r), rt.Circle(bottom_x + back_x_offset, bottom_y + back_y_offset, button_r)
    local left_back, left_back_outline = rt.Circle(left_x + back_x_offset, left_y + back_y_offset, button_r), rt.Circle(left_x + back_x_offset, left_y + back_y_offset, button_r)

    local outline_outline_width = 3
    local top_outline_outline = rt.Circle(top_x, top_y, button_r + outline_outline_width)
    local right_outline_outline = rt.Circle(right_x, right_y, button_r + outline_outline_width)
    local bottom_outline_outline = rt.Circle(bottom_x, bottom_y, button_r + outline_outline_width)
    local left_outline_outline = rt.Circle(left_x, left_y, button_r + outline_outline_width)

    local top_back_outline_outline = rt.Circle(top_x + back_x_offset, top_y + back_y_offset, button_r + outline_outline_width)
    local right_back_outline_outline = rt.Circle(right_x + back_x_offset, right_y + back_y_offset, button_r + outline_outline_width)
    local bottom_back_outline_outline = rt.Circle(bottom_x + back_x_offset, bottom_y + back_y_offset, button_r + outline_outline_width)
    local left_back_outline_outline = rt.Circle(left_x + back_x_offset, left_y + back_y_offset, button_r + outline_outline_width)
    
    local outline_width = 2
    local selection_inlay_radius = (button_r - outline_width) * 0.85
    local top_selection = rt.Circle(top_x, top_y, selection_inlay_radius)
    local right_selection = rt.Circle(right_x, right_y, selection_inlay_radius)
    local bottom_selection = rt.Circle(bottom_x, bottom_y, selection_inlay_radius)
    local left_selection = rt.Circle(left_x, left_y, selection_inlay_radius)

    for base in range(top_base, right_base, bottom_base, left_base) do
        base:set_color(self.foreground_color)
    end

    for back in range(top_back, right_back, bottom_back, left_back) do
        back:set_color(self.background_color)
    end

    for outline_outline in range(top_outline_outline, right_outline_outline, bottom_outline_outline, left_outline_outline, top_back_outline_outline, right_back_outline_outline, bottom_back_outline_outline, left_back_outline_outline) do
        outline_outline:set_color(rt.Palette.TRUE_WHITE)
    end

    for selection in range(top_selection, right_selection, bottom_selection, left_selection) do
        selection:set_color(rt.Palette.WHITE)
    end

    for outline in range(top_outline, right_outline, bottom_outline, left_outline, top_back_outline, right_back_outline, bottom_back_outline, left_back_outline) do
        outline:set_color(self.outline_color)
        outline:set_is_outline(true)
        outline:set_line_width(outline_width)
        outline:set_n_outer_vertices(n_outer_vertices)
    end

    local selection_inlay
    if which == rt.GamepadButton.TOP then
        selection_inlay = top_selection
    elseif which == rt.GamepadButton.RIGHT then
        selection_inlay = right_selection
    elseif which == rt.GamepadButton.BOTTOM then
        selection_inlay = bottom_selection
    elseif which == rt.GamepadButton.LEFT then
        selection_inlay = left_selection
    end

    self._content = {
        top_outline_outline,
        right_outline_outline,
        bottom_outline_outline,
        left_outline_outline,
        top_back_outline_outline,
        right_back_outline_outline,
        bottom_back_outline_outline,
        left_back_outline_outline,
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
        left_outline,
        selection_inlay
    }
end

--- @brief
function rt.KeybindingIndicator:_as_dpad(up_selected, right_selected, down_selected, left_selected, width)
    local x, y = 0, 0
    local height = width
    local translate = rt.translate_point_by_angle
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height

    local r = 0.5 * width - 5
    local m = 0.3 * width
    local bottom_left_x, bottom_left_y = center_x - m / 2, center_y + r
    local bottom_right_x, bottom_right_y = center_x + m / 2, center_y + r
    local center_bottom_right_x, center_bottom_right_y = center_x + m / 2, center_y + m / 2
    local right_bottom_x, right_bottom_y = center_x + r, center_y + m / 2
    local right_top_x, right_top_y = center_x + r, center_y - m / 2
    local center_top_right_x, center_top_right_y = center_x + m / 2, center_y - m / 2
    local top_right_x, top_right_y = center_x + m / 2, center_y - r
    local top_left_x, top_left_y = center_x - m / 2, center_y - r
    local center_top_left_x, center_top_left_y = center_x - m / 2, center_y - m / 2
    local left_top_x, left_top_y = center_x - r, center_y - m / 2
    local left_bottom_x, left_bottom_y = center_x - r, center_y + m / 2
    local center_bottom_left_x, center_bottom_left_y = center_x - m / 2, center_y + m / 2

    local center_offset = 3
    local frame_offset = 4
    local top = {
        top_left_x + frame_offset, top_left_y + frame_offset,
        top_right_x - frame_offset, top_right_y + frame_offset,
        center_top_right_x - frame_offset, center_top_right_y + frame_offset - center_offset,
        center_x, center_y - center_offset,
        center_top_left_x + frame_offset, center_top_left_y + frame_offset - center_offset,
        top_left_x + frame_offset, top_left_y + frame_offset
    }

    local right = {
        right_top_x - frame_offset, right_top_y + frame_offset,
        right_bottom_x - frame_offset, right_bottom_y - frame_offset,
        center_bottom_right_x - frame_offset + center_offset, center_bottom_right_y - frame_offset,
        center_x + center_offset, center_y,
        center_top_right_x - frame_offset + center_offset, center_top_right_y + frame_offset,
        right_top_x - frame_offset, right_top_y + frame_offset
    }

    local bottom = {
        bottom_right_x - frame_offset, bottom_right_y - frame_offset,
        bottom_left_x + frame_offset, bottom_left_y - frame_offset,
        center_bottom_left_x + frame_offset, center_bottom_left_y - frame_offset + center_offset,
        center_x, center_y + center_offset,
        center_bottom_right_x - frame_offset, center_bottom_right_y - frame_offset + center_offset,
        bottom_right_x - frame_offset, bottom_right_y - frame_offset
    }

    local left = {
        left_top_x + frame_offset, left_top_y + frame_offset,
        center_top_left_x + frame_offset - center_offset, center_top_left_y + frame_offset,
        center_x - center_offset, center_y,
        center_bottom_left_x + frame_offset - center_offset, center_bottom_left_y - frame_offset,
        left_bottom_x + frame_offset, left_bottom_y - frame_offset,
        left_top_x + frame_offset, left_top_y + frame_offset
    }

    local top_base, top_outline = rt.Polygon(top), rt.Polygon(top)
    local right_base, right_outline = rt.Polygon(right), rt.Polygon(right)
    local bottom_base, bottom_outline = rt.Polygon(bottom), rt.Polygon(bottom)
    local left_base, left_outline = rt.Polygon(left), rt.Polygon(left)

    for base in range(top_base, right_base, bottom_base, left_base) do
        base:set_color(self.foreground_color)
    end

    local selected_color = rt.Palette.WHITE
    if up_selected then top_base:set_color(selected_color) end
    if right_selected then right_base:set_color(selected_color) end
    if down_selected then bottom_base:set_color(selected_color) end
    if left_selected then left_base:set_color(selected_color) end

    for outline in range(top_outline, right_outline, bottom_outline, left_outline) do
        outline:set_color(self.outline_color)
        outline:set_is_outline(true)
    end

    local corner_radius = 5

    local backlay_vertical = rt.Rectangle(top_left_x, top_left_y, m, 2 * r)
    local backlay_horizontal = rt.Rectangle(left_top_x, left_top_y, 2 * r, m)

    for backlay in range(backlay_horizontal, backlay_vertical) do
        backlay:set_color(self.background_color)
        backlay:set_corner_radius(corner_radius)
    end

    local whole = {
        top_left_x, top_left_y,
        top_right_x, top_right_y,
        center_top_right_x, center_top_right_y,
        right_top_x, right_top_y,
        right_bottom_x, right_bottom_y,
        center_bottom_right_x, center_bottom_right_y,
        bottom_right_x, bottom_right_y,
        bottom_left_x, bottom_left_y,
        center_bottom_left_x, center_bottom_left_y,
        left_bottom_x, left_bottom_y,
        left_top_x, left_top_y,
        center_top_left_x, center_top_left_y,
        top_left_x, top_left_y
    }

    local backlay_outline_vertical = rt.Rectangle(top_left_x, top_left_y, m, 2 * r)
    local backlay_outline_horizontal = rt.Rectangle(left_top_x, left_top_y, 2 * r, m)

    local backlay_outline_outline_vertical = rt.Rectangle(top_left_x, top_left_y, m, 2 * r)
    local backlay_outline_outline_horizontal = rt.Rectangle(left_top_x, left_top_y, 2 * r, m)

    for backlay_outline in range(backlay_outline_vertical, backlay_outline_horizontal) do
        backlay_outline:set_color(self.outline_color)
        backlay_outline:set_is_outline(true)
        backlay_outline:set_line_width(5)
        backlay_outline:set_corner_radius(corner_radius)
    end

    for outline_outline in range(backlay_outline_outline_vertical, backlay_outline_outline_horizontal) do
        outline_outline:set_color(rt.Palette.TRUE_WHITE)
        outline_outline:set_line_width(8)
        outline_outline:set_corner_radius(corner_radius)
        outline_outline:set_is_outline(true)
    end

    self._content = {
        backlay_outline_outline_horizontal,
        backlay_outline_outline_vertical,

        backlay_outline_vertical,
        backlay_outline_horizontal,
        backlay_horizontal,
        backlay_vertical,
        top_base,
        right_base,
        bottom_base,
        left_base,

        --[[
        top_outline,
        right_outline,
        bottom_outline,
        left_outline
        ]]--
    }
end

--- @brief
function rt.KeybindingIndicator:_as_start_select(start_or_select, width)
    local x, y = 0, 0
    local height = width

    local w = 0.9 * width / 1.5
    local h = 0.4 * height / 1.5

    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local base = rt.Rectangle(center_x - 0.5 * w, center_y - 0.5 * h, w, h)
    local base_outline = rt.Rectangle(center_x - 0.5 * w, center_y - 0.5 * h, w, h)
    local base_outline_outline = rt.Rectangle(center_x - 0.5 * w, center_y - 0.5 * h, w, h)

    for rectangle in range(base, base_outline, base_outline_outline) do
        rectangle:set_corner_radius(h / 2)
    end

    base:set_color(self.foreground_color)
    base_outline:set_color(self.outline_color)
    base_outline:set_is_outline(true)
    base_outline:set_line_width(2)

    base_outline_outline:set_color(rt.Palette.TRUE_WHITE)
    base_outline_outline:set_is_outline(true)
    base_outline_outline:set_line_width(6)

    local r = 0.5 * h * 0.8
    local right_triangle, right_triangle_outline

    do
        local angle1 = 0
        local angle2 = 2 * math.pi / 3
        local angle3 = 4 * math.pi / 3

        local vertices = {
            center_x + r * math.cos(angle1), center_y + r * math.sin(angle1),
            center_x + r * math.cos(angle2), center_y + r * math.sin(angle2),
            center_x + r * math.cos(angle3), center_y + r * math.sin(angle3)
        }

        right_triangle = rt.Polygon(vertices)
        right_triangle_outline = rt.Polygon(vertices)
    end

    local left_triangle, left_triangle_outline
    do
        local angle1 = math.pi
        local angle2 = math.pi + 2 * math.pi / 3
        local angle3 = math.pi + 4 * math.pi / 3

        local vertices = {
            center_x + r * math.cos(angle1), center_y + r * math.sin(angle1),
            center_x + r * math.cos(angle2), center_y + r * math.sin(angle2),
            center_x + r * math.cos(angle3), center_y + r * math.sin(angle3)
        }

        left_triangle = rt.Polygon(vertices)
        left_triangle_outline = rt.Polygon(vertices)
    end

    for triangle in range(left_triangle, right_triangle) do
        triangle:set_color(self.background_color)
    end

    for triangle_outline in range(left_triangle_outline, right_triangle_outline) do
        triangle_outline:set_color(self.outline_color)
        triangle_outline:set_is_outline(true)
    end

    local triangle, triangle_outline
    if start_or_select == true then
        triangle = right_triangle
        triangle_outline = right_triangle_outline
    else
        triangle = left_triangle
        triangle_outline = left_triangle_outline
    end

    self._content = {
        base_outline_outline,
        base,
        base_outline,
        triangle,
        triangle_outline
    }
end