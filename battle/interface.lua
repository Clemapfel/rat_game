bt._safe_invoke_catch_errors = false

--- @brief invoke a script callback in a safe, sandboxed environment
function bt.BattleScene._safe_invoke(scene, instance, callback_id, ...)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_string(callback_id)

    -- setup fenv, done everytime to reset any globals
    local env = {}
    for common in range(
        "pairs",
        "ipairs",
        "values",
        "keys",
        "range",
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
        "status", "global_status", "entity", "equip", "consumable"
    ) do
        local is_name = "is_" .. yes .. "_interface"
        env.meta[is_name] = meta[is_name]
        env.meta["assert_" .. yes .. "_interface"] = meta["assert_" .. yes .. "_interface"]
    end

    -- shared environment, not reset between calls
    if scene._safe_invoke_shared == nil then scene._safe_invoke_shared = {} end
    env._G = scene._safe_invoke_shared

    scene:_load_scene_interface(env)

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
    local res, error_maybe

    local args = {...}
    if bt._safe_invoke_catch_errors then
        res, error_maybe = pcall(function()
            return callback(table.unpack(args))
        end)

        if error_maybe ~= nil then
            rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": Error: " .. error_maybe)
        end
    else
        res = callback(table.unpack(args))
    end

    if res ~= nil then
        rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": callback returns `" .. serialize(res) .. "`, but it should return nil")
    end
    return res
end

--- @brief add non-interface global methods
function bt.BattleScene:_load_scene_interface(env)
    env.add_global_status = function(id)
        meta.assert_string(id)
        self:add_global_status(bt.GlobalStatus(id))
    end

    env.remove_global_status = function(id)
        meta.assert_string(id)
        self:remove_global_status(bt.GlobalStatus(id))
    end
end

--- @class bt.EntityInterface
function bt.EntityInterface(scene, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.BattleEntity)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.EntityInterface"
    metatable.scene = scene
    metatable.original = entity

    self.set_hp = function(self, new_value)
        meta.assert_entity_interface(self)
        meta.assert_number(new_value)

        if new_value < 0 then
            rt.warning("In EntityInterface.set_hp: value `" .. tostring(new_value) .. "` is smaller than 0")
            new_value = clamp(new_value, 0)
        end

        local entity = getmetatable(self).original
        local scene = getmetatable(self).scene

        if new_value == 0 then
            scene:kill(entity)
        else
            local difference = entity:get_hp_current() - clamp(new_value, 0, entity:get_hp_base())
            if difference > 0 then
                scene:add_hp(entity, difference)
            else
                scene:reduce_hp(entity, math.abs(difference))
            end
        end
    end

    self.add_hp = function(self, offset)
        meta.assert_entity_interface(self)
        meta.assert_number(offset)

        local entity = getmetatable(self).original
        local scene = getmetatable(self).scene

        if offset > 0 then
            scene:add_hp(entity, offset)
        elseif offset < 0 then
            scene:reduce_hp(entity, math.abs(offset))
        end
    end

    self.reduce_hp = function(self, offset)
        meta.assert_entity_interface(self)
        meta.assert_number(offset)

        local entity = getmetatable(self).original
        local scene = getmetatable(self).scene

        if offset < 0 then
            scene:add_hp(entity, offset)
        elseif offset > 0 then
            scene:reduce_hp(entity, math.abs(offset))
        end
    end

    self.add_status = function(self, id)
        meta.assert_entity_interface(self)
        meta.assert_string(id)

        local entity = getmetatable(self).original
        local scene = getmetatable(self).scene
        scene:add_status(entity, bt.Status(id))
    end

    self.remove_status = function(self, id)
        meta.assert_entity_interface(self)
        meta.assert_string(id)

        local entity = getmetatable(self).original
        local scene = getmetatable(self).scene
        scene:remove_status(entity, bt.Status(id))
    end

    self.list_statuses = function(self)
        meta.assert_entity_interface(self)
        local entity = getmetatable(self).original
        local scene = getmetatable(self).scene

        local out = {}
        for status in values(entity) do
            table.insert(bt.StatusInterface(scene, entity, status))
        end
        return out
    end

    -- autogenerated forwarding
    for forward in range(
        "get_id",
        "get_name",
        "get_hp",
        "get_hp_base",
        "get_attack",
        "get_attack_base",
        "get_defense",
        "get_defense_base",
        "get_speed",
        "get_speed_base",
        "get_is_dead",
        "get_is_knocked_out",
        "get_is_alive"
    ) do
        self[forward] = function(self)
            local entity = getmetatable(self).original
            return entity[forward](entity)
        end
    end

    -- autogenerated getters
    metatable.getter_mapping = {
        ["id"] = self.get_id,
        ["name"] = self.get_id,
        ["hp"] = self.get_hp_current,
        ["hp_current"] = self.get_hp_current,
        ["hp_base"] = self.get_hp_base,
    }

    metatable.__index = function(self, key)
        local getter = getmetatable(self).getter_mapping[key]
        if getter ~= nil then
            return getter(self)
        else
            local out = rawget(self, key)
            if out == nil then
                rt.warning("In bt.EntityInterface:__index: trying to access property `" .. key .. "` of Entity `" .. getmetatable(self).original:get_id() .. "`, but it does not exist")
            end
            return out
        end
    end

    return self
