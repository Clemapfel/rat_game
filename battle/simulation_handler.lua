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

do
    local _eq = function(self, other) return self.id == other.id end

    local _tostring = function(self)
        return bt.format_name(self)
    end

    local _index = function(self, key)
        if key == "id" then return getmetatable(self)._native:get_id() end
        bt.error_function("In bt.EntityProxy.__index: trying to access proxy directly, but it can only be accessed with outer functions, use `get_*` instead")
        return nil
    end

    local _newindex = function(self, key)
        bt.error_function("In bt.EntityProxy.__newindex: trying to modify proxy directly, but it can only be accessed with outer functions, use `set_*` instead")
    end

    local _create_proxy_metatable = function(type, scene)
        return {
            _type = type,
            _scene = scene,
            _native = nil,
            __eq = _eq,
            __tostring = _tostring,
            __index = _index,
            __newindex = _newindex
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
    --- @param status bt.GlobalStatus
    function bt.create_global_status_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.GlobalStatus)

        local metatable = _create_proxy_metatable(bt.GlobalStatusProxy, scene, native)
        metatable._native = native
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.Status
    function bt.create_status_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.Status)

        local metatable = _create_proxy_metatable(bt.StatusProxy, scene, native)
        metatable._native = native
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.Status

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_consumable_proxy(scene, native)
        meta.assert_isa(scene, bt.BattleScene)
        meta.assert_isa(native, bt.Consumable)

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
        meta.assert_isa(native, bt.Equip)

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
        meta.assert_isa(native, bt.Move)

        local metatable = _create_proxy_metatable(bt.MoveProxy, scene)
        metatable._native = native
        return setmetatable({}, metatable)
    end
end

--- ### ARG ASSERTION ###

bt.error_function = ternary(rt.settings.battle.simulation.illegal_action_is_error, rt.error, rt.warning)

