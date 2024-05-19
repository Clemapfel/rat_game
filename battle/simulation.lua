bt._safe_invoke_catch_errors = true
-- generate meta assertions
for which in values({
    {"entity", "bt.EntityInterface"},
    {"status", "bt.StatusInterface"},
    {"equip", "bt.EquipInterface"},
    {"consumable", "bt.ConsumableInterface"},
    {"global_status", "bt.GlobalStatusInterface"},
    {"move", "bt.MoveInterface"}
}) do
    local is_name = "is_" .. which[1] .. "_interface"

    --- @brief get whether type is interface
    meta["is_" .. which[1] .. "_interface"] = function(x)
        local metatable = getmetatable(x)
        return metatable ~= nil and metatable.type == which[2]
    end

    --- @brief throw if type is not interface
    meta["assert_" .. which[1] .. "_interface"] = function(x)
        if not meta[is_name](x) then
            rt.error("In " .. debug.getinfo(2, "n").name .. ": Expected `" .. which[2] .. "`, got `" .. meta.typeof(x) .. "`")
        end
    end
end

function bt.Scene:safe_invoke(instance, callback_id, ...)
    meta.assert_isa(self, bt.Scene)
    meta.assert_string(callback_id)
    local scene = self

    -- setup fenv, done everytime to reset any globals
    local env = {}
    for common in range(
        "pairs",
        "ipairs",
        "values",
        "keys",
        "range",
        "tostring",
        "print",
        "println",
        "dbg",

        "sizeof",
        "is_empty",
        "clamp",
        "project",
        "mix",
        "smoothstep",
        "fract",
        "ternary",
        "which",
        "splat",
        "slurp",
        "select",
        "serialize",

        "INFINITY",
        "POSITIVE_INFINITY",
        "NEGATIVE_INFINITY"
    ) do
        assert(_G[common] ~= nil)
        env[common] = _G[common]
    end

    env.rand = rt.rand
    env.random = {}
    env.math = math
    env.table = table
    env.string = string

    -- blacklist
    for no in range(
        "assert",
        "collectgarbage",
        "dofile",
        "error",
        "getmetatable",
        "setmetatable",
        "load",
        "loadfile",
        "require",
        "rawequal",
        "rawget",
        "rawset",
        "setfenv",
        "getfenv"
    ) do
        env[no] = nil
    end

    -- whitelist assertions
    env.meta = {}
    for yes in range(
        "status", "global_status", "entity", "equip", "consumable", "move"
    ) do
        local is_name = "is_" .. yes .. "_interface"
        env.meta[is_name] = meta[is_name]
        env.meta["assert_" .. yes .. "_interface"] = meta["assert_" .. yes .. "_interface"]
    end

    for yes in range(
        "number", "string", "function", "nil"
    ) do
        env.meta["is_" .. yes] = meta["is_" .. yes]
        env.meta["assert_" .. yes] = meta["assert_" .. yes]
    end

    -- shared environment, not reset between calls
    if scene._safe_invoke_shared == nil then scene._safe_invoke_shared = {} end
    env._G = scene._safe_invoke_shared

    setmetatable(env, {})
    local metatable = getmetatable(env)
    metatable.__index = function(self, key)
        rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": Error: trying to access `" .. key .. "` which is not part of the sandboxed environment")
        return nil
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": Error: trying to modify sandboxed environment, but it is immutable. Only use `local` variables, or write to the `_G` shared table")
        return nil
    end

    -- safely invoke callback
    local callback = instance[callback_id]
    debug.setfenv(callback, env)

    local args = { ... }
    local res
    if bt._safe_invoke_catch_errors then
        local success, error_maybe = pcall(function()
            return callback(table.unpack(args))
        end)

        if not success then
            rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": Error: " .. error_maybe)
        else
            res = error_maybe
        end
    else
        res = callback(table.unpack(args))
    end

    if res ~= nil then
        rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": callback returns `" .. serialize(res) .. "`, but it should return nil")
    end

    return res
end
--- @brief
function bt.Scene:_animate_apply_status(holder, status)
    meta.assert_isa(holder, bt.Entity)
    meta.assert_isa(status, bt.Status)
    if status.is_silent == true then return end
    local sprite = self._ui:get_sprite(holder)
    local apply = bt.Animation.STATUS_APPLIED(sprite, status)
    local message = bt.Animation.MESSAGE(self, self:format_name(holder) .. "s " .. self:format_name(status) .. " activated")
    self:play_animations({apply, message})
