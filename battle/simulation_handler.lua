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
            _scene._animation_queue:push(animation)
        end
    end

    -- callback invocation

    local _invoke = function(f)
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
        if status[callback_id] == nil then return end

        if status:get_is_silent() ~= true then
            _queue_animation(bt.Animation.STATUS_APPLIED(_scene, status, _get_native(entity_proxy)))
            env.message(rt.Translation.battle.message.status_applied_f(entity_proxy, status_proxy))
        end

        _push_current_move_user(nil)
        _scene:invoke(status[callback_id], status_proxy, entity_proxy, ...)
        _pop_current_move_user()
    end

    local _try_invoke_consumable_callback = function(callback_id, consumable_proxy, holder_proxy, ...)
        bt.assert_args("_try_invoke_consumable_callback",
            callback_id, bt.String,
            consumable_proxy, bt.ConsumableProxy,
            holder_proxy, bt.EntityProxy
        )

        local consumable = _get_native(consumable_proxy)
        if consumable[callback_id] == nil then return end

        local entity = _get_native(holder_proxy)
        local slot_i = _state:entity_get_consumable_slot_i(entity, consumable)
        if _state:entity_get_consumable_is_disabled(entity, slot_i) then
            return
        end

        if consumable:get_is_silent() ~= true then
            _queue_animation(bt.Animation.CONSUMABLE_APPLIED(_scene, slot_i, entity))
            env.message(rt.Translation.battle.message.consumable_applied_f(holder_proxy, consumable_proxy))
        end

        _push_current_move_user(nil)
        _scene:invoke(consumable[callback_id], consumable_proxy, holder_proxy, ...)
        _pop_current_move_user()
    end

    local _try_invoke_global_status_callback = function(callback_id, global_status_proxy, ...)
        bt.assert_args("_try_invoke_global_status_callback",
            callback_id, bt.String,
            global_status_proxy, bt.GlobalStatusProxy
        )

        local global_status = _get_native(global_status_proxy)
        if global_status[callback_id] == nil then return end

        if global_status:get_is_silent() ~= true then
            _scene:push_animation(bt.Animation.GLOBAL_STATUS_APPLIED(_scene, global_status))
            env.message(rt.Translation.battle.message.global_status_applied_f(global_status_proxy))
        end

        _push_current_move_user(nil)
        _scene:invoke(global_status[callback_id], global_status_proxy, ...)
        _pop_current_move_user()
    end

    local _try_invoke_equip_callback = function(callback_id, equip_proxy, holder_proxy, ...)
        bt.assert_args("_try_invoke_equip_callback",
            callback_id, bt.String,
            equip_proxy, bt.EquipProxy,
            holder_proxy, bt.EntityProxy
        )

        local equip = _get_native(equip_proxy)
        if equip[callback_id] == nil then return end

        if equip:get_is_silent() ~= true then
            _scene:push_animation(bt.Animation.EQUIP_APPLIED(_scene, equip, _get_native(holder_proxy)))
            env.message(rt.Translation.battle.message.equip_applied_f(holder_proxy, equip_proxy))
        end

        _push_current_move_user(nil)
        _scene:invoke(equip[callback_id], equip_proxy, holder_proxy, ...)
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

    env.message = function(...)
        local to_concat = {} -- table.concat does not invoke __concat metamethods
        for x in range(...) do
            table.insert(to_concat, tostring(x))
        end

        _queue_animation(bt.Animation.MESSAGE(_scene, table.concat(to_concat, " ")))
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

        _state:set_global_status_storage_value(_get_native(global_status_proxy), name, new_value)
    end

    function env.global_status_get_value(global_status_proxy, name, new_value)
        bt.assert_args("global_status_set_value",
            global_status_proxy, bt.GlobalStatusProxy,
            name, bt.String
        )

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

        local animation = bt.Animation.OBJECT_LOST(_scene, consumable, entity)
        animation:signal_connect("start", function(_)
            local sprite = _scene:get_sprite(entity)
            sprite:remove_consumable(slot_i)
        end)

        _new_animation_node()
        _queue_animation(animation)

        local consumable_proxy = bt.create_consumable_proxy(_scene, consumable)
        env.message(rt.Translation.battle.message.consumable_removed_f(entity_proxy, consumable_proxy))

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

        env.message(rt.Translation.battle.message.consumable_added_f(entity_proxy, consumable_proxy))
        if new_slot == nil then
            env.message(rt.Translation.battle.message.consumable_no_space_f(entity_proxy, consumable_proxy))
            return nil
        end

        _state:entity_add_consumable(entity, new_slot, consumable)

        local animation = bt.Animation.OBJECT_GAINED(_scene, consumable, entity)
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
        if was_used_up then
            _state:entity_remove_consumable(entity, slot_i)

            animation = bt.Animation.CONSUMABLE_CONSUMED(_scene, consumable, entity)
            animation:signal_connect("finish", function()
                _scene:get_sprite(entity):remove_consumable(slot_i)
            end)
        else
            animation = bt.Animation.CONSUMABLE_APPLIED(_scene, consumable, entity)
            animation:signal_connect("start", function()
                _scene:get_sprite(entity):set_consumable_n_uses_left(max - (n_used + n))
            end)
        end

        env.message(rt.Translation.battle.message.consumable_consumed_f(entity_proxy, consumable_proxy))
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

            if before ~= now then
                _state["entity_set_" .. which .. "_is_disabled"](_state, entity, slot_i, b)

                local object_proxy = bt["create_" .. which .. "_proxy"](_scene, object)
                _new_animation_node()

                if before == false and now == true then
                    _queue_animation(bt.Animation.OBJECT_DISABLED(_scene, object, entity))
                    env.message(rt.Translation.battle.message.object_disabled_f(entity_proxy, object_proxy))
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
                _scene:push_animation(bt.Animation.OBJECT_ENABLED(_scene, object, entity))
                env.message(rt.Translation.battle.message.object_no_longer_disabled_f(entity_proxy, object_proxy))
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

        local animation = bt.Animation.GLOBAL_STATUS_GAINED(_scene, global_status)
        animation:signal_connect("start", function(_)
            _scene:add_global_status(global_status, global_status:get_max_duration())
        end)
        _queue_animation(animation)
        env.message(rt.Translation.battle.message.global_status_added_f(global_status_proxy))

        _new_animation_node()

        _try_invoke_global_status_callback("on_gained", global_status_proxy)

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
            if _get_native(other_global_status_proxy) ~= _get_native(global_status_proxy) then
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

        local animation = bt.Animation.GLOBAL_STATUS_LOST(_scene, global_status)
        animation:signal_connect("finish", function(_)
            _scene:remove_global_status(global_status)
        end)
        _queue_animation(animation)
        env.message(rt.Translation.battle.message.global_status_removed_f(global_status_proxy))

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

        if env.is_dead(entity_proxy) or env.is_knocked_out(entity_proxy) then
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

        local animation = bt.Animation.STATUS_GAINED(_scene, status, entity)
        animation:signal_connect("start", function(_)
            _scene:get_sprite(entity):add_status(status, status:get_max_duration())
        end)
        _queue_animation(animation)
        env.message(rt.Translation.battle.message.status_added_f(entity_proxy, status_proxy))

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

        local animation = bt.Animation.STATUS_GAINED(_scene, status, entity)
        animation:signal_connect("finish", function(_)
            _scene:get_sprite(entity):remove_status(status)
        end)

        _scene:push_animation(animation)
        env.message(rt.Translation.battle.message.status_removed_f(entity_proxy, status_proxy))

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

end