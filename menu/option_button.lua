--- @class mn.OptionButton
mn.OptionButton = meta.new_type("OptionButton", rt.Widget, function(...)
    assert(_G._select("#", ...) > 0)
    return meta.new(mn.OptionButton, {
        _options = {...},
        _left_indicator = rt.DirectionIndicator(rt.Direction.LEFT),
        _right_indicator = rt.DirectionIndicator(rt.Direction.RIGHT),
        _items = {}, -- Table<rt.Label>
        _current_item_i = 1,
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
            x_offset = 0,
            width = 0
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
    local label_m = m * 2

    local max_w, max_h = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local total_w = 0
    for item in values(self._items) do
        local label = item.label
        local w, h = label:measure()
        max_w = math.max(max_w, w)
        max_h = math.max(max_h, h)
        item.width = w
        total_w = total_w + w + label_m
    end

    local start_x, start_y = x, y
    local current_x, current_y = start_x, start_y
    self._left_indicator:fit_into(current_x, current_x, max_h, height)
    current_x = current_x + select(1, self._left_indicator:measure())


    for item in values(self._items) do
        local current_w = select(1, item.label:measure())
        item.label:fit_into(current_x, y + 0.5 * height - 0.5 * max_h, current_w, height)
        current_x = current_x + current_w + label_m
    end

    self._right_indicator:fit_into(current_x, current_y, max_h, height)
end

--- @override
function mn.OptionButton:draw()
    local item = self._items[self._current_item_i]

    self._left_indicator:draw()
    self._right_indicator:draw()


    for item in values(self._items) do
        rt.graphics.translate(item.x_offset, 0)
        item.label:draw()
        rt.graphics.translate(-item.x_offset, 0)
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