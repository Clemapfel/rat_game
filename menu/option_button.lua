rt.settings.menu.option_button = {
    scroll_speed = 300, -- px per second
}

--- @class mn.OptionButton
mn.OptionButton = meta.new_type("OptionButton", rt.Widget, function(...)
    assert(_G._select("#", ...) > 0)
    return meta.new(mn.OptionButton, {
        _options = {...},
        _left_indicator = rt.DirectionIndicator(rt.Direction.LEFT),
        _right_indicator = rt.DirectionIndicator(rt.Direction.RIGHT),
        _left_line = rt.Line(),
        _right_line = rt.Line(),
        _items = {}, -- Table<rt.Label>
        _current_item_i = 1,
        _current_offset = 0,
        _x_offset = 0,
        _n_items = 0,
        _stencil = rt.Rectangle()
    })
end)

--- @override
function mn.OptionButton:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._option_labels = {}
    for option in values(self._options) do
        local to_push = {
            label = rt.Label("<o>" .. option .. "</o>"),
            offset = 0,
            line = rt.Line(),
        }
        to_push.label:realize()
        to_push.label:set_justify_mode(rt.JustifyMode.LEFT)

        self._n_items = self._n_items + 1
        table.insert(self._items, to_push)
    end

    self._left_indicator:realize()
    self._right_indicator:realize()
end

--- @override
function mn.OptionButton:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local current_x = x

    local label_ws = {}
    local label_hs = {}
    local max_h, max_w = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local total_w = 0
    local n = 0
    for item in values(self._items) do
        local w, h = item.label:measure()
        table.insert(label_ws, w)
        table.insert(label_hs, h)
        max_w = math.max(max_w, w)
        max_h = math.max(max_h, h)
        total_w = total_w + w
        n = n + 1
    end

    local label_m = (width - total_w) / (n + 1)

    self._left_indicator:fit_into(current_x, y + 0.5 * height - 0.5 * max_h, max_h, max_h)
    current_x = current_x + max_h

    self._left_line:resize(current_x, y, current_x, y + height)

    local label_start_x = current_x
    current_x = current_x + m

    for i, item in ipairs(self._items) do
        local w, h = label_ws[i], label_hs[i]
        item.label:fit_into(current_x, y + 0.5 * height - 0.5 * h, POSITIVE_INFINITY)
        item.offset = current_x + 0.5 * w - label_start_x

        local line_x = current_x + 0.5 * w
        item.line:resize(line_x, y, line_x, y + height)
        current_x = current_x + label_m + w
    end

    self._x_offset = (current_x - label_start_x) / 2

    self._right_line:resize(current_x, y, current_x, y + height)
    self._right_indicator:fit_into(current_x, y + 0.5 * height - 0.5 * max_h, max_h, max_h)
end

--- @override
function mn.OptionButton:draw()
    local item = self._items[self._current_item_i]

    self._left_indicator:draw()
    self._right_indicator:draw()

    self._left_line:draw()
    self._right_line:draw()

    rt.graphics.translate(self._x_offset - self._current_offset, 0)

    for item in values(self._items) do
        item.label:draw()
        item.line:draw()
    end
    rt.graphics.translate(-(self._x_offset - self._current_offset), 0)
end

--- @brief
function mn.OptionButton:update(delta)
    local target_offset = self._items[self._current_item_i].offset

    local offset = delta * rt.settings.menu.option_button.scroll_speed
    if self._current_offset < target_offset then
        self._current_offset = clamp(self._current_offset + offset, 0, target_offset)
    elseif self._current_offset > target_offset then
        self._current_offset = clamp(self._current_offset - offset, target_offset)
    end

end

--- @brief
function mn.OptionButton:move_right()
    if self:can_move_right() then
        self._current_item_i = self._current_item_i + 1
        return true
    else
        return false
    end
end

--- @brief
function mn.OptionButton:move_left()
    if self:can_move_left() then
        self._current_item_i = self._current_item_i - 1
        return true
    else
        return false
    end
end

--- @brief
function mn.OptionButton:can_move_left()
    return self._current_item_i > 1
end

--- @brief
function mn.OptionButton:can_move_right()
    return self._current_item_i < self._n_items
end