end

--- @class bt.StatusInterface
function bt.StatusInterface(scene, entity, status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.BattleEntity)
    meta.assert_isa(status, bt.Status)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.StatusInterface"
    metatable.scene = scene
    metatable.entity = entity
    metatable.original = status

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end

    self.get_max_duration = function(self)
        return getmetatable(self).original:get_max_duration()
    end

    self.get_n_turns_elapsed = function(self)

        return getmetatable(self).entity:get_status_n_turns_elapsed(status)
    end

    metatable.getter_mapping = {
        ["id"] = self.get_id,
        ["name"] = self.get_name,
        ["max_duration"] = self.get_max_duration,
        ["n_turns_elapsed"] = self.get_n_turns_elapsed
    }

    for which in range("attack", "defense", "speed") do
        local offset_name = which .. "_offset"
        self["get_" .. offset_name] = function(self)
            return getmetatable(self).original[offset_name]
        end
        metatable.getter_mapping[offset_name] = self["get_" .. offset_name]

        local factor_name = which .. "_factor"
        self["get_" .. factor_name] = function(self)
            return getmetatable(self).original[factor_name]
        end
        metatable.getter_mapping[factor_name] = self["get_" .. factor_name]
    end

    metatable.__index = function(self, key)
        local getter = getmetatable(self).getter_mapping[key]
        if getter ~= nil then
            return getter(self)
        else
            local out = rawget(self, key)
            if out == nil then
                rt.warning("In bt.StatusInterface:__index: trying to access property `" .. key .. "` of Status `" .. getmetatable(self).original:get_id() .. "`, but it does not exist")
            end
            return out
        end
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.StatusInterface:__newindex: trying to set property `" .. key .. "` of Status `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
        return
    end
    return self
end

--- @class bt.EquipInterface
function bt.EquipInterface(scene, equip)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(equip, bt.Equip)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.EquipInterface"
    metatable.scene = scene
    metatable.original = equip

    -- autogenerated forwarding
    for forward in range(
        "get_id",
        "get_name",
        "get_hp_base_offset",
        "get_attack_base_offset",
        "get_defense_base_offset",
        "get_speed_base_offset",
        "get_attack_factor",
        "get_defense_factor",
        "get_speed_factor"
    ) do
        self[forward] = function(self)
            local entity = getmetatable(self).original
            return entity[forward](entity)
        end
    end

    metatable.getter_mapping = {
        ["id"] = self.get_id,
        ["name"] = self.get_name,
        ["hp_base_offset"] = self.get_hp_base_offset,
        ["attack_base_offset"] = self.get_attack_base_offset,
        ["defense_base_offset"] = self.get_defense_base_offset,
        ["speed_base_offset"] = self.get_speed_base_offset,
        ["attack_factor"] = self.get_attack_factor,
        ["defense_factor"] = self.get_defense_factor,
        ["speed_factor"] = self.get_speed_factor,
    }

    for which in range("attack", "defense", "speed") do
        local offset_name = which .. "_offset"
        self["get_" .. offset_name] = function(self)
            return getmetatable(self).original[offset_name]
        end
        metatable.getter_mapping[offset_name] = self["get_" .. offset_name]

        local factor_name = which .. "_factor"
        self["get_" .. factor_name] = function(self)
            return getmetatable(self).original[factor_name]
        end
        metatable.getter_mapping[factor_name] = self["get_" .. factor_name]
    end

    metatable.__index = function(self, key)
        local getter = getmetatable(self).getter_mapping[key]
        if getter ~= nil then
            return getter(self)
        else
            local out = rawget(self, key)
            if out == nil then
                rt.warning("In bt.EquipInterface:__index: trying to access property `" .. key .. "` of Equip `" .. getmetatable(self).original:get_id() .. "`, but it does not exist")
            end
            return out
        end
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.EquipInterface:__newindex: trying to set property `" .. key .. "` of Equip `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
        return
    end
    return self
