--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _temp = bt.OrderedBox()
    })
end)

--- @override
function bt.BattleScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for object in range(
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.GlobalStatus("DEBUG_GLOBAL_STATUS")
    ) do
        local sprite = rt.LabeledSprite(object:get_sprite_id())
        sprite:set_minimum_size(2 * 32, 2 * 32)
        self._temp:add(sprite, not meta.isa(object, bt.Consumable))
    end

    self._temp:realize()
end

--- @override
function bt.BattleScene:create_from_state(state)

end

--- @override
function bt.BattleScene:size_allocate(x, y, width, height)
    local temp_w, temp_h = 0.5 * width, 50
    self._temp:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h, temp_w, temp_h)
end

--- @override
function bt.BattleScene:draw()
    self._temp:draw_bounds()
    self._temp:draw()
end

--- @override
function bt.BattleScene:update(delta)
    self._temp:update(delta)
end

--- @override
function bt.BattleScene:make_active()
    self._is_active = true
end

--- @override
function bt.BattleScene:make_inactive()
    self._is_active = false
end