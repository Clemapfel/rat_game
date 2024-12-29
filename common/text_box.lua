rt.settings.text_box = {
    max_n_lines = 10,
    letters_per_second = 60,
    reveal_duration = 0.5, -- seconds
    scroll_speed = 500, -- px / s, frame reveal/hide movement
    expand_speed = 500, -- px / s, frame resize
    label_hide_delay = 0.5, -- seconds, hold after line is done revealing but before scroll up
    all_entries_done_delay = 1, -- hold, waiting for new append to continue "combo"
}

local _HIDDEN = 1
local _SHOWN = 0

--- @class rt.TextBox
--- @signal scrolling_done (self) -> nil
rt.TextBox = meta.new_type("TextBox", rt.Widget, rt.Updatable, function()
    return meta.new(rt.TextBox, {
        _frame = rt.Frame(),
        _stencil_aabb = rt.AABB(0, 0, 1, 1),

        _position_path = nil, -- rt.Path
        _position_x = 0,
        _position_y = 0,
        _position_current_value = _HIDDEN,
        _position_target_value = _HIDDEN,

        _current_text_y_offset = 0,
        _target_text_y_offset = 0,

        _n_lines = 0,
        _max_n_lines = rt.settings.text_box.max_n_lines,

        _entries = {},
        _n_entries = {},
        _first_visible_entry = 1,
        _text_scroll_overlap_entry_offset = 0,
        _all_entries_done_delay = 0,

        _indicator_r = rt.settings.margin_unit,
        _font = rt.settings.font.default,

        _scroll_up_indicator = rt.Polygon(0, 0, 1, 1, 0.5, 0.5),
        _scroll_up_indicator_outline = rt.Polygon(0, 0, 1, 1, 0.5, 0.5),
        _scroll_up_indicator_x = 0,
        _scroll_up_indicator_y = 0,

        _scroll_down_indicator = rt.Polygon(0, 0, 1, 1, 0.5, 0.5),
        _scroll_down_indicator_outline = rt.Polygon(0, 0, 1, 1, 0.5, 0.5),
        _scroll_down_indicator_x = 0,
        _scroll_down_indicator_y = 0,
        _is_first_update = true,

        _scrollbar = rt.Scrollbar(),

        _current_frame_h = 0,
        _target_frame_h = 0
    })
end)

--- @brief
function rt.TextBox:_update_target_frame_h()
    self._target_frame_h = math.max(self._n_lines, 1) * self._font:get_native(rt.FontStyle.BOLD_ITALIC):getHeight()
end

--- @brief
function rt.TextBox:realize()
    if self:already_realized() then return end

    self._frame:realize()
    self._scrollbar:realize()
    self:_update_target_frame_h()
end

--- @brief
function rt.TextBox:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local xm = 2 * m + self._frame:get_thickness()
    local ym = m + self._frame:get_thickness()

    local stencil_h = math.max(self._current_frame_h, m)
    self._stencil_aabb = rt.AABB(
        0 + xm,
        0 + ym,
        width - 2 * xm,
        stencil_h
    )

    local frame_h = stencil_h + 2 * ym
    self._frame:fit_into(0, 0, width, frame_h)
    self._position_path = rt.Path(
        x, y,
        x, 0 - frame_h - m
    )

    do
        local down_vertices = {}
        local up_vertices = {}

        local up_offset = 0.5 * math.pi
        local down_offset = 2 * math.pi - up_offset
        for angle = 0, 2 * math.pi, 2 / 3 * math.pi do
            table.insert(down_vertices, 0 + math.cos(angle - down_offset) * self._indicator_r)
            table.insert(down_vertices, 0 + math.sin(angle - down_offset) * self._indicator_r)
            table.insert(up_vertices, 0 + math.cos(angle - up_offset) * self._indicator_r)
            table.insert(up_vertices, 0 + math.sin(angle - up_offset) * self._indicator_r)
        end

        self._scroll_down_indicator = rt.Polygon(down_vertices)
        self._scroll_down_indicator_outline = rt.Polygon(down_vertices)

        self._scroll_up_indicator = rt.Polygon(up_vertices)
        self._scroll_up_indicator_outline = rt.Polygon(up_vertices)
    end

    for fill in range(
        self._scroll_up_indicator,
        self._scroll_down_indicator
    ) do
        fill:set_color(rt.Palette.FOREGROUND)
    end

    for outline in range(
        self._scroll_up_indicator_outline,
        self._scroll_down_indicator_outline
    ) do
        outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
        outline:set_is_outline(true)
        outline:set_line_width(3)
    end

    for entry in values(self._entries) do
        entry.label:fit_into(0, 0, self._stencil_aabb.width)
    end
