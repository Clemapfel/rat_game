rt.settings.text_box = {
    n_lines = 3,
    scroll_duration = 0.5, -- seconds
    letters_per_second = 10010,
    scroll_speed = 300, -- px / s
    label_hide_delay = 1, -- seconds
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
    if current < target then
        current = current + delta * scrolling_speed
        if current >= target then current = target end
    elseif current > target then
        current = current - delta * scrolling_speed
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

    for i = self._first_scrolling_entry, self._n_entries do
        local entry = self._entries[i]

        entry.elapsed = entry.elapsed + delta
        local is_done, new_n_lines_visible = entry.label:update_n_visible_characters_from_elapsed(entry.elapsed)

        n_lines_shown = n_lines_shown + new_n_lines_visible
        if n_lines_shown > self._max_n_lines then
            self._target_line_y_offset = self._target_line_y_offset + (new_n_lines_visible - entry.n_lines_visible ) * entry.line_height
        end
        entry.n_lines_visible = new_n_lines_visible

        if is_done then
            entry.delay_elapsed = entry.delay_elapsed + delta
            if entry.delay_elapsed > line_delay then
                if entry.is_done == false and entry.on_done_f ~= nil then
                    entry.on_done_f()
                    entry.is_done = true
                end
            end
        else
            break
        end
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
    local is_done = true
    for entry in values(self._entries) do
        if entry.is_done == false then
            is_done = false
            break
        end
    end

    if is_done and self._current_line_y_offset >= self._target_line_y_offset then
        self._position_target_value = _HIDDEN
        self._first_scrolling_entry = self._n_entries + 1
    end
end

--- @brief
function rt.TextBox:draw()
    love.graphics.push()
    love.graphics.translate(self._position_x, self._position_y)
    self._frame:draw()

    local x, y, w, h = rt.aabb_unpack(self._stencil_aabb)
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle("fill", x, y, w, h)

    local stencil_value = meta.hash(self) % 254 + 1
    rt.graphics.stencil(stencil_value, function()
        love.graphics.rectangle("fill", x, y, w, h)
    end)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

    love.graphics.translate(x, y - self._current_line_y_offset)
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
    self:update(POSITIVE_INFINITY)
end

--- @brief
function rt.TextBox:clear()
    self._current_line_y_offset = 0
    self._target_line_y_offset = 0
    self._entries = {}
    self._n_entries = 0
    self._first_scrolling_entry = 1
end