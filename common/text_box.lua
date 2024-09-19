rt.settings.textbox = {
    scroll_speed = 50, -- letters / s
}

rt.TextBoxAlignment = meta.new_enum({
    TOP = "TOP",
    BOTTOM = "BOTTOM"
})

--- @class rt.TextBox
--- @signal scrolling_done (self) -> nil
rt.TextBox = meta.new_type("TextBox", rt.Widget, rt.SignalEmitter, function()
    local out = meta.new(rt.TextBox, {
        _backdrop = rt.Frame(),

        _alignment = rt.TextBoxAlignment.TOP,
        _last_width = 0,

        _scrollbar = rt.Scrollbar(),
        _scroll_up_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _scroll_down_indicator = rt.DirectionIndicator(rt.Direction.DOWN),
        _advance_indicator = rt.DirectionIndicator(rt.Direction.DOWN),

        _line_height = rt.settings.font.default:get_bold_italic():getHeight(),
        _labels = {},            -- Table<cf. append>
        _n_labels = 0,
        _n_lines = 0,
        _scrolling_labels = {},  -- Table<Number>
        _current_line_i = 1,
        _line_i_to_label_i = {}, -- Table<Number, { label_i, line_i }
        _max_n_visible_lines = 16,
        _n_visible_lines = 0,

        _scrolling_active = false,
        _maintain_minimum_size = true,
        _current_height = 0,
        _target_height = 0,

        _label_stencil = rt.Rectangle(0, 0, 1, 1),
        _label_aabb = rt.AABB(0, 0, 1, 1)
    })

    out:signal_add("scrolling_done")
    return out
end)

--- @override
function rt.TextBox:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for widget in range(
        self._backdrop,
        self._scrollbar,
        self._scroll_up_indicator,
        self._scroll_down_indicator,
        self._advance_indicator
    ) do
        widget:realize()
    end

    for muted in range(
        self._scroll_up_indicator,
        self._scroll_down_indicator,
        self._scrollbar
    ) do
        muted:set_color(rt.Palette.GRAY_3)
    end
    self._advance_indicator:set_color(rt.Palette.WHITE)
end

--- @override
function rt.TextBox:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local text_h = self:_calculate_text_height()

    local thickness = self._backdrop:get_thickness()
    local text_xm = 3 * m
    local text_ym = 2 * m
    local scroll_area_w = 4 * m
    
    local backdrop_height = self._n_visible_lines * self._line_height + 2 * text_ym + 2 * thickness

    local indicator_radius = scroll_area_w * 0.5

    local text_w = width - 2 * text_xm - scroll_area_w - 2 * thickness

    self._label_aabb = rt.AABB(
        x + thickness + text_xm,
        y + thickness + text_ym,
        text_w,
        text_h
    )

    local indicator_x = x + text_xm + text_w + text_xm
    local indicator_y = y + m
    self._scroll_up_indicator:fit_into(
        indicator_x + 0.5 * scroll_area_w - 0.5 * indicator_radius,
        indicator_y,
        indicator_radius,
        indicator_radius
    )

    local scrollbar_h = (text_h + 2 * text_ym) - 2 * m - 2 * indicator_radius
    self._scrollbar:fit_into(
        indicator_x + 0.5 * scroll_area_w - 0.5 * indicator_radius,
        indicator_y + indicator_radius,
        indicator_radius,
        scrollbar_h
    )

    self._scroll_down_indicator:fit_into(
        indicator_x + 0.5 * scroll_area_w - 0.5 * indicator_radius,
        indicator_y + indicator_radius + scrollbar_h,
        indicator_radius,
        indicator_radius
    )

    self._label_stencil:resize(self._label_aabb)
    self._backdrop:fit_into(x, y, width, backdrop_height)

    --[[
    if text_w ~= self._last_width then
        self._line_i_to_label_i = {}
        for entry in values(self._labels) do
            entry.label:fit_into(0, 0, self._label_aabb.width, POSITIVE_INFINITY)
            entry.height = select(2, entry.label:measure())
            entry.n_lines = entry.label:get_n_lines()

            for i = 1, entry.n_lines do
                self._line_i_to_label_i[self._n_lines] = {
                    label_i = self._n_labels,
                    line_i = i
                }
                self._n_lines = self._n_lines + 1
            end
        end
    end
    ]]--

    self:_update_indicators()
end

