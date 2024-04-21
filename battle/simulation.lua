--- @brief
function bt.BattleScene:start_battle(battle_config)

    -- TODO load battle config instead of hardcoded
    local state = self._state
    local entities = {
        bt.BattleEntity(state, "SMALL_UFO"),
        bt.BattleEntity(state, "SMALL_UFO"),
        bt.BattleEntity(state, "BALL_WITH_FACE")
    }

    for entity in values(entities) do
        self:spawn_entity(entity)
    end
end

--- @brief
function bt.BattleScene:spawn_entity(entity)
    self:add_entity(entity)
    local sprite = self._ui:get_sprite(entity)
    sprite:set_is_visible(false)

    if entity:get_is_enemy() then
        local animation, _ = self:play_animation(entity, "ENEMY_APPEARED")
        animation:register_finish_callback(function()
            self._ui:send_message(self:format_name(entity) .. " appeared!")
            sprite:set_is_visible(true)
        end)
    else
        rt.warning("In bt.BattleScene:spawn_entity: TODO: spawn ally")
    end

    self._ui:set_priority_order(self._state:get_entities_in_order())
end