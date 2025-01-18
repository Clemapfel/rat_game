rt.settings.battle.simulation = {
    illegal_action_is_error = true
}

-- ### PROXIES ###

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

--- @type bt.Table
bt.Table = "Table"

do
    local _eq = function(self, other) return self.id == other.id end

    local _index = function(self, key)
        if key == "id" then return getmetatable(self)._native:get_id() end
        bt.error_function("In bt.EntityProxy.__index: trying to access proxy directly, but it can only be accessed with outer functions, use `get_*` instead")
        return nil
    end

    local _newindex = function(self, key)
        bt.error_function("In bt.EntityProxy.__newindex: trying to modify proxy directly, but it can only be accessed with outer functions, use `set_*` instead")
    end

    local _concat = function(self, other)
        local self_native = getmetatable(self)._native
        local other_native = getmetatable(other)
        if other_native ~= nil then
            other_native = other_native._native
            if other_native ~= nil then
                return bt.format_name(self_native) .. bt.format_name(other_native)
            end
        end
        return bt.format_name(self_native) .. other
    end

    local _tostring = function(self)
        return bt.format_name(getmetatable(self)._native)
    end

    local _create_proxy_metatable = function(type, scene)
        return {
            _type = type,
            _scene = scene,
            _native = nil,
            __eq = _eq,
            __tostring = _tostring,
            __index = _index,
            __newindex = _newindex,
            __concat = _concat,
            __tostring = _tostring
        }
    end

    local _entity_proxy_atlas = meta.make_weak({})

    --- @brief
    --- @param scene bt.BattleScene
    --- @param entity bt.Entity
    function bt.create_entity_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.Entity)

        local id = native:get_id()
        if _entity_proxy_atlas[id] ~= nil then
            return _entity_proxy_atlas[id]
        end

        local metatable = _create_proxy_metatable(bt.EntityProxy, scene, native)
        metatable._native = native
        local out = setmetatable({}, metatable)
        _entity_proxy_atlas[id] = out
        return out
    end

    local _global_status_proxy_atlas = meta.make_weak({})

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.GlobalStatusConfig
    function bt.create_global_status_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.GlobalStatusConfig)

        local id = native:get_id()
        if _global_status_proxy_atlas[id] ~= nil then
            return _global_status_proxy_atlas[id]
        end

        local metatable = _create_proxy_metatable(bt.GlobalStatusProxy, scene, native)
        metatable._native = native
        local out = setmetatable({}, metatable)
        _global_status_proxy_atlas[id] = out
        return out
    end

    local _status_proxy_atlas = meta.make_weak({})

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.StatusConfig
    function bt.create_status_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.StatusConfig)

        local id = native:get_id()
        if _status_proxy_atlas[id] ~= nil then
            return _status_proxy_atlas[id]
        end

        local metatable = _create_proxy_metatable(bt.StatusProxy, scene, native)
        metatable._native = native
        local out = setmetatable({}, metatable)
        _status_proxy_atlas[id] = out
        return out
    end

    local _consumable_proxy_atlas = meta.make_weak({})

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_consumable_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.ConsumableConfig)

        local id = native:get_id()
        if _consumable_proxy_atlas[id] ~= nil then
            return _consumable_proxy_atlas[id]
        end

        local metatable = _create_proxy_metatable(bt.ConsumableProxy, scene)
        metatable._native = native
        local out = setmetatable({}, metatable)
        _consumable_proxy_atlas[id] = out
        return out
    end

    local _equip_proxy_atlas = meta.make_weak({})

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_equip_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.EquipConfig)

        local id = native:get_id()
        if _equip_proxy_atlas[id] ~= nil then
            return _equip_proxy_atlas[id]
        end

        local metatable = _create_proxy_metatable(bt.EquipProxy, scene)
        metatable._native = native
        local out = setmetatable({}, metatable)
        _equip_proxy_atlas[id] = out
        return out
    end

    local _move_proxy_atlas = meta.make_weak({})

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_move_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.MoveConfig)

        local id = native:get_id()
        if _move_proxy_atlas[id] ~= nil then
            return _move_proxy_atlas[id]
        end

        local metatable = _create_proxy_metatable(bt.MoveProxy, scene)
        metatable._native = native
        local out = setmetatable({}, metatable)
        _move_proxy_atlas[id] = out
        return out
    end
end

--- ### ARG ASSERTION ###

bt.error_function = ternary(rt.settings.battle.simulation.illegal_action_is_error, rt.error, rt.warning)

for name_type_proxy in range(
    {"entity", bt.Entity, bt.EntityProxy},
    {"move", bt.MoveConfig, bt.MoveProxy},
    {"equip", bt.EquipConfig, bt.EquipProxy},
    {"status", bt.StatusConfig, bt.StatusProxy},
    {"global_status", bt.GlobalStatusConfig, bt.GlobalStatusProxy},
    {"consumable", bt.ConsumableConfig, bt.ConsumableProxy}
) do
    local name, type, proxy = table.unpack(name_type_proxy)
    --- @brief bt.is_entity_proxy, bt.is_move_proxy, bt.is_equip_proxy, bt.is_status_proxy, bt.is_global_status_proxy, bt.is_consumable_proxy,
    meta["is_" .. name .. "_proxy"] = function(x)
        if _G.type(x) ~= "table" then return false end
        local metatable = getmetatable(x)
        return metatable._type == proxy and meta.isa(metatable._native, type)
    end
end

for which_type in range(
    {"is_number", bt.Number},
    {"is_string", bt.String},
    {"is_boolean", bt.Boolean},
    {"is_table", bt.Table},
    {"is_entity_proxy", bt.EntityProxy},
    {"is_move_proxy", bt.MoveProxy},
    {"is_status_proxy", bt.StatusProxy},
    {"is_global_status_proxy", bt.GlobalStatusProxy},
    {"is_consumable_proxy", bt.ConsumableProxy},
    {"is_equip_proxy", bt.EquipProxy}
) do
    local which, type = table.unpack(which_type)

    --- @brief bt.assert_is_number, bt.assert_is_string, bt.assert_is_boolean, bt.assert_is_table, bt.assert_is_entity_proxy, bt.assert_is_status_proxy, bt.assert_is_global_status_proxy, bt.assert_is_consumable_proxy
    bt["assert_" .. which] = function(function_name, x, arg_i)
        if not meta[which](x) then
            local true_type = getmetatable(x)
            if true_type == nil then true_type = meta.typeof(x) else true_type = true_type._type end
            bt.error_function("In " .. function_name .. ": Wrong argument #" .. arg_i .. ", expected `" .. type .. "`, got `" .. true_type .. "`")
        end
    end
end

--- @brief
function bt.assert_is_primitive(scope, x, arg_i)
    if getmetatable(x) ~= nil or not (type(x) == "nil" or type(x) == "string" or type(x) == "number") then
        bt.error_function("In " .. scope .. ": argument #" .. arg_i .. " is not a string, number, or nil")
    end
end

do
    local _type_to_function = {
        [bt.Number] = bt.assert_is_number,
        [bt.String] = bt.assert_is_string,
        [bt.Boolean] = bt.assert_is_boolean,
        [bt.Table] = bt.assert_is_table,
        [bt.EntityProxy] = bt.assert_is_entity_proxy,
        [bt.MoveProxy] = bt.assert_is_move_proxy,
        [bt.StatusProxy] = bt.assert_is_status_proxy,
        [bt.GlobalStatusProxy] = bt.assert_is_global_status_proxy,
        [bt.ConsumableProxy] = bt.assert_is_consumable_proxy,
        [bt.EquipProxy] = bt.assert_is_equip_proxy
    }

    --- @brief
    --- @param scope
    function bt.assert_args(scope, ...)
        meta.assert_string(scope)
        local n_args = select("#", ...)
        local arg_i = 1
        for i = 1, n_args, 2 do
            local arg = select(i, ...)
            local type = select(i+1, ...)
            local assert_f = _type_to_function[type]

            if assert_f == nil then
                bt.error_function("In bt.assert_args: unhandled type `" .. type .. "`")
            end

            assert_f(scope, arg, arg_i)
            arg_i = arg_i + 1
        end
    end
end

--- ### SIMULATION ###

