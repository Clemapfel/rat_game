rt.settings.battle.battle_sprite = {
    animation_ids = {
        idle = "idle",
        knocked_out = "knocked_out"
    }
}

bt.BattleSprite = meta.new_abstract_type("BattleSprite", rt.Widget, rt.Animation, {
    _entity = nil,  -- bt.Entity
    _ui_is_visible = true,
    _is_selected = false,

    _priority = 0,
    _state = bt.EntityState.ALIVE,

    _health_bar = nil, -- bt.HealthBar
    _speed_value = nil, -- bt.Speedvalue
    _status_bar = nil, -- bt.StatusBar

    _opacity = 1
})

--- @brief
function bt.BattleSprite:synchronize(entity)
    self._health_bar:synchronize(entity)
    self._speed_value:synchronize(entity)
    self._status_bar:synchronize(entity)
    self:set_state(entity:get_state())
end

--- @brief
function bt.BattleSprite:draw()
    if self._ui_is_visible == true then
        self._health_bar:draw()
        self._speed_value:draw()
        self._status_bar:draw()
    end
end

--- @brief
function bt.BattleSprite:set_ui_is_visible(b)
    self._ui_is_visible = b
    rt.error("In bt.BattleSprite.TODO: pure virtual function called")
end

--- @brief
function bt.BattleSprite:get_ui_is_visible()
    return self._ui_is_visible
end

--- @brief
function bt.BattleSprite:add_status(status)
    self._status_bar:add(status, 0)
end

--- @brief
function bt.BattleSprite:remove_status(status)
    self._status_bar:remove(status)
end

--- @brief
function bt.BattleSprite:activate_status(status)
    self._status_bar:activate(status)
end

--- @brief
function bt.BattleSprite:set_hp(value, value_max)
    self._health_bar:set_value(value, value_max)
end

--- @brief
function bt.BattleSprite:set_priority(status)
    self._priority = status
end

--- @brief
function bt.BattleSprite:get_priority()
    return self._priority
end

--- @brief
function bt.BattleSprite:set_state(state)
    self._state = state
    self._health_bar:set_state(state)
end

--- @brief
function bt.BattleSprite:get_state()
    return self._state
end

--- @brief
function bt.BattleSprite:set_is_selected(b)
    self._is_selected = b
end

--- @brief
function bt.BattleSprite:get_is_selected()
    return self._is_selected
end

--- @brief
function bt.BattleSprite:get_entity()
    return self._entity
end