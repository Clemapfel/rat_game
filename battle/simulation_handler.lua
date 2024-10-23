rt.settings.battle.simulation = {
    illegal_action_is_error = true
}

bt.error_function = ternary(rt.settings.battle.simulation.illegal_action_is_error, rt.error, rt.warning)

--- @brief
function bt.BattleScene:invoke(f, env)
    debug.setfenv(f, env)
    f()
end

--- @brief adds proxy table such that original table is read-only
function meta.as_immutable(t)
    return setmetatable({}, {
        __index = function(_, key)
            local out = t[key]
            if out == nil then
                bt.error_function("trying to access `" .. key .. "` of `" .. tostring(t) .. "`, but this value does not exist")
                return nil
            end
            return out
        end,

        __newindex = function(_, key, value)
            bt.error_function("trying to modify table `" .. tostring(t) .. "`, but it is immutable")
        end
    })
end

--- @type bt.EntityProxy
bt.EntityProxy= "EntityProxy"

--- @type bt.MoveProxy
bt.MoveProxy = "MoveProxy"

--- @type bt.StatusProxy
bt.StatusProxy = "StatusProxy"

--- @type bt.GlobalStatusProxy
bt.GlobalStatusProxy = "GlobalStatusProxy"

--- @type bt.EquipProxy
bt.EquipProxy = "EquipProxy"

--- @type bt.ConsumableProxy
bt.ConsumableProxy = "ConsumableProxy"

--- @type bt.Number
bt.Number = "Number"

--- @type bt.String
bt.String = "String"

--- @type bt.Boolean
bt.Boolean = "Boolean"

for name_type_proxy in range(
    {"entity", bt.Entity, bt.EntityProxy},
    {"move", bt.Move, bt.MoveProxy},
    {"equip", bt.Equip, bt.EquipProxy},
    {"status", bt.Status, bt.StatusProxy},
    {"global_status", bt.GlobalStatus, bt.GlobalStatusProxy},
    {"consumable", bt.Consumable, bt.ConsumableProxy}
) do
    local name, type, proxy = table.unpack(name_type_proxy)

    --- @class bt.EntityProxy
    --- @class bt.MoveProxy
    --- @class bt.StatusProxy
    --- @class bt.GlobalStatusProxy
    --- @class bt.EquipProxy
    --- @class bt.ConsumableProxy

    --- @brief create_entity_proxy, create_move_proxy, create_status_proxy, create_global_status_proxy, create_equip_proxy, create_consumable_proxy
    bt["create_" .. name .. "_proxy"] = function(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, type)
        local out = meta.as_immutable({})
        local metatable = getmetatable(out)

        metatable._type = proxy
        metatable._native = native
        metatable._scene = scene
        metatable._state = scene._state
        metatable._values = {} -- Table<String, { value::Number, per_turn_offset::Number }>

        metatable.__tostring = function(self)
            return "<" .. meta.get_typename(type) .. " #" .. meta.hash(native) .. ">"
        end

        metatable.__eq = function(self, other)
            local other_metatable = getmetatable(other)
            if other_metatable == nil then return false end
            local other_native = other_metatable._native
            if other_native == nil then return false end
            return native:get_id() == other_native:get_id()
        end

        return out
    end

    meta["is_" .. name .. "_proxy"] = function(x)
        if type(x) ~= "table" then return end
        local metatable = getmetatable(x)
        return metatable._type == proxy and meta.isa(metatable._native, type)
    end
end

for which_type in range(
    {"is_number", bt.Number},
    {"is_string", bt.String},
    {"is_boolean", bt.Boolean},
    {"is_entity_proxy", bt.EntityProxy},
    {"is_move_proxy", bt.MoveProxy},
    {"is_status_proxy", bt.StatusProxy},
    {"is_global_status_proxy", bt.GlobalStatusProxy},
    {"is_consumable_proxy", bt.ConsumableProxy}
) do
    local which, type = table.unpack(which_type)

    --- @brief bt.assert_is_number, bt.assert_is_string, bt.assert_is_boolean, bt.assert_is_entity_proxy, bt.assert_is_status_proxy, bt.assert_is_global_status_proxy, bt.assert_is_consumable_proxy
    bt["assert_" .. which] = function(x, function_name, arg_i)
        if not meta[which](x) then
            bt.error_function("In " .. function_name .. ": Wrong argument #" .. arg_i .. ", expected `" .. type .. "`, got `" .. meta.typeof(x) .. "`")
        end
    end