--- @override
function rt.TextBox:draw()
    if self._n_visible_lines == nil then return end

    self._backdrop:draw()

    if self._scrolling_active and self._n_lines >= self._max_n_visible_lines then
        self._scrollbar:draw()
        self._scroll_up_indicator:draw()
        self._scroll_down_indicator:draw()
    end

    local stencil_value = meta.hash(self) % 254 + 1
    rt.graphics.stencil(stencil_value, self._label_stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

    rt.graphics.push()
    rt.graphics.translate(self._label_aabb.x, self._label_aabb.y)

    local line_i = self._current_line_i
    local already_drawn = {}
    while line_i < math.min(self._current_line_i + self._max_n_visible_lines, self._n_lines + 1) do
        local label_i_entry = self._line_i_to_label_i[line_i]
        if label_i_entry == nil then break end
        local label_entry = self._labels[label_i_entry.label_i]
        if already_drawn[label_i_entry.label_i] ~= true then
            rt.graphics.translate(0, -1 * (label_i_entry.line_i - 1) * self._line_height)
            label_entry.label:draw()
            rt.graphics.translate(0,  1 * (label_i_entry.line_i - 1) * self._line_height)
            already_drawn[label_i_entry.label_i] = true
        end

        rt.graphics.translate(0, self._line_height)
        line_i = line_i + 1
    end

    rt.graphics.set_stencil_test()
    rt.graphics.pop()
end

--- @brief
function rt.TextBox:append(formatted_text)
    local label = rt.Label(formatted_text)
    local entry = {
        label = label,
        height = 0,
        n_lines = 1,
        n_lines_visible = 0,
        elapsed = 0
    }

    if self._scrolling_active == true then
        entry.n_lines_visible = entry.n_lines
    else
        label:set_n_visible_characters(0)
    end
    label:realize()

    label:fit_into(0, 0, self._label_aabb.width, POSITIVE_INFINITY)
    entry.height = select(2, label:measure())
    entry.n_lines = label:get_n_lines()
    table.insert(self._labels, entry)
    self._n_labels = self._n_labels + 1

    for i = 1, entry.n_lines do
        self._n_lines = self._n_lines + 1
        self._line_i_to_label_i[self._n_lines] = {
            label_i = self._n_labels,
            line_i = i
        }
    end

    table.insert(self._scrolling_labels, self._n_labels)
    self:_update_indicators()
    self:_update_n_visible_lines()
end

--- @brief
function rt.TextBox:update(delta)
    local first_i = self._scrolling_labels[1]
    if first_i ~= nil then
        local entry = self._labels[first_i]
        entry.elapsed = entry.elapsed + delta
        if entry.label:get_n_visible_characters() < entry.label:get_n_characters() then
            local is_done, n_lines_visible, rest_delta = entry.label:update_n_visible_characters_from_elapsed(entry.elapsed, rt.settings.textbox.scroll_speed)
            if entry.n_lines_visible ~= n_lines_visible then
                entry.n_lines_visible = n_lines_visible
                self:_update_n_visible_lines()
            end
            if is_done then
                table.remove(self._scrolling_labels, 1)
                self:_update_indicators()
                if self._n_scrolling_labels == 0 then
                    self:_emit_scrolling_done()
                end
            end
        end
    end
end

--- @brief
function rt.TextBox:skip()
    for index in values(self._scrolling_labels) do
        local entry = self._labels[index]
        entry.label:set_n_visible_characters(POSITIVE_INFINITY)
    end
    self._scrolling_labels = {}
    self:_update_n_visible_lines()
    self:_emit_scrolling_done()
end

--- @brief
function rt.TextBox:can_scroll_up()
    return self._current_line_i > 1
end

--- @brief
function rt.TextBox:scroll_up()
    if self:can_scroll_up() and self._scrolling_active then
        self._current_line_i = self._current_line_i - 1
        self:_update_n_visible_lines()
        self:_update_indicators()
    end
end

--- @brief
function rt.TextBox:can_scroll_down()
    return self._n_lines > self._current_line_i --self._current_line_i + self._max_n_visible_lines < self._n_lines
end

--- @brief
function rt.TextBox:scroll_down()
    if self:can_scroll_down() and self._scrolling_active then
        self._current_line_i = self._current_line_i + 1
        self:_update_n_visible_lines()
        self:_update_indicators()
    end
end

--- @override
function rt.TextBox:_calculate_text_height()
    return self._line_height * self._max_n_visible_lines
end

--- @brief
function rt.TextBox:_emit_scrolling_done()
    self:signal_emit("scrolling_done")
end

--- @brief [internal]
function rt.TextBox:_update_indicators()
    local off_opacity = 0.25
    self._scroll_up_indicator:set_opacity(ternary(self:can_scroll_up(), 1, off_opacity))
    self._scroll_down_indicator:set_opacity(ternary(self:can_scroll_down(), 1, off_opacity))
    self._scrollbar:set_page_index(self._current_line_i, self._n_lines - self._max_n_visible_lines)
end

--- @brief
function rt.TextBox:present()
end

--- @brief
function rt.TextBox:close()

end

--- @brief
function rt.TextBox:clear()
    self._lines = {}
    self._line_i_to_label_i = {}
    self._n_labels = 0
    self._n_lines = 0
end

--- @brief
function rt.TextBox:set_scrolling_active(b)
    self:skip()
    self._scrolling_active = b
end

--- @brief
function rt.TextBox:get_scrolling_active()
    return self._scrolling_active
end

--- @brief
function rt.TextBox:set_max_n_visible_lines(n)
    self._max_n_visible_lines = n
end

--- @brief
function rt.TextBox:get_max_n_visible_lines()
    return self._max_n_visible_lines
end

--- @brief
function rt.TextBox:_update_n_visible_lines()
    local n_steps = 0
    while self._current_line_i + n_steps <= self._n_lines do
        local line_i_entry = self._line_i_to_label_i[self._current_line_i + n_steps]
        if line_i_entry == nil then break end

        local label_entry = self._labels[line_i_entry.label_i]
        if label_entry.n_lines_visible < line_i_entry.line_i then break end

        n_steps = n_steps + 1
    end

    n_steps = math.min(n_steps, self._max_n_visible_lines)

    if n_steps ~= self._n_visible_lines then
        self._n_visible_lines = n_steps
        self:reformat()
    end
end