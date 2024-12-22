rt.settings.text_box = {
    n_lines = 3,
    scroll_duration = 0.5, -- seconds
    letters_per_second = 60,
    scroll_speed = 300, -- px / s, frame reveal/hide movement
    label_hide_delay = 0.2, -- seconds, hold after line is done revealing but before scroll up
}
rt.settings.text_box.position_show_delay = rt.settings.text_box.scroll_duration * 1.3

local _HIDDEN = 1
local _SHOWN = 0

--- @class rt.TextBox
--- @signal scrolling_done (self) -> nil
rt.TextBox = meta.new_type("TextBox", rt.Widget, rt.Updatable, function()
    local out = meta.new(rt.TextBox, {
        _frame = rt.Frame(),
        _stencil_aabb = rt.AABB(0, 0, 1, 1),
        
        _position_path = nil, -- rt.Path
        _position_current_value = _HIDDEN,
        _position_target_value = _HIDDEN,
        _position_x = 0,
        _position_y = 0,
        _position_show_delay = 0,

        _current_line_y_offset = 0,
        _target_line_y_offset = 0,

        _max_n_lines = rt.settings.text_box.n_lines,

        _entries = {},
        _n_entries = 0,
        _first_scrolling_entry = 1
    })

    return out
end)

--- @brief
function rt.TextBox:realize()
    if self:already_realized() then return end
    self._frame:realize()
end

--- @brief
function rt.TextBox:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local xm = 2 * m + self._frame:get_thickness()
    local ym = m + self._frame:get_thickness()

    local stencil_h = rt.settings.font.default:get_native(rt.FontStyle.BOLD_ITALIC):getHeight() * rt.settings.text_box.n_lines
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
        x, 0 - frame_h * 1.3
    )

    self._manual_scroll_indicator_radius = 0.5 * m
    self._manual_scroll_indicator_x = frame_h - 2 * xm
    self._manual_scroll_indicator_y = height - 2 * ym
end

--- @brief
function rt.TextBox:append(msg, on_done_notify)
    if msg == nil or msg == "" then
        if on_done_notify ~= nil then on_done_notify() end
        return
    end

    local entry = {
        label = rt.Label(msg),
        width = 0,
        height = 0,
        line_height = 0,
        elapsed = 0,
        delay_elapsed = 0,
        n_lines_visible = 0,
        n_lines = 0,
        on_done_f = on_done_notify,
        is_done = false
    }

    entry.label:set_justify_mode(rt.JustifyMode.LEFT)
    entry.label:realize()
    entry.label:fit_into(0, 0, self._stencil_aabb.width)
    entry.line_height = entry.label:get_line_height()
    entry.n_lines = entry.label:get_n_lines()
    entry.label:set_n_visible_characters(0)
    entry.width, entry.height = entry.label:measure()

    table.insert(self._entries, entry)
    self._n_entries = self._n_entries + 1

    self._position_target_value = _SHOWN
    self._position_show_delay = 0
end

--- @brief
function rt.TextBox:update(delta)
    -- update position
    local scrolling_speed = 1 / rt.settings.text_box.scroll_duration
    local current, target = self._position_current_value, self._position_target_value
    local distance = math.abs(current - target) * 2
    if current < target then
        current = current + delta * scrolling_speed -- sic, linear when leaving screen
        if current >= target then current = target end
    elseif current > target then
        current = current - delta * scrolling_speed * distance
        if current < target then current = target end
    end

    self._position_current_value = current
    self._position_x, self._position_y = self._position_path:at(current)

    -- only scroll once frame is in position
    if current < _SHOWN then
        return
    end

    self._position_show_delay = self._position_show_delay + delta
    if self._position_show_delay < rt.settings.text_box.position_show_delay then
        return
    end

    -- scroll labels
    local letters_per_second = rt.settings.text_box.letters_per_second
    local line_delay = rt.settings.text_box.label_hide_delay

    local line_height = NEGATIVE_INFINITY
    local n_lines_shown = 0
    local is_manual = self._manual_mode == true

    local all_entries_done = self._first_scrolling_entry < self._n_entries
    local is_previous_done = true
    for i = self._first_scrolling_entry, self._n_entries do
        local entry = self._entries[i]
        entry.label:update(delta)

        local is_done, new_n_lines_visible = false, 0
        if is_previous_done then
            entry.elapsed = entry.elapsed + delta
            is_done, new_n_lines_visible = entry.label:update_n_visible_characters_from_elapsed(entry.elapsed, letters_per_second)
            n_lines_shown = n_lines_shown + new_n_lines_visible
            if n_lines_shown > self._max_n_lines then
                self._target_line_y_offset = self._target_line_y_offset + (new_n_lines_visible - entry.n_lines_visible ) * entry.line_height
            end
            entry.n_lines_visible = new_n_lines_visible
        end

        if is_done and not self._waiting_for_input then
            entry.delay_elapsed = entry.delay_elapsed + delta
            if entry.delay_elapsed > line_delay then
                if entry.is_done == false and entry.on_done_f ~= nil then
                    entry.on_done_f()
                    entry.is_done = true
                end
            else
                all_entries_done = false
            end
        else
            all_entries_done = false
            break
        end

        is_previous_done = entry.is_done
    end

    -- scroll up smoothly
    local scroll_speed = rt.settings.text_box.scroll_speed
    local current, target = self._current_line_y_offset, self._target_line_y_offset
    if current < target then
        current = current + delta * scroll_speed
        if current > target then current = target end
    end
    self._current_line_y_offset = current

    -- hide once scrolling is done
    if not self._waiting_for_input and all_entries_done and self._current_line_y_offset >= self._target_line_y_offset then
        self._position_target_value = _HIDDEN
        self._current_line_y_offset = 0
        self._target_line_y_offset = 0
        self._first_scrolling_entry = self._n_entries + 1
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

    love.graphics.translate(x, y - self._current_line_y_offset)
    local n_drawn, max_lines = 0, self._max_n_lines
    for i = self._first_scrolling_entry, self._n_entries do
        local entry = self._entries[i]
        entry.label:draw()
        love.graphics.translate(0, entry.height)
    end

    rt.graphics.set_stencil_test()

    love.graphics.pop()
end

--- @brief
function rt.TextBox:skip()
    local offset = 0
    for entry in values(self._entries) do
        entry.label:set_n_visible_characters(POSITIVE_INFINITY)
        if entry.on_done_f ~= nil and entry.is_done == false then
            entry.on_done_f()
        end
        entry.is_done = true
        offset = offset + entry.height
    end
    self._target_line_y_offset = 0
    self._current_line_y_offset = 0
    self._first_scrolling_entry = self._n_entries + 1
    self._position_target_value = _HIDDEN
    self._position_current_value = _HIDDEN
end

--- @brief
function rt.TextBox:clear()
    self._current_line_y_offset = 0
    self._target_line_y_offset = 0
    self._entries = {}
    self._n_entries = 0
    self._first_scrolling_entry = 1
end

--- @brief
function rt.TextBox:advance()
    if self._manual_mode == false then
        rt.warning("In rt.TextBox.advance: advancing textbox, even though it is not in manual advance mode")
        -- TODO
    end
end