end

--- @brief
--- @return Number message id
function rt.TextBox:append(message, on_done_notify)
    if message == "" or message == nil then
        if on_done_notify ~= nil then on_done_notify() end
        return
    end

    local label = rt.Label(message, self._font)
    label:realize()
    label:fit_into(0, 0, self._stencil_aabb.width, POSITIVE_INFINITY)

    local entry = {
        label = label,
        height = select(2, label:measure()),
        line_height = label:get_line_height(),
        elapsed = 0,
        delay_elapsed = 0,
        n_lines_visible = 0,
        n_lines = label:get_n_lines(),
        on_done_f = on_done_notify,
        is_done = false
    }

    label:set_n_visible_characters(0)
    table.insert(self._entries, entry)
    self._n_entries = self._n_entries + 1

    self._position_target_value = _SHOWN
    self._all_entries_done_delay = 0
    self._scrollbar:set_page_index(self._first_visible_entry, self._n_entries)

    return self._n_entries
end

--- @brief
function rt.TextBox:_resize_frame(value)
    self._current_frame_h = value
    local x, y, width, height = rt.aabb_unpack(self._bounds)
    x, y = 0, 0
    local m = rt.settings.margin_unit
    local stencil_h = math.max(self._current_frame_h, m)
    self._stencil_aabb.height = stencil_h

    local xm = 2 * m + self._frame:get_thickness()
    local ym = m + self._frame:get_thickness()
    local frame_h = stencil_h + 2 * ym
    self._frame:fit_into(0, 0, width, frame_h)

    local indicator_x = x + width - xm
    self._scroll_up_indicator_x, self._scroll_up_indicator_y = indicator_x, y + 2 * ym
    self._scroll_down_indicator_x, self._scroll_down_indicator_y = indicator_x, y + frame_h - 2 * ym
    local scrollbar_width = 2 * m
    self._scrollbar:fit_into(
        indicator_x - 2 * self._indicator_r + 0.5 * scrollbar_width,
        y + 2 * ym + self._indicator_r,
        scrollbar_width,
        frame_h - 4 * self._indicator_r - 2 * ym - 0.5 * m
    )
end

