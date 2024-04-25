--- @brief
function bt.BattleScene:start_battle(config)
    println("[DBG][SCENE] Start Battle")

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
    println("[DBG][SCENE] Spawn entity " .. entity:get_id())

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

    println("[DBG][SCENE] Add global status " .. to_add:get_id())

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
        animation:register_finish_callback(function()
            self._ui:send_message(self:format_name(to_add) .. " is now active globally")
        end)
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

    println("[DBG][SCENE] Remove global status " .. to_remove:get_id())

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
        animation:register_finish_callback(function()
            self._ui:send_message(self:format_name(to_remove) .. " is no longer active globally")
        end)
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
function bt.BattleScene:add_status(entity, to_add)
    meta.assert_isa(to_add, bt.Status)

    local is_silent = to_add.is_silent

    -- if entity is dead or knocked out, prevent adding status
    if entity:get_is_dead() or entity:get_is_knocked_out() then
        return
    end

    -- prevent double status
    for status in values(entity:list_statuses()) do
        if status:get_id() == to_add:get_id() then
            if not is_silent then
                local animation = self:play_animation(entity, "MESSAGE",
                        "Already Has " .. self:format_name(to_add)
                )
                animation:register_start_callback(function()
                    self._ui:send_message(self:format_name(entity) .. " already has status " .. self:format_name(to_add))
                end)
            end
            return
        end
    end

    -- add status
    entity:add_status(to_add)

    if not is_silent then
        local animation, sprite = self:play_animation(entity, "STATUS_GAINED", to_add)
        animation:register_start_callback(function()
            self._ui:send_message(self:format_name(entity) .. " gained status " .. self:format_name(to_add))
            sprite:add_status(to_add)
        end)
    end

    -- invoke callback on self
    local callback_id = "on_gained"
    if to_add[callback_id] ~= nil then
        local afflicted_proxy = bt.EntityInterface(self, entity)
        local self_proxy = bt.StatusInterface(self, entity, to_add)
        self:_safe_invoke(to_add, callback_id, self_proxy, afflicted_proxy)
    end

    callback_id = "on_status_gained"
    local afflicted_proxy = bt.EntityInterface(self, entity)
    local new_status_proxy = bt.StatusInterface(self, entity, to_add)

    -- invoke status gained for global statuses, and status / consumable of self
    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:_safe_invoke(status, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
        end
    end

    for status in values(entity:list_statuses()) do
        if not (status == to_add) then
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                self:_safe_invoke(status, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
            end
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            local holder_proxy = bt.EntityInterface(self, entity)
            self:_safe_invoke(consumable, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
        end
    end
end

--- @brief
function bt.BattleScene:remove_status(entity, to_remove)
    meta.assert_isa(to_remove, bt.Status)

    -- if entity is already dead, do nothing
    if entity:get_is_dead() then return end

    -- if status is not present, do nothing
    if not entity:has_status(to_remove) then
        return
    end

    -- play animation, actual removal is delayed until after all the callbacks are invoked
    local is_silent = to_remove.is_silent
    if not is_silent then
        local animation, sprite = self:play_animation(entity, "STATUS_LOST", to_remove)
        animation:register_start_callback(function()
            self._ui:send_message(self:format_name(entity) .. " lost status " .. self:format_name(to_remove))
            sprite:remove_status(to_remove)
        end)
    end

    -- invoke lost callback on self
    local callback_id = "on_lost"
    if to_remove[callback_id] ~= nil then
        local afflicted_proxy = bt.EntityInterface(self, entity)
        local self_proxy = bt.StatusInterface(self, entity, to_remove)
        self:_safe_invoke(to_remove, callback_id, self_proxy, afflicted_proxy)
    end

    -- invoke on_status_lost for (global) status, consumables
    callback_id = "on_status_lost"
    local afflicted_proxy = bt.EntityInterface(self, entity)
    local old_status_proxy = bt.StatusInterface(self, entity, to_remove)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:_safe_invoke(status, callback_id, self_proxy, afflicted_proxy, old_status_proxy)
        end
    end

    for status in values(entity:list_statuses()) do
        if not (status == to_remove) then
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                self:_safe_invoke(status, callback_id, self_proxy, afflicted_proxy, old_status_proxy)
            end
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            self:_safe_invoke(consumable, callback_id, self_proxy, afflicted_proxy, old_status_proxy)
        end
    end

    -- remove status
    entity:remove_status(to_remove)
end

--- @brief
function bt.BattleScene:knock_out(entity)
    meta.assert_isa(entity, bt.BattleEntity)

    -- if entity is already dead or knocked out, do nothing
    if entity:get_is_dead() then
        return
    end

    if entity:get_is_knocked_out() then
        local animation, _ = self:play_animation(entity, "MESSAGE", "Already Knocked out")
        animation:register_start_callback(function()
            self._ui:send_message(self:format_name(entity) .. " is already knocked out")
        end)
    end

    local hp_before = entity.hp
    local prio_before = entity.priority

    local status_before = {}
    for status in values(entity:list_statuses()) do
        table.insert(status_before, status)
    end

    -- set hp to 0, clear all statuses, add knocked out
    -- setting hp like this is not considered damage, so damage callbacks are not invoked
    meta.set_is_mutable(entity, true)
    entity.hp = 0
    entity:clear_statuses()
    entity.state = bt.BattleEntityState.KNOCKED_OUT
    entity.priority = 0
    meta.set_is_mutable(entity, false)

    -- animation
    local animation, sprite = self:play_animation(entity, "KNOCKED_OUT")
    animation:register_start_callback(function()
        self._ui:send_message(self:format_name(entity) .. " was <b><color=LIGHT_RED_3><u>knocked out</u></color></b>")
        sprite:set_hp(0, entity.hp_base)
        for status in values(status_before) do
            sprite:remove_status(status)
        end
        self._ui:set_state(entity, bt.BattleEntityState.KNOCKED_OUT)
        if prio_before ~= entity.priority then
            self._ui:set_priority_order(self._state:get_entities_in_order())
        end
    end)

    -- invoke on_knocked_out callbacks on global status, status, consumables
    local callback_id = "on_knocked_out"
    local knocked_out_proxy = bt.EntityInterface(self, entity)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:_safe_invoke(status, callback_id, self_proxy, knocked_out_proxy)
        end
    end

    for status in values(entity:list_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, entity, status)
            self:_safe_invoke(status, callback_id, self_proxy, knocked_out_proxy)
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            self:_safe_invoke(consumable, callback_id, self_proxy, knocked_out_proxy)
        end
    end

    -- delay to after status callbacks were invoked
    meta.set_is_mutable(entity, true)
    entity:clear_statuses()
    entity.state = bt.BattleEntityState.KNOCKED_OUT
    meta.set_is_mutable(entity, false)
end

--- @brief
function bt.BattleScene:help_up(entity)
    meta.assert_isa(entity, bt.BattleEntity)

    -- if entity is dead or not knocked out, do nothing
    if entity:get_is_dead() or not entity:get_is_knocked_out() then
        return
    end

    -- set hp to 1, restore state
    meta.set_is_mutable(entity, true)
    entity.hp = 1
    entity.state = bt.BattleEntityState.ALIVE

    entity:clear_statuses() -- redundancy from knock_out
    entity.priority = 0
    meta.set_is_mutable(entity, false)

    -- animation
    local animation, sprite = self:play_animation(entity, "HELPED_UP")
    animation:register_start_callback(function()
        self._ui:send_message(self:format_name(entity) .. " got <b><color=LIGHT_GREEN_2><u>back up</u></color></b>")
        sprite:set_hp(1, entity.hp_base)
        self._ui:set_state(entity, bt.BattleEntityState.ALIVE)
        self._ui:set_priority_order(self._state:get_entities_in_order())
    end)

    -- invoked on_helped_up
    local callback_id = "on_helped_up"
    local helped_up_proxy = bt.EntityInterface(self, entity)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:_safe_invoke(status, callback_id, self_proxy, helped_up_proxy)
        end
    end

    for status in values(entity:list_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, entity, status)
            self:_safe_invoke(status, callback_id, self_proxy, helped_up_proxy)
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            self:_safe_invoke(consumable, callback_id, self_proxy, helped_up_proxy)
        end
    end
end

--- @brief
function bt.BattleScene:kill(entity)
    meta.assert_isa(entity, bt.BattleEntity)

    -- if entity is already dead, do nothing
    if entity:get_is_dead() then return end

    local status_before = {}
    for status in values(entity:list_statuses()) do
        table.insert(status_before, status)
    end

    -- override all properties
    meta.set_is_mutable(entity, true)
    entity.hp = 0
    entity.priority = 0
    meta.set_is_mutable(entity, false)

    -- animation
    local animation, sprite = self:play_animation(entity, "KILLED")
    animation:register_start_callback(function()
        self._ui:send_message(self:format_name(entity) .. " was <o><b><outline_color=TRUE_WHITE><color=BLACK>KILLED</color></b></o></outline_color>")
        sprite:set_hp(0)
        for status in values(status_before) do
            sprite:remove_status(status)
        end
        self._ui:set_state(entity, bt.BattleEntityState.DEAD)
    end)

    animation:register_finish_callback(function()
        self._ui:set_priority_order(self._state:get_entities_in_order())
    end)

    -- invoked on_killed
    local callback_id = "on_killed"
    local killed_proxy = bt.EntityInterface(self, entity)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:_safe_invoke(status, callback_id, self_proxy, killed_proxy)
        end
    end

    for status in values(entity:list_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, entity, status)
            self:_safe_invoke(status, callback_id, self_proxy, killed_proxy)
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            self:_safe_invoke(consumable, callback_id, self_proxy, killed_proxy)
        end
    end

    -- delay status and state to after status callbacks were invoked
    meta.set_is_mutable(entity, true)
    entity.state = bt.BattleEntityState.DEAD
    entity:clear_statuses()
    meta.set_is_mutable(entity, false)
end

--- @brief
function bt.BattleScene:switch(entity_a, entity_b)
    meta.assert_isa(entity_a, bt.BattleEntity)
    meta.assert_isa(entity_b, bt.BattleEntity)

    -- avoid redundant switch
    if entity_a == entity_b then return end

    -- entity cannot switch between ally and enemy
    if not (entity_a:get_is_enemy() == entity_b:get_is_enemy()) then
        rt.warning("In bt.BattleScene:switch: trying to switch entities `" .. entity_a:get_id() .. "` and `" .. entity_b:get_id() .. "`, which are a mix of enemies and allies, this operation is not permitted")
        return
    end

    -- get positions of entities
    local a_i, b_i = -1, -1
    do
        local i = 1
        for entity in values(self._state:list_entities()) do
            if entity == entity_a then a_i = i end
            if entity == entity_b then b_i = i end
            if a_i ~= -1 and b_i ~= -1 then break end
            i = i + 1
        end
    end

    -- swap entities
    self._state:swap(a_i, b_i)

    -- animation
    local a_animation, a_sprite = self:play_animation(entity_a, "SWITCH")
    local b_animation, b_sprite = self:play_animation(entity_b, "SWITCH")
    a_animation:synch_with(b_animation)
    a_animation:register_finish_callback(function()
        self._ui:send_message(self:format_name(entity_a) .. " and " .. self:format_name(entity_b) .. " swapped places")
        self._ui:swap(entity_a, entity_b)
    end)

    -- invoke callbacks
    local callback_id = "on_switch"
    local a_proxy = bt.EntityInterface(self, entity_a)
    local b_proxy = bt.EntityInterface(self, entity_b)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:_safe_invoke(status, callback_id, self_proxy, a_proxy, b_proxy)
        end
    end

    for both in range(
        {entity_a, entity_b},
        {entity_b, entity_a}
    ) do
        local this = both[1]
        local other = both[2]
        for status in values(this:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, this, status)
                local afflicted_proxy = bt.EntityInterface(self, this)
                local other_proxy = bt.EntityInterface(self, other)
                self:_safe_invoke(status, callback_id, self_proxy, afflicted_proxy, other_proxy)
            end
        end
    end

    for both in range(
        {entity_a, entity_b},
        {entity_b, entity_a}
    ) do
        local this = both[1]
        local other = both[2]
        for consumable in values(this:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self, this, consumable)
                local afflicted_proxy = bt.EntityInterface(self, this)
                local other_proxy = bt.EntityInterface(self, other)
                self:_safe_invoke(consumable, callback_id, self_proxy, afflicted_proxy, other_proxy)
            end
        end
    end
end