end

--- @brief
function bt.Scene:_animate_apply_consumable(holder, consumable)
    meta.assert_isa(holder, bt.Entity)
    meta.assert_isa(consumable, bt.Consumable)
    local sprite = self._ui:get_sprite(holder)
    local apply = bt.Animation.CONSUMABLE_APPLIED(sprite, consumable)
    local message = bt.Animation.MESSAGE(self, self:format_name(holder) .. "s " .. self:format_name(consumable) .. " activated")
    self:play_animations({apply, message})
end

--- @brief
function bt.Scene:_animate_apply_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatus)
    if global_status.is_silent == true then return end
    local apply = bt.Animation.GLOBAL_STATUS_APPLIED(self._ui, global_status)
    local message = bt.Animation.MESSAGE(self, self:format_name(global_status) .. " activated")
    self:play_animations({apply, message})
end

--- @brief
function bt.Scene:start_battle(battle)
    meta.assert_isa(battle, bt.Battle)
    self._state = battle
    self._ui:clear()

    local animations = {}
    local messages = {}
    for entity in values(self._state:list_entities()) do
        self._ui:add_entity(entity)
        if entity:get_is_enemy() then
            self._ui:get_sprite(entity):set_ui_is_visible(false)
        end

        if entity:get_is_enemy() then
            table.insert(animations, bt.Animation.ENEMY_APPEARED(self._ui:get_sprite(entity)))
            table.insert(messages, self:format_name(entity) .. " appeared")
        else
            table.insert(animations, bt.Animation.ALLY_APPEARED(self._ui:get_sprite(entity)))
        end
    end
    table.insert(animations, bt.Animation.MESSAGE(self, table.concat(messages, "\n")))

    local on_finish = function()
        for entity in values(self._state:list_entities()) do
            if entity:get_is_enemy() then
                self._ui:get_sprite(entity):set_ui_is_visible(true)
            end
        end
    end

    self:play_animations(animations, nil, on_finish)

    -- wait with queue reveal until sprites are visible
    self:play_animations(bt.Animation.REORDER_PRIORITY_QUEUE(self, self._state:list_entities_in_order()))

    -- apply equips
    for entity in values(self._entities) do
        for equip in values(entity:list_equips()) do
            if equip.effect ~= nil then
                local holder_proxy = bt.EntityInterface(self, entity)
                local equip_proxy = bt.EquipInterface(self, equip)
                self:play_animations(bt.Animation.MESSAGE(self, self:format_name(entity) .. "s equipped " .. self:format_name(equip) .. " activated"))
                bt.safe_invoke(self, equip, "effect", equip_proxy, holder_proxy)
            end
        end
    end

    -- apply global statuses
    for status in values(battle:list_global_statuses()) do
        self:add_global_status(status)
    end

    -- TODO: set music
    -- TODO: set background
end

--- @brief
function bt.Scene:add_global_status(to_add)
    local is_silent = to_add.is_silent

    -- check if status is already present
    for status in values(self._state:list_global_statuses()) do
        if status == to_add then
            return
        end
    end

    -- add status
    self._state:add_global_status(to_add)

    if not is_silent then
        local add = bt.Animation.GLOBAL_STATUS_GAINED(self._ui, to_add)
        local message = bt.Animation.MESSAGE(self, self:format_name(to_add) .. " is now active globally")
        local on_start = function()
            self._ui:add_global_status(to_add)
        end
        self:play_animations({add, message}, on_start)
    end

    -- invoke on_gained callbacks
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
        self:safe_invoke(to_add, callback_id, self_proxy, entity_proxies)
        self:_animate_apply_global_status(to_add)
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
                self:safe_invoke(status, callback_id, self_proxy, gained_proxy, entity_proxies)
                self:_animate_apply_global_status(status)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local afflicted_proxy = bt.EntityInterface(self, entity)
        for status in values(entity:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                local gained_proxy = bt.GlobalStatusInterface(self, to_add)
                self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, gained_proxy)
                self:_animate_apply_status(entity, status)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local holder_proxy = bt.EntityInterface(self, entity)
        for consumable in values(entity:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self, entity, consumable)
                local gained_proxy = bt.GlobalStatusInterface(self, to_add)
                self:safe_invoke(consumable, callback_id, self_proxy, holder_proxy, gained_proxy)
                self:_animate_apply_consumable(entity, consumable)
            end
        end
    end