for name_type_proxy in range(
    {"entity", bt.Entity, bt.EntityProxy},
    {"move", bt.Move, bt.MoveProxy},
    {"equip", bt.Equip, bt.EquipProxy},
    {"status", bt.Status, bt.StatusProxy},
    {"global_status", bt.GlobalStatus, bt.GlobalStatusProxy},
    {"consumable", bt.Consumable, bt.ConsumableProxy}
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
    {"is_entity_proxy", bt.EntityProxy},
    {"is_move_proxy", bt.MoveProxy},
    {"is_status_proxy", bt.StatusProxy},
    {"is_global_status_proxy", bt.GlobalStatusProxy},
    {"is_consumable_proxy", bt.ConsumableProxy},
    {"is_equip_proxy", bt.EquipProxy}
) do
    local which, type = table.unpack(which_type)

    --- @brief bt.assert_is_number, bt.assert_is_string, bt.assert_is_boolean, bt.assert_is_entity_proxy, bt.assert_is_status_proxy, bt.assert_is_global_status_proxy, bt.assert_is_consumable_proxy
    bt["assert_" .. which] = function(function_name, x, arg_i)
        if not meta[which](x) then
            local true_type = getmetatable(x)._type
            if true_type == nil then true_type = meta.typeof(x) end
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

    -- bind IDs of immutables to globals, used by add_status, spawn, etc.
    local entity_prefix = "ENTITY"
    local consumable_prefix = "CONSUMABLE"
    local equip_prefix = "EQUIP"
    local move_prefix = "MOVE"
    local global_status_prefix = "GLOBAL_STATUS"
    local status_prefix = "STATUS"

    for prefix_path_type_proxy in range(
        {consumable_prefix, rt.settings.battle.consumable.config_path, bt.Consumable, bt.create_consumable_proxy},
        {equip_prefix, rt.settings.battle.equip.config_path, bt.Equip, bt.create_equip_proxy},
        {move_prefix, rt.settings.battle.move.config_path, bt.Move, bt.create_move_proxy},
        {global_status_prefix, rt.settings.battle.global_status.config_path, bt.GlobalStatus, bt.create_global_status_proxy},
        {status_prefix, rt.settings.battle.status.config_path, bt.Status, bt.create_status_proxy}
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
        local afflicted_sprite = _scene._sprites[_get_native(entity_proxy)]
        local animation = bt.Animation.STATUS_APPLIED(_scene, status, afflicted_sprite)
        _scene:_push_animation(animation)
        return _scene:invoke(status[callback_id], status_proxy, entity_proxy, ...)
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

        local entity = _get_native(consumable_proxy)

        local slot_i = _state:entity_get_consumable_slot_i(entity, consumable)
        if _state:entity_get_consumable_is_disabled(entity, slot_i) then
            return
        end

        local holder_sprite = _scene._sprites[entity]
        local animation = bt.Animation.CONSUMABLE_APPLIED(_scene, consumable, holder_sprite)
        _scene:_push_animation(animation)
        _scene:invoke(consumable[callback_id], consumable_proxy, holder_proxy, ...)
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

        local animation = bt.Animation.GLOBAL_STATUS_APPLIED(_scene, global_status)
        _scene:_push_animation(animation)
        _scene:invoke(global_status[callback_id], global_status_proxy, ...)
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
        local n_args = select("#", ...)
        if n_args == 0 then return end

        local msg = {}
        for i = 1, n_args do
            local arg = select(i, ...)
            local native_maybe = getmetatable(arg)._native
            if native_maybe ~= nil then
                table.insert(msg, bt.format_name(native_maybe))
            else
                table.insert(msg, bt.format_name(arg))
            end
        end

        if append_or_push then
            _scene:_append_animation(bt.Animation.MESSAGE(_scene, table.concat(msg, " ")))
        else
            _scene:_push_animation(bt.Animation.MESSAGE(_scene, table.concat(msg, " ")))
        end
    end

    --- @brief
    env.message = function(...)  _message(true, ...) end
    env.queue_message = function(...) _message(false, ...) end

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

        --- ### MOVE ###

        env.list_moves = function(entity_proxy)
            bt.assert_args("list_moves", entity_proxy, bt.EntityProxy)
            local out = {}
            local n, slots = _state:entity_list_move_slots(_get_native(entity_proxy))
            for i = 1, n do
                local move = slots[i]
                if move ~= nil then
                    table.insert(out, bt.create_move_proxy(_scene, move))
                end
            end

            return out
        end

        env.has_move = function(entity_proxy, move_proxy)
            bt.assert_args("has_move",
                entity_proxy, bt.EntityProxy,
                move_proxy, bt.MoveProxy
            )
            return _state:entity_has_move(_get_native(entity_proxy), _get_native(move_proxy))
        end

        env.get_move_n_used = function(entity_proxy, move_proxy)
            bt.assert_args("get_move_n_used",
                entity_proxy, bt.EntityProxy,
                move_proxy, bt.MoveProxy
            )

            local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
            if not _state:entity_has_move(entity, move) then
                return 0
            else
                local slot_i = _state:entity_get_move_slot_i(entity, move)
                return _state:entity_get_move_n_used(_get_native(entity_proxy), slot_i)
            end
        end

        env.get_move_max_n_uses = function(move_proxy)
            bt.assert_args("get_move_max_n_uses", move_proxy, bt.MoveProxy)
            return _get_native(move_proxy):get_max_n_uses()
        end

        env.get_move_n_uses_left = function(entity_proxy, move_proxy)
            bt.assert_args("get_move_n_uses_left",
                entity_proxy, bt.EntityProxy,
                move_proxy, bt.MoveProxy
            )

            local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
            if not _state:entity_has_move(entity, move) then
                return 0
            else
                local max = env.get_move_max_n_uses(move_proxy)
                local used = env.get_move_n_used(entity_proxy, move_proxy)
                return max - used
            end
        end

        env.set_move_n_uses_left = function(entity_proxy, move_proxy, n_left)
            bt.assert_args("set_move_n_uses_left",
                entity_proxy, bt.EntityProxy,
                move_proxy, bt.MoveProxy,
                n_left, bt.Number
            )

            local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
            if not _state:entity_has_move(entity, move) then
                bt.error_function("In env.set_move_n_uses_left: entity `" .. env.get_id(entity_proxy) .. "` does not have move `" .. env.get_id(move_proxy ).. "`")
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

            local slot_i = _state:entity_get_move_slot_i(entity, move)
            local max = move:get_max_n_uses()
            local n_used = max - n_left

            local before = _state:entity_get_move_n_used(entity, slot_i)
            _state:entity_set_move_n_used(entity, move, n_used)
            local after = _state:entity_get_move_n_used(entity, slot_i)

            if before < after then
                env.message(entity_proxy, "s ", move_proxy, " gained PP")
            elseif before > after then
                env.message(entity_proxy, "s ", move_proxy, " lost PP")
            end -- else, noop, for example if move has infinty PP
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

        env.get_move_is_disabled = function(entity_proxy, move_proxy)
            bt.assert_args("get_move_disabled",
                entity_proxy, bt.EntityProxy,
                move_proxy, bt.MoveProxy
            )

            local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
            if not _state:entity_has_move(entity, move) then
                bt.error_function("In env.get_move_disabled: entity `" .. env.get_id(entity_proxy) .. "` does not have move `" .. env.get_id(move_proxy ).. "`")
                return nil
            end

            local slot_i = _state:entity_get_move_slot_i(entity, move)
            return _state:entity_get_move_is_disabled(entity, slot_i)
        end

        env.set_move_is_disabled = function(entity_proxy, move_proxy, b)
            bt.assert_args("set_move_disabled",
                entity_proxy, bt.EntityProxy,
                move_proxy, bt.MoveProxy
            )

            local entity, move = _get_native(entity_proxy), _get_native(move_proxy)
            if not _state:entity_has_move(entity, move) then
                rt.warning("In env.set_move_disabled: entity `" .. env.get_id(entity_proxy) .. "` does not have move `" .. env.get_id(move_proxy ).. "`")
                return nil
            end

            local slot_i = _state:entity_get_move_slot_i(entity, move)
            local before = _state:entity_get_move_is_disabled(entity, slot_i)
            local now = b
            _state:entity_set_move_is_disabled(entity, slot_i, b)

            if before ~= now then -- fizzle unless state changes
                local sprite, animation = _scene:get_sprite(entity), nil
                if before == false and now == true then
                    _scene:_push_animation(bt.Animation.OBJECT_DISABLED(_scene, move, sprite))
                    env.message(entity_proxy, " can no longer use ", move_proxy)
                elseif before == true and now == false then
                    _scene:_push_animation(bt.Animation.OBJECT_ENABLED(_scene, move, sprite))
                    env.message(entity_proxy, "s " , move_proxy, " is no longer disabled")
                end

                -- no callbacks
            end
        end

        --- ### EQUIP ###

        env.list_equips = function(entity_proxy)
            bt.assert_args("list_equips", entity_proxy, bt.EntityProxy)
            local out = {}
            for equip in values(_state:entity_list_equips(_get_native(entity_proxy))) do
                table.insert(out, bt.create_equip_proxy(self, bt.create_equip_proxy(_scene, equip)))
            end
            return out
        end

        env.has_equip = function(entity_proxy, equip_proxy)
            bt.assert_args("has_equip",
                entity_proxy, bt.EntityProxy,
                equip_proxy, bt.EquipProxy
            )
            return _state:entity_has_equip(_get_native(entity_proxy), _get_native(equip_proxy))
        end

        env.set_equip_slot_is_disabled = function(entity_proxy, slot_i, b)
            bt.assert_args("set_equip_slot_is_disabled",
                entity_proxy, bt.EntityProxy,
                slot_i, bt.Number,
                b, bt.Boolean
            )

            local entity = _get_native(entity_proxy)
            local equip = _state:entity_get_equip(entity, slot_i)
            if equip == nil then
                bt.error_function("In env.set_equip_slot_is_disabled: entity `" .. entity_proxy.id .. "` has no move in slot `" .. slot_i .. "` equipped")
                return
            end

            local before = _state:entity_get_equip_is_disabled(entity, slot_i)
            local now = b
            _state:entity_set_equip_is_disabled(entity, slot_i, b)

            if before ~= now then
                local sprite, animation = _scene:get_sprite(entity), nil
                local equip_proxy = bt.create_equip_proxy(_scene, equip)
                if before == false and now == true then
                    _scene:_push_animation(bt.Animation.OBJECT_DISABLED(_scene, equip, sprite))
                    env.message(entity_proxy, " s ", equip_proxy, " was made useless")
                elseif before == true and now == false then
                    _scene:_push_animation(bt.Animation.OBJECT_ENABLED(_scene, equip, sprite))
                    env.message(entity_proxy, " s", equip_proxy, " is working again")
                end
            end

            -- no callbacks
        end

        env.get_equip_slot_is_disabled = function(entity_proxy, slot_i)
            bt.assert_args("get_equip_is_disabled",
                entity_proxy, bt.EntityProxy,
                slot_i, bt.Number
            )

            local entity = _get_native(entity_proxy)
            if _state:entity_get_equip(entity, slot_i) ~= nil then
                return _state:entity_get_equip_is_disabled(entity, slot_i)
            else
                rt.warning("In env.get_equip_slot_is_disabled: entity ´" .. entity_proxy.id .. "` does not have an equip equipped in slot `" .. slot_i .. "`")
                return true
            end
        end

        env.set_equip_is_disabled = function(entity_proxy, equip_proxy, b)
            bt.assert_args("set_equip_is_disabled",
                entity_proxy, bt.EntityProxy,
                equip_proxy, bt.EquipProxy,
                b, bt.Boolean
            )

            -- only disabled first copy, if multiple are equipped
            local slot_i = _state:entity_get_equip_slot_i(_get_native(entity_proxy), _get_native(equip_proxy))
            if slot_i ~= nil then
                env.set_equip_slot_is_disabled(entity_proxy, slot_i, b)
            else
                bt.error_function("In env.set_equip_is_disabled: entity `" .. entity_proxy.id .. "` does not have equip `" .. equip_proxy.id .. "` equipped")
            end
        end

        env.get_equip_is_disabled = function(entity_proxy, equip_proxy)
            bt.assert_args("get_equip_is_disabled",
                entity_proxy, bt.EntityProxy,
                equip_proxy, bt.EquipProxy
            )

            local slot_i = _state:entity_get_equip_slot_i(_get_native(entity_proxy), _get_native(equip_proxy))
            if slot_i == nil then
                rt.warning("In env.get_equip_is_disabled: entity ´" .. entity_proxy.id .. "` does not have `" .. equip_proxy.id .. "` equipped")
                return true
            end
            return _state:entity_get_equip_is_disabled(_get_native(entity_proxy), _get_native())
        end

        for which_proxy in range(
            { "move", bt.MoveProxy },
            { "equip", bt.EquipProxy },
            { "consumable", bt.ConsumableProxy }
        ) do
            local which, proxy = table.unpack(which_proxy)
            local get_name = "get_" .. which .. "_is_disabled"
            local get_slot_name = "get_" .. which .. "_slot_is_disabled"
            local set_slot_disabled_name = "set_" .. which .. "_slot_is_disabled"
            local set_disabled_name = "set_" .. which .. "_is_disabled"

            --- @brief get_move_is_disabled, get_equip_is_disabled, get_consumable_is_disabled
            env[get_name] = function(entity_proxy, object_proxy)
                bt.assert_args(get_name,
                    entity_proxy, bt.EntityProxy,
                    object_proxy, proxy
                )

                local entity, object = _get_native(entity_proxy), _get_native(object_proxy)
                if not _state["entity_has_" .. which](_state, entity, object) then
                    bt.error_function("In env." .. get_name .. ": entity `" .. entity_proxy.id .. "` does not have `" .. object_proxy.id .. "` equipped")
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

                local object = _state["entity_get_" .. which](_state, slot_i)
                if object == nil then
                    return -- fizzle if unequipped
                end

                local entity = _get_native(entity_proxy)

                local before = _state["entity_get_" .. which .. "_is_disabled"](_state, entity, slot_i)
                local now = b
                _state["entity_set_" .. which .. "_is_disabled"](_state, entity, slot_i, b)

                if before ~= now then -- fizzle unless state changes
                    local object_proxy = bt["create_" .. which .. "_proxy"](_scene, object)
                    local sprite, animation = _scene:get_sprite(entity), nil
                    if before == false and now == true then
                        _scene:_push_animation(bt.Animation.OBJECT_DISABLED(_scene, object, sprite))
                        env.message(entity_proxy, "s ", object_proxy, " was disabled")
                    elseif before == true and now == false then
                        _scene:_push_animation(bt.Animation.OBJECT_ENABLED(_scene, object, sprite))
                        env.message(entity_proxy, "s " , object_proxy, " is no longer disabled")
                    end

                    -- no callbacks?
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

        --- ### CONSUMABLE ###

        --- ### STATUS ###

        --- ### GLOBAL STATUS ###
    end
    return env
end

function bt.BattleScene:_test_simulation()
    self._simulation_environment = self:create_simulation_environment()
    local env = self._simulation_environment
    local entity = self._state:list_enemies()[1]
    local target = bt.create_entity_proxy(self, entity)
    local status = bt.create_status_proxy(self, self._state:entity_list_statuses(entity)[1])
    local move = bt.create_move_proxy(self, self._state:entity_list_moves(entity)[1])
    local equip = bt.create_equip_proxy(self, self._state:entity_list_equips(entity)[1])
    local consumable = bt.create_consumable_proxy(self, self._state:entity_list_consumables(entity)[1])
    local global_status = bt.create_global_status_proxy(self, self._state:list_global_statuses()[1])

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

    self._animation_queue:clear()
    rt.log("In bt.BattleScene:_test_simulation: all tests passed")
end