--- @brief
function rt.TextBox:update(delta)
    do -- update frame position
        local scrolling_speed = 1 / rt.settings.text_box.reveal_duration
        local current, target = self._position_current_value, self._position_target_value
        local distance = math.abs(current - target) * 2
        if current < target then
            current = current + delta * scrolling_speed
            if current >= target then current = target end
        elseif current > target then
            current = current - delta * scrolling_speed
            if current <= target then current = target end
        end

        self._position_current_value = current
        self._position_x, self._position_y = self._position_path:at(current)
    end

    do -- update text scroll
        local scroll_speed = rt.settings.text_box.scroll_speed
        local current, target = self._current_text_y_offset, self._target_text_y_offset
        if current < target then
            current = current + delta * scroll_speed
            if current > target then current = target end
        elseif current > target then
            current = current - delta * scroll_speed
            if current < target then current = target end
        end
        self._current_text_y_offset = current

        local n_scrolled = 0
        local scrolled_height = self._current_text_y_offset
        local entry_i = self._first_visible_entry
        local n = 0
        while entry_i < self._n_entries and scrolled_height > 0 do
            local entry = self._entries[entry_i]
            if entry.is_done == false then break end
            if scrolled_height > entry.height then
                scrolled_height = scrolled_height - entry.height
                n = n + 1
            end
            entry_i = entry_i + 1
        end
        self._text_scroll_overlap_entry_offset = n
    end

    local all_entries_done = true
    do -- scroll characters
        local letters_per_second = rt.settings.text_box.letters_per_second
        local line_delay = rt.settings.text_box.label_hide_delay

        local n_lines_shown = 0
        for i = self._first_visible_entry, self._n_entries do
            local entry = self._entries[i]
            entry.label:update(delta)
            entry.elapsed = entry.elapsed + delta

            local is_done, new_n_lines_visible = entry.label:update_n_visible_characters_from_elapsed(entry.elapsed, letters_per_second)
            n_lines_shown = n_lines_shown + new_n_lines_visible
            local n_line_delta = new_n_lines_visible - entry.n_lines_visible
            entry.n_lines_visible = new_n_lines_visible
            if n_lines_shown > self._max_n_lines then
                self._target_text_y_offset = self._target_text_y_offset + n_line_delta * entry.line_height
            end

            if n_line_delta ~= 0 then
                self._n_lines = math.min(self._n_lines + n_line_delta, self._max_n_lines)
                self:_update_target_frame_h()
            end

            if is_done then
                entry.delay_elapsed = entry.delay_elapsed + delta
                if entry.delay_elapsed > line_delay then
                    if entry.is_done == false then
                        if entry.on_done_f ~= nil then
                            entry.on_done_f()
                        end
                        entry.is_done = true
                    end
                end
            end

            if entry.is_done == false then
                all_entries_done = false
                break
            end
        end
    end

    -- hide if done
    if all_entries_done and not self._history_mode_active then
        self._all_entries_done_delay = self._all_entries_done_delay + delta
        if self._all_entries_done_delay > rt.settings.text_box.all_entries_done_delay then
            self._position_target_value = _HIDDEN
            self._first_visible_entry = self._n_entries + 1
            self._scrollbar:set_page_index(self._first_visible_entry)
            self._n_lines = 0
            self:_update_target_frame_h()
            self._current_text_y_offset = 0
            self._target_text_y_offset = 0
            self._all_entries_done_delay = 0
        end
    end

    do -- update frame size
        local expand_speed = rt.settings.text_box.expand_speed
        local current, target = self._current_frame_h, self._target_frame_h
        if current < target then
            current = current + delta * expand_speed
            if current > target then current = target end
        elseif current > target then
            current = current - delta * expand_speed
            if current < target then current = target end
        end

        if current ~= self._current_frame_h or self._is_first_update then
            self:_resize_frame(current)
            self._is_first_update = false
        end
    end
end

--- @brief
function rt.TextBox:draw()
    love.graphics.push()
    love.graphics.translate(self._position_x, self._position_y)
    self._frame:draw()

    local x, y, w, h = rt.aabb_unpack(self._stencil_aabb)
    local stencil_value = rt.graphics.get_stencil_value()
    rt.graphics.stencil(stencil_value, function()
        love.graphics.rectangle("fill", x, y, w, h)
    end)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

    love.graphics.push()
    love.graphics.translate(x, y - self._current_text_y_offset)

    local y_offset = 0
    local n_drawn = 0
    for i = self._first_visible_entry, self._n_entries do
        local entry = self._entries[i]

        if i - self._first_visible_entry + 1 > self._text_scroll_overlap_entry_offset then
            entry.label:draw()
        end -- skip drawing for entries scrolled above stencil by text_y_offset

        love.graphics.translate(0, entry.height)
        y_offset = y_offset + entry.height
        if y_offset - self._current_text_y_offset > h then break end
    end
    love.graphics.pop()
    rt.graphics.set_stencil_test()

    love.graphics.push()
    love.graphics.translate(self._scroll_up_indicator_x, self._scroll_up_indicator_y)
    self._scroll_up_indicator_outline:draw()
    self._scroll_up_indicator:draw()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(self._scroll_down_indicator_x, self._scroll_down_indicator_y)
    self._scroll_down_indicator_outline:draw()
    self._scroll_down_indicator:draw()
    love.graphics.pop()

    self._scrollbar:draw()

    love.graphics.pop()