function bt.BattleScene:create_simulation_environment()
    local _scene = self
    local _state = self._state
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

    local enable_console_output = true
    env["println"] = function(...)
        if enable_console_output then println(...) end
    end

    env["print"] = function(...)
        if enable_console_output then print(...) end
    end

    env["dbg"] = function(...)
        if enable_console_output then dbg(...) end
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

    -- debug assertions
    for metas in range(
        "is_number",
        "is_table",
        "is_string",
        "is_boolean",
        "is_nil"
    ) do
        env[metas] = function(x)
            return meta[metas](x)
        end
    end

    for name_type in range(
        {"entity_proxy", bt.EntityProxy},
        {"move_proxy", bt.MoveProxy},
        {"status_proxy", bt.StatusProxy},
        {"global_status_proxy", bt.GlobalStatusProxy},
        {"consumable_proxy", bt.ConsumableProxy},
        {"equip_proxy", bt.EquipProxy}
    ) do
        local name, type = table.unpack(name_type)
        env["is_" .. name] = function(x)
            if meta.is_table(x) then
                local metatable = getmetatable(x)
                if metatable == nil then
                    return metatable._type == type
                end
            else return false end
        end

        env["assert_is_" .. name] = function(x)
            if meta.is_table(x) then
                local metatable = getmetatable(x)
                if metatable ~= nil then
                    if metatable._type == type then
                        return
                    else
                        bt.error_function("In assert_is_" .. name .. ": excpected `" .. type .. "`, got `" .. metatable._type .. "`")
                    end
                end
            end
            bt.error_function("In assert_is_" .. name .. ": excpected `" .. type .. "`, got `" .. meta.typeof(x) .. "`")
        end
    end

    -- bind IDs of immutables to globals, used by add_status, spawn, etc.

    local entity_prefix = "ENTITY"
    local consumable_prefix = "CONSUMABLE"
    local equip_prefix = "EQUIP"
    local move_prefix = "MOVE"
    local global_status_prefix = "GLOBAL_STATUS"
    local status_prefix = "STATUS"

    for prefix_path_type_proxy in range(
        {consumable_prefix, rt.settings.battle.consumable.config_path, bt.ConsumableConfig, bt.create_consumable_proxy},
        {equip_prefix, rt.settings.battle.equip.config_path, bt.EquipConfig, bt.create_equip_proxy},
        {move_prefix, rt.settings.battle.move.config_path, bt.MoveConfig, bt.create_move_proxy},
        {global_status_prefix, rt.settings.battle.global_status.config_path, bt.GlobalStatusConfig, bt.create_global_status_proxy},
        {status_prefix, rt.settings.battle.status.config_path, bt.StatusConfig, bt.create_status_proxy}
    ) do
        local prefix, path, type_f, proxy_f = table.unpack(prefix_path_type_proxy)
        for _, name in pairs(love.filesystem.getDirectoryItems(path)) do
            if string.match(name, "%.lua$") ~= nil then
                local id = string.gsub(name, "%.lua$", "")
                env[prefix .. "_" .. id] = proxy_f(_scene, type_f(id))
            end
        end
    end

    do -- for entities, only store id
        for _, name in pairs(love.filesystem.getDirectoryItems(rt.settings.battle.entity.config_path)) do
            if string.match(name, "%.lua$") ~= nil then
                local id = string.gsub(name, "%.lua$", "")
                env[entity_prefix .. "_" .. id] = id
            end
        end
    end

    local _get_native = function(x) return getmetatable(x)._native end

    local _assert_id_exists = function(scope, id)
        meta.assert_string(scope, id)
        local out = env[id]
        if out == nil or not meta.is_string(out) then
            bt.error_function("In env." .. scope .. ": no object with id `" .. id .. "` exists")
        end
    end

    -- keep track of currently invoking entity

    local _current_move_user_stack = {} -- Table<Union<Nil, EntityProxy>>
    local _push_current_move_user = function(entity_proxy)
        if entity_proxy ~= nil then bt.assert_is_entity_proxy(entity_proxy) end
        table.insert(_current_move_user_stack, 1, entity_proxy)
    end

    local _pop_current_move_user = function()
        local current = _current_move_user_stack[1]
        table.remove(_current_move_user_stack, 1)
        return current
    end

    local _get_current_move_user = function()
        return _current_move_user_stack[1]
    end

    -- manage running multiple animations at once by opening / closing nodes

    local _animation_should_open_new_node = true
    local _new_animation_node = function()
        _animation_should_open_new_node = true
    end

    local _queue_animation = function(animation)
        meta.assert_isa(animation, bt.Animation)
        if _animation_should_open_new_node == true then
            _scene._animation_queue:push(animation)
            _animation_should_open_new_node = false
        else
            _scene._animation_queue:append(animation)
        end
    end

    -- callback invocation

    local _invoke = function(f, ...)
        debug.setfenv(f, env)
        return f(...)
    end

    local _try_invoke_status_callback = function(callback_id, status_proxy, entity_proxy, ...)
        bt.assert_args("_try_invoke_status_callback",
            callback_id, bt.String,
            status_proxy, bt.StatusProxy,
            entity_proxy, bt.EntityProxy
        )

        local status = _get_native(status_proxy)
        if status[callback_id] == nil or
            not env.has_status(entity_proxy, status_proxy) or
            env.get_is_dead(entity_proxy)
        then
            return
        end

        _queue_animation(bt.Animation.STATUS_APPLIED(
            _scene, status, _get_native(entity_proxy),
            rt.Translation.battle.message.status_applied_f(entity_proxy, status_proxy)
        ))

        _push_current_move_user(nil)
        _invoke(status[callback_id], status_proxy, entity_proxy, ...)
        _pop_current_move_user()
    end

    local _try_invoke_consumable_callback = function(callback_id, consumable_proxy, holder_proxy, ...)
        bt.assert_args("_try_invoke_consumable_callback",
            callback_id, bt.String,
            consumable_proxy, bt.ConsumableProxy,
            holder_proxy, bt.EntityProxy
        )

        local consumable = _get_native(consumable_proxy)
        if consumable[callback_id] == nil or
            not env.has_consumable(holder_proxy, consumable_proxy) or
            env.get_is_dead(holder_proxy)
        then
            return
        end

        local entity = _get_native(holder_proxy)
        local slot_i = _state:entity_get_consumable_slot_i(entity, consumable)
        if _state:entity_get_consumable_is_disabled(entity, slot_i) then
            return
        end

        _queue_animation(bt.Animation.CONSUMABLE_APPLIED(
            _scene, slot_i, entity,
            rt.Translation.battle.message.consumable_applied_f(holder_proxy, consumable_proxy)
        ))

        _push_current_move_user(nil)
        _invoke(consumable[callback_id], consumable_proxy, holder_proxy, ...)
        _pop_current_move_user()
    end

    local _try_invoke_global_status_callback = function(callback_id, global_status_proxy, ...)
        bt.assert_args("_try_invoke_global_status_callback",
            callback_id, bt.String,
            global_status_proxy, bt.GlobalStatusProxy
        )

        local global_status = _get_native(global_status_proxy)
        if global_status[callback_id] == nil or
            not env.has_global_status(global_status_proxy)
        then
            return
        end

        _queue_animation(bt.Animation.GLOBAL_STATUS_APPLIED(
            _scene, global_status,
            rt.Translation.battle.message.global_status_applied_f(global_status_proxy)
        ))

        _push_current_move_user(nil)
        _invoke(global_status[callback_id], global_status_proxy, ...)
        _pop_current_move_user()
    end

    local _try_invoke_equip_callback = function(callback_id, equip_proxy, holder_proxy, ...)
        bt.assert_args("_try_invoke_equip_callback",
            callback_id, bt.String,
            equip_proxy, bt.EquipProxy,
            holder_proxy, bt.EntityProxy
        )

        local equip = _get_native(equip_proxy)
        if equip[callback_id] == nil or
            not env.has_equip(holder_proxy, equip_proxy) or
            env.get_is_dead(holder_proxy)
        then
            return
        end

        _queue_animation(bt.Animation.EQUIP_APPLIED(
            _scene, equip, _get_native(holder_proxy)),
            rt.Translation.battle.message.equip_applied_f(holder_proxy, equip_proxy)
        )

        _push_current_move_user(nil)
        _invoke(equip[callback_id], equip_proxy, holder_proxy, ...)
        _pop_current_move_user()
    end

    -- common
    function env.get_name(object)
        if not (
            meta.is_entity_proxy(object) or
                meta.is_move_proxy(object) or
                meta.is_status_proxy(object) or
                meta.is_global_status_proxy(object) or
                meta.is_equip_proxy(object) or
                meta.is_consumable_proxy(object))
        then
            bt.error_function("In env.get_name: objects of type `" .. meta.typeof(object) .. "` do not have a name")
            return nil
        end
        return bt.format_name(_get_native(object))
    end

    function env.get_id(object)
        if not (
            meta.is_entity_proxy(object) or
                meta.is_move_proxy(object) or
                meta.is_status_proxy(object) or
                meta.is_global_status_proxy(object) or
                meta.is_equip_proxy(object) or
                meta.is_consumable_proxy(object))
        then
            bt.error_function("In env.get_id: objects of type `" .. meta.typeof(object) .. "` do not have an ID")
            return nil
        end

        return _get_native(object):get_id()
    end

    function env.hash(object)
        return meta.hash(_get_native(object))
    end

    env.message = function(...)
        _queue_animation(bt.Animation.MESSAGE(_scene, string.concat(" ", ...)))
    end

    env.get_turn_i = function()
        return _state:get_turn_i()
    end

    -- local storage

    function env.entity_set_value(entity_proxy, name, new_value)
        bt.assert_args("entity_set_value",
            entity_proxy, bt.EntityProxy,
            name, bt.String
        )
        bt.assert_is_primitive("entity_set_value", new_value, 3)

        _state:entity_set_storage_value(_get_native(entity_proxy), name, new_value)
    end

    function env.entity_get_value(entity_proxy, name)
        bt.assert_args("entity_get_value",
            entity_proxy, bt.EntityProxy,
            name, bt.String
        )
        return _state:entity_get_storage_value(_get_native(entity_proxy), name)
    end

    function env.global_status_set_value(global_status_proxy, name, new_value)
        bt.assert_args("global_status_set_value",
            global_status_proxy, bt.GlobalStatusProxy,
            name, bt.String
        )
        bt.assert_is_primitive("global_status_set_value", new_value, 3)
        if not env.has_global_status(global_status_proxy) then
            bt.error_function("In global_status_set_value: global status `" .. env.get_id(global_status_proxy) .. "` is not present")
            return
        end

        _state:set_global_status_storage_value(_get_native(global_status_proxy), name, new_value)
    end

    function env.global_status_get_value(global_status_proxy, name)
        bt.assert_args("global_status_set_value",
            global_status_proxy, bt.GlobalStatusProxy,
            name, bt.String
        )

        if not env.has_global_status(global_status_proxy) then
            bt.error_function("In global_status_get_value: global status `" .. env.get_id(global_status_proxy) .. "` is not present")
            return nil
        end

        return _state:get_global_status_storage_value(_get_native(global_status_proxy), name)
    end

    -- moves

    env.get_move_slot_i = function(entity_proxy, move_proxy)
        bt.assert_args("get_move_slot_i",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )

        local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
        if _state:entity_has_move(entity, move) == false then
            bt.error_function("In get_move_slot_i: entity `" .. entity:get_id() .. "` does not have move `" .. move:get_id() .. "`")
            return 0
        else
            return _state:entity_get_move_slot_i(entity, move)
        end
    end

    env.get_move_slot_n_used = function(entity_proxy, slot_i)
        bt.assert_args("get_move_slot_n_used",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local move = _state:entity_get_move(entity, slot_i)
        if move == nil then
            bt.error_function("In get_move_slot_n_used: entity `" .. entity:get_id() .. "` has no move in slot `" .. slot_i .. "`")
            return 0
        end

        return _state:entity_get_move_n_used(entity, slot_i)
    end

    env.get_move_n_used = function(entity_proxy, move_proxy)
        bt.assert_args("get_move_n_used",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )

        local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
        local slot_i = _state:entity_get_move_slot_i(entity, move)
        if slot_i == nil then
            bt.error_function("In get_move_n_used: entity `" .. entity:get_id() .. "")
            return 0
        end
        return env.get_move_slot_n_used(entity_proxy, slot_i)
    end

    env.get_move_max_n_uses = function(move_proxy)
        bt.assert_args("get_move_max_n_uses", move_proxy, bt.MoveProxy)
        return _get_native(move_proxy):get_max_n_uses()
    end

    env.get_move_slot_n_uses_left = function(entity_proxy, slot_i)
        bt.assert_args("get_move_slot_n_uses_left",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local move = _state:entity_get_move(entity, slot_i)
        if move == nil then
            bt.error_function("In get_move_slot_n_uses_left: entity `" .. entity:get_id() .. "` has no move in slot `" .. slot_i .. "`")
            return 0
        end

        return move:get_max_n_uses() - env.get_move_slot_n_used(entity_proxy, slot_i)
    end

    env.get_move_n_uses_left = function(entity_proxy, move_proxy)
        bt.assert_args("get_move_n_uses_left",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )

        local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
        local slot_i = _state:entity_get_move_slot_i(entity, move)
        if slot_i == nil then
            bt.error_function("In get_move_n_uses_left: entity `" .. entity:get_id() .. "` does not have move `" .. move:get_id() .. "` equipped")
            return 0
        end

        return env.get_move_slot_n_uses_left(entity_proxy, slot_i)
    end

    env.set_move_slot_n_uses_left = function(entity_proxy, slot_i, n_left)
        bt.assert_args("set_move_slot_n_uses_left",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number,
            n_left, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local move = _state:entity_get_move(entity, slot_i)
        if move == nil then
            bt.error_function("In set_move_slot_n_uses_left: entity `" .. entity:get_id() .. "` has no move in slot `" .. slot_i .. "`")
            return
        end

        if n_left < 0 then
            bt.error_function("In env.set_move_n_uses_left: for entity `" .. env.get_id(entity_proxy) .. "`, move `" .. move:get_id() .. "`: count `" .. n_left .. "` is negative, it should be 0 or higher")
            n_left = 0
        end

        if math.fmod(n_left, 1) ~= 0 then
            rt.warning("In env.set_move_n_uses_left: for entity `" .. env.get_id(entity_proxy) .. "`, move `" .. move:get_id() .. "`: count `" .. n_left .. "` is non-integer")
            n_left = math.ceil(n_left)
        end

        local max = move:get_max_n_uses()
        local n_used = max - n_left

        local before = _state:entity_get_move_n_used(entity, slot_i)
        _state:entity_set_move_n_used(entity, move, n_used)
        local after = _state:entity_get_move_n_used(entity, slot_i)

        local move_proxy = bt.create_move_proxy(_scene, move)
        if before < after then
            env.message(rt.Translation.battle.message.move_gained_pp_f(entity_proxy, move_proxy))
        elseif before > after then
            env.message(rt.Translation.battle.message.move_lost_pp_f(entity_proxy, move_proxy))
        end -- else, noop, for example if move has infinty PP
    end

    env.set_move_n_uses_left = function(entity_proxy, move_proxy, n_left)
        bt.assert_args("set_move_n_uses_left",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy,
            n_left, bt.Number
        )

        local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
        local slot_i = _state:entity_get_move_slot_i(entity, move)
        if slot_i == nil then
            bt.error_function("In set_move_n_uses_left: entity `" .. entity:get_id() .. "` does not have move `" .. move:get_id() .. "` equipped")
            return
        end
        env.set_move_slot_n_uses_left(entity_proxy, slot_i, n_left)
    end

    for which in range(
        "priority",
        "is_intrinsic",
        "can_target_multiple",
        "can_target_self",
        "can_target_ally"
    ) do
        local name = "get_move_" .. which
        --- @brief get_move_priority, get_move_is_intrinsict, get_move_can_target_multiple, get_move_can_target_ally
        env[name] = function(move_proxy)
            bt.assert_args(name, move_proxy, bt.MoveProxy)
            local move = _get_native(move_proxy)
            return move["get_" .. which](move)
        end
    end

    -- equip

    env.get_equip_count = function(entity_proxy, equip_proxy)
        bt.assert_args("get_equip_slot_i",
            entity_proxy, bt.EntityProxy,
            equip_proxy, bt.EquipProxy
        )

        return select("#", _state:entity_get_equip_slot_i(_get_native(entity_proxy), _get_native(equip_proxy)))
    end

    env.get_equip_slot_i = function(entity_proxy, equip_proxy)
        bt.assert_args("get_equip_slot_i",
            entity_proxy, bt.EntityProxy,
            equip_proxy, bt.EquipProxy
        )

        local entity, equip = _get_native(entity_proxy), _get_native(equip_proxy)
        if _state:entity_has_equip(entity, equip) == false then
            bt.error_function("In get_equip_slot_i: entity `" .. entity:get_id() .. "` does not have equip `" .. equip:get_id() .. "` equipped")
            return 0
        end
        return _state:entity_get_equip_slot_i(entity, equip)
    end

    for which in range(
        "hp_base_offset",
        "attack_base_offset",
        "defense_base_offset",
        "speed_base_offset",
        "hp_base_factor",
        "attack_base_factor",
        "defense_base_factor",
        "speed_base_factor"
    ) do
        local get_name = "get_equip_" .. which
        env[get_name] = function(equip_proxy)
            bt.assert_args(get_name, equip_proxy, bt.EquipProxy)
            local native = _get_native(equip_proxy)
            return native["get_" .. which](native)
        end
    end

    -- consumable

    env.get_consumable_max_n_uses = function(consumable_proxy)
        bt.assert_args("get_consumable_max_n_uses", consumable_proxy, bt.ConsumableProxy)
        return _get_native(consumable_proxy):get_max_n_uses()
    end

    env.get_consumable_count = function(entity_proxy, consumable_proxy)
        bt.assert_args("get_consumable_count",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )
        return select("#", _state:entity_get_consumable_slot_i(_get_native(entity_proxy), _get_native(consumable_proxy)))
    end

    env.get_consumable_slot_i = function(entity_proxy, consumable_proxy)
        bt.assert_args("get_consumable_slot_i",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        local entity, consumable = _get_native(entity_proxy), _get_native(consumable_proxy)
        if _state:entity_has_consumable(consumable_proxy) == false then
            bt.error_function("In get_consumable_slot_i: entity `" .. entity:get_id() .. "` does not have consumable `" .. consumable:get_id() .. "` equipped")
            return 0
        end

        return _state:entity_get_consumable_slot_i(entity, consumable)
    end

    env.get_consumable_slot_n_used = function(entity_proxy, slot_i)
        bt.assert_args("get_consumable_slot_n_used",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        if _state:entity_get_consumable(entity, slot_i) == nil then
            bt.error_function("In get_consumable_slot_n_used: entity `" .. entity:get_id() .. "` does not have consumable in slot `" .. slot_i .. "` equipped")
            return 0
        end

        return _state:entity_get_consumable_n_used(entity, slot_i)
    end

    env.get_consumable_n_used = function(entity_proxy, consumable_proxy)
        bt.assert_args("get_consumable_n_used",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        local entity, consumable = _get_native(entity_proxy), _get_native(consumable_proxy)
        if _state:entity_has_consumable(consumable_proxy) == false then
            bt.error_function("In get_consumable_n_used: entity `" .. entity:get_id() .. "` does not have consumable `" .. consumable:get_id() .. "` equipped")
            return 0
        end

        local slot_i = _state:entity_get_consumable_slot_i(entity, consumable)
        return env.get_consumable_slot_n_used(entity_proxy, slot_i)
    end

    env.get_consumable_slot_n_uses_left = function(entity_proxy, slot_i)
        bt.assert_args("get_consumable_slot_n_uses_left",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local consumable = _state:entity_get_consumable(entity, slot_i)
        if consumable == nil then
            bt.error_function("In get_consumable_slot_n_used: entity `" .. entity:get_id() .. "` does not have consumable in slot `" .. slot_i .. "` equipped")
            return 0
        end

        return consumable:get_max_n_uses() - _state:entity_get_consumable_n_used(entity, slot_i)
    end

    env.get_consumable_n_used = function(entity_proxy, consumable_proxy)
        bt.assert_args("get_consumable_n_used",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        local entity, consumable = _get_native(entity_proxy), _get_native(consumable_proxy)
        if not _state:entity_has_consumable(entity_proxy, consumable_proxy) then
            bt.error_function("In get_consumable_n_used: entity `" .. entity:get_id() .. "` does not have consumable `" .. consumable:get_id() .. "` equipped")
            return 0
        end

        local slot_i = _state:entity_get_consumable_slot_i(entity)
        return consumable:get_max_n_uses() - env.get_consumable_slot_n_uses_left(entity_proxy, slot_i)
    end

    env.remove_consumable_slot = function(entity_proxy, slot_i)
        bt.assert_args("remove_consumable_slot",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local consumable = _state:entity_get_consumable(entity, slot_i)
        if consumable == nil then
            bt.error_function("In env.remove_consumable_slot: entity `" .. entity_proxy.id .. "` has no consumable in slot ´" .. slot_i .. "`")
            return
        end

        _state:entity_remove_consumable(entity, slot_i)

        local consumable_proxy = bt.create_consumable_proxy(_scene, consumable)
        local animation = bt.Animation.OBJECT_LOST(
            _scene, consumable, entity,
            rt.Translation.battle.message.consumable_removed_f(entity_proxy, consumable_proxy)
        )

        animation:signal_connect("start", function(_)
            local sprite = _scene:get_sprite(entity)
            sprite:remove_consumable(slot_i)
        end)

        _new_animation_node()
        _queue_animation(animation)


        _new_animation_node()

        _try_invoke_consumable_callback("on_lost", consumable_proxy, entity_proxy)

        local callback_id = "on_consumable_lost"
        for status_proxy in values(env.list_statuses(entity_proxy)) do
            _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, consumable_proxy)
        end

        for other_proxy in values(env.list_consumables(entity_proxy)) do
            if other_proxy ~= consumable_proxy then
                _try_invoke_consumable_callback(callback_id, other_proxy, entity_proxy, consumable_proxy)
            end
        end

        for status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, status_proxy, entity_proxy, consumable_proxy)
        end
    end

    env.remove_consumable = function(entity_proxy, consumable_proxy)
        bt.assert_args("remove_consumable",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        local entity, consumable = _get_native(entity_proxy), _get_native(consumable_proxy)
        local slot_i = _state:entity_get_consumable_slot_i(entity, consumable)
        if slot_i == nil then
            bt.error_function("In remove_consumable: entity `" .. entity:get_id() .. "` does not have consumable `" .. consumable:get_id() .. "` equipped")
            return
        end

        env.remove_consumable_slot(entity_proxy, slot_i)
    end

    env.add_consumable = function(entity_proxy, consumable_proxy)
        bt.assert_args("add_consumable",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        local entity, consumable = _get_native(entity_proxy), _get_native(consumable_proxy)

        local new_slot = nil
        for i = 1, _state:entity_get_n_consumable_slots(entity) do
            if _state:entity_get_consumable(entity, i) == nil then
                new_slot = i
                break
            end
        end

        _new_animation_node()


        _state:entity_add_consumable(entity, new_slot, consumable)

        local animation = bt.Animation.OBJECT_GAINED(
            _scene, consumable, entity,
            rt.Translation.battle.message.consumable_added_f(entity_proxy, consumable_proxy)
        )
        animation:signal_connect("start", function(_)
            local sprite = _scene:get_sprite(entity)
            sprite:add_consumable(new_slot, consumable, consumable:get_max_n_uses())
        end)
        _queue_animation(animation)

        _new_animation_node()

        -- callbacks
        _try_invoke_consumable_callback("on_gained", consumable_proxy, entity_proxy)

        local callback_id = "on_consumable_gained"
        for status_proxy in values(env.list_statuses(entity_proxy)) do
            _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, consumable_proxy)
        end

        for other_proxy in values(env.list_consumables(entity_proxy)) do
            if other_proxy ~= consumable_proxy then
                _try_invoke_consumable_callback(callback_id, other_proxy, entity_proxy, consumable_proxy)
            end
        end

        for status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, status_proxy, entity_proxy, consumable_proxy)
        end

        return new_slot
    end

    env.consume_consumable_slot = function(entity_proxy, slot_i, n)
        bt.assert_args("consume_consumable_slot",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        if n == nil then n = 1 end

        local entity = _get_native(entity_proxy)
        local consumable = _state:entity_get_consumable(entity, slot_i)
        if consumable == nil then
            bt.error_function("In env.consume_consumable_slot: entity `" .. entity:get_id() .. "` has no consumable in slot `" .. slot_i .. "`")
            return
        end

        local max = consumable:get_max_n_uses()
        if max == POSITIVE_INFINITY then return end

        _new_animation_node()

        local n_used = _state:entity_get_consumable_n_used(entity, slot_i)
        local was_used_up = max - (n_used + n) <= 0
        _state:entity_set_consumable_n_used(entity, slot_i, clamp(n_used + n, 0, consumable:get_max_n_uses()))

        local consumable_proxy = bt.create_consumable_proxy(_scene, consumable)
        local animation
        local message = rt.Translation.battle.message.consumable_consumed_f(entity_proxy, consumable_proxy)

        if was_used_up then
            _state:entity_remove_consumable(entity, slot_i)

            animation = bt.Animation.CONSUMABLE_CONSUMED(_scene, consumable, entity, message)
            animation:signal_connect("finish", function()
                _scene:get_sprite(entity):remove_consumable(slot_i)
            end)
        else
            animation = bt.Animation.CONSUMABLE_APPLIED(_scene, consumable, entity, message)
            animation:signal_connect("start", function()
                _scene:get_sprite(entity):set_consumable_n_uses_left(max - (n_used + n))
            end)
        end

        _queue_animation(animation)

        _new_animation_node()

        _try_invoke_consumable_callback("on_consumable_consumed", consumable_proxy, entity_proxy, consumable_proxy)

        local callback_id = "on_consumable_consumed"
        for status_proxy in values(env.list_statuses(entity_proxy)) do
            _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, consumable_proxy)
        end

        for other_consumable_proxy in values(env.list_consumables(entity_proxy)) do
            if other_consumable_proxy ~= consumable_proxy then
                _try_invoke_consumable_callback(callback_id, other_consumable_proxy, entity_proxy, consumable_proxy)
            end
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy, consumable_proxy)
        end
    end

    env.consume_consumable = function(entity_proxy, consumable_proxy)
        bt.assert_args("consume_consumable",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        local entity, consumable = _get_native(entity_proxy), _get_native(consumable_proxy)
        if not _state:entity_has_consumable(entity, consumable) then
            bt.error_function("In consume_consumable: entity `" .. entity:get_id() .. "` does not have consumable `" .. consumable:get_id() .. "` equiped")
            return
        end

        local slot_i = _state:entity_get_consumable_slot_i(_get_native(entity_proxy), _get_native(consumable_proxy))
        env.consume_consumable_slot(entity_proxy, slot_i)
    end


    for which_proxy in range(
        { "move", bt.MoveProxy },
        { "equip", bt.EquipProxy },
        { "consumable", bt.ConsumableProxy }
    ) do
        local which, proxy = table.unpack(which_proxy)

        --- @brief has_move, has_equip, has_consumable
        env["has_" .. which] = function(entity_proxy, object_proxy)
            bt.assert_args("has_" .. which,
                entity_proxy, bt.EntityProxy,
                object_proxy, proxy
            )
            return _state["entity_has_" .. which](_state, _get_native(entity_proxy), _get_native(object_proxy))
        end

        --- @brief has_move_in_slot, has_equip_in_slot, has_consumable_in_slot
        env["has_" .. which .. "_in_slot"] = function(entity_proxy, slot_i)
            bt.assert_args("has_" .. which .. "_in_slot",
                entity_proxy, bt.EntityProxy,
                slot_i, bt.Number
            )
            return _state["entity_get_" .. which](_state, _get_native(entity_proxy), slot_i) ~= nil
        end

        --- @brief list_moves, list_equips, list_consumables
        env["list_" .. which .. "s"] = function(entity_proxy)
            bt.assert_args("list_" .. which .. "s", entity_proxy, bt.EntityProxy)
            local out = {}
            local n, slots = _state["entity_list_" .. which .. "_slots"](_state, _get_native(entity_proxy))
            for i = 1, n do
                local object = slots[i]
                if object ~= nil then
                    table.insert(out, bt["create_" .. which .. "_proxy"](_scene, object))
                end
            end
            return out
        end

        --- @brief list_move_slots, list_equip_slots, list_consumable_slots
        env["list_" .. which .. "_slots"] = function(entity_proxy)
            bt.assert_args("list_" .. which .. "_slots", entity_proxy, bt.EntityProxy)
            local out = {}
            local n, slots = _state["entity_list_" .. which .. "_slots"](_state, _get_native(entity_proxy))
            for i = 1, n do
                out[i] = slots[i]
            end
            return out
        end

        --- @brief get_move_is_disabled, get_equip_is_disabled, get_consumable_is_disabled
        env["get_" .. which .. "_is_disabled"] = function(entity_proxy, object_proxy)
            bt.assert_args("get_" .. which .. "_is_disabled",
                entity_proxy, bt.EntityProxy,
                object_proxy, proxy
            )

            local entity, object = _get_native(entity_proxy), _get_native(object_proxy)
            if not _state["entity_has_" .. which](_state, entity, object) then
                bt.error_function("In env." .. "get_" .. which .. "_is_disabled" .. ": entity `" .. entity_proxy.id .. "` does not have " .. which .. " `" .. object_proxy.id .. "` equipped")
                return false
            end

            local slot_i = _state["entity_get_" .. which .. "_slot_i"](_state, entity, object)
            return _state["entity_get_" .. which .. "_is_disabled"](_state, entity, slot_i)
        end

        --- @brief get_move_slot_is_disabled, get_equip_slot_is_disabled, get_consumable_slot_is_disabled
        env["get_" .. which .. "_slot_is_disabled"] = function(entity_proxy, slot_i)
            bt.assert_args("get_" .. which .. "_slot_is_disabled",
                entity_proxy, bt.EntityProxy,
                slot_i, bt.Number
            )

            local entity = _get_native(entity_proxy)
            local object_maybe = _state["entity_get_" .. which](_state, entity, slot_i)
            if object_maybe == nil then
                return false
            else
                return _state["entity_" .. which .. "_is_disabled"](_state, entity, slot_i)
            end
        end

        --- @brief set_move_slot_is_disabled, set_equip_slot_is_disabled, set_consumable_slot_is_disabled
        env["set_" .. which .. "_slot_is_disabled"] = function(entity_proxy, slot_i, b)
            bt.assert_args("set_" .. which .. "_slot_is_disabled",
                entity_proxy, bt.EntityProxy,
                slot_i, bt.Number,
                b, bt.Boolean
            )

            local entity = _get_native(entity_proxy)
            local object = _state["entity_get_" .. which](_state, entity, slot_i)
            if object == nil then
                bt.error_function("In " .. "set_" .. which .. "_slot_is_disabled: entity `" .. entity:get_id() .. "` has no " .. which .. " in slot " .. slot_i)
                return
            end

            local before = _state["entity_get_" .. which .. "_is_disabled"](_state, entity, slot_i)
            local now = b
            local object_proxy = bt["create_" .. which .. "_proxy"](_scene, object)

            if before ~= now then
                _state["entity_set_" .. which .. "_is_disabled"](_state, entity, slot_i, b)
                _new_animation_node()

                if before == false and now == true then
                    _queue_animation(bt.Animation.OBJECT_DISABLED(
                        _scene, object, entity,
                        rt.Translation.battle.message.object_disabled_f(entity_proxy, object_proxy)
                    ))
                end

                _new_animation_node()
                local callback_id = "on_" .. which .. "_disabled"
                for status_proxy in values(env.list_statuses(entity_proxy)) do
                    _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, object_proxy)
                end

                for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                    if consumable_proxy ~= object_proxy then
                        _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, object_proxy)
                    end
                end

                for global_status_proxy in values(env.list_global_statuses()) do
                    if global_status_proxy ~= object_proxy then
                        _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy, object_proxy)
                    end
                end
            elseif before == true and now == false then
                _queue_animation(bt.Animation.OBJECT_ENABLED(
                    _scene, object, entity,
                    rt.Translation.battle.message.object_no_longer_disabled_f(entity_proxy, object_proxy)
                ))
                -- no callbacks on enable
            end
        end

        --- @brief set_move_is_disabled, set_equip_is_disabled, set_consumable_is_disabled
        env["set_" .. which .. "_is_disabled"] = function(entity_proxy, object_proxy, b)
            bt.assert_args("set_" .. which .. "_is_disabled",
                entity_proxy, bt.EntityProxy,
                object_proxy, proxy,
                b, bt.Boolean
            )

            local slot_i = _state["entity_get_" .. which .. "_slot_i"](_state, _get_native(entity_proxy), _get_native(object_proxy))
            if slot_i == nil then
                return -- fizzle if not equipped
            else
                env["set_" .. which .. "_slot_is_disabled"](entity_proxy, slot_i, b)
            end
        end
    end

    -- global status

    env.list_global_statuses = function()
        local out = {}
        for global_status in values(_state:list_global_statuses()) do
            table.insert(out, bt.create_global_status_proxy(_scene, global_status))
        end
        return out
    end

    env.has_global_status = function(global_status_proxy)
        bt.assert_args("has_global_status", global_status_proxy, bt.GlobalStatusProxy)
        return _state:has_global_status(_get_native(global_status_proxy))
    end

    env.get_global_status_max_duration = function(global_status_proxy)
        bt.assert_args("get_global_status_max_duration", global_status_proxy, bt.GlobalStatusProxy)
        return _get_native(global_status_proxy):get_max_duration()
    end

    env.get_global_status_n_turns_elapsed = function(global_status_proxy)
        bt.assert_args("get_global_status_n_turns_elapsed", global_status_proxy, bt.GlobalStatusProxy)

        local global_status = _get_native(global_status_proxy)
        if not _state:has_global_status(global_status) then
            bt.error_function("In get_global_status_n_turns_elapsed: global status `" .. global_status:get_id() .. "` is not present")
            return 0
        end

        return _state:get_global_status_n_turns_elapsed(_get_native(global_status_proxy))
    end

    env.get_global_status_n_turns_left = function(global_status_proxy)
        bt.assert_args("get_global_status_n_turns_left", global_status_proxy, bt.GlobalStatusProxy)

        local global_status = _get_native(global_status_proxy)
        if not _state:has_global_status(global_status) then
            bt.error_function("In get_global_status_n_turns_left: global status `" .. global_status:get_id() .. "` is not present")
            return 0
        end

        return global_status:get_max_duration() - env.get_global_status_n_turns_elapsed(global_status_proxy)
    end

    env.add_global_status = function(global_status_proxy)
        bt.assert_args("add_global_status",
            global_status_proxy, bt.GlobalStatusProxy
        )

        local global_status = _get_native(global_status_proxy)
        if _state:has_global_status(global_status) then
            return -- prevent double status
        end

        _state:add_global_status(global_status)

        _new_animation_node()

        local animation = bt.Animation.GLOBAL_STATUS_GAINED(
            _scene, global_status,
            rt.Translation.battle.message.global_status_added_f(global_status_proxy)
        )
        animation:signal_connect("start", function(_)
            _scene:add_global_status(global_status, global_status:get_max_duration())
        end)
        _queue_animation(animation)

        _new_animation_node()

        _try_invoke_global_status_callback("on_gained", global_status_proxy, env.list_entities())

        local callback_id = "on_global_status_gained"
        for entity in values(_state:list_entities()) do
            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, global_status_proxy)
            end
        end

        for entity in values(_state:list_entities()) do -- separate for loop bc status < consumable
            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, global_status_proxy)
            end
        end

        for other_global_status_proxy in values(env.list_global_statuses()) do
            if other_global_status_proxy ~= global_status_proxy then
                _try_invoke_global_status_callback(callback_id, other_global_status_proxy, global_status_proxy)
            end
        end
    end

    env.remove_global_status = function(global_status_proxy)
        bt.assert_args("remove_global_status",
            global_status_proxy,
            bt.GlobalStatusProxy
        )

        local global_status = _get_native(global_status_proxy)
        if not _state:has_global_status(global_status) then
            return -- fizzle
        end

        _state:remove_global_status(global_status)

        _new_animation_node()

        local animation = bt.Animation.GLOBAL_STATUS_LOST(
            _scene, global_status,
            rt.Translation.battle.message.global_status_removed_f(global_status_proxy)
        )
        animation:signal_connect("finish", function(_)
            _scene:remove_global_status(global_status)
        end)
        _queue_animation(animation)

        _new_animation_node()

        _try_invoke_global_status_callback("on_lost", global_status_proxy)

        local callback_id = "on_global_status_lost"
        for entity in values(_state:list_entities()) do
            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, global_status_proxy)
            end
        end

        for entity in values(_state:list_entities()) do
            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, global_status_proxy)
            end
        end

        for other_global_status_proxy in values(env.list_global_statuses()) do
            if _get_native(other_global_status_proxy) ~= _get_native(global_status_proxy) then
                _try_invoke_global_status_callback(callback_id, other_global_status_proxy, global_status_proxy)
            end
        end
    end

    -- status

    env.list_statuses = function(entity_proxy)
        bt.assert_args("list_statuses", entity_proxy, bt.EntityProxy)
        local out = {}
        local entity = _get_native(entity_proxy)
        for status in values(_state:entity_list_statuses(entity)) do
            table.insert(out, bt.create_status_proxy(_scene, status, entity))
        end
        return out
    end

    env.has_status = function(entity_proxy, status_proxy)
        bt.assert_args("has_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )
        return _state:entity_has_status(_get_native(entity_proxy), _get_native(status_proxy))
    end

    for which in range(
        "attack_offset",
        "defense_offset",
        "speed_offset",
        "attack_factor",
        "defense_factor",
        "speed_factor",

        "damage_dealt_factor",
        "damage_received_factor",
        "healing_performed_factor",
        "healing_received_factor",

        "damage_dealt_offset",
        "damage_received_offset",
        "healing_performed_offset",
        "healing_received_offset",

        "is_stun",
        "max_duration"
    ) do
        env["get_status_" .. which] = function(status_proxy)
            bt.assert_args("get_status_" .. which, status_proxy, bt.StatusProxy)
            local status = _get_native(status_proxy)
            return status["get_" .. which](status)
        end
    end

    env.get_status_n_turns_elapsed = function(status_proxy, entity_proxy)
        bt.assert_args("get_status_n_turns_elapsed",
            status_proxy, bt.StatusProxy,
            entity_proxy, bt.EntityProxy
        )

        local entity, status = _get_native(entity_proxy), _get_native(status_proxy)
        if not _state:entity_has_status(entity, status) then
            rt.warning("In get_status_n_turns_elapsed: entity `" .. entity:get_id() .. "` does not have status `" .. status:get_id() .. "`")
            return 0
        else
            return _state:entity_get_status_n_turns_elapsed(entity, status)
        end
    end

    env.get_status_n_turns_left = function(status_proxy, entity_proxy)
        bt.assert_args("get_status_n_turns_left",
            status_proxy, bt.StatusProxy,
            entity_proxy, bt.EntityProxy
        )

        local entity, status = _get_native(entity_proxy), _get_native(status_proxy)
        if not _state:entity_has_status(entity, status) then
            rt.warning("In get_status_n_turns_left: entity `" .. entity:get_id() .. "` does not have status `" .. status:get_id() .. "`")
            return POSITIVE_INFINITY
        else
            local elapsed = _state:entity_get_status_n_turns_elapsed(entity, status)
            local max = status:get_max_duration()
            return max - elapsed
        end
    end

    env.add_status = function(entity_proxy, status_proxy)
        bt.assert_args("add_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )

        if env.get_is_dead(entity_proxy) or env.get_is_knocked_out(entity_proxy) then
            return
        end

        local entity, status = _get_native(entity_proxy), _get_native(status_proxy)
        if _state:entity_has_status(entity, status) then
            -- if already present, invoke callback, then fizzle
            _new_animation_node()
            for other_status_proxy in values(env.list_statuses()) do
                if env.get_id(status_proxy) == env.get_id(other_status_proxy) then
                    _try_invoke_status_callback("on_already_present", other_status_proxy)
                end
            end
            return
        end

        _state:entity_add_status(entity, status)

        _new_animation_node()

        local animation = bt.Animation.STATUS_GAINED(
            _scene, status, entity,
            rt.Translation.battle.message.status_added_f(entity_proxy, status_proxy)
        )
        animation:signal_connect("start", function(_)
            _scene:get_sprite(entity):add_status(status, status:get_max_duration())
        end)

        animation:signal_connect("finish", function(_)
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _queue_animation(animation)

        _new_animation_node()

        _try_invoke_status_callback("on_gained", status_proxy, entity_proxy)

        local callback_id = "on_status_gained"
        for other_status_proxy in values(env.list_statuses(entity_proxy)) do
            if status_proxy ~= other_status_proxy then
                _try_invoke_status_callback(callback_id, other_status_proxy, entity_proxy, status_proxy)
            end
        end

        for consumable_proxy in values(env.list_consumables(entity_proxy)) do
            _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, status_proxy)
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy, status_proxy)
        end
    end

    env.remove_status = function(entity_proxy, status_proxy)
        bt.assert_args("remove_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )

        local entity, status = _get_native(entity_proxy), _get_native(status_proxy)
        if not _state:entity_has_status(entity, status) then
            return -- fizzle
        end

        _state:entity_remove_status(entity, status)

        _new_animation_node()

        local animation = bt.Animation.STATUS_LOST(
            _scene, status, entity,
            rt.Translation.battle.message.status_removed_f(entity_proxy, status_proxy)
        )
        animation:signal_connect("finish", function(_)
            _scene:get_sprite(entity):remove_status(status)
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _queue_animation(animation)

        _new_animation_node()

        _try_invoke_status_callback("on_lost", status_proxy, entity_proxy)

        local callback_id = "on_status_lost"
        for other_status_proxy in values(env.list_statuses(entity_proxy)) do
            if status_proxy ~= other_status_proxy then
                _try_invoke_status_callback(callback_id, other_status_proxy, entity_proxy, status_proxy)
            end
        end

        for consumable_proxy in values(env.list_consumables(entity_proxy)) do
            _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, status_proxy)
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy, status_proxy)
        end
    end

    -- entity

    function env.list_entities()
        local out = {}
        for entity in values(_state:list_entities_in_order()) do
            table.insert(out, bt.create_entity_proxy(_scene, entity))
        end
        return out
    end

    --- @return Tuple<bt.EntityProxy>
    function env.get_entity_from_id(id)
        bt.assert_args("get_entity_from_id", id, bt.String)
        local entities = _state:get_entity_from_id(id)
        local out = {}
        for entity in values(entities) do
            table.insert(out, bt.create_entity_proxy(_scene, entity))
        end
        return table.unpack(out)
    end

    function env.list_enemies()
        local out = {}
        for entity in values(_state:list_entities_in_order()) do
            if _state:entity_get_is_enemy(entity) == true then
                table.insert(out, bt.create_entity_proxy(_scene, entity))
            end
        end
        return out
    end

    function env.list_party()
        local out = {}
        for entity in values(_state:list_entities_in_order()) do
            if _state:entity_get_is_enemy(entity) == false then
                table.insert(out, bt.create_entity_proxy(_scene, entity))
            end
        end
        return out
    end

    function env.list_dead_entities()
        local out = {}
        for entity in values(_state:list_dead_entities()) do
            table.insert(out, bt.create_entity_proxy(_scene, entity))
        end
        return out
    end

    function env.list_dead_enemies()
        local out = {}
        for entity in values(_state:list_dead_entities()) do
            if _state:entity_get_is_enemy(entity) == true then
                table.insert(out, bt.create_entity_proxy(_scene, entity))
            end
        end
        return out
    end

    function env.list_dead_party()
        local out = {}
        for entity in values(_state:list_dead_entities()) do
            if _state:entity_get_is_enemy(entity) == false then
                table.insert(out, bt.create_entity_proxy(_scene, entity))
            end
        end
        return out
    end

    function env.list_enemies_of(entity_proxy)
        bt.assert_args("list_enemies_of", entity_proxy, bt.EntityProxy)
        local self_is_enemy = _get_native(entity_proxy):get_is_enemy()
        local out = {}
        for entity in values(_state:list_entities_in_order()) do
            if _state:entity_get_is_enemy(entity) ~= self_is_enemy then
                table.insert(out, bt.create_entity_proxy(_scene, entity))
            end
        end
        return out
    end

    function env.list_allies_of(entity_proxy)
        bt.assert_args("list_party_of", entity_proxy, bt.EntityProxy)
        local self_is_enemy = _get_native(entity_proxy):get_is_enemy()
        local out = {}
        for entity in values(_state:list_entities_in_order()) do
            if _state:entity_get_is_enemy(entity) == self_is_enemy then
                table.insert(out, bt.create_entity_proxy(_scene, entity))
            end
        end
        return out
    end

    for which in range(
        "hp",
        "hp_base",
        "attack",
        "defense",
        "speed",
        "attack_base",
        "defense_base",
        "speed_base",
        "attack_base_raw",
        "defense_base_raw",
        "speed_base_raw",
        "n_move_slots",
        "n_equip_slots",
        "n_consumable_slots",
        "is_stunned",
        "priority"
    ) do
        --- @brief get_hp, get_hp_base, get_attack, get_defense, get_speed, get_attack_base, get_defense_base, get_speed_base, get_attack_base_raw, get_defense_base_raw, get_speed_base_raw, get_n_move_slots, get_n_consumable_slots, get_n_equip_slots, get_is_stunned, get_priority
        env["get_" .. which] = function(entity_proxy)
            bt.assert_args("get_" .. which, entity_proxy, bt.EntityProxy)
            local native = _get_native(entity_proxy)
            return _state["entity_get_" .. which](_state, native)
        end
    end

    env.ENTITY_STATE_ALIVE = bt.EntityState.ALIVE
    env.ENTITY_STATE_KNOCKED_OUT = bt.EntityState.KNOCKED_OUT
    env.ENTITY_STATE_DEAD = bt.EntityState.DEAD

    env.get_state = function(entity_proxy)
        bt.assert_args("get_state", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy))
    end

    env.get_is_alive = function(entity_proxy)
        bt.assert_args("is_alive", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.ALIVE
    end

    env.get_is_dead = function(entity_proxy)
        bt.assert_args("is_dead", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.DEAD
    end

    env.get_is_knocked_out = function(entity_proxy)
        bt.assert_args("is_knocked_out", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.KNOCKED_OUT
    end

    env.knock_out = function(entity_proxy)
        bt.assert_args("knock_out", entity_proxy, bt.EntityProxy)

        if not env.get_is_alive(entity_proxy) then
            return -- fizzle
        end

        local entity = _get_native(entity_proxy)
        _state:entity_set_state(entity, bt.EntityState.KNOCKED_OUT)
        _state:entity_set_hp(entity, 0)

        _new_animation_node()

        local message = rt.Translation.battle.message.knocked_out_f(entity_proxy)
        local animation
        if env.get_is_enemy(entity_proxy) then
            animation = bt.Animation.ENEMY_KNOCKED_OUT(_scene, entity, message)
        else
            animation = bt.Animation.ALLY_KNOCKED_OUT(_scene, entity, message)
        end

        animation:signal_connect("start", function(_)
            local sprite = _scene:get_sprite(entity)
            sprite:set_hp(0)

            for status_proxy in values(env.list_statuses(entity)) do
                sprite:remove_status(_get_native(status_proxy))
            end

            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        animation:signal_connect("finish", function(_)
            _scene:get_sprite(entity):set_sprite_state(bt.EntitySpriteState.KNOCKED_OUT)
        end)

        _queue_animation(animation)

        _new_animation_node()

        for status_proxy in values(env.list_statuses(entity_proxy)) do
            _try_invoke_status_callback("on_knocked_out", status_proxy, entity_proxy)
        end

        for consumable_proxy in values(env.list_consumables(entity_proxy)) do
            _try_invoke_consumable_callback("on_knocked_out", consumable_proxy, entity_proxy)
        end

        local user_proxy = _get_current_move_user()
        if user_proxy ~= nil then
            for status_proxy in values(env.list_statuses(user_proxy)) do
                _try_invoke_status_callback("on_knocked_out_other", status_proxy, user_proxy, entity_proxy)
            end

            for consumable_proxy in values(env.list_consumables(user_proxy)) do
                _try_invoke_consumable_callback("on_knocked_out_other", consumable_proxy, user_proxy, entity_proxy)
            end
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback("on_knocked_out", global_status_proxy, entity_proxy)
        end

        _state:entity_clear_statuses(entity) -- delay clear to after callbacks so storage is still available
    end

    env.help_up = function(entity_proxy, hp_value)
        if hp_value == nil then hp_value = 1 end
        bt.assert_args("help_up",
            entity_proxy, bt.EntityProxy,
            hp_value, bt.Number
        )

        if env.get_is_dead(entity_proxy) or not env.get_is_knocked_out(entity_proxy) then
            return -- fizzle
        end

        local entity = _get_native(entity_proxy)
        hp_value = clamp(hp_value, 1, _state:entity_get_hp_base(entity))

        _state:entity_set_state(entity, bt.EntityState.ALIVE)
        _state:entity_set_hp(entity, hp_value)
        _state:entity_clear_statuses(entity)

        _new_animation_node()

        local message = rt.Translation.battle.message.helped_up_f(entity_proxy)
        local animation
        if env.get_is_enemy(entity_proxy) then
            animation = bt.Animation.ENEMY_HELPED_UP(_scene, entity, message)
        else
            animation = bt.Animation.ALLY_HELPED_UP(_scene, entity, message)
        end

        animation:signal_connect("start", function(_)
            local sprite = _scene:get_sprite(entity)
            sprite:set_hp(hp_value)

            for status_proxy in values(env.list_statuses(entity_proxy)) do
                sprite:remove_status(_get_native(status_proxy))
            end

            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        animation:signal_connect("finish", function(_)
            local sprite = _scene:get_sprite(entity)
            sprite:set_state(bt.EntityState.ALIVE)
        end)

        _queue_animation(animation)
        _new_animation_node()

        for status_proxy in values(env.list_statuses(entity_proxy)) do
            _try_invoke_status_callback("on_helped_up", status_proxy, entity_proxy)
        end

        for consumable_proxy in values(env.list_consumables(entity_proxy)) do
            _try_invoke_consumable_callback("on_helped_up", consumable_proxy, entity_proxy)
        end

        local user_proxy = _get_current_move_user()
        if user_proxy ~= nil then
            for status_proxy in values(env.list_statuses(user_proxy)) do
                _try_invoke_status_callback("on_helped_up_other", status_proxy, user_proxy, entity_proxy)
            end

            for consumable_proxy in values(env.list_consumables(user_proxy)) do
                _try_invoke_consumable_callback("on_helped_up_other", consumable_proxy, user_proxy, entity_proxy)
            end
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback("on_helped_up", global_status_proxy, entity_proxy)
        end
    end

    env.kill = function(entity_proxy)
        bt.assert_args("kill", entity_proxy, bt.EntityProxy)
        if env.get_is_dead(entity_proxy) then
            return -- fizzle
        end

        local entity = _get_native(entity_proxy)
        _state:entity_set_state(entity, bt.EntityState.DEAD)
        _state:entity_set_hp(entity, 0)

        _new_animation_node()

        local message = rt.Translation.battle.message.killed_f(entity_proxy)
        local animation
        if env.get_is_enemy(entity_proxy) then
            animation = bt.Animation.ENEMY_KILLED(_scene, entity, message)
        else
            animation = bt.Animation.ALLY_KILLED(_scene, entity, message)
        end

        animation:signal_connect("start", function(_)
            local sprite = _scene:get_sprite(entity)
            sprite:set_hp(0)
            sprite:set_sprite_state(bt.EntitySpriteState.DEAD)
            for status_proxy in env.list_statuses(entity_proxy) do
                sprite:remove_status(_get_native(status_proxy))
            end

            local slots = env.list_consumable_slots(entity_proxy)
            for i, which in pairs(slots) do
                if which ~= nil then
                    sprite:remove_consumable(i)
                end
            end
        end)

        animation:signal_connect("finish", function(_)
            _scene:remove_entity(entity)
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _queue_animation(animation)

        _new_animation_node()

        for status_proxy in values(env.list_statuses(entity_proxy)) do
            _try_invoke_status_callback("on_killed", status_proxy, entity_proxy)
        end

        for consumable_proxy in values(env.list_consumables(entity_proxy)) do
            _try_invoke_consumable_callback("on_killed", consumable_proxy, entity_proxy)
        end

        local user_proxy = _get_current_move_user()
        if user_proxy ~= nil then
            for status_proxy in values(env.list_statuses(user_proxy)) do
                _try_invoke_status_callback("on_killed_other", status_proxy, user_proxy, entity_proxy)
            end

            for consumable_proxy in values(env.list_consumables(user_proxy)) do
                _try_invoke_consumable_callback("on_killed_other", consumable_proxy, user_proxy, entity_proxy)
            end
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback("on_killed", global_status_proxy, entity_proxy)
        end

        _state:entity_clear_statuse(entity) -- delay to after callbacks
    end

    env.revive = function(entity_proxy, hp_value)
        if hp_value == nil then hp_value = 1 end
        bt.assert_args("revive",
            entity_proxy, bt.EntityProxy,
            hp_value, bt.Number
        )

        if env.get_is_dead(entity_proxy) ~= true then return end

        local entity = _get_native(entity_proxy)
        hp_value = clamp(hp_value, 1, _state:entity_get_hp_base(entity))
        _state:entity_set_state(entity, bt.EntityState.ALIVE)
        _state:entity_set_hp(entity, hp_value)

        _new_animation_node()

        local animation = bt.Animation.ENTITY_REVIVED(self, entity, rt.Translation.battle.message.revived_f(entity_proxy))
        animation:signal_connect("start", function(_)
            _scene:add_entity(entity)
            local sprite = _scene:get_sprite(entity)

            for status_proxy in values(env.list_statuses(entity_proxy)) do
                local status = _get_native(status_proxy)
                sprite:add_status(_get_native(status_proxy), status:get_max_duration() - _state:entity_get_status_n_turns_elapsed(entity, status))
            end

            local consumables = env.list_consumable_slots(entity_proxy)
            for i, consumable in pairs(consumables) do
                if consumable ~= nil then
                    sprite:add_consumable(i, consumable, consumable:get_max_n_uses() - _state:entity_get_consumable_n_used(entity, i))
                end
            end

            sprite:set_hp(hp_value)
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _queue_animation(animation)

        _new_animation_node()

        for status_proxy in values(env.list_statuses(entity_proxy)) do
            _try_invoke_status_callback("on_revived", status_proxy, entity_proxy)
        end

        for consumable_proxy in values(env.list_consumables(entity_proxy)) do
            _try_invoke_consumable_callback("on_revived", consumable_proxy, entity_proxy)
        end

        local user_proxy = _get_current_move_user()
        if user_proxy then
            for status_proxy in values(env.list_statuses(user_proxy)) do
                _try_invoke_status_callback("on_revived_other", status_proxy, user_proxy, entity_proxy)
            end

            for consumable_proxy in values(env.list_consumables(user_proxy)) do
                _try_invoke_consumable_callback("on_revived_other", consumable_proxy, user_proxy, entity_proxy)
            end
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback("on_revived", global_status_proxy, entity_proxy, user_proxy)
        end
    end

    env.add_hp = function(entity_proxy, value)
        bt.assert_args("add_hp",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        value = math.ceil(value)

        local entity = _get_native(entity_proxy)
        if value < 0 then
            rt.warning("In env.add_hp: value `" .. value .. "` is negative, reducing hp of `" .. entity:get_id() .. "` instead")
            env.reduce_hp(entity_proxy, math.abs(value))
            return
        end

        local hp_current = env.get_hp(entity_proxy)
        local hp_base = env.get_hp_base(entity_proxy)
        if hp_current >= hp_base or value == 0 or
            env.get_is_knocked_out(entity_proxy) or
            env.get_is_dead(entity_proxy)
        then
            return -- fizzle
        end

        _state:entity_set_hp(entity, clamp(hp_current + value, 1, hp_base))

        _new_animation_node()

        local difference = value -- unclamped value for animation display
        local animation = bt.Animation.HP_GAINED(
            _scene, entity, difference,
            rt.Translation.battle.message.hp_gained_f(entity_proxy, difference)
        )

        animation:signal_connect("start", function(_)
            _scene:get_sprite(entity):set_hp(clamp(hp_current + difference, 0, hp_base))
        end)

        _queue_animation(animation)

        _new_animation_node()

        do
            local callback_id = "on_hp_gained"
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, value)
            end

            for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, value)
            end

            for global_status_proxy in values(env.list_global_statuses()) do
                _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy, value)
            end
        end

        local performer_proxy = _get_current_move_user()
        if performer_proxy ~= nil then
            local callback_id = "on_healing_performed"
            for status_proxy in values(env.list_statuses(performer_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, performer_proxy, value)
            end

            for consumable_proxy in values(env.list_consumables(performer_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, performer_proxy, value)
            end

            for global_status_proxy in values(env.list_global_statuses()) do
                _try_invoke_global_status_callback(callback_id, global_status_proxy, performer_proxy, value)
            end
        end
    end

    env.reduce_hp = function(entity_proxy, value)
        bt.assert_args("reduce_hp",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        value = math.floor(value)

        local entity = _get_native(entity_proxy)
        if value < 0 then
            rt.warning("In env.reduce_hp: value `" .. value .. "` is negative, increasing hp of `" .. entity:get_id() .. "` instead")
            env.add_hp(entity_proxy, math.abs(value))
            return
        end

        if value == 0 or env.get_is_dead(entity_proxy) then
            return -- if dead, fizzle
        end

        if env.get_is_knocked_out(entity_proxy) then
            -- if knocked out, any damage > 0 kills
            env.kill(entity_proxy)
            return
        end

        local hp_current = env.get_hp(entity_proxy)
        local difference = value -- no clamp

        _state:entity_set_hp(entity, clamp(hp_current - difference, 0))

        _new_animation_node()

        local animation = bt.Animation.HP_LOST(
            _scene, entity, difference,
            rt.Translation.battle.message.hp_lost_f(entity_proxy, difference)
        )
        animation:signal_connect("start", function(_)
            _scene:get_sprite(entity):set_hp(clamp(hp_current - difference, 0))
        end)

        _queue_animation(animation)

        _new_animation_node()

        do
            local callback_id = "on_hp_lost"
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, value)
            end

            for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, value)
            end

            for global_status_proxy in values(env.list_global_statuses()) do
                _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy, value)
            end
        end

        local performer_proxy = _get_current_move_user()
        if performer_proxy ~= nil then
            local callback_id = "on_damage_dealt"
            for status_proxy in values(env.list_statuses(performer_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, performer_proxy, value)
            end

            for consumable_proxy in values(env.list_consumables(performer_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, performer_proxy, value)
            end

            for global_status_proxy in values(env.list_global_statuses()) do
                _try_invoke_global_status_callback(callback_id, global_status_proxy, performer_proxy, value)
            end
        end

        if _state:entity_get_hp(entity) <= 0 then
            -- if 0, knock out after hp reduce callbacks
            env.knock_out(entity_proxy)
            return
        end
    end

    env.set_hp = function(entity_proxy, value)
        bt.assert_args("reduce_hp",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        value = math.round(value)

        local entity = _get_native(entity_proxy)
        local current = _state:entity_get_hp(entity)
        local diff = current - clamp(value, 0, _state:entity_get_hp_base(entity))
        if diff > 0 then
            env.add_hp(entity_proxy, diff)
        elseif diff < 0 then
            env.reduce_hp(entity_proxy, math.abs(diff))
        else
            return -- fizzle
        end
    end

    env.get_is_enemy = function(entity_proxy)
        bt.assert_args("get_is_enemy", entity_proxy, bt.EntityProxy)
        return _state:entity_get_is_enemy(_get_native(entity_proxy)) == true
    end

    env.get_is_ally = function(entity_proxy)
        bt.assert_args("get_is_enemy", entity_proxy, bt.EntityProxy)
        return _state:entity_get_is_enemy(_get_native(entity_proxy)) == false
    end

    env.spawn = function(...)
        _new_animation_node()

        local added_entities = {}
        local entity_id_to_status_proxies = {}

        local is_first_animation = true

        local args = {...}
        for to_spawn in values(args) do
            local entity_id, move_proxies, consumable_proxies, equip_proxies, status_proxies = table.unpack(to_spawn)
            if move_proxies == nil then move_proxies = {} end
            if consumable_proxies == nil then consumable_proxies = {} end
            if equip_proxies == nil then equip_proxies = {} end
            if status_proxies == nil then status_proxies = {} end

            bt.assert_args("spawn",
                entity_id, bt.String,
                move_proxies, bt.Table,
                consumable_proxies, bt.Table,
                equip_proxies, bt.Table
            )

            if env[entity_prefix .. "_" .. entity_id] == nil then
                bt.error_function("In env.spawn: entity id `" .. entity_id .. "` is not a valid entity config id")
                return
            end

            local entity = _state:create_entity(bt.EntityConfig(entity_id))
            table.insert(added_entities, entity)
            for i, move_proxy in pairs(move_proxies) do
                bt.assert_is_move_proxy("spawn", move_proxy, 2)
                _state:entity_add_move(entity, i, _get_native(move_proxy))
            end

            for i, consumable_proxy in pairs(consumable_proxies) do
                bt.assert_is_consumable_proxy("spawn", consumable_proxy, 3)
                _state:entity_add_consumable(entity, i, _get_native(consumable_proxy))
            end

            for i, equip_proxy in pairs(equip_proxies) do
                bt.assert_is_equip_proxy("spawn", equip_proxy, 4)
                _state:entity_add_equip(entity, i, _get_native(equip_proxy))
            end

            entity_id_to_status_proxies[entity:get_id()] = {}
            for status_proxy in values(status_proxies) do
                table.insert(entity_id_to_status_proxies[entity:get_id()], status_proxy)
            end

            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            local message
            if env.get_is_enemy(entity_proxy) then
                message = rt.Translation.battle.message.enemy_spawned_f(entity_proxy)
            else
                message = rt.Translation.battle.message.ally_spawned_f(entity_proxy)
            end

            local animation
            if _state:entity_get_is_enemy(entity) then
                animation = bt.Animation.ENEMY_APPEARED(_scene, entity, message)
            else
                animation = bt.Animation.ALLY_APPEARED(_scene, entity, message)
            end

            if is_first_animation then
                -- batch sprite add so animations can trigger on fully formatted scene
                animation:signal_connect("start", function(_)
                    for entity in values(added_entities) do
                        _scene:add_entity(entity)
                    end
                end)
                is_first_animation = false
            end

            animation:signal_connect("start", function()
                local sprite = _scene:get_sprite(entity)
                sprite:set_hp(_state:entity_get_hp(entity), _state:entity_get_hp_base(entity))
                sprite:set_is_visible(false)
                sprite:set_speed(_state:entity_get_speed(entity))
            end)

            animation:signal_connect("finish", function()
                local sprite = _scene:get_sprite(entity)
                for consumable_proxy in values(consumable_proxies) do
                    local native = _get_native(consumable_proxy)
                    local slot_i = _state:entity_get_consumable_slot_i(entity, native)
                    local n_used = _state:entity_get_consumable_n_used(entity, slot_i)
                    sprite:add_consumable(slot_i, native, native:get_max_n_uses() - n_used)
                end

                -- status added separately
            end)

            _queue_animation(animation)
        end

        _new_animation_node()

        do
            local animation = bt.Animation.DUMMY(_scene)
            animation:signal_connect("start", function(_)
                _scene:set_priority_order(_state:list_entities_in_order())
            end)
            _queue_animation(animation)
        end

        _new_animation_node()

        -- invoke added on self

        for entity in values(added_entities) do
            local entity_proxy = bt.create_entity_proxy(_scene, entity)

            for equip_proxy in values(env.list_equips(entity_proxy)) do
                _try_invoke_equip_callback("effect", equip_proxy, entity_proxy)
            end

            for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                _try_invoke_consumable_callback("on_gained", consumable_proxy, entity_proxy)
            end

            -- invoke spawn
            local callback_id = "on_entity_spawned"
            for other_entity_proxy in values(env.list_entities()) do
                if other_entity_proxy ~= entity_proxy then
                    for status_proxy in values(env.list_statuses(other_entity_proxy)) do
                        _try_invoke_status_callback(callback_id, status_proxy, other_entity_proxy, entity_proxy)
                    end
                end
            end

            for other_entity_proxy in values(env.list_entities()) do
                if other_entity_proxy ~= entity_proxy then -- separate loops to preserve status < consumable order
                    for consumable_proxy in values(env.list_consumables(other_entity_proxy)) do
                        _try_invoke_consumable_callback(callback_id, consumable_proxy, other_entity_proxy, entity_proxy)
                    end
                end
            end

            for global_status_proxy in values(env.list_global_statuses()) do
                _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy)
            end
        end

        _new_animation_node()

        -- now add statuses
        for entity in values(added_entities) do
            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            for status_proxy in values(entity_id_to_status_proxies[entity:get_id()]) do
                bt.assert_is_status_proxy("spawn", status_proxy, 5)
                env.add_status(entity_proxy, status_proxy, false)
            end
        end
    end

    env.swap = function(entity_a_proxy, entity_b_proxy)
        bt.assert_args("swap",
            entity_a_proxy, bt.EntityProxy,
            entity_b_proxy, bt.EntityProxy
        )

        local entity_a, entity_b = _get_native(entity_a_proxy), _get_native(entity_b_proxy)
        if entity_a:get_is_enemy() ~= entity_b:get_is_enemy() then
            bt.error_function("In env.swap: entity `" .. entity_a:get_id() .. "` and entity `" .. entity_b:get_id() .. "` are party and enemy, only entities on the same side can be swapped")
            return
        end

        if env.get_is_dead(entity_a_proxy) or env.get_is_dead(entity_a_proxy) then
            return -- fizzle
        end

        _state:entity_swap_indices(entity_a, entity_b)

        _new_animation_node()

        local animation = bt.Animation.SWAP(
            _scene, entity_a, entity_b,
            rt.Translation.battle.message.swap_f(entity_a_proxy, entity_b_proxy)
        )
        animation:signal_connect("finish", function(_)
            if entity_a:get_is_enemy() then -- == entity_b:get_is_enemy()
                _scene:reformat_enemy_sprites()
            else
                _scene:reformat_party_sprites()
            end
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _queue_animation(animation)

        -- for callbacks, sort by priority for deterministic ordering
        local a_prio, b_prio = _state:get_entity_priority(entity_a), _state:get_entity_priority(entity_b)
        local a_speed, b_speed = _state:get_entity_speed(entity_a), _state:get_entity_speed(entity_b)

        local first_entity, second_entity
        if a_prio == b_prio then
            if a_speed > b_speed then
                first_entity = entity_a_proxy
                second_entity = entity_b_proxy
            else
                first_entity = entity_b_proxy
                second_entity = entity_a_proxy
            end
        else
            if a_prio > b_prio then
                first_entity = entity_a_proxy
                second_entity = entity_b_proxy
            else
                first_entity = entity_b_proxy
                second_entity = entity_a_proxy
            end
        end

        local callback_id = "on_swap"
        for status_proxy in values(env.list_statuses(first_entity)) do
            _try_invoke_status_callback(callback_id, status_proxy, first_entity, second_entity)
        end

        for status_proxy in values(env.list_statuses(second_entity)) do
            _try_invoke_status_callback(callback_id, status_proxy, second_entity, first_entity)
        end

        for consumable_proxy in values(env.list_consumables(first_entity)) do
            _try_invoke_consumable_callback(callback_id, consumable_proxy, first_entity, second_entity)
        end

        for consumable_proxy in values(env.list_consumables(second_entity)) do
            _try_invoke_consumable_callback(callback_id, consumable_proxy, second_entity, first_entity)
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy, first_entity, second_entity)
        end
    end

    env.compute_damage = function(
        attacking_entity_proxy,
        defending_entity_proxy,
        damage
    )
        bt.assert_args("compute_damage",
            attacking_entity_proxy, bt.EntityProxy,
            defending_entity_proxy, bt.EntityProxy,
            damage, bt.Number
        )

        local value = damage
        local attack_statuses = {}
        for status_proxy in values(env.list_statuses(attacking_entity_proxy)) do
            table.insert(attack_statuses, _get_native(status_proxy))
        end

        local defense_statuses = {}
        for status_proxy in values(env.list_statuses(defending_entity_proxy)) do
            table.insert(defense_statuses, _get_native(status_proxy))
        end

        local attack_consumables = {}
        for consumable_proxy in values(env.list_consumables(attacking_entity_proxy)) do
            table.insert(attack_consumables, _get_native(consumable_proxy))
        end

        local defense_consumables = {}
        for consumable_proxy in values(env.list_consumables(defending_entity_proxy)) do
            table.insert(defense_consumables, _get_native(consumable_proxy))
        end

        -- factors first
        for status in values(attack_statuses) do
            value = value * status:get_damage_dealt_factor()
        end

        for status in values(defense_statuses) do
            value = value * status:get_damage_received_factor()
        end

        for consumable in values(attack_consumables) do
            value = value * consumable:get_damage_dealt_factor()
        end

        for consumable in values(defense_consumables) do
            value = value * consumable:get_damage_received_factor()
        end

        -- offsets last
        for status in values(attack_statuses) do
            value = value + status:get_damage_dealt_offset()
        end

        for status in values(defense_statuses) do
            value = value + status:get_damage_received_offset()
        end

        for consumable in values(attack_consumables) do
            value = value + consumable:get_damage_dealt_offset()
        end

        for consumable in values(defense_consumables) do
            value = value + consumable:get_damage_received_offset()
        end

        -- weigh defense
        value = value - env.get_defense(defending_entity_proxy)

        value = math.ceil(value)
        if value < 1 then value = 1 end
        return value
    end

    env.deal_damage = function(target_proxy, value)
        bt.assert_args("deal_damage",
            target_proxy, bt.EntityProxy,
            value, bt.Number
        )

        local user_proxy = _get_current_move_user()
        if user_proxy ~= nil then
            value = env.compute_damage(user_proxy, target_proxy, value)
        end
        env.reduce_hp(target_proxy, math.max(value, 0))
    end

    env.compute_healing = function(
        healing_performing_entity_proxy,
        healing_receiving_entity_proxy,
        healing
    )
        bt.assert_args("compute_healing",
            healing_performing_entity_proxy, bt.EntityProxy,
            healing_receiving_entity_proxy, bt.EntityProxy,
            healing, bt.Number
        )

        local value = healing
        local performing_statuses = {}
        for status_proxy in values(env.list_statuses(healing_performing_entity_proxy)) do
            table.insert(performing_statuses, _get_native(status_proxy))
        end

        local receiving_statuses = {}
        for status_proxy in values(env.list_statuses(healing_receiving_entity_proxy)) do
            table.insert(receiving_statuses, _get_native(status_proxy))
        end

        local performing_consumables = {}
        for consumable_proxy in values(env.list_consumables(healing_performing_entity_proxy)) do
            table.insert(performing_consumables, _get_native(consumable_proxy))
        end

        local receiving_consumables = {}
        for consumable_proxy in values(env.list_consumables(healing_receiving_entity_proxy)) do
            table.insert(receiving_consumables, _get_native(consumable_proxy))
        end

        -- factors
        for status in values(performing_statuses) do
            value = value * status:get_healing_performed_factor()
        end

        for status in values(receiving_statuses) do
            value = value * status:get_healing_received_factor()
        end

        for consumable in values(performing_consumables) do
            value = value * consumable:get_healing_performed_factor()
        end

        for consumable in values(receiving_consumables) do
            value = value * consumable:get_healing_received_factor()
        end

        -- offsets
        for status in values(performing_statuses) do
            value = value + status:get_healing_performed_offset()
        end

        for status in values(receiving_statuses) do
            value = value + status:get_healing_received_offset()
        end

        for consumable in values(performing_consumables) do
            value = value + consumable:get_healing_performed_offset()
        end

        for consumable in values(receiving_consumables) do
            value = value + consumable:get_healing_received_offset()
        end

        return math.ceil(value) -- no clamp, negative healing possible
    end

    env.heal = function(target_proxy, value)
        bt.assert_args("deal_damage",
            target_proxy, bt.EntityProxy,
            value, bt.Number
        )
        local user_proxy = _get_current_move_user()
        if user_proxy ~= nil then
            value = env.compute_healing(user_proxy, target_proxy, value)
        end
        env.add_hp(target_proxy, math.max(value, 0))
    end

    env.use_move = function(user_proxy, move_proxy, ...)
        bt.assert_args("use_move",
            user_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )

        local target_proxies = {...}

        -- assert valid targets
        if select("#", ...) > 1 and not env.get_can_target_multiple(move_proxy) then
            bt.error_function("In use_move: move `" .. env.get_id(move_proxy) .. "` used by `" .. env.get_id(user_proxy) .. "` targets multiple, even though `can_target_multiple` is false")
            return
        end

        for target in values(target_proxies) do
            bt.assert_args("use_move", target, bt.EntityProxy)
            table.insert(target_proxies, target)

            if env.get_is_enemy(target) ~= env.get_is_enemy(user_proxy) and not env.get_can_target_enemies(move_proxy) then
                bt.error_function("In use_move: move `" .. env.get_id(move_proxy) .. "` used by `" .. env.get_id(user_proxy) .. "` targets enemy, even though `can_target_enemy` is false")
                return
            end

            if env.get_is_enemy(target) == env.get_is_enemy(user_proxy) and not env.get_can_target_allies(move_proxy)then
                bt.error_function("In use_move: move `" .. env.get_id(move_proxy) .. "` used by `" .. env.get_id(user_proxy) .. "` targets ally, even though `can_target_ally` is false")
                return
            end

            if target == user_proxy and not env.get_can_target_self(move_proxy) then
                bt.error_function("In use_move: move `" .. env.get_id(move_proxy) .. "` used by `" .. env.get_id(user_proxy) .. "` targets self, even though `can_target_self` is false")
                return
            end
        end

        local move = _get_native(move_proxy)
        if move.effect == nil then
            bt.error_function("In use_move: move `" .. move:get_id() .. "` has no `effect` function")
            return
        end

        _new_animation_node()

        rt.warning("In env.use_move: TODO: move animation")
        env.message(rt.Translation.battle.message.move_used_f)

        _push_current_move_user(user_proxy)
        _invoke(move.effect, move, user_proxy, target_proxies)
        _pop_current_move_user()

        _new_animation_node()

        local callback_id = "on_move_used"
        for status_proxy in values(env.list_statuses(user_proxy)) do
            _try_invoke_status_callback(callback_id, status_proxy, user_proxy)
        end

        for consumable_proxy in values(env.list_consumables(user_proxy)) do
            _try_invoke_consumable_callback(callback_id, consumable_proxy, user_proxy)
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy, user_proxy, target_proxies)
        end
    end

    env.start_turn = function()
        _new_animation_node()
        local animation = bt.Animation.TURN_START(
            _scene,
            rt.Translation.battle.message.turn_start_f(_state:get_turn_i())
        )
        _queue_animation(animation)

        local callback_id = "on_turn_start"
        local entity_proxies = env.list_entities()
        for entity_proxy in values(entity_proxies) do
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, entity_proxy)
            end
        end

        for entity_proxy in values(entity_proxies) do
            for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy)
            end
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxies)
        end

        _new_animation_node()
        animation = bt.Animation.DUMMY()
        animation:signal_connect("finish", function()
            _scene:start_move_selection()
        end)
        _queue_animation(animation)
    end

    env.end_turn = function()
        -- check if game over
        local party, enemies = {}
        local n_dead_allies, n_knocked_out_allies, n_allies = 0, 0, 0
        local n_dead_enemies, n_knocked_out_enemies, n_enemies = 0, 0, 0

        for entity in values(_state:list_all_entities()) do
            local state = _state:entity_get_state(entity)
            if _state:entity_get_is_enemy(entity) then
                n_enemies = n_enemies + 1
                if state == bt.EntityState.DEAD then
                    n_dead_enemies = n_dead_enemies + 1
                elseif state == bt.EntityState.KNOCKED_OUT then
                    n_knocked_out_enemies = n_knocked_out_enemies + 1
                end
            else
                n_allies = n_allies + 1
                if state == bt.EntityState.DEAD then
                    n_dead_allies = n_dead_allies + 1
                elseif state == bt.EntityState.KNOCKED_OUT then
                    n_knocked_out_allies = n_knocked_out_allies + 1
                end
            end
        end

        if n_dead_allies >= 1 then -- or n_knocked_out_allies == n_allies then
            env.loose_battle()
            return
        end

        if (n_dead_enemies + n_knocked_out_enemies) >= n_enemies then
            env.win_battle()
            return
        end

        -- increase status n turns or mark for expiration
        local entity_to_status_n_left = {}
        local entity_to_status_remove = {}

        for entity in values(_state:list_entities()) do
            entity_to_status_remove[entity] = {}
            entity_to_status_n_left[entity] = {}

            for status in values(_state:entity_list_statuses(entity)) do
                local max = status:get_max_duration()
                local current = _state:entity_get_status_n_turns_elapsed(entity, status)
                current = current + 1

                if current >= max then
                    _state:entity_remove_status(entity, status)
                    table.insert(entity_to_status_remove[entity], status)
                else
                    _state:entity_set_status_n_turns_elapsed(entity, status, current)
                    table.insert(entity_to_status_n_left[entity], {
                        status,
                        max - current
                    })

                end
            end
        end

        local global_status_n_left = {}
        local global_status_to_remove = {}

        for global_status in values(_state:list_global_statuses()) do
            local max = global_status:get_max_duration()
            local current = _state:get_global_status_n_turns_elapsed(global_status)
            current = current + 1

            if current >= max then
                global_status_to_remove[global_status] = true
            else
                _state:set_global_status_n_turns_elapsed(global_status, current)
                global_status_n_left[global_status] = max - current
            end
        end

        -- reset priority
        for entity in values(_state:list_all_entities()) do
            _state:entity_set_priority(entity, 0)
        end

        _new_animation_node()

        local animation = bt.Animation.TURN_END(_scene)
        animation:signal_connect("finish", function(_)
            if _state:get_quicksave_exists() then
                _scene._quicksave_indicator:set_n_turns_elapsed(_state:get_quicksave_n_turns_elapsed() + 1)
            end

            for entity, t in pairs(entity_to_status_n_left) do
                local sprite = _scene:get_sprite(entity)
                sprite:set_global_status_n_turns_left(t[1], t[2])
            end

            for global_status, n_left in pairs(global_status_n_left) do
                _scene:set_global_status_n_turns_left(n_left)
            end

            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _queue_animation(animation)

        -- callbacks before statuses expire
        local callback_id = "on_turn_end"
        local entity_proxies = env.list_entities()
        for entity_proxy in values(entity_proxies) do
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, entity_proxy)
            end
        end

        for entity_proxy in values(entity_proxies) do
            for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy)
            end
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy)
        end

        -- expire statuses
        for entity, statuses in pairs(entity_to_status_remove) do
            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            for status in values(statuses) do
                env.remove_status(entity_proxy, bt.create_status_proxy(_scene, status))
            end
        end

        for global_status, _ in pairs(global_status_to_remove) do
            env.remove_global_status(bt.create_global_status_proxy(_scene, global_status))
        end

        -- delay increment turn count
        _state:set_turn_i(_state:get_turn_i() + 1)
    end

    env.quicksave = function()
        local animation = rt.Animation.QUICKSAVE(
            self, _scene._quicksave_indicator,
            rt.Translation.battle.message.quicksave_created_f()
        )
        animation:signal_connect("start", function(animation)
            local texture = _state:create_quicksave()
            animation._snapshot = texture
        end)

        animation:signal_connect("finish", function(animation)
            _scene._quicksave_indicator:set_n_turns_elapsed(0)
        end)

        _new_animation_node()
        _queue_animation(animation)
    end

    env.quickload = function()
        if _state:has_quicksave() == false then
            bt.error_function("In env.quickload: trying to load a quicksave, but none is present")
            return
        end

        _state:load_quicksave()

        local animation = rt.Animation.QUICKLOAD(
            self, _scene._quicksave_indicator,
            rt.Translation.battle.message.quicksave_loaded_f()
        )
        animation:signal_connect("finish", function(_)
            _scene._quicksave_indicator:set_screenshot(nil)
            _scene:create_from_state(self._state)
        end)

        _new_animation_node()
        _queue_animation(animation)
    end

    env.start_battle = function(battle_id)
        local battle = bt.BattleConfig(battle_id)
        _scene._animation_queue:clear()

        -- clear state if present
        _state:reset_entity_multiplicity()
        for enemy in values(_state:list_all_entities()) do
            _state:remove_entity(enemy)
        end

        for global_status in values(_state:list_global_statuses()) do
            _state:remove_global_status(global_status)
        end

        _scene:create_from_state()
        _scene:set_background(battle:get_background())

        -- spawn enemies
        local to_spawn = {}
        local n_enemies = battle:get_n_enemies()
        for enemy_i = 1, n_enemies do
            local id = battle:get_enemy_id(enemy_i)
            local moves = {}
            local consumables = {}
            local equips = {}
            local statuses = {}

            for move in values(battle:get_enemy_moves(enemy_i)) do
                table.insert(moves, bt.create_move_proxy(_scene, move))
            end

            for equip_i, equip in ipairs(battle:get_enemy_equips(enemy_i)) do
                table.insert(equips, bt.create_equip_proxy(_scene, equip))
            end

            for consumable_i, consumable in ipairs(battle:get_enemy_consumables(enemy_i)) do
                table.insert(consumables, bt.create_consumable_proxy(_scene, consumable))
            end

            for status in values(battle:get_enemy_statuses(enemy_i)) do
                table.insert(statuses, bt.create_status_proxy(_scene, status))
            end

            table.insert(to_spawn, {
                id,
                moves,
                consumables,
                equips,
                statuses
            })
        end

        -- spawn allies
        for ally in values(_state:active_template_list_party()) do
            local id = ally:get_id()
            local moves = {}
            local consumables = {}
            local equips = {}
            local statuses = {}

            local n, move_slots = _state:active_template_list_move_slots(ally)
            for i = 1, n do
                local config = move_slots[i]
                if config ~= nil then
                    moves[i] = bt.create_move_proxy(_scene, config)
                end
            end

            local n, equip_slots = _state:active_template_list_equip_slots(ally)
            for i = 1, n do
                local config = equip_slots[i]
                if config ~= nil then
                    equips[i] = bt.create_equip_proxy(_scene, config)
                end
            end

            local n, consumable_slots = _state:active_template_list_consumable_slots(ally)
            for i = 1, n do
                local config = consumable_slots[i]
                if config ~= nil then
                    consumables[i] = bt.create_consumable_proxy(_scene, config)
                end
            end

            -- TODO
            --table.insert(statuses, bt.create_status_proxy(_scene, bt.StatusConfig("DEBUG_STATUS")))
            -- TODO

            table.insert(to_spawn, {
                id,
                moves,
                consumables,
                equips,
                statuses
            })
        end

        env.spawn(table.unpack(to_spawn))

        for global_status in values(battle:list_global_statuses()) do
            env.add_global_status(bt.create_global_status_proxy(_scene, global_status))
        end
    end



    return env
end