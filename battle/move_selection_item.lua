
bt.MoveSelectionItem = meta.new_type("MoveSelectionItem", rt.Widget, rt.Animation, function(move, n_uses)
    return meta.new(bt.MoveSelectionItem, {
        _sprite = {},
        _label = {},
        _selection_state = bt.SelectionState.INACTIVE,
        _move = move,
        _n_uses = n_uses,
        _final_width = 0,
        _final_height = 0,
        _is_empty = false
    })
end)

function bt.MoveSelectionItem:get_move()
    return self._move
end

function bt.MoveSelectionItem:get_n_uses()
    return self._n_uses
end

function bt.MoveSelectionItem:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._sprite = rt.LabeledSprite(self._move:get_sprite_id())
    self._sprite:realize()
    self._sprite:set_sprite_scale(2)
    self._sprite:set_label("<o><mono>" .. ternary(self._n_uses == POSITIVE_INFINITY, "\u{221E}", self._n_uses) .. "</mono></o>")

    self._label = rt.Label("<o>" .. self._move:get_name() .. "</o>", rt.settings.font.default_small, rt.settings.font.default_mono_small)
    self._label:realize()
    self._label:set_justify_mode(rt.JustifyMode.LEFT)

    local sprite_w, sprite_h = self._sprite:measure()
    local label_w, label_h = self._label:measure()
    self._final_width = sprite_w --math.max(sprite_w, label_w)
    self._final_height = sprite_h --sprite_h + select(2, self._label:measure())
end

function bt.MoveSelectionItem:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local sprite_w, sprite_h = self._sprite:measure()
    local sprite_x, sprite_y = x + 0.5 * width - 0.5 * sprite_w, y + 0.5 * height - 0.5 * sprite_h
    self._sprite:fit_into(sprite_x, sprite_y, sprite_w, sprite_h)

    local label_w, label_h = self._label:measure()
    self._label:fit_into(sprite_x + 0.5 * sprite_w - 0.5 * label_w, sprite_y + sprite_h, POSITIVE_INFINITY, sprite_h)
end

function bt.MoveSelectionItem:draw()
    if self._is_realized ~= true then return end
    self._sprite:draw()
    --self._label:draw()
end

function bt.MoveSelectionItem:measure()
    return self._final_width, self._final_height
end

function bt.MoveSelectionItem:update(delta)
    -- noop
end
