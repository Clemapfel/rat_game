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

        _drop_animation = rt.SmoothedMotion2D(0, 0),

        _line_height = rt.settings.font.default:get_bold_italic():getHeight(),
        _labels = {},            -- Table<cf. append>
        _n_labels = 0,
        _n_lines = 1,
        _scrolling_labels = {},  -- Table<Number>
        _current_line_i = 1,
        _line_i_to_label_i = {}, -- Table<Number, { label_i, line_i }
        _n_visible_lines = 4,

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
        self._scroll_down_indicator
    ) do
        muted:set_color(rt.Palette.GRAY_3)
    end
    self._advance_indicator:set_color(rt.Palette.WHITE)
end

--- @override
function rt.TextBox:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local text_h = self:_calculate_text_height()

    local text_xm, text_ym = 3 * m, 2 * m
    local w = width - 2 * text_xm

    self._backdrop:fit_into(x, y, width, text_h + 2 * text_ym)
    self._label_aabb = rt.AABB(x + text_xm, y + text_ym, w, height - 2 * text_ym)
    self._label_stencil:resize(x + text_xm, y + text_ym, w, text_h)

    if w ~= self._last_width then
        -- TODO: reformat all
    end
end

--- @override
function rt.TextBox:draw()
    self._backdrop:draw()

    local stencil_value = meta.hash(self) % 254 + 1
    rt.graphics.stencil(stencil_value, self._label_stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

    rt.graphics.push()
    rt.graphics.translate(self._label_aabb.x, self._label_aabb.y)

    do
        local i = self._current_line_i
        local last_label = nil
        while i < self._n_visible_lines do
            local line_i_entry = self._line_i_to_label_i[i]
            if line_i_entry == nil then break end

            local label_entry = self._labels[line_i_entry.label_i]
            label_entry.label:draw()
            rt.graphics.translate(0, label_entry.height)

            i = i + label_entry.n_lines
        end
    end

    rt.graphics.set_stencil_test()
    rt.graphics.pop()
end

--- @brief
function rt.TextBox:append(formatted_text)
    local label = rt.Label(formatted_text)
    label:set_n_visible_characters(0)
    label:realize()
    local entry = {
        label = label,
        height = 0,
        n_lines = 1,
        elapsed = 0
    }

    label:fit_into(0, 0, self._label_aabb.width, POSITIVE_INFINITY)
    entry.height = select(2, label:measure())
    entry.n_lines = label:get_n_lines()
    table.insert(self._labels, entry)
    self._n_labels = self._n_labels + 1

    for i = 1, entry.n_lines do
        self._line_i_to_label_i[self._n_lines] = {
            label_i = self._n_labels,
            line_i = i
        }
        self._n_lines = self._n_lines + 1
    end

    table.insert(self._scrolling_labels, self._n_labels)
end

--- @brief
function rt.TextBox:update(delta)
    local first_i = self._scrolling_labels[1]
    if first_i ~= nil then
        local entry = self._labels[first_i]
        entry.elapsed = entry.elapsed + delta
        local is_done, n_rows_visible, rest_delta = entry.label:update_n_visible_characters_from_elapsed(entry.elapsed, rt.settings.textbox.scroll_speed)

        if is_done then
            table.remove(self._scrolling_labels, 1)
            if self._n_scrolling_labels == 0 then
                self:_emit_scrolling_done()
                self:scroll_down()
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
    self:_emit_scrolling_done()
end

--- @brief
function rt.TextBox:can_scroll_up()
    return self._current_line_i > 1
end

--- @brief
function rt.TextBox:scroll_up()
    if self:can_scroll_up() then
        self._current_line_i = self._current_line_i - 1
    end
end

--- @brief
function rt.TextBox:can_scroll_down()
    return self._current_line_i < self._n_lines
end

--- @brief
function rt.TextBox:scroll_down()
    if self:can_scroll_down() then
        self._current_line_i = self._current_line_i + 1
    end
end

--- @override
function rt.TextBox:_calculate_text_height()
    return self._line_height * self._n_visible_lines
end

--- @brief
function rt.TextBox:_emit_scrolling_done()
    self:signal_emit("scrolling_done")
end