end

--- @brief
function bt.Scene:remove_global_status(to_remove)
    local is_silent = to_remove.is_silent

    -- check if status is present
    local present = false
    for status in values(self._state:list_global_statuses()) do
        if status == to_remove then
            present = true
            break
        end
    end
    if not present then return end

    -- remove status
    self._state:remove_global_status(to_remove)

    if not is_silent then
        local remove = bt.Animation.GLOBAL_STATUS_LOST(self._ui, to_remove)
        local message = bt.Animation.MESSAGE(self, self:format_name(to_remove) .. " faded")
        self:play_animations({ remove, message })
    end

    -- invoke on lost callback
    local callback_id = "on_lost"
    local entity_proxies

    if to_remove[callback_id] ~= nil then
        local self_proxy = bt.GlobalStatusInterface(self, to_remove)
        if entity_proxies == nil then
            entity_proxies = {}
            for entity in values(self._state:list_entities()) do
                table.insert(entity_proxies, bt.EntityInterface(self, entity))
            end
        end
        self:safe_invoke(to_remove, callback_id, self_proxy, entity_proxies)
        self:_animate_apply_global_status(to_remove)
    end

    -- delay ui removal until after callbacks are invoked
    self:play_animations({bt.Animation.DELAY(0.2)}, function()
        self._ui:remove_global_status(to_remove)
    end)

    -- invoke on_global_status_gained for all global statuses, statuses, and consumables
    callback_id = "on_global_status_lost"

    for status in values(self._state:list_global_statuses()) do
        if status ~= to_remove then
            if status[callback_id] ~= nil then
                local self_proxy = bt.GlobalStatusInterface(self, status)
                local lost_proxy = bt.GlobalStatusInterface(self, to_remove)
                if entity_proxies == nil then
                    entity_proxies = {}
                    for entity in values(self._state:list_entities()) do
                        table.insert(entity_proxies, bt.EntityInterface(self, entity))
                    end
                end
                self:safe_invoke(status, callback_id, self_proxy, lost_proxy, entity_proxies)
                self:_animate_apply_global_status(status)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local afflicted_proxy = bt.EntityInterface(self, entity)
        for status in values(entity:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                local lost_proxy = bt.GlobalStatusInterface(self, to_remove)
                self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, lost_proxy)
                self:_animate_apply_status(entity, status)
            end
        end
    end

    for entity in values(self._state:list_entities()) do
        local holder_proxy = bt.EntityInterface(self, entity)
        for consumable in values(entity:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self, entity, consumable)
                local lost_proxy = bt.GlobalStatusInterface(self, to_remove)
                self:safe_invoke(consumable, callback_id, self_proxy, holder_proxy, lost_proxy)
                self:_animate_apply_consumable(entity, consumable)
            end
        end
    end
end

