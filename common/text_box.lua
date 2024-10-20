rt.settings.textbox = {
    scroll_speed = 10, -- letters / s
}

--- @class rt.TextBox
--- @signal scrolling_done (self) -> nil
rt.TextBox = meta.new_type("TextBox", rt.Widget, rt.Updatable, function()
    local out = meta.new(rt.TextBox, {
        _frame = rt.Frame(),

        _entries = {},  -- cf append
        _n_entries = 0,

        _scrolling_labels = meta.make_weak({}), -- cf append
        _n_scrolling_labels = 0,
        _line_offset = 0,
        _first_visible_entry_i = 1,
        _total_line_height = 0,

        _label_aabb = rt.AABB(0, 0, 1, 1),
        _label_stencil = rt.Rectangle(0, 0, 1, 1),

        _is_visible = false,
        _current_y_offset = 0,
        _max_y_offset = 0
    })

    return out
end)

meta.add_signal(rt.TextBox, "scrolling_done")

--- @brief [internal]
function rt.TextBox:_realize_entry(entry)
    entry.label:realize()
    entry.width, entry.height = entry.label:measure()
    entry.height = entry.label:get_line_height()
    entry.n_lines = entry.label:get_n_lines()
end

--- @brief
function rt.TextBox:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._frame:realize()

    for entry in values(self._entries) do
        self:_realize_entry(entry)
    end
end

--- @brief
function rt.TextBox:size_allocate(x, y, width, height)
    self._frame:fit_into(x, y, width, height)
    local m = rt.settings.margin_unit
    local xm = 2 * m + self._frame:get_thickness()
    local ym = m + self._frame:get_thickness()

    self._label_aabb = rt.AABB(x + xm, y + ym, width - 2 * xm, height - 2 * ym)
    self._label_stencil:resize(self._label_aabb)

    self._max_y_offset = 1.3 * (y + height)
    if self._is_visible == false then
        self._current_y_offset = self._max_y_offset
    end
end

--- @brief
function rt.TextBox:append(msg)
    local entry = {
        label = rt.Label(msg),
        width = 0,
        height = 0,
        n_lines = 1,
        n_lines_visible = 0,
        elapsed = 0
    }

    if self._is_realized then
        self:_realize_entry(entry)
        entry.label:fit_into(0, 0, self._label_aabb.width, entry.height)
    end

    table.insert(self._entries, entry)
    self._n_entries = self._n_entries + 1

    entry.label:set_n_visible_characters(0)
    table.insert(self._scrolling_labels, entry)
    self._n_scrolling_labels = self._n_scrolling_labels + 1
end

--- @brief
function rt.TextBox:update(delta)
    -- position
    local y_offset_speed = 1000
    if not self._is_shown and self._current_y_offset < self._max_y_offset then
        self._current_y_offset = self._current_y_offset + delta * y_offset_speed
    elseif self._is_shown and self._current_y_offset > 0 then
        self._current_y_offset = self._current_y_offset - delta * y_offset_speed
    end

    -- labels
    local letters_per_second = rt.settings.textbox.scroll_speed
    ::next_label::
    local first = self._scrolling_labels[1]
    if first ~= nil then
        first.elapsed = first.elapsed + delta
        local is_done, new_n_lines_visible, rest_delta = first.label:update_n_visible_characters_from_elapsed(first.elapsed, letters_per_second)

        -- scroll up
        while first.n_lines_visible < new_n_lines_visible do
            first.n_lines_visible = first.n_lines_visible + 1
            local line_height = first.height

            self._total_line_height = self._total_line_height + line_height
            if self._total_line_height > self._label_aabb.height then
                self._line_offset = self._line_offset - line_height
            end
        end

        if is_done then
            table.remove(self._scrolling_labels, 1)
            self._n_scrolling_labels = self._n_scrolling_labels - 1
            if self._n_scrolling_labels == 0 then
                self:signal_emit("scrolling_done")
            end
        end

        delta = rest_delta
        if delta > 0 then
            goto next_label
        end
    end
end

--- @brief
function rt.TextBox:draw()
    love.graphics.push()
    love.graphics.translate(0, -1 * self._current_y_offset) -- or 1 * for bottom alignemnt

    self._frame:draw()
    if self._n_entries > 0 then
        local stencil_value = meta.hash(self) % 254 + 1
        rt.graphics.stencil(stencil_value, self._label_stencil)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

        love.graphics.translate(self._label_aabb.x, self._label_aabb.y + self._line_offset)
        for i = self._first_visible_entry_i, self._n_entries do
            local entry = self._entries[i]
            entry.label:draw()
            love.graphics.translate(0, entry.height)
        end

        rt.graphics.set_stencil_test()
    end
    love.graphics.pop()
end

--- @brief
function rt.TextBox:show()
    self._is_shown = true
end

--- @brief
function rt.TextBox:hide()
    self._is_shown = false
end

--- @brief
function rt.TextBox:clear()
    self._entries = {}
    self._n_entries = 0
    self._scrolling_labels = {}
    self._n_scrolling_labels = 0
    self._line_offset = 0
    self._first_visible_entry_i = 1
    self._total_line_height = 0
end
