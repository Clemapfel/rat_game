bt.EntitySpriteState = meta.new_enum("EntitySpriteState", {
    IDLE = "idle",
    KNOCKED_OUT = "knocked_out",
    DEAD = "dead",
    FLINCHING = "flinching",
    ACTING = "acting"
})

--- @class bt.EntitySprite
bt.EntitySprite = meta.new_abstract_type("BattleEntitySprite", rt.Widget, {
    _is_visible = true,
    _speed_visible = true,
    _health_visible = true,
    _status_visible = true,
    _is_stunned = false,
    _snapshot = nil, -- rt.RenderTexture
    _snapshot_position_x = 0,
    _snapshot_position_y = 0,
    _state = bt.EntityState.ALIVE,
    _opacity = 1
})

--- @brief
function bt.EntitySprite:set_hp(value)
    self._health_bar:set_value(value)
end

--- @brief
function bt.EntitySprite:set_speed(value)
    self._speed_value:set_value(value)
end

--- @brief
function bt.EntitySprite:set_state(entity_state)
end

--- @brief
function bt.EntitySprite:set_selection(selection_state)
end

--- @brief
function bt.EntitySprite:add_status(status, n_turns_left)
    rt.warning("In " .. meta.typeof(self) .. ".add_status: abstract method called")
end

--- @brief
function bt.EntitySprite:remove_status(value)
    rt.warning("In " .. meta.typeof(self) .. ".remove_status: abstract method called")
end

--- @brief
function bt.EntitySprite:set_status_n_turns_left()
    rt.warning("In " .. meta.typeof(self) .. ".set_status_n_turns_left: abstract method called")
end

--- @brief
function bt.EntitySprite:activate_status(status, on_done_notify)
    rt.warning("In " .. meta.typeof(self) .. ".activate_status: abstract method called")
end

--- @brief
function bt.EntitySprite:add_consumable(value)
    rt.warning("In " .. meta.typeof(self) .. ".add_consumable: abstract method called")
end

--- @brief
function bt.EntitySprite:remove_consumable(value)
    rt.warning("In " .. meta.typeof(self) .. ".remove_consumable: abstract method called")
end

--- @brief
function bt.EntitySprite:set_consumable_n_uses_left(status)
    rt.warning("In " .. meta.typeof(self) .. ".set_consumable_n_uses_left: abstract method called")
end

--- @brief
function bt.EntitySprite:activate_consumable(status, on_done_notify)
    rt.warning("In " .. meta.typeof(self) .. ".activate_consumable: abstract method called")
end

--- @brief
function bt.EntitySprite:set_selection_state(state)
    rt.warning("In " .. meta.typeof(self) .. ".set_selection_state: abstract method called")
end

--- @brief
function bt.EntitySprite:set_is_stunned(b)
    self._is_stunned = b
end

--- @brief
function bt.EntitySprite:set_is_visible(b)
    self._is_visible = b
end

--- @brief
function bt.EntitySprite:set_health_visible(b)
    self._health_visible = b
end

--- @brief
function bt.EntitySprite:set_speed_visible(b)
    self._speed_visible = b
end

--- @brief
function bt.EntitySprite:set_status_visible(b)
    self._status_visible = b
end

--- @brief
function bt.EntitySprite:get_is_visible()
    return self._is_visible
end

--- @brief
function bt.EntitySprite:draw_snapshot(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    love.graphics.setColor(1, 1, 1, self._opacity)
    love.graphics.draw(self._snapshot._native, self._snapshot_position_x + x, self._snapshot_position_y + y)
end

--- @brief
function bt.EntitySprite:set_opacity(alpha)
    self._opacity = alpha
end

--- @brief
--- @return rt.RenderTexture
function bt.EntitySprite:get_snapshot()
    return self._snapshot
end

--- @brief
function bt.EntitySprite:get_position()
    return self._snapshot_position_x, self._snapshot_position_y
end

--- @brief
function bt.EntitySprite:skip()
    self._health_bar:skip()
    self._speed_value:skip()
    self._status_consumable_bar:skip()
end