--- @brief
function bt.Scene:add_status(entity, to_add)
    meta.assert_isa(to_add, bt.Status)

    local is_silent = to_add.is_silent

    -- if entity is dead or knocked out, prevent adding status
    if entity:get_is_dead() or entity:get_is_knocked_out() then
        return
    end

    -- prevent double status
    for status in values(entity:list_statuses()) do
        if status == to_add then
            if not is_silent then
                self:play_animations(bt.Animation.MESSAGE(self, self:format_name(entity) .. " already has " .. self:format_name(to_add)))
            end
            return
        end
    end

    -- add status
    local stun_before = entity:get_is_stunned()
    entity:add_status(to_add)
    local stun_after = entity:get_is_stunned()

    -- animation
    if not is_silent then
        local sprite = self._ui:get_sprite(entity)
        do
            local animation = bt.Animation.STATUS_GAINED(sprite, to_add)
            local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " gained status " .. self:format_name(to_add))
            local reorder = bt.Animation.REORDER_PRIORITY_QUEUE(self, self._state:list_entities_in_order())

            local on_start = function()
                sprite:add_status(to_add)
            end
            self:play_animations({animation, message, reorder}, on_start)
        end

        do -- newly stunned
            if stun_after == true and stun_after ~= stun_before then
                local animation = bt.Animation.STUNNED(sprite)
                local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " is now stunned")

                local on_start = function()
                    self._ui:set_is_stunned(entity, true)
                end
                self:play_animations({animation, message}, on_start)
            end
        end
    end

    -- invoke callback on self
    local callback_id = "on_gained"
    if to_add[callback_id] ~= nil then
        local afflicted_proxy = bt.EntityInterface(self, entity)
        local self_proxy = bt.StatusInterface(self, entity, to_add)
        self:safe_invoke(to_add, callback_id, self_proxy, afflicted_proxy)
        self:_animate_apply_status(entity, to_add)
    end

    -- invoke status gained for global statuses, and status / consumable of self
    callback_id = "on_status_gained"
    local afflicted_proxy = bt.EntityInterface(self, entity)
    local new_status_proxy = bt.StatusInterface(self, entity, to_add)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
            self:_animate_apply_global_status(status)
        end
    end

    for status in values(entity:list_statuses()) do
        if not (status == to_add) then
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
                self:_animate_apply_status(entity, status)
            end
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            local holder_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(consumable, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
            self:_animate_apply_consumable(entity, consumable)
        end
    end
end

--- @brief
function bt.Scene:remove_status(entity, to_remove)
    meta.assert_isa(to_remove, bt.Status)

    local is_silent = to_remove.is_silent

    -- if entity is dead or knocked out, prevent adding status
    if entity:get_is_dead() or entity:get_is_knocked_out() then
        return
    end

    -- assert has status
    local present = false
    for status in values(entity:list_statuses()) do
        if status == to_remove then
            present = true
            break
        end
    end
    if not present then return end

    -- add status
    local stun_before = entity:get_is_stunned()
    entity:remove_status(to_remove)
    local stun_after = entity:get_is_stunned()

    -- animation
    local sprite = self._ui:get_sprite(entity)
    if not is_silent then
        do
            local animation = bt.Animation.STATUS_LOST(sprite, to_remove)
            local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " lost status " .. self:format_name(to_remove))
            local reorder = bt.Animation.REORDER_PRIORITY_QUEUE(self, self._state:list_entities_in_order())
            self:play_animations({animation, message, reorder})
        end

        do -- no longer stunned
            if stun_after == false and stun_after ~= stun_before then
                local animation = bt.Animation.NO_LONGER_STUNNED(sprite)
                local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " is no longer stunned")

                local on_finish = function()
                    self._ui:set_is_stunned(entity, false)
                end
                self:play_animations({animation, message}, nil, on_finish)
            end
        end
    end

    -- invoke callback on self
    local callback_id = "on_lost"
    if to_remove[callback_id] ~= nil then
        local afflicted_proxy = bt.EntityInterface(self, entity)
        local self_proxy = bt.StatusInterface(self, entity, to_remove)
        self:safe_invoke(to_remove, callback_id, self_proxy, afflicted_proxy)
        self:_animate_apply_status(entity, to_remove)
    end

    -- delay status bar update until after status callback is invoked, so _apply_status doesn't fizzle
    if not is_silent then
        local on_finish = function() sprite:remove_status(to_remove) end
        self:play_animations({}, nil, on_finish)
    end

    -- invoke status lost for global statuses, and status / consumable of self
    callback_id = "on_status_lost"
    local afflicted_proxy = bt.EntityInterface(self, entity)
    local new_status_proxy = bt.StatusInterface(self, entity, to_remove)

    --[[
    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
            self:_animate_apply_global_status(status)
        end
    end

    for status in values(entity:list_statuses()) do
        if not (status == to_remove) then
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, entity, status)
                self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
                self:_animate_apply_status(entity, status)
            end
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            local holder_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(consumable, callback_id, self_proxy, afflicted_proxy, new_status_proxy)
            self:_animate_apply_consumable(entity, consumable)
        end
    end
    ]]--
end

