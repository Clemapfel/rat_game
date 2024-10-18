rt.settings.battle.simulation = {
    illegal_action_is_error = true
}

bt.error_function = ternary(rt.settings.battle.simulation.illegal_action_is_error, rt.error, rt.warning)

--- @brief adds proxy table such that original table is read-only
function meta.as_immutable(t)
    return setmetatable({}, {
        __index = function(_, key)
            local out = t[key]
            if out == nil then
                bt.error_function("trying to access `" .. key .. "` of `" .. tostring(t) .. "`, but this value does not exist")
            end
            return out
        end,

        __newindex = function(_, key, value)
            bt.error_function("trying to modify table `" .. tostring(t) .. "`, but it is immutable")
        end,

        __metatable = nil
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

    --- @brief create_entity_proxy, create_move_proxy, create_status_proxy, create_global_status_proxy, create_equip_proxy, create_consumable_proxy
    bt["create_" .. name .. "_proxy"] = function(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, type)
        local out = setmetatable({}, {
            _type = proxy,
            _native = native,
            _scene = scene,
            _state = scene._state,
            _values = {}, -- Table<String, { value::Number, per_turn_offset::Number }>

            __tostring = function(self)
                return "<" .. meta.get_typename(type) .. " #" .. meta.hash(native) .. ">"
            end,

            __eq = function(self, other)
                local metatable = getmetatable(other)
                if metatable == nil then return false end
                local other_native = metatable._native
                if other_native == nil then return false end
                return native:get_id() == other_native:get_id()
            end
        })
        meta.as_immutable(out)
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
    
    local function _initialize_non_entities(prefix, path, true_type_ctor, proxy_ctor)
        for _, name in pairs(love.filesystem.getDirectoryItems(path)) do
            if string.match(name, "%.lua$") ~= nil then
                local id = string.gsub(name, "%.lua$", "")
                env[prefix .. "_" .. id] = proxy_ctor(_scene, true_type_ctor(id))
            end
        end
    end

    -- consumables as CONSUMABLE_* global
    _initialize_non_entities(
        "CONSUMABLE",
        rt.settings.battle.consumable.config_path,
        bt.Consumable,
        bt.create_consumable_proxy
    )

    -- equips as EQUIP_* global
    _initialize_non_entities(
        "EQUIP",
        rt.settings.battle.equip.config_path,
        bt.Equip,
        bt.create_equip_proxy
    )

    -- moves as MOVE_* global
    _initialize_non_entities(
        "MOVE",
        rt.settings.battle.move.config_path,
        bt.Move,
        bt.create_move_proxy
    )

    -- global status as GLOBAL_STATUS_* global
    _initialize_non_entities(
        "GLOBAL_STATUS",
        rt.settings.battle.global_status.config_path,
        bt.GlobalStatus,
        bt.create_global_status_proxy
    )

    -- status as STATUS_* global
    _initialize_non_entities(
        "STATUS",
        rt.settings.battle.status.config_path,
        bt.Status,
        bt.create_status_proxy
    )

    --- @brief add numerical value to entity cache, is reduced by `per_turn_offset` at end of turn
    --- @param entity bt.EntityProxy
    --- @param name String
    --- @param initial_value Number
    --- @param per_turn_offset Number (optional)
    function env.set_value(entity, name, initial_value, per_turn_offset)
        if per_turn_offset == nil then per_turn_offset = 0 end
        bt.assert_args("add_value",
            entity, bt.EntityProxy,
            name, bt.String,
            initial_value, bt.Number,
            per_turn_offset, bt.Number
        )

        local values = getmetatable(entity)._values
        values[name] = {
            value = initial_value,
            per_turn_offset = per_turn_offset
        } -- intentional override
    end

    --- @brief get value
    --- @param entity bt.EntityProxy
    --- @param name String
    function env.get_value(entity, name)
        bt.assert_args("get_value",
            entity, bt.EntityProxy,
            name, bt.String
        )

        local entry = getmetatable(entity)._values[name]
        if entry == nil then
            return nil
        else
            return entry.value
        end
    end

    --- @brief get value
    --- @param entity bt.EntityProxy
    --- @param name String
    function env.has_value(entity, name)
        bt.assert_args("has_value",
            entity, bt.EntityProxy,
            name, bt.String
        )

        return getmetatable(entity)._values[name] ~= nil
    end

    --- @brief
    function env.get_hp(entity)
        bt.assert_args("get_hp", entity, bt.EntityProxy)
        return _state:entity_get_hp(getmetatable(entity)._native)
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
        "n_move_slots",
        "n_equip_slots",
        "n_consumable_slots"
    ) do
        --- @brief get_attack, get_defense, get_speed, get_attack_base, get_defense_base, get_speed_base, get_name, get_id, get_n_move_slots, get_n_equip_slots, get_n_consumable_slots
        env["get_" .. which] = function(entity)
            bt.assert_args("get_" .. which, entity, bt.EntityProxy)
            local native = getmetatable(entity)._native
            return native["get_" .. which](native)
        end
    end

    --- @brief
    function env.is_alive(entity)
        bt.assert_args("is_alive", entity, bt.EntityProxy)
        return _state:entity_get_state(getmetatable(entity)._native) == bt.EntityState.ALIVE
    end

    --- @brief
    function env.is_knocked_out(entity)
        bt.assert_args("is_knocked_out", entity, bt.EntityProxy)
        return _state:entity_get_state(getmetatable(entity)._native) == bt.EntityState.KNOCKED_OUT
    end

    --- @brief
    function env.is_dead(entity)
        bt.assert_args("is_dead", entity, bt.EntityProxy)
        return _state:entity_get_state(getmetatable(entity)._native) == bt.EntityState.DEAD
    end

    env.ENTITY_STATE_ALIVE = bt.EntityState.ALIVE
    env.ENTITY_STATE_KNOCKED_OUT = bt.EntityState.KNOCKED_OUT
    env.ENTITY_STATE_DEAD = bt.EntityState.DEAD

    --- @brief
    function env.get_state(entity)
        bt.assert_args("get_state", entity, bt.EntityProxy)
        return _state:entity_get_state(getmetatable(entity)._native)
    end

    dbg(env)
    return meta.as_immutable(env)
end

--- @brief
function bt.BattleScene:invoke(f, env)
    debug.setfenv(f, env)
    f()
end

--- @brief
function bt.BattleScene:apply_end_turn()
    -- TODO: lower flag and value caches of entities
end
