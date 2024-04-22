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

    -- add global conditions from battle config
    local statuses = {}
    for id in values(config.global_status_ids) do
        table.insert(statuses, bt.GlobalStatus(id))
    end

    for status in values(statuses) do
        self:add_global_status(status)
    end
end

--- @brief
function bt.BattleScene:spawn_entity(entity)
    -- add entity
    self:add_entity(entity)

    -- add UI
    local sprite = self._ui:get_sprite(entity)
    sprite:set_is_visible(false)

    if entity:get_is_enemy() then
        local animation, _ = self:play_animation(entity, "ENEMY_APPEARED")
        animation:register_start_callback(function()
            self._ui:send_message(self:format_name(entity) .. " appeared!")
            sprite:set_is_visible(true)
        end)
    else
        rt.warning("In bt.BattleScene:spawn_entity: TODO: spawn ally")
    end

    self._ui:set_priority_order(self._state:get_entities_in_order())

    -- apply equips
    local holder_proxy
    for equip in values(entity:list_equips()) do
        if equip.effect ~= nil then
            if holder_proxy == nil then
                holder_proxy = bt.EntityInterface(self, entity)
            end
            local self_proxy = bt.EquipInterface(self, equip)
            self:_safe_invoke(equip, "effect", self_proxy, holder_proxy)
        end
    end
end

--- @brief
function bt.BattleScene:remove_entity(entity)

end

--- @brief
function bt.BattleScene:add_global_status(to_add)
    meta.assert_isa(to_add, bt.GlobalStatus)

    local is_silent = to_add.is_silent

    -- check if status is already present
    for status in values(self._state:list_global_statuses()) do
        if status == to_add then
            self:play_animation(self, "MESSAGE", "", "Status " .. self:format_name(status) .. " is already active globally")
            return
        end
    end

    -- add status
    self._state:add_global_status(to_add)

    if not is_silent then
        local animation = self:play_animation(self, "GLOBAL_STATUS_GAINED", to_add)
        animation:register_finish_callback(
            self._ui:send_message(self:format_name(to_add) .. " is now active globally")
        )
    end

    -- invoke on_gained callback on self
    local callback_id = "on_gained"
    local entity_proxies

    if to_add[callback_id] ~= nil then
        local self_proxy = bt.GlobalStatusInterface(self, to_add)
        if entity_proxies == nil then
            entity_proxies = {}
            for entity in values(self._state:list_entities()) do
                table.insert(entity_proxies, bt.EntityInterface(self, entity))
            end
        end
        self:_safe_invoke(to_add, callback_id, self_proxy, entity_proxies)
    end

    -- invoke on_global_status_gained for all global statuses, statuses, and consumables
    callback_id = "on_global_status_gained"

    for status in values(self._state:list_global_statuses()) do
        if status ~= to_add then
            if status[callback_id] ~= nil then
                local self_proxy = bt.GlobalStatusInterface(self, status)
                local gained_proxy = bt.GlobalStatusInterface(self, to_add)
                if entity_proxies == nil then
                    entity_proxies = {}
                    for entity in values(self._state:list_entities()) do
                        table.insert(entity_proxies, bt.EntityInterface(self, entity))
                    end
                end
                self:_safe_invoke(status, callback_id, self_proxy, gained_proxy, entity_proxies)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local afflicted_proxy = bt.EntityInterface(self, entity)
        for status in values(entity:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                local gained_proxy = bt.GlobalStatusInterface(self, to_add)
                self:_safe_invoke(status, callback_id, self_proxy, afflicted_proxy, gained_proxy)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local holder_proxy = bt.EntityInterface(self, entity)
        for consumable in values(entity:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self, entity, consumable)
                local gained_proxy = bt.GlobalStatusInterface(self, to_add)
                self:_safe_invoke(consumable, callback_id, self_proxy, holder_proxy, gained_proxy)
            end
        end
    end
end

--- @brief
function bt.BattleScene:remove_global_status(to_remove)
    meta.assert_isa(to_remove, bt.GlobalStatus)

    local is_silent = to_remove.is_silent

    -- check if status is present
    local present = false
    for status in values(self._state:list_global_statuses()) do
        if status == to_remove then
            present = true
            break
        end
    end

    if not present then
        -- silent
        return
    end

    -- remove status
    self._state:remove_global_status(to_remove)

    if not is_silent then
        local animation = self:play_animation(self, "GLOBAL_STATUS_LOST", to_remove)
        animation:register_finish_callback(
            self._ui:send_message(self:format_name(to_remove) .. " is no longer active globally")
        )
    end

    -- invoke on_lost callback
    local callback_id = "on_gained"
    local entity_proxies

    if to_remove[callback_id] ~= nil then
        local self_proxy = bt.GlobalStatusInterface(self, to_remove)
        if entity_proxies == nil then
            entity_proxies = {}
            for entity in values(self._state:list_entities()) do
                table.insert(entity_proxies, bt.EntityInterface(self, entity))
            end
        end
        self:_safe_invoke(to_remove, callback_id, self_proxy, entity_proxies)
    end

    -- invoke on_global_status_gained for all global statuses, statuses, and consumables
    callback_id = "on_global_status_lost"

    for status in values(self._state:list_global_statuses()) do
        if status ~= to_remove then
            if status[callback_id] ~= nil then
                local self_proxy = bt.GlobalStatusInterface(self, status)
                local gained_proxy = bt.GlobalStatusInterface(self, to_remove)
                if entity_proxies == nil then
                    entity_proxies = {}
                    for entity in values(self._state:list_entities()) do
                        table.insert(entity_proxies, bt.EntityInterface(self, entity))
                    end
                end
                self:_safe_invoke(status, callback_id, self_proxy, gained_proxy, entity_proxies)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local afflicted_proxy = bt.EntityInterface(self, entity)
        for status in values(entity:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                local gained_proxy = bt.GlobalStatusInterface(self, to_remove)
                self:_safe_invoke(status, callback_id, self_proxy, afflicted_proxy, gained_proxy)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local holder_proxy = bt.EntityInterface(self, entity)
        for consumable in values(entity:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self, entity, consumable)
                local gained_proxy = bt.GlobalStatusInterface(self, to_remove)
                self:_safe_invoke(consumable, callback_id, self_proxy, holder_proxy, gained_proxy)
            end
        end
    end
end

--- @brief
function bt.BattleScene:add_status(entity, id)
    -- TODO
    self:play_animation(entity, "MESSAGE", "Added: " .. id)
    entity:add_status(bt.Status(id))
end