--- @brief
function bt.Scene:knock_out(entity)

    -- if already dead, do nothing
    if entity:get_is_dead() then return end

    -- if already knocked out, do nothing
    if entity:get_is_knocked_out() then
        local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " is already knocked out")
        self:play_animations(message)
        return
    end

    local status_before = {}
    for status in values(entity:list_statuses()) do
        table.insert(status_before, status)
    end

    meta.set_is_mutable(entity, true)
    entity.hp_current = 0
    entity.state = bt.EntityState.KNOCKED_OUT
    entity.priority = 0
    entity:clear_statuses()
    meta.set_is_mutable(entity, false)

    do -- animation and UI updates
        local knock_out = bt.Animation.KNOCKED_OUT(self._ui:get_sprite(entity))
        local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " was <b><color=LIGHT_RED_3><u>knocked out</u></color></b>")

        local on_start = function()
            local sprite = self._ui:get_sprite(entity)
            sprite:set_hp(0, entity:get_hp_base())
            self._ui:set_state(entity, bt.EntityState.KNOCKED_OUT)
        end
        self:play_animations({knock_out, message}, on_start)
    end

    -- invoke on_knocked_out callbacks on global status, status, consumables
    local callback_id = "on_knocked_out"
    local knocked_out_proxy = bt.EntityInterface(self, entity)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:safe_invoke(status, callback_id, self_proxy, knocked_out_proxy)
            self:_animate_apply_global_status(status)
        end
    end

    for status in values(status_before) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, entity, status)
            self:safe_invoke(status, callback_id, self_proxy, knocked_out_proxy)
            self:_animate_apply_status(entity, status)
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            self:safe_invoke(consumable, callback_id, self_proxy, knocked_out_proxy)
            self:_animate_apply_consumable(entity, consumable)
        end
    end

    -- clear sprite statuses bar after callbacks
    local on_start = function()
        for status in values(status_before) do
            self._ui:get_sprite(entity):remove_status(status)
        end
    end
    self:play_animations({bt.Animation.DELAY(0.5)}, on_start) -- delay to make status removal obvious
end

--- @brief
function bt.Scene:help_up(entity)
    -- if entity is dead or not knocked out, do nothing
    if entity:get_is_dead() or not entity:get_is_knocked_out() then
        return
    end

    -- set hp to 1, restore state
    meta.set_is_mutable(entity, true)
    entity.hp_current = 1
    entity.state = bt.EntityState.ALIVE
    entity.priority = 0
    meta.set_is_mutable(entity, false)

    -- animation
    do
        local sprite = self._ui:get_sprite(entity)
        local help_up = bt.Animation.HELPED_UP(sprite)
        local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " got <b><color=LIGHT_GREEN_2><u>back up</u></color></b>")

        local on_start = function()
            local sprite = self._ui:get_sprite(entity)
            sprite:set_hp(1, entity:get_hp_base())
            self._ui:set_state(entity, bt.EntityState.ALIVE)
        end
        self:play_animations({help_up, message}, on_start)
    end

    -- invoked on_helped_up
    local callback_id = "on_helped_up"
    local helped_up_proxy = bt.EntityInterface(self, entity)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:safe_invoke(status, callback_id, self_proxy, helped_up_proxy)
            self:_animate_apply_global_status(status)
        end
    end

    -- no callbacks for self.status, because being knocked out always clears all statuses
    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            self:safe_invoke(consumable, callback_id, self_proxy, helped_up_proxy)
            self:_animate_apply_consumable(entity, consumable)
        end
    end
end

--- @brief
function bt.Scene:kill(entity)
    -- if entity is already dead, do nothing
    if entity:get_is_dead() then return end

    local status_before = {}
    for status in values(entity:list_statuses()) do
        table.insert(status_before, status)
    end

    -- override all properties
    meta.set_is_mutable(entity, true)
    entity.hp_current = 0
    entity.state = bt.EntityState.DEAD
    entity.priority = 0
    entity:clear_statuses()
    meta.set_is_mutable(entity, false)

    -- animation, announce kill, invoke all callbacks, then actually animate kill
    do -- animation and UI updates
        local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " was <o><b><outline_color=TRUE_WHITE><color=BLACK>KILLED</color></b></o></outline_color>")
        self:play_animations({message})
    end

    -- invoked on_killed
    local callback_id = "on_killed"
    local killed_proxy = bt.EntityInterface(self, entity)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:safe_invoke(status, callback_id, self_proxy, killed_proxy)
            self:_animate_apply_global_status(status)
        end
    end

    for status in values(status_before) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, entity, status)
            self:safe_invoke(status, callback_id, self_proxy, killed_proxy)
            self:_animate_apply_status(entity, status)
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            self:safe_invoke(consumable, callback_id, self_proxy, killed_proxy)
            self:_animate_apply_consumable(entity, consumable)
        end
    end

    -- animation, announce kill, invoke all callbacks, then actually animate kill
    do -- animation and UI updates
        local kill = bt.Animation.KILLED(self._ui:get_sprite(entity))

        local on_start = function()
            local sprite = self._ui:get_sprite(entity)
            sprite:set_hp(0, entity:get_hp_base())
            for status in values(status_before) do
                sprite:remove_status(status)
            end
            self._ui:set_state(entity, bt.EntityState.DEAD)
        end
        self:play_animations({kill}, on_start)
    end