end

--- @brief
function rt.TextBox:skip()
    for entry in values(self._entries) do
        entry.label:set_n_visible_characters(POSITIVE_INFINITY)
        entry.n_lines_visible = entry.n_lines
        if entry.on_done_f ~= nil and entry.is_done == false then
            entry.on_done_f()
            entry.is_done = true
        end
    end

    self._target_text_y_offset = 0
    self._current_text_y_offset = self._target_text_y_offset
    self._text_scroll_overlap_entry_offset = 0
    self._first_visible_entry = self._n_entries + 1
    self._scrollbar:set_page_index(self._first_visible_entry)
    self._position_target_value = _HIDDEN
    -- self._position_current_value = self._position_target_value

    self._n_lines = 0
    self:_update_target_frame_h()
    self:_resize_frame(self._target_frame_h)
end

--- @brief
function rt.TextBox:skip_message(id)
    if id == nil then return end

    local entry = self._entries[id]
    if entry == nil then
        rt.error("In rt.TextBox.skip: no entry with id `" .. id .. "`")
        return
    end
    if entry.is_done then return end

    entry.elapsed = POSITIVE_INFINITY
    entry.delay_elapsed = POSITIVE_INFINITY
    entry.label:set_n_visible_characters(POSITIVE_INFINITY)
    entry.n_lines_visible = entry.n_lines
    -- on_done invoked in next update
end

--- @brief
function rt.TextBox:clear()
    self._current_text_y_offset = 0
    self._text_scroll_overlap_entry_offset = 0
    self._target_text_y_offset = 0
    self._entries = {}
    self._n_entries = 0
    self._first_visible_entry = 1
    self._scrollbar:set_page_index(self._first_visible_entry, self._n_entries)
    self._n_lines = 0
    self:_update_target_frame_h()
    self:reformat()
end

--- @brief
function rt.TextBox:set_history_mode_active(b)
    if b == self._history_mode_active then return end

    self._history_mode_active = b
    if b then
        for entry in values(self._entries) do
            entry.label:set_n_visible_characters(POSITIVE_INFINITY)
            entry.n_lines_visible = entry.n_lines
            if entry.on_done_f ~= nil and entry.is_done == false then
                entry.on_done_f()
                entry.is_done = true
            end
        end

        self._position_target_value = _SHOWN
        self._target_text_y_offset = 0
        self._current_text_y_offset = 0
        self._text_scroll_overlap_entry_offset = 0
        self._first_visible_entry = math.max(self._n_entries, 1)
        self._scrollbar:set_page_index(self._first_visible_entry)
        self._n_lines = self._max_n_lines
        self:_update_target_frame_h()
    else
        self._n_lines = 0
        self:_update_target_frame_h()
    end
end

--- @brief
function rt.TextBox:get_history_mode_active()
    return self._history_mode_active
end

--- @brief
function rt.TextBox:scroll_up()
    if self._history_mode_active == false then
        self:set_history_mode_active(true)
    end

    if not self:can_scroll_up() then return end
    self._first_visible_entry = self._first_visible_entry - 1
    self._scrollbar:set_page_index(self._first_visible_entry)
end

--- @brief
function rt.TextBox:scroll_down()
    if self._history_mode_active == false then
        self:set_history_mode_active(true)
    end

    if not self:can_scroll_down() then return end
    self._first_visible_entry = self._first_visible_entry + 1
    self._scrollbar:set_page_index(self._first_visible_entry)
end

--- @brief
function rt.TextBox:can_scroll_up()
    return self._first_visible_entry > 1
end

--- @brief
function rt.TextBox:can_scroll_down()
    return self._first_visible_entry < self._n_entries
end