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
    local _create_proxy_metatable = function(type, scene)
        return {
            _type = type,
            _scene = scene,

            __eq = function(self, other)
                return getmetatable(self)._native:get_id() == getmetatable(self)._native:get_id()
            end,

            __tostring = function(self)
                return bt.format_name(self)
            end,

            __index = function(self, key)
                bt.error_function("In bt.EntityProxy.__index: trying to access proxy directly, but it can only be accessed with outer functions, use `get_*` instead")
                return nil
            end,

            __newindex = function(self, key)
                bt.error_function("In bt.EntityProxy.__newindex: trying to modify proxy directly, but it can only be accessed with outer functions, use `set_*` instead")
            end
        }
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param entity bt.Entity
    function bt.create_entity_proxy(scene, native)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(native, bt.Entity)

        local metatable = _create_proxy_metatable(bt.EntityProxy, scene, native)
        metatable._native = native
        return setmetatable({}, metatable)    
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.GlobalStatus
    function bt.create_global_status_proxy(scene, native)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(native, bt.GlobalStatus)

        local metatable = _create_proxy_metatable(bt.GlobalStatusProxy, scene, native)
        metatable._native = native
        return setmetatable({}, metatable)    
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.Status
    function bt.create_status_proxy(scene, native, afflicted)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(native, bt.Status)
        meta.assert_isa(afflicted, bt.Entity)

        local metatable = _create_proxy_metatable(bt.GlobalStatusProxy, scene, native)
        metatable._native = native
        metatable._entity = afflicted
        return setmetatable({}, metatable)
    end
    
    --- @brief
    --- @param scene bt.BattleScene
    --- @param status bt.Status

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_consumable_proxy(scene, holder, slot_i)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(holder, bt.Entity)
        meta.assert_number(slot_i)

        local metatable = _create_proxy_metatable(bt.ConsumableProxy, scene)
        local native = scene._state:entity_get_consumable(holder, slot_i)
        meta.assert_isa(native, bt.Consumable)
        metatable._native = native
        metatable._entity = holder
        metatable._slot_i = slot_i
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_equip_proxy(scene, holder, slot_i)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(holder, bt.Entity)
        meta.assert_number(slot_i)

        local metatable = _create_proxy_metatable(bt.EquipProxy, scene)
        local native = scene._state:entity_get_equip(holder, slot_i)
        meta.assert_isa(native, bt.Equip)
        metatable._native = native
        metatable._entity = holder
        metatable._slot_i = slot_i
        return setmetatable({}, metatable)
    end

    --- @brief
    --- @param scene bt.BattleScene
    --- @param holder bt.Entity
    --- @param slot_i Unsigned
    function bt.create_move_proxy(scene, holder, slot_i)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(holder, bt.Entity)
        meta.assert_number(slot_i)

        local metatable = _create_proxy_metatable(bt.MoveProxy, scene)
        local native = scene._state:entity_get_move(holder, slot_i)
        meta.assert_isa(native, bt.Move)
        metatable._native = native
        metatable._entity = holder
        metatable._slot_i = slot_i
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
    meta["is_" .. name .. proxy] = function(x)
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
    {"is_consumable_proxy", bt.ConsumableProxy}
) do
    local which, type = table.unpack(which_type)

    --- @brief bt.assert_is_number, bt.assert_is_string, bt.assert_is_boolean, bt.assert_is_entity_proxy, bt.assert_is_status_proxy, bt.assert_is_global_status_proxy, bt.assert_is_consumable_proxy
    bt["assert_" .. which] = function(function_name, x, arg_i)
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

    -- bind IDs as globals, used by add_status, spawn, etc.
    local entity_prefix = "ENTITY"
    local consumable_prefix = "CONSUMABLE"
    local equip_prefix = "EQUIP"
    local move_prefix = "MOVE"
    local global_status_prefix = "GLOBAL_STATUS"
    local status_prefix = "STATUS"

    for prefix_path in range(
        {entity_prefix, rt.settings.battle.entity.config_path},
        {consumable_prefix, rt.settings.battle.consumable.config_path},
        {equip_prefix, rt.settings.battle.equip.config_path},
        {move_prefix, rt.settings.battle.move.config_path},
        {global_status_prefix, rt.settings.battle.global_status.config_path},
        {status_prefix, rt.settings.battle.status.config_path}
    ) do
        local prefix, path = table.unpack(prefix_path)
        for _, name in pairs(love.filesystem.getDirectoryItems(path)) do
            if string.match(name, "%.lua$") ~= nil then
                local id = string.gsub(name, "%.lua$", "")
                env[prefix .. "_" .. id] = id
                dbg(prefix .. "_" .. id)
            end
        end
    end

    local _get_native = function(x) return getmetatable(x)._native end
    local _get_holder = function(x) return getmetatable(x)._entity end
    local _get_slot_i = function(x) return getmetatable(x)._slot_i end

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

        local afflicted = _get_native(entity_proxy)
        assert(_get_holder(status_proxy) == afflicted)

        local afflicted_sprite = _scene._sprites[afflicted]
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

        local holder = _get_native(holder_proxy)
        assert(_get_holder(consumable_proxy) == holder)

        if _state:entity_get_consumable_is_disabled(holder, _get_slot_i(consumable_proxy)) then
            return
        end

        local holder_sprite = _scene._sprites[holder]
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

        return env
    end

    --- @biref
    function env.set_value(object, name, new_value)
        bt.assert_is_string("set_value", name, 2)

        if meta.is_entity_proxy(object) then
            _state:entity_set_storage_value(
                _get_native(object),
                name, new_value
            )
        elseif meta.is_move_proxy(object) then
            _state:entity_set_move_storage_value(
                _get_holder(object),
                _get_slot_i(object),
                name, new_value
            )
        elseif meta.is_status_proxy(object) then
            _state:entity_set_status_storage_value(
                _get_holder(object),
                _get_native(object),
                name, new_value
            )
        elseif meta.is_equip_proxy(object) then
            _state:entity_set_equip_storage_value(
                _get_holder(object),
                _get_slot_i(object),
                name, new_value
            )
        elseif meta.is_consumable_proxy(object) then
            _state:entity_set_consumable_storage_value(
                _get_holder(object),
                _get_slot_i(object),
                name, new_value
            )
        elseif meta.is_global_status_proxy(object) then
            _state:set_global_status_storage_value(
                _get_native(object),
                name, new_value
            )
        else
            bt.error_function("In env.set_value: objects of type `" .. meta.typeof(object) .. "` do not support value storage")
            return nil
        end

        return new_value
    end

    --- @brief
    function env.get_value(object, name, new_value)
        bt.assert_is_string("get_value", name, 2)

        if meta.is_entity_proxy(object) then
            _state:entity_get_storage_value(
                _get_native(object),
                name
            )
        elseif meta.is_move_proxy(object) then
            _state:entity_get_move_storage_value(
                _get_holder(object),
                _get_slot_i(object),
                name
            )
        elseif meta.is_status_proxy(object) then
            _state:entity_get_status_storage_value(
                _get_holder(object),
                _get_native(object),
                name
            )
        elseif meta.is_equip_proxy(object) then
            _state:entity_get_equip_storage_value(
                _get_holder(object),
                _get_slot_i(object),
                name
            )
        elseif meta.is_consumable_proxy(object) then
            _state:entity_get_consumable_storage_value(
                _get_holder(object),
                _get_slot_i(object),
                name
            )
        elseif meta.is_global_status_proxy(object) then
            _state:get_global_status_storage_value(
                _get_native(object),
                name
            )
        else
            bt.error_function("In env.get_value: objects of type `" .. meta.typeof(object) .. "` do not support value storage")
            return nil
        end

        return new_value
    end
end

--- @brief
function bt.BattleScene:invoke(f)
    if self._simulation_environment == nil then
        self._simulation_environment = self:create_simulation_environment()
    end
    debug.setfenv(f, self._simulation_environment)
    return f()
end