end

--- @brief
function bt.Scene:switch(entity_a, entity_b)
    meta.assert_isa(entity_a, bt.Entity)
    meta.assert_isa(entity_b, bt.Entity)

    -- avoid redundant switch
    if entity_a == entity_b then return end

    -- entity cannot switch between ally and enemy
    if not (entity_a:get_is_enemy() == entity_b:get_is_enemy()) then
        rt.warning("In bt.BattleScene:switch: trying to switch entities `" .. entity_a:get_id() .. "` and `" .. entity_b:get_id() .. "`, which are a mix of enemies and allies, this operation is dissallowed")
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
    do
        local swap_01 = bt.Animation.SWITCH(self._ui:get_sprite(entity_a))
        local swap_02 = bt.Animation.SWITCH(self._ui:get_sprite(entity_b))
        local message = bt.Animation.MESSAGE(self, self:format_name(entity_a) .. " and " .. self:format_name(entity_b) .. " switched places")
        local on_finish = function()
            self._ui:swap(entity_a, entity_b)
        end
        self:play_animations({swap_01, swap_02}, nil, on_finish)
    end

    -- invoke callbacks
    local callback_id = "on_switch"
    local a_proxy = bt.EntityInterface(self, entity_a)
    local b_proxy = bt.EntityInterface(self, entity_b)

    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:safe_invoke(status, callback_id, self_proxy, a_proxy, b_proxy)
            self:_animate_apply_global_status(status)
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
                self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, other_proxy)
                self:_animate_apply_status(this, status)
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
                self:safe_invoke(consumable, callback_id, self_proxy, afflicted_proxy, other_proxy)
                self:_animate_apply_consumable(this, consumable)
            end
        end
    end
end

