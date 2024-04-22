--- @brief
function bt.BattleScene:start_battle(config)
    local state = self._state

    -- clear old state
    for entity in values(self._state:list_entities()) do
        self:remove_entity(entity)
    end

    for status in values(self._state:list_global_statuses()) do
        self:remove_global_status(status)
    end

    -- set music
    self._ui:set_music("assets/music/" .. config.music_id)
    self._ui:set_background(config.background_id)

    -- spawn enemies
    local entities = {}
    for id in values(config.enemy_ids) do
        table.insert(entities, bt.BattleEntity(state, id))
    end

    for entity in values(entities) do
        self:spawn_entity(entity)
    end

    -- add global conditions
    local statuses = {}
    for id in values(config.global_status_ids) do
        table.insert(statuses, bt.GlobalStatus(id))
    end

    for status in values(statuses) do
        self:add_global_status(status)
    end

    -- activate on_battle_start for global_statuses, statuses, consumables
    local callback_id = "on_battle_start"

    local entity_proxies = {}
    for status in values(self._state:list_global_statuses()) do
        if #entity_proxies == 0 then
            for entity in values(self._state:list_entities()) do
                table.insert(entity_proxies, bt.EntityInterface(self._state, entity))
            end
        end

        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self._state, status)
            bt.safe_invoke(self._state, status, callback_id, self_proxy, entities)
        end
    end

    for entity in values(self._state:list_entities()) do
        for status in values(entity:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self._state, entity, status)
                local entity_proxy = bt.EntityInterface(self._state, entity)
                bt.safe_invoke(self._state, status, callback_id, self_proxy, entity_proxy)
            end
        end
    end
end

--- @brief
function bt.BattleScene:spawn_entity(entity)
    -- add entity
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

    -- activate equipment effects

end

--- @brief
function bt.BattleScene:remove_entity(entity)

end

--- @brief
function bt.BattleScene:add_global_status(new_status)
    meta.assert_isa(new_status, bt.GlobalStatus)

    local is_silent = new_status.is_silent

    -- check if status is already present
    for status in values(self._state:list_global_statuses()) do
        if status == status then
            self:play_animation(self, "MESSAGE", "", "Status " .. self:format_name(status) .. " is already present")
            return
        end
    end

    -- add status
    self._state:add_global_status(new_status)

    -- invoke on_gained callback on self
    local callback_id = "on_gained"
    local entity_proxies

    if new_status[callback_id] ~= nil then
        local self_proxy = bt.GlobalStatusInterface(self._state, new_status)
        if entity_proxies == nil then
            local entity_proxies = {}
            for entity in values(self._state:list_entities()) do
                table.insert(entity_proxies, bt.EntityInterface(self._state, entity))
            end
        end
        bt.safe_invoke(new_status, callback_id, self_proxy, entity_proxies)
    end

    -- invoke on_global_status_gained for all global statuses, statuses, and consumables
    callback_id = "on_global_status_gained"

    for status in values(self._state:list_global_statuses()) do
        if status ~= new_status then
            if status[callback_id] ~= nil then
                local self_proxy = bt.GlobalStatusInterface(self._state, status)
                local gained_proxy = bt.GlobalStatusInterface(self._state, new_status)
                if entity_proxies == nil then
                    for entity in values(self._state:list_entities()) do
                        table.insert(entity_proxies, bt.EntityInterface(self._state, entity))
                    end
                end
                bt.safe_invoke(status, callback_id, self_proxy, gained_proxy, entity_proxies)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local afflicted_proxy = bt.EntityInterface(self._state, entity)
        for status in values(entity:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self._state, entity, status)
                local gained_proxy = bt.GlobalStatusInterface(self._state, new_status)
                bt.safe_invoke(status, callback_id, self_proxy, afflicted_proxy, gained_proxy)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local holder_proxy = bt.EntityInterface(self._state, entity)
        for consumable in values(entity:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self._state, entity, consumable)
                local gained_proxy = bt.GlobalStatusInterface(self._state, new_status)
                bt.safe_invok(consumable, callback_id, self_proxy, holder_proxy, gained_proxy)
            end
        end
    end
end

--- @brief
function bt.BattleScene:remove_global_status(status)

end