end

--- @class bt.ConsumableInterface
function bt.ConsumableInterface(scene, entity, consumable)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.BattleEntity)
    meta.assert_isa(consumable, bt.Consumable)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.ConsumableInterface"
    metatable.scene = scene
    metatable.entity = entity
    metatable.original = consumable

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end

    self.get_max_n_uses = function(self)
        return getmetatable(self).original:get_max_n_uses()
    end

    metatable.getter_mapping = {
        ["id"] = self.get_id,
        ["name"] = self.get_name,
        ["max_n_uses"] = self.get_max_n_uses
    }

    metatable.__index = function(self, key)
        local getter = getmetatable(self).getter_mapping[key]
        if getter ~= nil then
            return getter(self)
        else
            local out = rawget(self, key)
            if out == nil then
                rt.warning("In bt.ConsumableInterface:__index: trying to access property `" .. key .. "` of Entity `" .. getmetatable(self).original:get_id() .. "`, but it does not exist")
            end
            return out
        end
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.ConsumableInterface:__newindex: trying to set property `" .. key .. "` of Consumable `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
        return
    end
    return self
end

--- @class bt.GlobalStatusInterface
function bt.GlobalStatusInterface(scene, status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.GlobalStatus)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.GlobalStatusInterface"
    metatable.scene = scene
    metatable.original = status

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end

    self.get_max_duration = function(self)
        return getmetatable(self).original:get_max_duration()
    end

    self.get_n_turns_elapsed = function(self)
        return getmetatable(self).scene:get_global_status_n_turns_elapsed(status)
    end

    metatable.getter_mapping = {
        ["id"] = self.get_id,
        ["name"] = self.get_name,
        ["max_duration"] = self.get_max_duration,
        ["n_turns_elapsed"] = self.get_n_turns_elapsed
    }

    for which in range("attack", "defense", "speed") do
        local offset_name = which .. "_offset"
        self["get_" .. offset_name] = function(self)
            return getmetatable(self).original[offset_name]
        end
        metatable.getter_mapping[offset_name] = self["get_" .. offset_name]

        local factor_name = which .. "_factor"
        self["get_" .. factor_name] = function(self)
            return getmetatable(self).original[factor_name]
        end
        metatable.getter_mapping[factor_name] = self["get_" .. factor_name]
    end

    metatable.__index = function(self, key)
        local getter = getmetatable(self).getter_mapping[key]
        if getter ~= nil then
            return getter(self)
        else
            local out = rawget(self, key)
            if out == nil then
                rt.warning("In bt.GlobalStatusInterface:__index: trying to access property `" .. key .. "` of GlobalStatus `" .. getmetatable(self).original:get_id() .. "`, but it does not exist")
            end
            return out
        end
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.GlobalStatusInterface:__newindex: trying to set property `" .. key .. "` of GlobalStatus `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
        return
    end
    return self
end

-- generate meta assertions
for which in values({
    {"entity", "bt.EntityInterface"},
    {"status", "bt.StatusInterface"},
    {"equip", "bt.EquipInterface"},
    {"consumable", "bt.ConsumableInterface"},
    {"global_status", "bt.GlobalStatusInterface"},
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