--- @brief
function bt.Scene:consume(holder, to_consume)
    -- if not held, abort
    if not holder:has_consumable(to_consume) then
        return
    end

    -- consume 1 stack
    local n_left = holder:consume_consumable(to_consume)
    local sprite = self._ui:get_sprite(holder)
    local consume = bt.Animation.CONSUMABLE_CONSUMED(sprite, to_consume)
    local message = bt.Animation.MESSAGE(self, self:format_name(holder) .. " consumed their " .. self:format_name(to_consume))
    local on_finish = function()
        if n_left <= 0 then
            sprite:remove_consumable(to_consume)
        else
            sprite:set_consumable_n_consumed(to_consume, holder:get_consumable_n_consumed(to_consume))
        end
    end

    self:play_animations({consume, message}, nil, on_finish)

    -- invoke callbacks if consumable is gone
    if n_left <= 0 then
        local callback_id = "on_consumable_consumed"
        local consumable_proxy = bt.ConsumableInterface(self, holder, to_consume)
        local holder_proxy = bt.EntityInterface(self, holder)

        for status in values(self._state:list_global_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.GlobalStatusInterface(self, status)
                self:safe_invoke(status, callback_id, self_proxy, holder_proxy, consumable_proxy)
                self:_animate_apply_global_status(status)
            end
        end

        for status in values(holder:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, holder, status)
                self:safe_invoke(status, callback_id, self_proxy, holder_proxy, consumable_proxy)
                self:_animate_apply_status(holder, status)
            end
        end

        for consumable in values(holder:list_consumables()) do
            if consumable ~= to_consume and consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(holder, consumable)
                self:safe_invoke(consumable, callback_id, self_proxy, holder_proxy, consumable_proxy)
                self:_animate_apply_consumable(holder, consumable)
            end
        end
    end
end

--- @brief
function bt.Scene:increase_hp(entity, value)
    meta.assert_number(value)
    value = math.ceil(value)

    -- only allow positive hp gain
    if value == 0 then
        return
    elseif value < 0 then
        self:reduce_hp(entity, math.abs(value))
    end

    -- fizzle on dead
    if entity:get_is_dead() then
        return
    end

    -- revive if knocked out
    if entity:get_is_knocked_out() then
        self:help_up(entity)
        -- continue
    end

    local current = entity:get_hp()
    local max = entity:get_hp_base()
    local after = clamp(current + value, 1, max)
    local offset = math.abs(after - current)

    -- mutate entity
    meta.set_is_mutable(entity, true)
    entity.hp_current = after
    meta.set_is_mutable(entity, false)

    local sprite = self._ui:get_sprite(entity)
    local gain = bt.Animation.HP_GAINED(sprite, value)
    local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " gained " .. "<color=LIGHT_GREEN_2><mono><b>" .. tostring(value) .. "</b></mono></color> HP")
    local on_start = function()
        sprite:set_hp(after, max)
    end
    self:play_animations({gain, message}, on_start)

    if offset <= 0 then return end

    -- invoke callbacks
    local callback_id = "on_healing_received"
    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            local healed_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(status, callback_id, self_proxy, healed_proxy, value)
            self:_animate_apply_global_status(status)
        end
    end

    for status in values(entity:list_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, entity, status)
            local healed_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(status, callback_id, self_proxy, healed_proxy, value)
            self:_animate_apply_status(entity, status)
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            local holder_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(consumable, callback_id, self_proxy, holder_proxy, value)
            self:_animate_apply_consumable(entity, consumable)
        end
    end

    callback_id = "on_healing_performed"
    local move_user = self._state:get_current_move_user()
    if move_user ~= nil then
        for status in values(self._state:list_global_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.GlobalStatusInterface(self, status)
                local performer_proxy = bt.EntityInterface(self, move_user)
                local receiver_proxy = bt.EntityInterface(self, entity)
                self:safe_invoke(status, callback_id, self_proxy, performer_proxy, receiver_proxy, value)
                self:_animate_apply_global_status(status)
            end
        end

        for status in values(move_user:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, move_user, status)
                local afflicted_proxy = bt.EntityInterface(self, move_user)
                local receiver_proxy = bt.EntityInterface(self, entity)
                self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, receiver_proxy, value)
                self:_animate_apply_status(move_user, status)
            end
        end

        for consumable in values(move_user:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self, move_user, consumable)
                local holder_proxy = bt.EntityInterface(self, move_user)
                local receiver_proxy = bt.EntityInterface(self, entity)
                self:safe_invoke(consumable, callback_id, self_proxy, holder_proxy, receiver_proxy, value)
                self:_animate_apply_consumable(move_user, consumable)
            end
        end
    end
end

