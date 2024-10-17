--- @class bt.EntitySprite
bt.EntitySprite = meta.new_abstract_type("BattleEntitySprite", rt.Widget)

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
--- @return rt.RenderTexture
function bt.EntitySprite:get_snapshot()

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








