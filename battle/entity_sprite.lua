--- @class bt.EntitySprite
bt.EntitySprite = meta.new_abstract_type("BattleEntitySprite", rt.Widget, {
    _is_visible = true,
    _is_stunned = false,
    _snapshot = nil, -- rt.RenderTexture
    _snapshot_position_x = 0,
    _snapshot_position_y = 0
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
function bt.EntitySprite:add_status(value)
    error("abstract method called")
end

--- @brief
function bt.EntitySprite:remove_status(value)
    error("abstract method called")
end

--- @brief
function bt.EntitySprite:add_consumable(value)
    error("abstract method called")
end

--- @brief
function bt.EntitySprite:remove_consumable(value)
    error("abstract method called")
end

--- @brief
function bt.EntitySprite:set_selection_state(state)
    error("abstract method called")
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
function bt.EntitySprite:get_is_visible()
    return self._is_visible
end

--- @brief
function bt.EntitySprite:draw_snapshot(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    self._snapshot:draw(self._snapshot_position_x + x, self._snapshot_position_y + y)
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