end

do
    local _type_to_function = {
        [bt.Number] = bt.assert_is_number,
        [bt.String] = bt.assert_is_string,
        [bt.Boolean] = bt.assert_is_boolean,
        [bt.EntityProxy] = bt.assert_is_entity_proxy,
        [bt.MoveProxy] = bt.assert_is_move_proxy,
        [bt.StatusProxy] = bt.assert_is_status_proxy,
        [bt.GlobalStatusProxy] = bt.assert_is_global_status_proxy,
        [bt.ConsumableProxy] = bt.assert_is_consumable_proxy
    }

    --- @brief
    function bt.assert_args(scope, ...)
        local n_types = select("#", ...)
        local arg_i = 1
        for i = 1, n_types, 2 do
            local arg = select(i, ...)
            local type = select(i+1, ...)
            local assert_f = _type_to_function[type]
            if assert_f == nil then
                rt.error("In bt.assert_args: unhandled type `" .. type .. "`")
            end

            assert_f(arg, scope, arg_i)
            arg_i = arg_i + 1
        end
    end
end

--- @brief
function bt.BattleScene:create_simulation_environment()
    local _scene = self
    local _state = self._state
    meta.assert_isa(_scene, bt.BattleScene)
    meta.assert_isa(_state, rt.GameState)

    local env = {}

    -- math
    local math_proxy = {}
    for k, v in pairs(math) do
        math_proxy[k] = v
    end
    env.math = meta.as_immutable(math_proxy)

    -- table
    local table_proxy = {}
    for k, v in pairs(table) do
        table_proxy[k] = v
    end
    env.table = meta.as_immutable(table_proxy)

    -- string
    local string_proxy = {}
    for k, v in pairs(string) do
        string_proxy[k] = v
    end
    env.string = meta.as_immutable(string_proxy)

    --- common
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
        "clamp",
        "mix",
        "smoothstep",
        "fract",
        "ternary",
        "which",
        "select",
        "serialize",
        "INFINITY",
        "POSITIVE_INFINITY",
        "NEGATIVE_INFINITY"
    ) do
        assert(_G[common] ~= nil)
        env[common] = _G[common]
    end

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
        "getfenv",
        "debug"
    ) do
        env[no] = nil
    end

    local function _initialize_non_entities(prefix, path, true_type_ctor, proxy_ctor)
        for _, name in pairs(love.filesystem.getDirectoryItems(path)) do
            if string.match(name, "%.lua$") ~= nil then
                local id = string.gsub(name, "%.lua$", "")
                env[prefix .. "_" .. id] = proxy_ctor(_scene, true_type_ctor(id))
            end
        end
    end

    local consumable_prefix = "CONSUMABLE"
    local equip_prefix = "EQUIP"
    local move_prefix = "MOVE"
    local global_status_prefix = "GLOBAL_STATUS"
    local status_prefix = "STATUS"

    -- consumables as CONSUMABLE_* global
    _initialize_non_entities(
        consumable_prefix,
        rt.settings.battle.consumable.config_path,
        bt.Consumable,
        bt.create_consumable_proxy
    )

    -- equips as EQUIP_* global
    _initialize_non_entities(
        equip_prefix,
        rt.settings.battle.equip.config_path,
        bt.Equip,
        bt.create_equip_proxy
    )

    -- moves as MOVE_* global
    _initialize_non_entities(
        move_prefix,
        rt.settings.battle.move.config_path,
        bt.Move,
        bt.create_move_proxy
    )

    -- global status as GLOBAL_STATUS_* global
    _initialize_non_entities(
        global_status_prefix,
        rt.settings.battle.global_status.config_path,
        bt.GlobalStatus,
        bt.create_global_status_proxy
    )

    -- status as STATUS_* global
    _initialize_non_entities(
        status_prefix,
        rt.settings.battle.status.config_path,
        bt.Status,
        bt.create_status_proxy
    )

    -- override proxy creation to use cached global version
    bt.get_consumable_proxy = function(x)
        assert(env[consumable_prefix .. "_" .. x:get_id()] ~= nil)
        return env[consumable_prefix .. "_" .. x:get_id()]
    end

    bt.get_equip_proxy = function(x)
        assert(env[equip_prefix .. "_" .. x:get_id()] ~= nil)
        return env[equip_prefix .. "_" .. x:get_id()]
    end

    bt.get_move_proxy = function(x)
        assert(env[move_prefix .. "_" .. x:get_id()] ~= nil)
        return env[move_prefix .. "_" .. x:get_id()]
    end

    bt.get_status_proxy = function(x)
        assert(env[status_prefix .. "_" .. x:get_id()] ~= nil)
        return env[status_prefix .. "_" .. x:get_id()]
    end

    bt.get_global_status_proxy = function(x)
        assert(env[global_status_prefix .. "_" .. x:get_id()] ~= nil)
        return env[global_status_prefix .. "_" .. x:get_id()]
    end

    -- entity IDs only, use by env.spawn
    local entity_path = rt.settings.battle.entity.config_path
    for _, name in pairs(love.filesystem.getDirectoryItems(entity_path)) do
        if string.match(name, "%.lua$") ~= nil then
            local id = string.gsub(name, "%.lua$", "")
            env["ENTITY_" .. id] = id
        end
    end

    local _get_native = function(x)
        return getmetatable(x)._native
    end

    --- @param callback_id String
    --- @param status bt.Status
    --- @param afflicted_proxy bt.EntityProxy
    local _try_invoke_status_callback = function(callback_id, status, afflicted_proxy, ...)
        if status[callback_id] == nil then return end
        local afflicted = _get_native(afflicted_proxy)
        local afflicted_sprite = _scene._sprites[afflicted]
        local animation = bt.Animation.STATUS_APPLIED(
            _scene, status, afflicted_sprite
        )
        _scene:_push_animation(animation)
        _scene:invoke(status[callback_id], status, afflicted_proxy, ...)
    end

    local _invoke_all_status_callbacks = function(callback_id, afflicted_proxy, ...)
        local afflicted = _get_native(afflicted_proxy)
        for status in values(_state:entity_list_statuses(afflicted)) do
            _try_invoke_status_callback(callback_id, status, afflicted_proxy)
        end
    end

    --- @param callback_id String
    --- @param consumable bt.Consumable
    --- @param holder_proxy bt.EntityProxy
    local _try_invoke_consumable_callback = function(callback_id, consumable, holder_proxy, ...)
        if consumable[callback_id] == nil then return end
        local holder = _get_native(holder_proxy)
        local holder_sprite = _scene._sprites[holder]
        local animation = bt.Animation.STATUS_APPLIED(
            _scene, consumable, holder_sprite
        )
        _scene:_push_animation(animation)
        _scene:invoke(consumable[callback_id], consumable, holder_proxy, ...)
    end

    local _invoke_all_consumable_callbacks = function(callback_id, holder_proxy, ...)
        local holder = _get_native(holder_proxy)
        for consumable in values(_state:entity_list_consumables(holder)) do
            _try_invoke_consumable_callback(callback_id, consumable, holder_proxy, ...)
        end
    end

    --- @param callback_id String
    --- @param global_status bt.GlobalStatusProxy
    local _try_invoke_global_status_callback = function(callback_id, global_status, ...)
        if global_status[callback_id] == nil then return end
        local animation bt.Animation.GLOBAL_STATUS_APPLIED(_scene, global_status)
        _scene:_push_animation(animation)
        _scene:invoke(global_status[callback_id], global_status, ...)
    end

    local _invoke_all_global_status_callbacks = function(callback_id, ...)
        for global_status in values(_state:list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status, ...)
        end
    end

    --- @brief add numerical value to entity cache, is reduced by `per_turn_offset` at end of turn
    --- @param entity_proxy bt.EntityProxy
    --- @param name String
    --- @param initial_value Number
    --- @param per_turn_offset Number (optional)
    --- @return nil
    function env.set_value(entity_proxy, name, initial_value, per_turn_offset)
        if per_turn_offset == nil then per_turn_offset = 0 end
        bt.assert_args("add_value",
            entity_proxy, bt.EntityProxy,
            name, bt.String,
            initial_value, bt.Number,
            per_turn_offset, bt.Number
        )

        local values = getmetatable(entity_proxy)._values
        values[name] = {
            value = initial_value,
            per_turn_offset = per_turn_offset
        } -- intentional override
    end

    --- @brief get value
    --- @param entity_proxy bt.EntityProxy
    --- @param name String
    --- @return any
    function env.get_value(entity_proxy, name)
        bt.assert_args("get_value",
            entity_proxy, bt.EntityProxy,
            name, bt.String
        )

        local entry = getmetatable(entity_proxy)._values[name]
        if entry == nil then
            return nil
        else
            return entry.value
        end
    end

    --- @brief get value
    --- @param entity_proxy bt.EntityProxy
    --- @param name String
    function env.has_value(entity_proxy, name)
        bt.assert_args("has_value",
            entity_proxy, bt.EntityProxy,
            name, bt.String
        )

        return getmetatable(entity_proxy)._values[name] ~= nil
    end

    --- @brief get current hp
    --- @param entity_proxy bt.EntityProxy
    --- @return Number
    function env.get_hp(entity_proxy)
        bt.assert_args("get_hp", entity_proxy, bt.EntityProxy)
        return _state:entity_get_hp(_get_native(entity_proxy))
    end

    -- trivial getters
    for which in range(
        "hp_base",
        "attack",
        "defense",
        "speed",
        "attack_base",
        "defense_base",
        "speed_base",
        "name",
        "id",
        "n_move_slots",
        "n_equip_slots",
        "n_consumable_slots",
        "is_stunned"
    ) do
        --- @brief get_hp_base, get_attack, get_defense, get_speed, get_attack_base, get_defense_base, get_speed_base, get_name, get_id, get_n_move_slots, get_n_equip_slots, get_n_consumable_slots
        env["get_" .. which] = function(entity_proxy)
            bt.assert_args("get_" .. which, entity_proxy, bt.EntityProxy)
            local native = _get_native(entity_proxy)
            return native["get_" .. which](native)
        end
    end

    --- @brief
    function env.is_alive(entity_proxy)
        bt.assert_args("is_alive", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.ALIVE
    end

    --- @brief
    function env.is_knocked_out(entity_proxy)
        bt.assert_args("is_knocked_out", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.KNOCKED_OUT
    end

    --- @brief
    function env.is_dead(entity_proxy)
        bt.assert_args("is_dead", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.DEAD
    end

    env.ENTITY_STATE_ALIVE = bt.EntityState.ALIVE
    env.ENTITY_STATE_KNOCKED_OUT = bt.EntityState.KNOCKED_OUT
    env.ENTITY_STATE_DEAD = bt.EntityState.DEAD

    --- @brief
    function env.get_state(entity_proxy)
        bt.assert_args("get_state", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy))
    end

    --- @brief
    function env.deal_damage(entity_proxy, value)
        bt.assert_args("deal_damage",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        if value < 0 then
            env.heal(entity_proxy, value)
            return
        end

        -- TODO#
    end

    --- @brief
    function env.heal(entity_proxy, value)
        bt.assert_args("heal",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        if value < 0 then
            env.deal_damage(entity_proxy, value)
            return
        end

        -- TODO#
    end

    --- @brief
    function env.set_hp(entity_proxy, value)
        bt.assert_args("set_hp",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        value = clamp(value, 0, env.get_hp_base(entity_proxy))
        -- TODO#
    end

    --- @brief
    function env.knock_out(entity_proxy)
        bt.assert_args("knock_out", entity_proxy, bt.EntityProxy)
        -- TODO#
    end

    --- @brief
    function env.help_up(entity_proxy)
        bt.assert_args("help_up", entity_proxy, bt.EntityProxy)
        -- TODO#
    end

    --- @brief
    function env.kill(entity_proxy)
        bt.assert_args("kill", entity_proxy, bt.EntityProxy)
        -- TODO#
    end

    --- @brief
    function env.revive(entity_proxy)
        bt.assert_args("revive", entity_proxy, bt.EntityProxy)
        -- TODO#
    end

    --- @brief
    function env.spawn(entity_id)
        bt.assert_args("spawn", entity_id, bt.String)
        -- TODO#
    end

    --- @brief
    function env.switch(entity_proxy_a, entity_proxy_b)
        bt.assert_args("switch",
            entity_proxy_a, bt.EntityProxy,
            entity_proxy_b, bt.EntityProxy
        )
        -- TODO#
    end

    --- @brief
    function env.add_status(entity_proxy, status_proxy)
        bt.assert_args("add_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )

        -- fizzle if entity can't be statused
        if env.get_is_dead(entity_proxy) or env.get_is_knocked_out(entity_proxy) then return end

        -- on already present, invoke callback then fizzle
        local already_present = false
        for already in values(env.get_statuses(entity_proxy))  do
            if already == status_proxy then
                _try_invoke_status_callback("on_already_present", status, entity)
                return
            end
        end

        -- apply status
        local entity = _get_native(entity_proxy)
        local status = _get_native(status_proxy)
        local stun_before = _state:entity_get_is_stunned(entity)
        local will_stun = status:get_is_stun()
        _state:entity_add_status(entity, status)

        -- status animation
        local sprite = _scene._sprites[entity]
        local animation_id = status:get_animation_id()
        local animation = bt.Animation[animation_id]

        if animation == nil then
            rt.warning("In env.add_status: Status `" .. status:get_id() .. "`s animation id `" .. animation_id .. "` does not point to a valid animation, falling back on default animation.")
            animation = bt.Animation[rt.settings.battle.status.default_animation_id]
        end

        animation:signal_connect("start", function(_)
            sprite:add_status(status)
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _scene:_push_animation(animation)

        if stun_before == false and will_stun == true then
            _scene._push_animation(bt.Animation.STUN_GAINED(_scene, sprite))
        end

        -- callbacks
        _try_invoke_status_callback("on_gained", status_proxy, entity_proxy)

        _invoke_all_consumable_callbacks("on_status_gained", entity_proxy, status_proxy)
        _invoke_all_status_callbacks("on_status_gained", entity_proxy, status_proxy)
        _invoke_all_global_status_callbacks("on_status_gained", entity_proxy, status_proxy)
    end

    --- @brief
    function env.remove_status(entity_proxy, status_proxy)
        bt.assert_args("remove_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )
        -- TODO#
    end

    --- @brief
    function env.has_status(entity_proxy, status_proxy)
        bt.assert_args("has_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )

        return _state:entity_has_status(_get_native(entity_proxy), _get_native(status_proxy))
    end

    --- @brief
    --- @param entity_proxy bt.EntityProxy
    --- @return Table<bt.StatusProxy>
    function env.get_statuses(entity_proxy)
        bt.assert_args("get_statuses", entity_proxy, bt.EntityProxy)
        local out = {}
        for status in values(_state:entity_list_statuses(_get_native(entity_proxy))) do
            table.insert(out, bt.create_status_proxy(status))
        end
        return out
    end

    --- @brief
    function env.get_status_n_turns_elapsed(entity_proxy, status_proxy)
        bt.assert_args("has_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )
        return _state:entity_get_status_n_turns_elapsed(_get_native(entity_proxy), _get_native(status_proxy))
    end

    --- @brief
    function env.set_status_n_turns_elapsed(entity_proxy, status_proxy, turns)
        bt.assert_args("set_status_n_turns_elapsed",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy,
            turns, bt.Number
        )

        --TODO#
    end

    --- @brief
    function env.add_global_status(global_status_proxy)
        bt.assert_args("add_global_status", global_status_proxy, bt.GlobalStatusProxy)
        -- TODO#
    end

    --- @brief
    function env.remove_global_status(global_status_proxy)
        bt.assert_args("remove_global_status", global_status_proxy, bt.GlobalStatusProxy)
        -- TODO#
    end

    --- @brief
    function env.has_global_status(global_status_proxy)
        bt.assert_args("remove_global_status", global_status_proxy, bt.GlobalStatusProxy)
        return _state:has_global_status(_get_native(global_status_proxy))
    end

    --- @brief
    function env.get_global_statuses()
        local out = {}
        for status in values(self._state:list_global_statuses()) do
            table.insert(out, bt.create_global_status_proxy(status))
        end
        return out
    end

    --- @brief
    function env.get_global_status_n_turns_elapsed(global_status)
        bt.assert_args("get_global_status_n_turns_elapsed", global_status, bt.GlobalStatusProxy)
        return _state:get_global_status_n_turns_elapsed(global_status)
    end

    --- @brief
    function env.set_global_status_n_turns_elapsed(global_status)
        bt.assert_args("set_global_status_n_turns_elapsed", global_status, bt.GlobalStatusProxy)
        -- TODO#
    end

    --- @brief
    function env.add_consumable(entity_proxy, consumable_proxy)
        bt.assert_args("add_consumable",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )
        -- TODO#
    end

    --- @brief
    function env.get_consumables(entity_proxy)
        bt.assert_args("get_consumables", entity_proxy, bt.EntityProxy)
        local out = {}
        for consumable in values(_state:entity_list_consumables(_get_native(entity_proxy))) do
            table.insert(out, bt.get_consumable_proxy(consumable))
        end
        return out
    end

    --- @brief
    function env.get_consumable(entity_proxy, slot_i)
        bt.assert_args("get_consumable",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local n_slots = _get_native(entity_proxy):get_n_consumable_slots()
        if slot_i > n_slots then
            rt.warning("In env.get_consumable: Consumable slot `" .. slot_i .. "` is out of bounds for entity `" .. env.get_id(entity_proxy) .. "`, which has `" .. n_slots .. "` consumable slots")
            return nil
        else
            return _state:entity_get_equip(_get_native(entity_proxy), slot_i)
        end

        return _state:entity_get_consumable(entity_proxy, slot_i)
    end

    --- @brief
    function env.get_n_consumable_slots(entity_proxy)
        bt.assert_args("get_n_consumable_slots", entity_proxy, bt.EntityProxy)
        return _get_native(entity_proxy):get_n_consumable_slots()
    end

    --- @brief
    function env.remove_consumable(entity_proxy, consumable_proxy)
        bt.assert_args("remove_consumable",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )
        -- TODO# disable
    end

    --- @brief
    function env.has_consumable(entity_proxy, consumable_proxy)
        bt.assert_args("has_consumable",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        return _state:entity_has_consumable(_get_native(entity_proxy), _get_native(consumable_proxy)) and
            _state:entity_get_consumable_is_disabled(_get_native(entity_proxy), _get_native(consumable_proxy))
    end

    --- @brief
    function env.consume(entity_proxy, consumable_proxy)
        bt.assert_args("consume",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        -- TODO#
    end

    --- @brief
    function env.get_consumable_max_n_uses(consumable_proxy)
        bt.assert_args("get_consumable_max_n_uses",
            consumable_proxy, bt.ConsumableProxy
        )
        return _get_native(consumable_proxy):get_max_n_uses()
    end

    --- @brief
    function env.get_consumable_n_uses_left(entity_proxy, consumable_proxy)
        bt.assert_args("get_consumable_n_uses_left",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )
        return _get_native(consumable_proxy):get_max_n_uses() - _state:entity_get_consumable_n_used(_get_native(entity_proxy), _get_native(consumable_proxy))
    end

    --- @brief
    function env.get_consumable_n_used(entity_proxy, consumable_proxy)
        bt.assert_args("get_consumable_n_used",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )
        return _state:entity_get_consumable_n_used(_get_native(entity_proxy), _get_native(consumable_proxy))
    end

    --- @brief
    function env.add_move(entity_proxy, consumable_proxy)
        bt.assert_args("add_move",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.MoveProxy
        )

        -- TODO#
    end

    --- @brief
    function env.remove_move(entity_proxy, move_proxy)
        bt.assert_args("remove_move",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )
        -- TODO# do not disable
    end

    --- @brief
    function env.get_moves(entity_proxy)
        bt.assert_args("get_moves", entity_proxy, bt.Entity)
        local out = {}
        for move in values(self._state:entity_list_moves(entity_proxy)) do
            table.insert(out, bt.create_move_proxy(move))
        end
        return out
    end

    --- @brief
    function env.get_move(entity_proxy, slot_i)
        bt.assert_args("get_move",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )
        return _state:entity_get_move(_get_native(entity_proxy), slot_i)
    end

    --- @brief
    function env.set_move_is_disabled(entity_proxy, move_proxy)
        bt.assert_args("remove_move",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )

        -- TODO
    end

    --- @brief
    function env.get_move_is_disabled(entity_proxy, move_proxy)
        bt.assert_args("remove_move",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )

        return _state:entity_get_move_is_disabled(_get_native(entity_proxy), _get_native(move_proxy))
    end

    --- @brief
    function env.get_move_max_n_uses(move_proxy)
        bt.assert_args("get_move_max_n_uses", move_proxy, bt.MoveProxy)
        return _get_native(move_proxy):get_max_n_uses()
    end

    --- @brief
    function env.get_move_n_uses_left(entity_proxy, move_proxy)
        bt.assert_args("get_move_n_uses_left",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )
        local n_used = _state:entity_get_move_n_used(_get_native(entity_proxy), _get_native(move_proxy))
        return _get_native(move_proxy):get_max_n_uses() - n_used
    end
    
    --- @brief
    function env.get_move_n_used(entity_proxy, move_proxy)
        bt.assert_args("get_move_n_uses_left",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )
        return _state:entity_get_move_n_used(_get_native(entity_proxy), _get_native(move_proxy))
    end
    
    --- @brief
    function env.set_move_n_uses_left(entity_proxy, move_proxy, n)
        bt.assert_args("set_move_n_uses_left",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy,
            n, bt.Number
        )
        
        -- TODO#
    end
    
    --- @brief
    function env.add_equip(entity_proxy, equip_proxy)
        bt.assert_args("add_equip",
            entity_proxy, bt.EntityProxy,
            equip_proxy, bt.EquipProxy
        )
        
        -- TODO#
    end
    
    
    --- @brief
    function env.remove_equip(entity_proxy, equip_proxy)
        bt.assert_args("remove_equip",
            entity_proxy, bt.EntityProxy,
            equip_proxy, bt.EquipProxy
        )
        -- TODO#
    end
    
    --- @brief
    function env.has_equip(entity_proxy, equip_proxy)
        bt.assert_args("remove_equip",
            entity_proxy, bt.EntityProxy,
            equip_proxy, bt.EquipProxy
        )
        return _state:entity_has_equip(_get_native(entity_proxy), _get_native(equip_proxy))
    end
    
    --- @brief
    function env.get_equips(entity_proxy)
        bt.assert_args("get_equips", entity_proxy, bt.EntityProxy)
        local out = {}
        for equip in values(_state:entity_list_equips()) do
            table.insert(out, bt.get_equip_proxy(equip))
        end
        return out
    end

    --- @brief
    function env.get_equip(entity_proxy, slot_i)
        bt.assert_args("get_equip",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )
        local n_slots = _get_native(entity_proxy):get_n_equip_slots()
        if slot_i > n_slots then
            rt.warning("In env.get_equip: Equip slot `" .. slot_i .. "` is out of bounds for entity `" .. env.get_id(entity_proxy) .. "`, which has `" .. n_slots .. "` equip slots")
            return nil
        else
            return _state:entity_get_equip(_get_native(entity_proxy), slot_i)
        end
    end

    --- @brief
    function env.get_n_equip_slots(entity_proxy)
        bt.assert_args("get_n_equip_slots", entity_proxy, bt.EntityProxy)
        return _get_native(entity_proxy):get_n_equip_slots()
    end

    --- @brief
    function env.quicksave()
        -- TODO
    end


    --- @brief
    function env.quickload()
        -- TODO
    end

    --- @brief
    function env.message(str, ...)
        local n = select("#", ...)
        local out = {str}
        for i = 1, n do
            table.insert(out, select(i, ...))
        end
        local msg = table.concat(out)
        _scene:_push_animation(bt.Animation.MESSAGE(_scene._text_box, msg))
    end

    return meta.as_immutable(env)
end

--- @brief
function bt.BattleScene:apply_end_turn()
    -- TODO: lower flag and value caches of entities
end
