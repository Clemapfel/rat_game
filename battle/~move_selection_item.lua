rt.settings.battle.move_selection_item = {

}

--- @class
bt.MoveSelectionItem = meta.new_type("MoveSelectionItem", rt.Widget, function(move)
    return meta.new(bt.MoveSelectionItem, {
        _move = move,
        _sprite = {}, -- rt.Sprite
        _name = {}, -- rt.Label
        _n_uses_label = {}, -- rt.Label

        _current_n_uses = 0,
        _max_n_uses = 0,
    })
end)

--- @brief
function bt.MoveSelectionItem:set_n_uses(current, max)
    self._current_n_uses = current
    self._max_n_uses = max
    if self._is_realized then
        self._n_uses_label:set_text(self:_format_n_uses())

        local opacity = ternary(current == 0, 0.3, 1)
        self._name:set_opacity(opacity)
        self._n_uses_label:set_opacity(opacity)
        self:reformat()
    end
end

--- @brief [internal]
function bt.MoveSelectionItem:_format_n_uses()
    if self._current_n_uses == POSITIVE_INFINITY then
        return "∞"
    else
        local current = tostring(self._current_n_uses)
        local max = tostring(self._max_n_uses)
        return current -- .. " / " .. max
    end
end

--- @override
function bt.MoveSelectionItem:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    local sprite_id, sprite_index = self._move:get_sprite_id()
    self._sprite = rt.Sprite(sprite_id)
    self._sprite:realize()

    if sprite_index ~= nil then
        self._sprite:set_animation(sprite_index)
    end

    self._name = rt.Label(self._move:get_name())
    self._n_uses_label = rt.Label(self:_format_n_uses())

    for widget in range(self._name, self._n_uses_label) do
        widget:realize()
        widget:set_justify_mode(rt.JustifyMode.LEFT)
    end
end

--- @override
function bt.MoveSelectionItem:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end

    local m = rt.settings.margin_unit
    local sprite_w, sprite_h = self._sprite:get_resolution()
    self._sprite:fit_into(x, y, sprite_w, sprite_h)

    self._n_uses_label:fit_into(0, y, width, sprite_h)
    local n_uses_w = select(1, self._n_uses_label:measure())
    self._n_uses_label:fit_into(x + width - n_uses_w - m, y, width, sprite_h)

    self._name:fit_into(x + sprite_w + m, y, width, sprite_w)
end

--- @override
function bt.MoveSelectionItem:measure()
    if self._is_realized ~= true then return rt.Widget.measure(self) end
    local _, sprite_h = self._sprite:get_resolution()
    return self._bounds.width, sprite_h
end

--- @override
function bt.MoveSelectionItem:draw()
    if self._is_realized ~= true then return end
    self._sprite:draw()
    self._n_uses_label:draw()
    self._name:draw()
end