--- @brief
function bt.Scene:reduce_hp(entity, value)
    meta.assert_number(value)
    value = math.floor(value)

    -- only allow hp loss
    if value == 0 then
        return
    elseif value < 0 then
        self:add_hp(entity, math.abs(value))
    end

    -- fizzle on death
    if entity:get_is_dead() then return end

    -- kill if knocked out
    if entity:get_is_knocked_out() then
        self:kill(entity)
        return
    end

    local current = entity:get_hp()
    local after = clamp(current - value, 0)
    local offset = current - after

    meta.set_is_mutable(entity, true)
    entity.hp_current = after
    meta.set_is_mutable(entity, false)

    -- animation
    local sprite = self._ui:get_sprite(entity)
    local lost = bt.Animation.HP_LOST(sprite, value)
    local message = bt.Animation.MESSAGE(self, self:format_name(entity) .. " lost " .. "<color=RED><mono><b>" .. tostring(value) .. "</b></mono></color> HP")
    local on_start = function()
        sprite:set_hp(after)
    end

    self:play_animations({lost, message}, on_start)

    -- invoke damage taken callbacks
    local callback_id = "on_damage_taken"
    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            local healed_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(status, callback_id, self_proxy, healed_proxy, value)
            self:_animate_apply_global_status(status)
        end
    end

    for status in values(entity:list_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, entity, status)
            local healed_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(status, callback_id, self_proxy, healed_proxy, value)
            self:_animate_apply_status(entity, status)
        end
    end

    for consumable in values(entity:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, entity, consumable)
            local holder_proxy = bt.EntityInterface(self, entity)
            self:safe_invoke(consumable, callback_id, self_proxy, holder_proxy, value)
            self:_animate_apply_consumable(entity, consumable)
        end
    end

    callback_id = "on_damage_dealt"
    local move_user = self._state:get_current_move_user()
    if move_user ~= nil then
        for status in values(self._state:list_global_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.GlobalStatusInterface(self, status)
                local performer_proxy = bt.EntityInterface(self, move_user)
                local receiver_proxy = bt.EntityInterface(self, entity)
                self:safe_invoke(status, callback_id, self_proxy, performer_proxy, receiver_proxy, value)
                self:_animate_apply_global_status(status)
            end
        end

        for status in values(move_user:list_statuses()) do
            if status[callback_id] ~= nil then
                local self_proxy = bt.StatusInterface(self, move_user, status)
                local afflicted_proxy = bt.EntityInterface(self, move_user)
                local receiver_proxy = bt.EntityInterface(self, entity)
                self:safe_invoke(status, callback_id, self_proxy, afflicted_proxy, receiver_proxy, value)
                self:_animate_apply_status(move_user, status)
            end
        end

        for consumable in values(move_user:list_consumables()) do
            if consumable[callback_id] ~= nil then
                local self_proxy = bt.ConsumableInterface(self, move_user, consumable)
                local holder_proxy = bt.EntityInterface(self, move_user)
                local receiver_proxy = bt.EntityInterface(self, entity)
                self:safe_invoke(consumable, callback_id, self_proxy, holder_proxy, receiver_proxy, value)
                self:_animate_apply_consumable(move_user, consumable)
            end
        end
    end

    if after <= 0 then
        self:knock_out(entity)
    end
end

--- @brief
function bt.Scene:use_move(user, move, targets)
    if meta.isa(targets, bt.Entity) then
        targets = { targets }
    end

    -- if stunned, fizzle
    if user:get_is_stunned() == true then
        local stunned = bt.Animation.STUNNED(self._ui:get_sprite(user))
        local message = bt.Animation.MESSAGE(self, self:format_name(user) .. " is stunned")
        self:play_animations({stunned, message})
        return
    end

    -- make current move, reduce n uses
    local depleted = user:reduce_move_n_uses(move)

    -- animation
    local animations = {}
    for target in values(targets) do
        -- TODO: use move-specific animation instead of placeholder
        table.insert(animations, bt.Animation.MOVE(self._ui:get_sprite(target), move))
    end

    table.insert(animations, bt.Animation.MESSAGE(self, self:format_name(user) .. " used " .. self:format_name(move) .. "!"))
    self:play_animations(animations)

    -- invoke effect
    local move_proxy = bt.MoveInterface(self, move)
    local user_proxy = bt.EntityInterface(self, user)
    local target_proxies = {}
    for target in values(targets) do
        table.insert(target_proxies, bt.EntityInterface(self, target))
    end

    self._state:set_current_move_selection(user, move, targets)
    self:safe_invoke(move, "effect", move_proxy, user_proxy, target_proxies)
    self._state:reset_current_move_selection()

    -- callbacks
    local callback_id = "on_move_used"
    for status in values(self._state:list_global_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.GlobalStatusInterface(self, status)
            self:safe_invoke(status, callback_id, self_proxy, user_proxy, move_proxy, target_proxies)
            self:_animate_apply_global_status(status)
        end
    end

    for status in values(user:list_statuses()) do
        if status[callback_id] ~= nil then
            local self_proxy = bt.StatusInterface(self, user, status)
            self:safe_invoke(status, callback_id, self_proxy, user_proxy, move_proxy, target_proxies)
            self:_animate_apply_status(user, status)
        end
    end

    for consumable in values(user:list_consumables()) do
        if consumable[callback_id] ~= nil then
            local self_proxy = bt.ConsumableInterface(self, user, consumable)
            self:safe_invoke(consumable, callback_id, self_proxy, user_proxy, move_proxy, target_proxies)
            self:_animate_apply_consumable(user, consumable)
        end
    end
end

--- @brief
function bt.Scene:start_turn()
    -- on_turn_start for consumable, status, global_status
end

--- @brief
function bt.Scene:end_turn()
    -- on_turn_end for consumable, status, global_status
    -- cleanup dead enemies
    -- gameover if dead allies
    -- advance status, global_status n turns, clear if above max duration
end