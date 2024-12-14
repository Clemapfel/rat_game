rt.settings.battle.simulation = {
    illegal_action_is_error = true
}

--- @brief
function bt.BattleScene:invoke(f, ...)
    if self._simulation_environment == nil then
        self._simulation_environment = self:create_simulation_environment()
    end
    debug.setfenv(f, self._simulation_environment)
    return f(...)
end

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

    --- @brief
    --- @param scene bt.BattleScene
    --- @param entity bt.Entity
    function bt.create_entity_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.Entity)

        local metatable = _create_proxy_metatable(bt.EntityProxy, scene, native)
        metatable._native = native
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.GlobalStatusConfig
    function bt.create_global_status_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.GlobalStatusConfig)

        local metatable = _create_proxy_metatable(bt.GlobalStatusProxy, scene, native)
        metatable._native = native
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.StatusConfig
    function bt.create_status_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.StatusConfig)

        local metatable = _create_proxy_metatable(bt.StatusProxy, scene, native)
        metatable._native = native
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.StatusConfig

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_consumable_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.ConsumableConfig)

        local metatable = _create_proxy_metatable(bt.ConsumableProxy, scene)
        metatable._native = native
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_equip_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.EquipConfig)

        local metatable = _create_proxy_metatable(bt.EquipProxy, scene)
        metatable._native = native
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_move_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.MoveConfig)

        local metatable = _create_proxy_metatable(bt.MoveProxy, scene)
        metatable._native = native
        return setmetatable({}, metatable)
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

    -- callback invocations

    --- @param callback_id String
    --- @param status_proxy bt.StatusProxy
    --- @param afflicted_proxy bt.EntityProxy
    local _try_invoke_status_callback = function(callback_id, status_proxy, entity_proxy, ...)
        bt.assert_args("_try_invoke_status_callback",
            callback_id, bt.String,
            status_proxy, bt.StatusProxy,
            entity_proxy, bt.EntityProxy
        )

        local status = _get_native(status_proxy)
        if status[callback_id] == nil then return end

        _push_current_move_user(nil)
        local afflicted_sprite = _scene._sprites[_get_native(entity_proxy)]
        local animation = bt.Animation.STATUS_APPLIED(_scene, status, afflicted_sprite)
        _scene:push_animation(animation)
        local out = _scene:invoke(status[callback_id], status_proxy, entity_proxy, ...)
        _pop_current_move_user()
        return out
    end

    --- @param callback_id String
    --- @param consumable_proxy bt.ConsumableProxy
    --- @param holder_proxy bt.EntityProxy
    local _try_invoke_consumable_callback = function(callback_id, consumable_proxy, holder_proxy, ...)
        bt.assert_args("_try_invoke_consumable_callback",
            callback_id, bt.String,
            consumable_proxy, bt.ConsumableProxy,
            holder_proxy, bt.EntityProxy
        )

        local consumable = _get_native(consumable_proxy)
        if consumable[callback_id] == nil then return end

        _push_current_move_user(nil)
        local entity = _get_native(consumable_proxy)

        local slot_i = _state:entity_get_consumable_slot_i(entity, consumable)
        if _state:entity_get_consumable_is_disabled(entity, slot_i) then
            return
        end

        local holder_sprite = _scene._sprites[entity]
        local animation = bt.Animation.CONSUMABLE_APPLIED(_scene, consumable, holder_sprite)
        _scene:push_animation(animation)
        local out = _scene:invoke(consumable[callback_id], consumable_proxy, holder_proxy, ...)
        _pop_current_move_user()
        return out
    end

    --- @param callback_id String
    --- @param global_status_proxy bt.GlobalStatusProxy
    local _try_invoke_global_status_callback = function(callback_id, global_status_proxy, ...)
        bt.assert_args("_try_invoke_global_status_callback",
            callback_id, bt.String,
            global_status_proxy, bt.GlobalStatusProxy
        )

        local global_status = _get_native(global_status_proxy)
        if global_status[callback_id] == nil then return end

        _push_current_move_user(nil)
        local animation = bt.Animation.GLOBAL_STATUS_APPLIED(_scene, global_status)
        _scene:push_animation(animation)
        local out = _scene:invoke(global_status[callback_id], global_status_proxy, ...)
        _pop_current_move_user()
        return out
    end

    --- @param callback_id String
    --- @param equip_proxy bt.EquipProxy
    local _try_invoke_equip_callback = function(callback_id, equip_proxy, ...)
        bt.assert_args("_try_invoke_equip_callback",
            callback_id, bt.String,
            equip_proxy, bt.EquipProxy
        )

        local equip = _get_native(equip_proxy)
        if equip[callback_id] == nil then return end

        _push_current_move_user(nil)
        local animation = bt.Animation.EQUIP_APPLIED(_scene, equip)
        _scene:push_animation(animation)
        local out = _scene:invoke(equip[callback_id], equip_proxy, ...)
        _pop_current_move_user()
        return out
    end

    --- @brief
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

    --- @brief get object id
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

    local _message = function(append_or_push, ...)
        local to_concat = {} -- table.concat does not invoke __concat metamethods
        for x in range(...) do
            table.insert(to_concat, tostring(x))
        end

        if append_or_push then
            _scene:append_animation(bt.Animation.MESSAGE(_scene, table.concat(to_concat, " ")))
        else
            _scene:push_animation(bt.Animation.MESSAGE(_scene, table.concat(to_concat, " ")))
        end
    end

    env.push_message = function(...) _message(false, ...) end
    env.append_message = function(...) _message(true, ...) end

    --- @brief
    env.message = env.append_message

    env.get_turn_i = function()
        return _state:get_turn_i()
    end

    --- @brief
    function env.entity_set_value(entity_proxy, name, new_value)
        bt.assert_args("entity_set_value",
            entity_proxy, bt.EntityProxy,
            name, bt.String
        )
        bt.assert_is_primitive("entity_set_value", new_value, 3)

        _state:entity_set_storage_value(_get_native(entity_proxy), name, new_value)
    end

    --- @brief
    function env.entity_get_value(entity_proxy, name)
        bt.assert_args("entity_get_value",
            entity_proxy, bt.EntityProxy,
            name, bt.String
        )
        return _state:entity_get_storage_value(_get_native(entity_proxy), name)
    end

    --- @brief
    function env.global_status_set_value(global_status_proxy, name, new_value)
        bt.assert_args("global_status_set_value",
            global_status_proxy, bt.GlobalStatusProxy,
            name, bt.String
        )
        bt.assert_is_primitive("global_status_set_value", new_value, 3)

        _state:set_global_status_storage_value(_get_native(global_status_proxy), name, new_value)
    end

    --- @brief
    function env.global_status_get_value(global_status_proxy, name, new_value)
        bt.assert_args("global_status_set_value",
            global_status_proxy, bt.GlobalStatusProxy,
            name, bt.String
        )

        return _state:get_global_status_storage_value(_get_native(global_status_proxy), name)
    end

    --- @brief
    function env.status_set_value(entity_proxy, status_proxy, name, new_value)
        bt.assert_args("status_set_value",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy,
            name, bt.String
        )
        bt.assert_is_primitive("status_set_value", new_value, 4)

        _state:entity_set_status_storage_value(_get_native(entity_proxy), _get_native(status_proxy), name, new_value)
    end

    --- @brief
    function env.status_get_value(entity_proxy, status_proxy, name, new_value)
        bt.assert_args("status_get_value",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy,
            name, bt.String
        )

        return _state:entity_get_status_storage_value(_get_native(entity_proxy), _get_native(status_proxy), name)
    end

    for which_type in range(
        {"consumable", bt.ConsumableProxy},
        {"move", bt.MoveProxy},
        {"equip", bt.EquipProxy}
    ) do
        local which, type = table.unpack(which_type)
        local name = which .. "_set_value"

        --- @brief consumable_set_value, move_set_value, equip_set_value
        env[name] = function(entity_proxy, object_proxy, name, new_value)
            bt.assert_args(name,
                entity_proxy, bt.EntityProxy,
                object_proxy, type
            )
            bt.assert_is_primitive(name, new_value, 4)

            local entity = _get_native(entity_proxy)
            local object = _get_native(object_proxy)
            local slot_i = _state["entity_get_" .. which .. "_slot_i"](_state, entity, object)
            _state["entity_set_" .. which .. "_storage_value"](_state, entity, slot_i, name, new_value)
        end

        --- @brief consumable_get_value, move_get_value, equip_get_value
        env[which .. "_get_value"] = function(entity_proxy, object_proxy, name, new_value)
            bt.assert_args(which .. "_get_value",
                entity_proxy, bt.EntityProxy,
                object_proxy, type
            )

            local entity = _get_native(entity_proxy)
            local object = _get_native(object_proxy)
            local slot_i = _state["entity_get_" .. which .. "_slot_i"](_state, entity, object)
            return _state["entity_get_" .. which .. "_storage_value"](_state, entity, slot_i, name)
        end
    end

    --- ### MOVE ###

    env.get_move_slot_n_used = function(entity_proxy, slot_i)
        bt.assert_args("get_move_slot_n_used",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local move = _state:entity_get_move(entity, slot_i)
        if move == nil then
            bt.error_function("In get_move_slot_n_used: entity `" .. entity.id .. "` has no move in slot `" .. slot_i .. "`")
            return
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
            bt.error_function("In get_move_slot_n_uses_left: entity `" .. entity.id .. "` has no move in slot `" .. slot_i .. "`")
            return
        end

        return move:get_max_n_uses() - env.get_move_slot_n_used(entity_proxy, slot_i)
    end

    env.get_move_n_uses_left = function(entity_proxy, move_proxy)
        bt.assert_args("get_move_n_uses_left",
            entity_proxy, bt.EntityProxy,
            move_proxy, bt.MoveProxy
        )

        local slot_i = _state:entity_get_move_slot_i(_get_native(entity_proxy), _get_native(move_proxy))
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
            bt.error_function("In set_move_slot_n_uses_left: entity `" .. entity.id .. "` has no move in slot `" .. slot_i .. "`")
            return
        end

        if n_left < 0 then
            bt.error_function("In env.set_move_n_uses_left: for entity `" .. env.get_id(entity_proxy) .. "`, move `" .. env.get_id(move_proxy ).. "`: count `" .. n_left .. "` is negative, it should be 0 or higher")
            n_left = 0
        end

        if math.fmod(n_left, 1) ~= 0 then
            rt.warning("In env.set_move_n_uses_left: for entity `" .. env.get_id(entity_proxy) .. "`, move `" .. env.get_id(move_proxy ).. "`: count `" .. n_left .. "` is non-integer")
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

        local slot_i = _state:entity_get_move_slot_i(_get_native(entity_proxy), _get_native(move_proxy))
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

    --- ### EQUIP ###

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

    env.apply_equip_slot = function(entity_proxy, slot_i)
        bt.assert_args("apply_equip",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local equip = _state:entity_get_equip(entity, slot_i)
        if equip == nil then return end

        if equip.effect ~= nil and (not _state:entity_get_equip_is_disabled(entity, slot_i)) then
            _push_current_move_user(nil)
            local equip_proxy = bt.create_equip_proxy(_scene, equip)
            local sprite = _scene:get_sprite(entity)
            local animation = bt.Animation.EQUIP_APPLIED(_scene, equip, sprite)
            _scene:push_animation(animation)
            env.append_message(rt.Translation.battle.message.equip_applied_f(entity_proxy, equip_proxy))
            local out = _scene:invoke(equip.effect, equip_proxy, entity_proxy)
            _pop_current_move_user()
            return out
        end
    end

    env.apply_equip = function(entity_proxy, equip_proxy)
        bt.assert_args("apply_equip",
            entity_proxy, bt.EntityProxy,
            equip_proxy, bt.EquipProxy
        )

        local slot_i = _state:entity_get_equip_slot_i(_get_native(entity_proxy), _get_native(equip_proxy))
        if slot_i == nil then
            bt.error_function("In env.apply_equip: entity `" .. entity_proxy.id .. "` does not have equip `" .. equip_proxy.id .. "` equipped")
            return
        else
            env.apply_equip_slot(entity_proxy, slot_i)
        end
    end

    --- ### CONSUMABLE ###

    env.get_consumable_max_n_uses = function(consumable_proxy)
        bt.assert_args("get_consumable_max_n_uses", consumable_proxy, bt.ConsumableProxy)
        return _get_native(consumable_proxy):get_max_n_uses()
    end

    env.get_consumable_slot_n_used = function(entity_proxy, slot_i)
        bt.assert_args("get_consumable_slot_n_used",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )
        return _state:entity_get_consumable_n_used(_get_native(entity_proxy), slot_i)
    end

    env.get_consumable_n_used = function(entity_proxy, consumable)
        bt.assert_args("get_consumable_n_used",
            entity_proxy, bt.EntityProxy,
            consumable, bt.ConsumableProxy
        )

        local slot_i = _state:entity_get_consumable_slot_i(_get_native(entity_proxy), _get_native(consumable))
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
            bt.error_function("In env.get_consumable_slot_n_uses_left: entity `" .. entity_proxy.id .. "` has no consumable in slot `" .. slot_i .. "`")
            return
        end

        local n_used = _state:entity_get_consumable_n_used(entity, slot_i)
        return consumable:get_max_n_uses() - n_used
    end

    env.get_consumable_n_uses_left = function(entity_proxy, consumable)
        bt.assert_args("get_consumable_n_uses_left",
            entity_proxy, bt.EntityProxy,
            consumable, bt.ConsumableProxy
        )

        local slot_i = _state:entity_get_consumable_slot_i(_get_native(entity_proxy), _get_native(consumable))
        return env.get_consumable_slot_n_uses_left(entity_proxy, slot_i)
    end

    env.get_consumable_slot = function(entity_proxy, slot_i)
        bt.assert_args("remove_consumable_slot",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local consumable = _state:entity_get_consumable(entity, slot_i)
        return bt.create_consumable_proxy(self, entity, consumable)
    end

    env.remove_consumable_slot = function(entity_proxy, slot_i)
        bt.assert_args("remove_consumable_slot",
            entity_proxy, bt.EntityProxy,
            slot_i, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local consumable = _state:entity_get_consumable(entity, slot_i)
        if consumable == nil then -- fizzle if slot is empty
            bt.error_function("In env.remove_consumable_slot: entity `" .. entity_proxy.id .. "` has no consumable in slot ´" .. slot_i .. "`")
            return
        end

        _state:entity_remove_consumable(entity, slot_i)

        local sprite = self._sprites[entity]
        local animation = bt.Animation.OBJECT_LOST(_scene, consumable, sprite)

        animation:signal_connect("start", function(_)
            sprite:remove_consumable(slot_i)
        end)

        _scene:push_animation(animation)

        local consumable_proxy = bt.create_consumable_proxy(_scene, consumable)
        env.message(rt.Translation.battle.message.consumable_removed_f(entity_proxy, consumable_proxy))

        -- callbacks
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

        env.remove_consumable_slot(
            entity_proxy,
            _state:entity_get_consumable_slot_i(_get_native(entity_proxy), _get_native(consumable_proxy))
        )
    end

    env.get_consumable_count = function(entity_proxy, consumable_proxy)
        bt.assert_args("get_consumable_count",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )
        return select("#", _state:entity_get_consumable_slot_i(_get_native(entity_proxy), _get_native(consumable_proxy)))
    end

    env.add_consumable = function(entity_proxy, consumable_proxy)
        bt.assert_args("add_consumable",
            entity_proxy, bt.EntityProxy,
            consumable_proxy, bt.ConsumableProxy
        )

        local entity = _get_native(entity_proxy)
        local consumable = _get_native(consumable_proxy)

        env.push_message(rt.Translation.battle.message.consumable_added_f(entity_proxy, consumable_proxy))

        local new_slot = nil
        for i = 1, _state:entity_get_n_consumable_slots(entity) do
            if _state:entity_get_consumable(entity, i) == nil then
                new_slot = i
                break
            end
        end
        if new_slot == nil then
            env.push_message(rt.Translation.battle.message.consumable_no_space_f(entity_proxy, consumable_proxy))
            return
        end

        local sprite = self._sprites[entity]
        local animation = bt.Animation.OBJECT_GAINED(_scene, consumable, sprite)
        animation:signal_connect("finish", function(_)
            sprite:add_consumable(new_slot, consumable, consumable:get_max_n_uses())
        end)
        _scene:append_animation(animation)

        _state:entity_add_consumable(entity, new_slot, consumable)

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
            bt.error_function("In env.consume_consumable_slot: entity `" .. entity_proxy.id .. "` has no consumable in slot `" .. slot_i .. "`")
            return
        end

        local consumable_proxy = bt.create_consumable_proxy(_scene, consumable)

        local max = consumable:get_max_n_uses()
        if max == POSITIVE_INFINITY then return end

        local n_used = _state:entity_get_consumable_n_used(entity, slot_i)
        local used_up = max - (n_used + n) <= 0

        env.push_message(rt.Translation.battle.message.consumable_consumed_f(entity_proxy, consumable_proxy))

        local sprite = _scene:get_sprite(entity)
        if used_up then -- used up
            local animation = bt.Animation.CONSUMABLE_CONSUMED(_scene, consumable, sprite)
            animation:signal_connect("finish", function()
                sprite:remove_consumable(slot_i)
            end)
            _scene:append_animation(animation)

            _state:entity_set_consumable_n_used(entity, slot_i, 0)
            _state:entity_remove_consumable(entity, slot_i)
        else
            local animation = bt.Animation.CONSUMABLE_APPLIED(_scene, consumable, sprite)
            animation:signal_connect("start", function()
                sprite:set_consumable_n_uses_left(max - (n_used + n))
            end)

            _scene:append_animation(animation)
            _state:entity_set_consumable_n_used(entity, slot_i, n_used + n)
        end

        -- callbacks
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

        if _get_native(consumable_proxy):get_max_n_uses() == POSITIVE_INFINITY then return end
        local slot_i = _state:entity_get_consumable_slot_i(_get_native(entity_proxy), _get_native(consumable_proxy))
        env.consume_consumable_slot(entity_proxy, slot_i)
    end

    ---

    for which_proxy in range(
        { "move", bt.MoveProxy },
        { "equip", bt.EquipProxy },
        { "consumable", bt.ConsumableProxy }
    ) do
        local which, proxy = table.unpack(which_proxy)
        local list_name = "list_" .. which .. "s"
        local has_name = "has_" .. which
        local get_disabled_name = "get_" .. which .. "_is_disabled"
        local get_slot_name = "get_" .. which .. "_slot_is_disabled"
        local set_slot_disabled_name = "set_" .. which .. "_slot_is_disabled"
        local set_disabled_name = "set_" .. which .. "_is_disabled"
        local add_name = "add_" .. which
        local remove_name = "remove_" .. which
        local remove_slot_name = "remove_" .. which .. "_slot"

        --- @brief has_move, has_equip, has_consumable
        env[has_name] = function(entity_proxy, object_proxy)
            bt.assert_args(has_name,
                entity_proxy, bt.EntityProxy,
                object_proxy, proxy
            )
            return _state["entity_has_" .. which](_state, _get_native(entity_proxy), _get_native(object_proxy))
        end

        --- @brief list_moves, list_equips, list_consumables
        env[list_name] = function(entity_proxy)
            bt.assert_args(list_name, entity_proxy, bt.EntityProxy)
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

        --- @brief get_move_is_disabled, get_equip_is_disabled, get_consumable_is_disabled
        env[get_disabled_name] = function(entity_proxy, object_proxy)
            bt.assert_args(get_disabled_name,
                entity_proxy, bt.EntityProxy,
                object_proxy, proxy
            )

            local entity, object = _get_native(entity_proxy), _get_native(object_proxy)
            if not _state["entity_has_" .. which](_state, entity, object) then
                bt.error_function("In env." .. get_disabled_name .. ": entity `" .. entity_proxy.id .. "` does not have `" .. object_proxy.id .. "` equipped")
                return false
            end

            local slot_i = _state["entity_get_" .. which .. "_slot_i"](_state, entity, object)
            return _state["entity_get_" .. which .. "_is_disabled"](_state, entity, slot_i)
        end

        --- @brief get_move_slot_is_disabled, get_equip_slot_is_disabled, get_consumable_slot_is_disabled
        env[get_slot_name] = function(entity_proxy, slot_i)
            bt.assert_args(get_slot_name,
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
        env[set_slot_disabled_name] = function(entity_proxy, slot_i, b)
            bt.assert_args(set_slot_disabled_name,
                entity_proxy, bt.EntityProxy,
                slot_i, bt.Number,
                b, bt.Boolean
            )

            local entity = _get_native(entity_proxy)
            local object = _state["entity_get_" .. which](_state, entity, slot_i)
            if object == nil then
                return -- fizzle if unequipped
            end

            local before = _state["entity_get_" .. which .. "_is_disabled"](_state, entity, slot_i)
            local now = b
            _state["entity_set_" .. which .. "_is_disabled"](_state, entity, slot_i, b)

            if before ~= now then -- fizzle unless state changes
                local object_proxy = bt["create_" .. which .. "_proxy"](_scene, object)
                local sprite, animation = _scene:get_sprite(entity), nil
                if before == false and now == true then
                    _scene:push_animation(bt.Animation.OBJECT_DISABLED(_scene, object, sprite))
                    env.message(rt.Translation.battle.message.object_disabled_f(entity_proxy, object_proxy))

                    -- callbacks
                    local callback_id = "on_" .. which .. "_disabled"
                    for status_proxy in values(env.list_statuses(entity_proxy)) do
                        _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, object_proxy)
                    end

                    for consumable_proxy in values(env.list_consumables(entity_proxy)) do
                        _try_invoke_consumable_callback(callback_id, consumable_proxy, entity_proxy, object_proxy)
                    end

                    for global_status_proxy in values(env.list_global_statuses()) do
                        _try_invoke_global_status_callback(callback_id, global_status_proxy, entity_proxy, object_proxy)
                    end
                elseif before == true and now == false then
                    _scene:push_animation(bt.Animation.OBJECT_ENABLED(_scene, object, sprite))
                    env.message(rt.Translation.battle.message.object_no_longer_disabled_f(entity_proxy, object_proxy))
                    -- no callbacks on enable
                end
            end
        end

        --- @brief set_move_is_disabled, set_equip_is_disabled, set_consumable_is_disabled
        env[set_disabled_name] = function(entity_proxy, object_proxy, b)
            bt.assert_args(set_disabled_name,
                entity_proxy, bt.EntityProxy,
                object_proxy, proxy,
                b, bt.Boolean
            )

            local slot_i = _state["entity_get_" .. which .. "_slot_i"](_state, _get_native(entity_proxy), _get_native(object_proxy))
            if slot_i == nil then
                return -- fizzle if not equipped
            else
                env[set_slot_disabled_name](entity_proxy, slot_i, b)
            end
        end
    end

    --- ### GLOBAL STATUS ###

    env.list_global_statuses = function()
        local out = {}
        for global_status in values(_state:list_global_statuses()) do
            table.insert(out, bt.create_global_status_proxy(_scene, global_status))
        end
        return out
    end

    env.add_global_status = function(global_status_proxy)
        bt.assert_args("add_global_status", global_status_proxy, bt.GlobalStatusProxy)

        local global_status = _get_native(global_status_proxy)
        if _state:has_global_status(global_status) then -- prevent double status
            return
        end

        local animation = bt.Animation.GLOBAL_STATUS_GAINED(_scene, global_status)
        animation:signal_connect("start", function(_)
            _scene:add_global_status(global_status, global_status:get_max_duration())
        end)
        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.global_status_added_f(global_status_proxy))

        _state:add_global_status(global_status)

        -- callbacks
        _try_invoke_global_status_callback("on_gained", global_status_proxy)

        local callback_id = "on_global_status_gained"
        for entity in values(_state:list_entities()) do
            local entity_proxy = bt.create_entity_proxy(_scene, entity)
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                _try_invoke_status_callback(callback_id, status_proxy, entity_proxy, global_status_proxy)
            end
        end

        for entity in values(_state:list_entities()) do
            -- separate for loop to preserve status < consumable < global_status invocation order
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
        bt.assert_args("remove_global_status", global_status_proxy, bt.GlobalStatusProxy)

        local global_status = _get_native(global_status_proxy)
        if not _state:has_global_status(global_status) then
            return -- fizzle
        end

        local animation = bt.Animation.GLOBAL_STATUS_LOST(_scene, global_status)
        animation:signal_connect("finish", function(_)
            _scene:remove_global_status(global_status)
        end)

        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.global_status_removed_f(global_status_proxy))

        _state:remove_global_status(global_status)

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
            if other_global_status_proxy ~= global_status_proxy then
                _try_invoke_global_status_callback(callback_id, other_global_status_proxy, global_status_proxy)
            end
        end
    end

    env.has_global_status = function(global_status_proxy)
        bt.assert_args("has_global_status", global_status_proxy, bt.GlobalStatusProxy)
        return _state:has_global_status(_get_native(global_status_proxy))
    end

    env.get_global_status_max_duration = function(global_status_proxy)
        bt.assert_args("has_global_status", global_status_proxy, bt.GlobalStatusProxy)
        return _get_native(global_status_proxy):get_max_duration()
    end

    env.get_global_status_n_turns_elapsed = function(global_status_proxy)
        bt.assert_args("has_global_status", global_status_proxy, bt.GlobalStatusProxy)
        return _state:get_global_status_n_turns_elapsed(_get_native(global_status_proxy))
    end

    env.get_global_status_n_turns_left = function(global_status_proxy)
        bt.assert_args("has_global_status", global_status_proxy, bt.GlobalStatusProxy)
        local max = env.get_global_status_max_duration(global_status_proxy)
        local elapsed = env.get_global_status_n_turns_elapsed(global_status_proxy)
        return max - elapsed
    end

    --- ### STATUS ###

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

    env.add_status = function(entity_proxy, status_proxy)
        bt.assert_args("add_status",
            entity_proxy, bt.EntityProxy,
            status_proxy, bt.StatusProxy
        )

        local entity, status = _get_native(entity_proxy), _get_native(status_proxy)
        if _state:entity_has_status(entity, status) then
            -- if already there, invoke callback, then fizzle
            for other_status_proxy in values(env.list_statuses()) do
                if env.get_id(status_proxy) == env.get_id(other_status_proxy) then
                    _try_invoke_status_callback("on_already_present", other_status_proxy)
                end
            end
            return
        end

        if env.is_dead(entity_proxy) or env.is_knocked_out(entity_proxy) then
            return
        end

        local sprite = _scene:get_sprite(entity)
        local animation = bt.Animation.STATUS_GAINED(_scene, status, sprite)
        animation:signal_connect("start", function(_)
            sprite:add_status(status, status:get_max_duration())
        end)
        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.status_added_f(entity_proxy, status_proxy))

        _state:entity_add_status(entity, status)

        -- callbacks
        _try_invoke_status_callback("on_gained", status_proxy, entity_proxy)

        local callback_id = "on_status_gained"
        for other_status_proxy in values(env.list_statuses(entity_proxy)) do
            if other_status_proxy ~= status then
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

        local sprite = _scene:get_sprite(entity)
        local animation = bt.Animation.STATUS_GAINED(_scene, status, sprite)
        animation:signal_connect("finish", function(_)
            sprite:remove_status(status)
        end)

        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.status_removed_f(entity_proxy, status_proxy))

        _state:entity_remove_status(entity, status)

        _try_invoke_status_callback("on_lost", status_proxy, entity_proxy)

        local callback_id = "on_status_lost"
        for other_status_proxy in values(env.list_statuses(entity_proxy)) do
            if other_status_proxy ~= status then
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

    --- ### ENTITY ###

    function env.list_entities()
        local out = {}
        for entity in values(_state:list_entities_in_order()) do
            table.insert(out, bt.create_entity_proxy(_scene, entity))
        end
        return out
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

    function env.list_party_of(entity_proxy)
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

    function env.get_hp(entity_proxy)
        bt.assert_args("get_hp", entity_proxy, bt.EntityProxy)
        return _state:entity_get_hp(_get_native(entity_proxy))
    end

    function env.get_priority(entity_proxy)
        bt.assert_args("get_priority", entity_proxy, bt.EntityProxy)
        return _state:entity_get_priority(_get_native(entity_proxy))
    end

    function env.set_priority(entity_proxy, value)
        bt.assert_args("add_priority",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        local before = env.get_priority(entity_proxy)
        local after = value
        if before == after then return end

        local entity = _get_native(entity_proxy)
        _state:entity_set_priority(entity, value)

        local animation = rt.Animation.PRIORITY_CHANGED(
            _scene,
            _scene:get_sprite(entity),
            ternary(before < after, rt.Direction.UP, rt.Direction.DOWN)
        )

        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.priority_raised_f(entity_proxy, after))

        -- no callbacks
    end

    for which in range(
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
        "is_stunned"
    ) do
        --- @brief get_hp_base, get_attack, get_defense, get_speed, get_attack_base, get_defense_base, get_speed_base, get_attack_base_raw, get_defense_base_raw, get_speed_base_raw, get_n_move_slots, get_n_consumable_slots, get_n_equip_slots, get_is_stunned
        env["get_" .. which] = function(entity_proxy)
            bt.assert_args("get_" .. which, entity_proxy, bt.EntityProxy)
            local native = _get_native(entity_proxy)
            return _state["entity_get_" .. which](_state, native)
        end
    end

    for which_proxy in range(
        {"list_move_slots", bt.create_move_proxy},
        {"list_equip_slots", bt.create_equip_proxy},
        {"list_consumable_slots", bt.create_consumable_proxy}
    ) do
        local which, proxy_f = table.unpack(which_proxy)
        --- @brief list_move_slots, list_equip_slots, list_consumable_slots
        env[which] = function(entity_proxy)
            bt.assert_args(which, entity_proxy, bt.EntityProxy)
            local n, slots = _state["entity_" .. which](_state, _get_native(entity_proxy))
            local out = {}
            for i = 1, n do
                if slots[i] ~= nil then
                    out[i] = proxy_f(_scene, slots[i])
                end
            end

            return n, out
        end
    end

    for which in range(
        "move",
        "equip",
        "consumable"
    ) do
        env["get_" .. which] = function(entity_proxy, slot_i)
            bt.assert_args("get_" .. which,
                entity_proxy, bt.EntityProxy,
                slot_i, bt.Number
            )
            return _state["entity_get_" .. which](_state, _get_native(entity_proxy), slot_i)
        end
    end

    env.ENTITY_STATE_ALIVE = bt.EntityState.ALIVE
    env.ENTITY_STATE_KNOCKED_OUT = bt.EntityState.KNOCKED_OUT
    env.ENTITY_STATE_DEAD = bt.EntityState.DEAD

    env.get_state = function(entity_proxy)
        bt.assert_args("get_state", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy))
    end

    env.is_alive = function(entity_proxy)
        bt.assert_args("is_alive", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.ALIVE
    end

    env.is_dead = function(entity_proxy)
        bt.assert_args("is_dead", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.DEAD
    end

    env.is_knocked_out = function(entity_proxy)
        bt.assert_args("is_knocked_out", entity_proxy, bt.EntityProxy)
        return _state:entity_get_state(_get_native(entity_proxy)) == bt.EntityState.KNOCKED_OUT
    end

    env.knock_out = function(entity_proxy)
        bt.assert_args("knock_out", entity_proxy, bt.EntityProxy)
        local entity = _get_native(entity_proxy)

        if _state:entity_get_state(entity) ~= bt.EntityState.ALIVE then
            return -- fizzle on dead or already knocked out
        end

        local sprite = _scene:get_sprite(entity)
        local animation
        if _state:entity_get_is_enemy(entity) then
            animation = bt.Animation.ENEMY_KNOCKED_OUT(_scene, sprite)
        else
            animation = bt.Animation.ALLY_KNOCKED_OUT(_scene, sprite)
        end

        animation:signal_connect("start", function(_)
            sprite:set_hp(0)
        end)

        animation:signal_connect("finish", function(_)
            sprite:set_state(bt.EntityState.KNOCKED_OUT)
        end)

        _scene:push_animation(animation)

        local status_backup = {}
        for proxy in values(env.list_statuses(entity_proxy)) do
            table.insert(status_backup, proxy)
        end

        -- clear state
        _state:entity_set_state(entity, bt.EntityState.KNOCKED_OUT)
        for proxy in values(status_backup) do
            _state:entity_remove_status(entity, _get_native(proxy))
            -- does not remove set_value, so they are still available for callbacks
        end
        _state:entity_set_hp(entity, 0)

        -- callbacks
        for status_proxy in values(status_backup) do
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
            _try_invoke_global_status_callback("on_knocked_out", global_status_proxy, entity_proxy, user_proxy)
        end

        -- now clear values
        for status_proxy in values(status_backup) do
            _state:entity_replace_storage_value(entity, _get_native(status_proxy), {})
        end
        -- consumable stays, so storage stays too
    end

    env.help_up = function(entity_proxy)
        bt.assert_args("help_up", entity_proxy, bt.EntityProxy)

        if env.is_dead(entity_proxy) or not env.is_knocked_out(entity_proxy) then
            return
        end

        local statuses_backup = env.list_statuses(entity_proxy)

        local entity = _get_native(entity_proxy)
        _state:entity_set_state(entity, bt.EntityState.KNOCKED_OUT)
        _state:entity_set_hp(entity, 0)
        _state:entity_clear_statuses(entity)

        local sprite = _scene:get_sprite(entity)
        local animation = bt.Animation.KNOCKED_OUT(_scene, sprite)
        animation:signal_connect("start", function(_)
            sprite:set_hp(0)
            sprite:set_state(bt.EntityState.KNOCKED_OUT)

            for status_proxy in values(statuses_backup) do
                sprite:remove_status(_get_native(status_proxy))
            end
        end)

        animation:signal_connect("finish", function(_)
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.knocked_out_f(entity_proxy))

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
            _try_invoke_global_status_callback("on_helped_up", global_status_proxy, entity_proxy, user_proxy)
        end
    end

    env.kill = function(entity_proxy)
        bt.assert_args("kill", entity_proxy, bt.EntityProxy)
        if env.is_dead(entity_proxy) then return end

        local entity = _get_native(entity_proxy)
        local sprite = _scene:get_sprite(entity)

        local statuses_backup = env.list_statuses(entity_proxy)
        local consumables_backup = env.list_consumables(entity_proxy)

        local animation = bt.Animation.KILL(self, sprite)
        animation:signal_connect("start", function(_)
            sprite:set_hp(0)
            sprite:set_state(bt.EntityState.DEAD)
            for status_proxy in values(statuses_backup) do
                sprite:remove_status(_get_native(status_proxy))
            end

            for i = 1, env.get_n_consumable_slots(entity_proxy) do
                sprite:remove_consumable(i)
            end

            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        animation:signal_connect("finish", function(_)
            _scene:remove_entity(entity)
        end)

        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.killed_f(entity_proxy))

        _state:entity_set_state(entity, bt.EntityState.DEAD)
        _state:entity_set_hp(entity, 0)

        -- callbacks after death
        for status_proxy in values(statuses_backup) do
            _try_invoke_status_callback("on_killed", status_proxy, entity_proxy)
        end

        _state:entity_clear_statuses(entity) -- delayed to after status callbacks

        for consumable_proxy in values(consumables_backup) do
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
            _try_invoke_global_status_callback("on_killed", global_status_proxy, entity_proxy, user_proxy)
        end
    end

    env.revive = function(entity_proxy)
        bt.assert_args("revive", entity_proxy, bt.EntityProxy)

        if env.is_dead(entity_proxy) ~= true then return end

        local entity = _get_native(entity_proxy)
        _state:entity_set_state(entity, bt.EntityState.ALIVE)
        _state:entity_set_hp(entity, 1)

        local animation = bt.Animation.REVIVE(self, nil)
        animation:signal_connect("start", function(_)
            _scene:add_entity(_get_native(entity_proxy))

            local sprite = _scene:get_sprite(entity)
            animation._sprite = sprite

            for status_proxy in values(env.list_statuses(entity_proxy)) do
                local status = _get_native(status_proxy)
                sprite:add_status(_get_native(status_proxy), status:get_max_duration() - _state:entity_get_status_n_turns_elapsed(entity, status))
            end

            for i = 1, env.get_n_consumable_slots(entity_proxy) do
                local consumable = _state:entity_get_consumable(entity, i)
                if consumable ~= nil then
                    sprite:add_consumable(i, consumable, consumable:get_max_n_uses() - _state:entity_get_consumable_n_used(entity, i))
                end
            end

            sprite:set_hp(1)
            _scene:set_priority_order(_state:list_entities_in_order())
        end)

        _scene:push_animation(animation)

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

        local entity = _get_native(entity_proxy)
        if value < 0 then
            rt.warning("In env.add_hp: value `" .. value .. "` is negative, reducing hp of `" .. entity:get_id() .. "` instead")
            env.reduce_hp(entity_proxy, math.abs(value))
            return
        end

        local hp_current = env.get_hp(entity_proxy)
        local hp_base = env.get_hp_base(entity_proxy)
        if
            hp_current >= hp_base or value == 0 or
            env.is_knocked_out(entity_proxy) or
            env.is_dead(entity_proxy)
        then
            return
        end

        local difference = value -- no clamp
        local sprite = _scene:get_sprite(entity)
        local animation = bt.Animation.HP_GAINED(_scene, sprite, difference)

        animation:signal_connect("start", function(_)
            sprite:set_hp(clamp(hp_current + difference, 0, hp_base))
        end)

        _scene:push_animation(animation)
        env.message(rt.Translation.battle.message.hp_gained_f(entity_proxy, difference))

        _state:entity_set_hp(entity, hp_current + difference)

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

        local entity = _get_native(entity_proxy)
        if value < 0 then
            rt.warning("In env.reduce_hp: value `" .. value .. "` is negative, increasing hp of `" .. entity:get_id() .. "` instead")
            env.add_hp(entity_proxy, math.abs(value))
            return
        end

        if value == 0 or env.is_dead(entity_proxy) then
            -- if dead, fizzle
            return
        end

        if env.is_knocked_out(entity_proxy) then
            -- if knocked out, any damage > 0 kills
            env.kill(entity_proxy)
            return
        end

        local hp_before = env.get_hp(entity_proxy)
        local difference = value -- no clamp

        local sprite = _scene:get_sprite(entity)
        local animation = bt.Animation.HP_LOST(_scene, sprite, difference)

        animation:signal_connect("start", function(_)
            sprite:set_hp(hp_before - difference)
        end)

        _scene:push_animation(animation)
        env.message(rt.Translation.battle.message.hp_lost_f(entity_proxy, difference))

        _state:entity_set_hp(entity, clamp(hp_before - difference, 0))
        local hp_after = _state:entity_get_hp(entity)

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

        if hp_after == 0 then
            -- if reaching 0, knock out
            env.knock_out(entity_proxy)
            return
        end
    end

    env.set_hp = function(entity_proxy, value)
        bt.assert_args("reduce_hp",
            entity_proxy, bt.EntityProxy,
            value, bt.Number
        )

        local entity = _get_native(entity_proxy)
        local current = _state:entity_get_hp(entity)
        local diff = current - clamp(value, 0, _state:entity_get_hp_base(entity))
        if diff > 0 then
            env.add_hp(entity_proxy, diff)
        elseif diff < 0 then
            env.reduce_hp(entity_proxy, math.abs(diff))
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

    -- init valid entity IDs
    local _valid_entity_ids = {}
    for _, name in pairs(love.filesystem.getDirectoryItems(rt.settings.battle.entity.config_path)) do
        if string.match(name, "%.lua$") ~= nil then
            local id = string.gsub(name, "%.lua$", "")
            env[entity_prefix .. "_" .. id] = id
            _valid_entity_ids[id] = true
        end
    end

    env.spawn = function(entity_id, move_proxies, consumable_proxies, equip_proxies)
        if move_proxies == nil then move_proxies = {} end
        if consumable_proxies == nil then consumable_proxies = {} end
        if equip_proxies == nil then equip_proxies = {} end

        bt.assert_args("spawn",
            entity_id, bt.String,
            move_proxies, bt.Table,
            consumable_proxies, bt.Table,
            equip_proxies, bt.Table
        )

        if _valid_entity_ids[entity_id] ~= true then
            bt.error_function("In env.spawn: entity id `" .. entity_id .. "` is not a valid entity config id")
            return
        end

        local entity = bt.Entity(_state, entity_id)
        _state:add_entity(entity)

        for move_proxy in values(move_proxies) do
            bt.assert_is_move_proxy("spawn", move_proxy, 2)
            _state:entity_add_move(entity, _get_native(move_proxy))
        end

        for consumable_proxy in values(consumable_proxies) do
            bt.assert_is_consumable_proxy("spawn", consumable_proxy, 3)
            _state:entity_add_consumable(entity, _get_native(consumable_proxy))
        end

        for equip_proxy in values(equip_proxies) do
            bt.assert_is_equip_proxy("spawn", equip_proxy, 4)
            _state:entity_add_equip(entity, _get_native(equip_proxy))
        end

        _scene:add_entity(entity)

        local entity_proxy = bt.create_entity_proxy(_scene, entity)
        local sprite = _scene:get_sprite(entity)
        sprite:set_is_visible(false)

        local animation
        if _state:entity_get_is_enemy(entity) then
            animation = bt.Animation.ENEMY_APPEARED(_scene, sprite)
        else
            animation = bt.Animation.ALLY_APPEARED(_scene, sprite)
        end

        _scene:push_animation(animation)

        -- invoke added items
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

    env.swap = function(entity_a_proxy, entity_b_proxy)
        bt.assert_args("swap",
            entity_a_proxy, bt.EntityProxy,
            entity_b_proxy, bt.EntityProxy
        )

        local entity_a, entity_b = _get_native(entity_a_proxy), _get_native(entity_b_proxy)
        if entity_a:get_is_enemy() ~= entity_b:get_is_enemy() then
            bt.error_function("In env.swap: entity `" .. entity_a:get_id() .. "` and entity `" .. entity_b:get_id() .. "` are ally and enemy, only entities on the same side can be swapped")
            return
        end

        if env.is_dead(entity_a_proxy) or env.is_dead(entity_a_proxy) then return end

        _state:entity_swap_indices(entity_a, entity_b)

        local a_sprite, b_sprite = _scene:get_sprite(entity_a), _scene:get_sprite(entity_b)
        local animation = bt.Animation.SWAP(_scene, a_sprite, b_sprite)
        animation:signal_connect("finish", function(_)
            if entity_a:get_is_enemy() then -- == entity_b:get_is_enemy()
                _scene:reformat_enemy_sprites()
            else
                _scene:reformat_party_sprites()
            end
        end)

        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.swap_f(entity_a_proxy, entity_b_proxy))

        -- sort by priority for deterministic ordering
        local a_index, b_index
        for i, entity in ipairs(_state:list_entities_in_order()) do
            if entity == entity_a then
                a_index = i
            elseif entity == entity_b then
                b_index = i
            end
            if a_index ~= nil and b_index ~= nil then break end
        end

        local first_entity, second_entity
        if a_index < b_index then
            first_entity, second_entity = entity_a_proxy, entity_b_proxy
        else
            first_entity, second_entity = entity_b_proxy, entity_a_proxy
        end

        local callback_id = "on_swap"
        for status_proxy in values(env.list_statuses(first_entity)) do
            _try_invoke_status_callback(callback_id, status_proxy, first_entity, second_entity)
        end

        for status_proxy in values(env.list_statuses(entity_b_proxy)) do
            _try_invoke_status_callback(callback_id, status_proxy, second_entity, first_entity)
        end

        for consumable_proxy in values(env.list_consumables(first_entity)) do
            _try_invoke_consumable_callback(callback_id, consumable_proxy, first_entity, second_entity)
        end

        for consumable_proxy in values(env.list_consumables(entity_b_proxy)) do
            _try_invoke_consumable_callback(callback_id, consumable_proxy, second_entity, first_entity)
        end

        for global_status_proxy in values(env.list_global_statuses()) do
            _try_invoke_global_status_callback(callback_id, global_status_proxy, first_entity, second_entity)
        end
    end

    --- ### COMMON ###

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

        -- factors
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

        -- offsets
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

        value = value - env.get_defense(defending_entity_proxy) -- TODO?

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
        bt.assert_args("compute_damage",
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

        return value
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

        local target_proxies = { ...}
        for target in values(target_proxies) do
            bt.assert_args("use_move", target, bt.EntityProxy)
            table.insert(target_proxies, target)
        end

        _push_current_move_user(user_proxy)
        local move = _get_native(move_proxy)
        if move.effect == nil then
            bt.error_function("In use_move: move `" .. move:get_id() .. "` has no `effect` function")
            return
        end

        do
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

        _scene:invoke(move.effect, move, user_proxy, target_proxies)
        _pop_current_move_user()
    end

    env.start_turn = function()
        local animation = bt.Animation.TURN_START(_scene)
        _scene:push_animation(animation)

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
            _try_invoke_global_status_callback(callback_id, global_status_proxy)
        end
    end

    env.end_turn = function()
        -- enumerate all entities including dead to determined end of battle
        -- delayed to end of turn to allow for passive reviving

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

        if (n_dead_enemies + n_knocked_out_enemies) == n_enemies then
            env.win_battle()
            return
        end

        local animation = bt.Animation.TURN_END(_scene)
        animation:signal_connect("finish", function(_)
            if _state:get_quicksave_exists() then
                _scene._quicksave_indicator:set_n_turns_elapsed(_state:get_quicksave_n_turns_elapsed() + 1)
                -- increased in state only after callbacks
            end
        end)
        _scene:push_animation(animation)

        -- callbacks

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

        -- remove expired statuses

        for entity_proxy in values(entity_proxies) do
            local entity = _get_native(entity_proxy)
            local to_remove = {}
            for status_proxy in values(env.list_statuses(entity_proxy)) do
                local status = _get_native(status_proxy)
                local n = _state:entity_get_status_n_turns_elapsed(entity, status)
                if _state:entity_set_status_n_turns_elapsed(entity, status, n + 1) then
                    table.insert(to_remove, status_proxy)
                end
            end

            for status_proxy in values(to_remove) do
                env.remove_status(entity_proxy, status_proxy)
            end
        end

        do
            local to_remove = {}
            for global_status_proxy in values(env.list_global_statuses()) do
                local global_status = _get_native(global_status_proxy)
                local n = _state:get_global_status_n_turns_elapsed(global_status)
                if _state:set_global_status_n_turns_elapsed(global_status, n + 1) then
                    table.insert(to_remove, global_status_proxy)
                end
            end

            for global_status_proxy in values(to_remove) do
                env.remove_global_status(global_status_proxy)
            end
        end
        
        -- increment turn counter
        _state:set_turn_i(_state:get_turn_i() + 1)

        -- reset priority
        for entity in values(_state:list_all_entities()) do
            _state:entity_set_priority(entity, 0)
        end
    end

    env.quicksave = function()
        local texture = _state:create_quicksave()
        local animation = rt.Animation.QUICKSAVE(self, _scene._quicksave_indicator, texture)
        animation:signal_connect("finish", function(_)
            _scene._quicksave_indicator:set_n_turns_elapsed(0)
        end)
        _scene:push_animation(animation)
        env.append_message(rt.Translation.battle.message.quicksave_created_f())
    end

    env.quickload = function()
        if _state:has_quicksave() == false then
            bt.error_function("In env.quickload: trying to load a quicksave, but none is present")
            return
        end

        _state:load_quicksave()
        local animation = rt.Animation.QUICKLOAD(self, _scene._quicksave_indicator)
        animation:signal_connect("finish", function(_)
            _scene._quicksave_indicator:set_screenshot(nil)
            _scene:create_from_state(self._state)
        end)
        _scene:push_animation(animation)
        env.push_message(rt.Translation.battle.message.quicksave_loaded_f())
    end

    env.start_battle = function(id)
        local battle = bt.BattleConfig(id)

        -- clear state if present
        for enemy in values(_state:list_all_enemies()) do
            _state:remove_entity(enemy)
        end

        for global_status in values(_state:list_global_statuses()) do
            _state:remove_global_status(global_status)
        end

        local animations = {}

        local n_enemies = battle:get_n_enemies()
        for enemy_i = 1, n_enemies do
            --rework animation to poll sprite on startup
            local entity = _state:create_entity(bt.EntityConfig(battle:get_enemy_id(enemy_i)))
            _state:entity_set_hp(entity, _state:entity_get_hp_base(entity))

            for move in values(battle:get_enemy_moves(enemy_i)) do
                _state:entity_add_move(entity, move)
            end

            for equip_i, equip in ipairs(battle:get_enemy_equips(enemy_i)) do
                _state:entity_add_equip(entity, equip_i, equip)
            end

            for consumable_i, consumable in ipairs(battle:get_enemy_consumables(enemy_i)) do
                _state:entity_add_consumable(entity, consumable_i, consumable)
            end

            for status in values(battle:get_enemy_statuses(enemy_i)) do
                _state:entity_add_status(entity, status)
            end
        end

        for global_status in values(battle:get_global_statuses()) do
            _state:add_global_status(global_status)
        end

        _scene:create_from_state()
    end

    env.win_battle = function()
        -- TODO
    end

    env.loose_battle = function()
        -- TODO
    end

    env.finish_battle = function()
        -- TODO
    end

    return env
end

function bt.BattleScene:_test_simulation()
    self._simulation_environment = self:create_simulation_environment()
    local env = self._simulation_environment
    local entity = self._state:list_enemies()[1]
    local target = bt.create_entity_proxy(self, entity)
    local status = bt.create_status_proxy(self, bt.StatusConfig("DEBUG_STATUS"))
    local move = bt.create_move_proxy(self, self._state:entity_list_moves(entity)[1])
    local equip = bt.create_equip_proxy(self, self._state:entity_list_equips(entity)[1])
    local consumable = bt.create_consumable_proxy(self, self._state:entity_list_consumables(entity)[1])
    local global_status = bt.create_global_status_proxy(self, bt.GlobalStatusConfig("DEBUG_GLOBAL_STATUS"))

    do -- test moves
        local found = false
        for proxy in values(env.list_moves(target)) do
            if proxy == move then found = true; break; end
        end
        assert(found)
        assert(env.has_move(target, move))
        env.set_move_is_disabled(target, move, true)
        assert(env.get_move_is_disabled(target, move) == true)
        env.set_move_is_disabled(target, move, false)
        assert(env.get_move_is_disabled(target, move) == false)
        assert(meta.is_number(env.get_move_n_used(target, move)))
        assert(meta.is_number(env.get_move_max_n_uses(move)))
        assert(meta.is_number(env.get_move_n_uses_left(target, move)))
        env.set_move_n_uses_left(target, move, 0)
        assert(meta.is_number(env.get_move_priority(move)))
        for which in range(
            "is_intrinsic",
            "can_target_multiple",
            "can_target_self",
            "can_target_ally"
        ) do
            assert(meta.is_boolean(env["get_move_" .. which](move)))
        end
    end

    do -- test equips
        local list = env.list_equips(target)
        assert(sizeof(list) > 0)

        local equip = list[1]
        assert(env.has_equip(target, equip))
        env.set_equip_is_disabled(target, equip, true)
        assert(env.get_equip_is_disabled(target, equip) == true)
        env.set_equip_is_disabled(target, equip, false)
        assert(env.get_equip_is_disabled(target, equip) == false)

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
            assert(meta.is_number(env["get_equip_" .. which](equip)))
        end

        env.apply_equip(target, equip)
    end

    do -- test consumables
        local list = env.list_consumables(target)
        assert(sizeof(list) > 0)

        local consumable = list[1]

        assert(env.has_consumable(target, consumable))
        env.set_consumable_is_disabled(target, consumable, true)
        assert(env.get_consumable_is_disabled(target, consumable) == true)
        env.set_consumable_is_disabled(target, consumable, false)
        assert(env.get_consumable_is_disabled(target, consumable) == false)

        assert(meta.is_number(env.get_consumable_max_n_uses(consumable)))
        assert(meta.is_number(env.get_consumable_n_uses_left(target, consumable)))
        assert(meta.is_number(env.get_consumable_n_used(target, consumable)))

        local before = env.get_consumable_count(target, consumable)
        env.remove_consumable(target, consumable)
        assert(env.get_consumable_count(target, consumable) == before - 1)
        env.add_consumable(target, consumable)
        assert(env.get_consumable_count(target, consumable) == before)

        env.consume_consumable(target, consumable)
        env.add_consumable(target, consumable)
    end

    self._animation_queue:clear()

    do -- test global status
        if self._state:has_global_status(getmetatable(global_status)._native) then
            self._state:remove_global_status(getmetatable(global_status)._native)
        end

        assert(env.has_global_status(global_status) == false)
        env.add_global_status(global_status)
        assert(env.has_global_status(global_status) == true)
        assert(sizeof(env.list_global_statuses) >= 1)
        assert(meta.is_number(env.get_global_status_max_duration(global_status)))
        assert(meta.is_number(env.get_global_status_n_turns_elapsed(global_status)))
        assert(meta.is_number(env.get_global_status_n_turns_left(global_status)))
        env.remove_global_status(global_status)
        assert(env.has_global_status(global_status) == false)

        env.add_global_status(global_status)
    end

    do -- test status
        assert(env.has_status(target, status) == false)
        env.add_status(target, status)
        assert(env.has_status(target, status) == true)
        assert(meta.is_number(env.get_status_n_turns_elapsed(status, target)))
        assert(meta.is_number(env.get_status_n_turns_left(status, target)))

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
            "max_duration"
        ) do
            assert(meta.is_number(env["get_status_" .. which](status)), which)
        end
        assert(meta.is_boolean(env.get_status_is_stun(status)))

        env.remove_status(target, status)
        assert(env.has_status(target, status) == false)

        env.add_status(target, status)
    end

    do -- test storage values
        local id, value = "test", 1234
        env.entity_set_value(target, id, value)
        assert(env.entity_get_value(target, id) == value)
        env.entity_set_value(target, id, nil)

        env.global_status_set_value(global_status, id, value)
        assert(env.global_status_get_value(global_status, id) == value)
        env.global_status_set_value(global_status, id, nil)

        env.status_set_value(target, status, id, value)
        assert(env.status_get_value(target, status, id) == value)
        env.status_set_value(target, status, id, nil)

        env.move_set_value(target, move, id, value)
        assert(env.move_get_value(target, move, id) == value)
        env.move_set_value(target, move, id, nil)

        env.equip_set_value(target, equip, id, value)
        assert(env.equip_get_value(target, equip, id) == value)
        env.equip_set_value(target, equip, id, nil)

        env.consumable_set_value(target, consumable, id, value)
        assert(env.consumable_get_value(target, consumable, id) == value)
        env.consumable_set_value(target, consumable, id, nil)
    end

    -- self._animation_queue:clear()
    rt.log("In bt.BattleScene:_test_simulation: all tests passed")
end