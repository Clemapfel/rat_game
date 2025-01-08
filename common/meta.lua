if meta == nil then meta = {} end

do
    -- use consecutive indices instead of string keys for better performance
    local _metatable_index = 1

    local _instance_signal_component_index = "signal_component" --_metatable_index + 1
    local _instance_hash_index = "hash"--_instance_signal_component_index + 1

    local _type_instance_properties_index = "instance_properties"--_metatable_index + 1
    local _type_instance_metatable_index = "instance_metatable"--_type_instance_properties_index + 1
    local _type_typename_index = "typename"--_type_instance_metatable_index + 1
    local _type_typehash_index = "typehash"--_type_typename_index + 1
    local _type_supers_index = "supers"--_type_typehash_index + 1
    local _type_super_hashes_index = "super_hashes"--_type_supers_index + 1
    local _type_signals_index = "signals"--_type_super_hashes_index + 1
    local _type_is_mutable_index = "is_mutable"--_type_signals_index + 1
    local _type_constructor_index = "constructor"--_type_is_mutable_index + 1

    local _enum_value_set_index = "value_set"--_type_constructor_index + 1

    local _instance_metatable_typename_index = "typename" --1
    local _instance_metatable_typehash_index = "typehash" --2
    local _instance_metatable_super_index = "super" --3

    local _signal_component_is_blocked_index = 1
    local _signal_component_handler_id_to_callback_index = _signal_component_is_blocked_index + 1
    local _signal_component_callbacks_in_order_index = _signal_component_handler_id_to_callback_index + 1
    local _signal_component_n_handlers = _signal_component_callbacks_in_order_index + 1

    -- upvalues instead of globals

    local _type_typename = "Type"
    local _type_typehash = 1

    local _enum_typename = "Enum"
    local _enum_typehash = 2
    local _meta_typehash_to_name = {
        [_type_typehash] = _type_typename,
        [_enum_typehash] = _enum_typename
    }

    local _meta_current_hash = _enum_typehash + 1

    --- @brief
    function meta.typeof(x)
        if _G.type(x) ~= "table" then
            return _G.type(x)
        end

        local metatable = rawget(x, _metatable_index)
        if metatable == nil or _G.type(metatable) ~= "table" then
            return "table"
        else
            local typename = metatable[_instance_metatable_typename_index]
            if typename == nil then
                return "table"
            else
                return typename
            end
        end
    end

    local _typeof = meta.typeof

    local _meta_signal_emit = function(self, name, ...)
        local error_handler = function(message)
            _G.error("In " .. _typeof(self) .. ".signal_emit(\"" .. name .. "\"): " .. message .. "\n" .. debug.traceback())
        end

        local component = rawget(self, _instance_signal_component_index)[name]
        if component[_signal_component_is_blocked_index] ~= true then
            for i, callback in ipairs(component[_signal_component_callbacks_in_order_index]) do
                --xpcall(callback, error_handler, self, ...)
                callback(self, ...)
            end
        end
    end

    local _meta_signal_connect = function(self, name, callback)
        local component = rawget(self, _instance_signal_component_index)[name]
        if component == nil then
            _G.error("In " .. _typeof(self) .. ".signal_connect: object has no signal with id `" .. name .. "`")
            return
        end

        local handler_id = component[_signal_component_n_handlers]
        component[_signal_component_n_handlers] = component[_signal_component_n_handlers] + 1

        component[_signal_component_handler_id_to_callback_index][handler_id] = callback
        table.insert(component[_signal_component_callbacks_in_order_index], callback)
        return handler_id
    end

    local _meta_signal_disconnect = function(self, name, handler_id)
        local component = rawget(self, _instance_signal_component_index)[name]
        if component == nil then
            _G.error("In " .. _typeof(self) .. ".signal_connect: object has no signal with id `" .. name .. "`")
            return
        end

        if handler_id == nil then
            self:signal_disconnect_all(name)
        else
            component[_signal_component_handler_id_to_callback_index][handler_id] = nil
        end
    end

    local _meta_signal_disconnect_all = function(self)
        for component in values(rawget(self, _instance_signal_component_index)) do
            component[_signal_component_handler_id_to_callback_index] = {}
            component[_signal_component_callbacks_in_order_index] = setmetatable({}, {
                __mode = "kv"
            })
        end
    end

    local _meta_signal_set_is_blocked = function(self, name, is_blocked)
        local component = rawget(self, _instance_signal_component_index)[name]
        if component == nil then
            _G.error("In " .. _typeof(self) .. ".signal_connect: object has no signal with id `" .. name .. "`")
            return
        end

        component[_signal_component_is_blocked_index] = is_blocked
    end

    local _meta_signal_get_is_blocked = function(self, name)
        local component = rawget(self, _instance_signal_component_index)[name]
        if component == nil then
            _G.error("In " .. _typeof(self) .. ".signal_connect: object has no signal with id `" .. name .. "`")
            return
        end

        return component[_signal_component_is_blocked_index]
    end

    local _meta_signal_block_all = function(self)
        for component in values(rawget(self, _instance_signal_component_index)) do
            component[_signal_component_is_blocked_index] = true
        end
    end

    local _meta_signal_unblock_all = function(self)
        for component in values(rawget(self, _instance_signal_component_index)) do
            component[_signal_component_is_blocked_index] = false
        end
    end

    local _meta_signal_has_signal = function(self, name)
        return rawget(self, _instance_signal_component_index)[name] ~= nil
    end

    local _meta_signal_list_handler_ids = function(self, name)
        local component = rawget(self, _instance_signal_component_index)[name]
        if component == nil then
            _G.error("In " .. _typeof(self) .. ".signal_connect: object has no signal with id `" .. name .. "`")
            return
        end

        local out = {}
        for id in keys(component[_signal_component_handler_id_to_callback_index]) do
            table.insert(out, id)
        end
        return out
    end

    local function _type_super_collect_fields_and_signals(super, instance_properties, signals, seen)
        local super_hash = rawget(super, _type_typehash_index)
        if seen[super_hash] == true then return end

        for signal in values(rawget(super, _type_signals_index)) do
            table.insert(signals, signal)
        end

        for key, value in pairs(rawget(super, _type_instance_properties_index)) do
            if instance_properties[key] == nil then -- prefer values from lower down the type hierarchy
                instance_properties[key] = value
            end
        end

        seen[super_hash] = true
        for super_super in values(rawget(super, _type_supers_index)) do
            _type_super_collect_fields_and_signals(super_super, instance_properties, signals, seen)
        end
    end

    local _type_metatable = {
        __newindex = function(type, key, value)
            rawget(type, _type_instance_properties_index)[key] = value
        end,

        __index = function(type, key)
            return rawget(type, _type_instance_properties_index)[key]
        end,

        __tostring = function(self)
            return rawget(self, _type_typename_index)
        end,

        __call = function(self, ...)
            local instance = rawget(self, _type_constructor_index)(...)
            if rawget(instance, _metatable_index)[_instance_metatable_typehash_index] ~= rawget(self, _type_typehash_index) then
                error("In " .. rawget(self, _type_typename_index) .. "__call: Constructor does not return an object of type `" .. rawget(self, _type_typename_index) .. "`")
            end
            return instance
        end,

        __eq = function(self, other)
            return rawget(self, _type_typehash_index) == rawget(other, _type_typehash_index)
        end,

        [_instance_metatable_typename_index] = _type_typename,
        [_instance_metatable_typehash_index] = _type_typehash,
        [_instance_metatable_super_index] = {}
    }

    --- @brief
    function meta.new_type(typename, ...)
        assert(type(typename) == "string", "In meta.new_type: expected typename as string for argument #1, got `" .. type(typename) .. "`")
        local typeof = _G.type
        local type = {}

        local typehash = _meta_current_hash
        _meta_current_hash = _meta_current_hash + 1

        type[_metatable_index] = _type_metatable
        type[_instance_hash_index] = typehash

        type[_type_constructor_index] = nil
        type[_type_typename_index] = typename
        type[_type_typehash_index] = typehash
        type[_type_supers_index] = {}
        type[_type_super_hashes_index] = {}
        type[_type_signals_index] = {}
        type[_type_is_mutable_index] = false

        type[_type_instance_properties_index] = {}
        type[_type_instance_metatable_index] = {
            __index = type[_type_instance_properties_index],

            __tostring = function(instance)  
                return typename .. "(" .. meta.hash(instance) .. ")"
            end,

            [_instance_metatable_typename_index] = typename,
            [_instance_metatable_typehash_index] = typehash,
            [_instance_metatable_super_index] = type
        }

        -- collect ctor, super types, and static fields from vararg
        local static_fields = nil
        local n_args = select("#", ...)
        for i = 1, n_args do
            local arg = select(i, ...)
            if typeof(arg) == "function" then
                if type[_type_constructor_index] ~= nil then
                    error("In meta.new_type: more than one constructor specified when creating type `" .. typename .. "`")
                end
                type[_type_constructor_index] = arg
            elseif typeof(arg) == "table" then
                if meta.typeof(arg) == "Type" then
                    table.insert(type[_type_supers_index], arg)
                    type[_type_super_hashes_index][rawget(arg, _type_typehash_index)] = true
                    type[rawget(arg, _type_typehash_index)] = true
                else
                    if static_fields ~= nil then
                        error("In meta.new_type: more than one type field table specified when creating type `" .. typename .. "`")
                    end
                    static_fields = arg
                end
            else
                error("In meta.new_type: unhandled argument `" .. _G.type(arg) .. "` when creating type `" .. typename .. "`")
            end
        end

        -- recursively collect all fields from supers
        local seen = {}
        for super in values(type[_type_supers_index]) do
            _type_super_collect_fields_and_signals(
                super,
                type[_type_instance_properties_index],
                type[_type_signals_index],
                seen
            )
        end

        -- add static fields
        if static_fields ~= nil then
            for key, value in pairs(static_fields) do
                type[_type_instance_properties_index][key] = value
            end
        end

        if type[_type_constructor_index] == nil then -- default ctor
            type[_type_constructor_index] = function()
                return meta.new(type, {})
            end
        end

        return setmetatable(type, _type_metatable)
    end

    --- @brief
    function meta.new(type, fields)
        local instance = {}
        local instance_metatable = rawget(type, _type_instance_metatable_index) -- shared metatable
        instance[_metatable_index] = instance_metatable
        instance[_instance_hash_index] = _meta_current_hash
        _meta_current_hash = _meta_current_hash + 1

        for key, value in pairs(fields) do
            instance[key] = value
        end

        -- install signals
        local type_signals = rawget(type, _type_signals_index)
        local instance_signal_component = {}
        if #type_signals ~= 0 then
            for name in values(type_signals) do
                instance_signal_component[name] = {
                    [_signal_component_is_blocked_index] = false,
                    [_signal_component_n_handlers] = 0,
                    [_signal_component_handler_id_to_callback_index] = {},
                    [_signal_component_callbacks_in_order_index] = setmetatable({}, {
                        __mode = "kv"
                    })
                }
            end

            instance.signal_emit = _meta_signal_emit
            instance.signal_connect = _meta_signal_connect
            instance.signal_disconnect = _meta_signal_disconnect
            instance.signal_list_handler_ids = _meta_signal_list_handler_ids
            instance.signal_disconnect_all = _meta_signal_disconnect_all
            instance.signal_set_is_blocked = _meta_signal_set_is_blocked
            instance.signal_get_is_blocked = _meta_signal_get_is_blocked
            instance.signal_block_all = _meta_signal_block_all
            instance.signal_unblock_all = _meta_signal_unblock_all
            instance.signal_has_signal = _meta_signal_has_signal
        end

        instance[_instance_signal_component_index] = instance_signal_component
        return setmetatable(instance, instance_metatable)
    end

    --- @brief
    function meta.new_enum(name, fields)
        local enum = meta.new_type(name)
        rawset(enum, _type_instance_properties_index, fields)
        rawset(enum, _type_is_mutable_index, false)

        local value_set = {}
        for value in values(fields) do
            value_set[value] = true
        end
        rawset(enum, _enum_value_set_index, value_set)

        -- reuse type but override metatable
        local metatable = {
            __newindex = function()
                _G.error("In " .. name .. ".__newindex: trying to modify enum, but enums are immutable")
            end,

            __index = function(self, key)
                local out = fields[key] -- non-chached metatable for additional speed here
                if out == nil then
                    rt.warning("In " .. name .. ".__index: key `" .. key .. "` is not part of enum")
                end
                return out
            end,

            __call = function()
                _G.error("In " .. name .. ".__call: trying instance enum")
            end,

            [_instance_metatable_typename_index] = _enum_typename,
            [_instance_metatable_typehash_index] = _enum_typehash,
            [_instance_metatable_super_index] = {}
        }
        rawset(enum, _metatable_index, metatable)
        return setmetatable(enum, metatable)
    end

    local _abstract_type_metatable = {}
    do
        for key, value in pairs(_type_metatable) do
            _abstract_type_metatable[key] = value
        end

        _abstract_type_metatable.__call = function(self)
            _G.error("In " .. rawget(self, _type_typename_index) .. ".__call: trying to instance abstract type")
        end
    end

    --- @brief
    function meta.new_abstract_type(typename, ...)
        local abstract = meta.new_type(typename, ...)
        rawset(abstract, _metatable_index, _abstract_type_metatable)
        return setmetatable(abstract, _abstract_type_metatable)
    end

    --- @brief
    function meta.add_signals(type, ...)
        for i = 1, select("#", ...) do
            local name = select(i, ...)
            assert(_G.type(name) == "string", "In meta.add_signals: expected `string`, got `" .. meta.typeof(name) .. "`")
            table.insert(rawget(type, _type_signals_index), name)
        end
    end
    meta.add_signal = meta.add_signals

    --- @brief
    function meta.get_typename(type)
        return rawget(type, _type_typename_index)
    end

    --- @brief
    function meta.hash(x)
        return rawget(x, _instance_hash_index)
    end

    --- @brief
    function meta.make_immutable(type, is_immutable)
        if is_immutable == nil then is_immutable = true end
        if not meta.typeof(type) == _type_typename then
            _G.error("In meta.make_immutable: expected `Type`, got `" .. meta.typeof(type) .. "`")
            return
        end
        rawset(type, _type_is_mutable_index, is_immutable)

        local instance_metatable = rawget(type, _type_instance_metatable_index)
        if is_immutable then
            instance_metatable.__newindex = function(self, key, value)
                _G.error("In " .. meta.typeof(self) .. ".__newindex: trying to modify instance, but its type was declared immutable")
            end
        else
            instance_metatable.__newindex = nil
        end
    end

    --- @brief
    function meta.get_is_immutable(type)
        return rawget(type, _type_is_mutable_index)
    end

    meta.set_is_mutable = function(x, b)
        if b then
            rawget(x, _metatable_index).__newindex = nil
        else
            rawget(x, _metatable_index).__newindex = nil
        end
    end

    --- @brief
    function meta.instances(enum)
        return rawget(enum, _type_instance_properties_index)
    end

    --- @brief
    function meta.isa(x, type)
        if x == nil and type ~= "nil" then return end
        local raw_type = _G.type(x)
        if raw_type ~= "table" then
            return raw_type == type
        end

        local metatable = rawget(x, _metatable_index)
        if metatable == nil or _G.type(metatable) ~= "table" then
            return _G.type(x) == type
        else
            if _G.type(type) == "string" then
                return metatable[_instance_metatable_typename_index] == type
            else
                local typehash = rawget(type, _type_typehash_index)
                if metatable[_instance_metatable_typehash_index] == typehash then
                    return true
                end

                return rawget(metatable[_instance_metatable_super_index], _type_super_hashes_index)[typehash] == true
            end
        end
    end

    --- @brief
    function meta.is_enum_value(x, enum)
        return rawget(enum, _enum_value_set_index)[x] == true
    end

    --- @brief
    function meta.assert_enum_value(x, enum)
        if rawget(enum, _enum_value_set_index)[x] ~= true then
            _G.error("In meta.assert_enum_value: value `" .. tostring(x) .. "` is not part of enum `" .. rawget(enum, _type_typename_index) .. "`")
        end
    end

    --- @brief
    function meta.assert_isa(x, type)
        if not meta.isa(x, type) then
            _G.error("In meta.assert_isa: expected `" .. rawget(type, _type_typename_index) .. "`, got: `" .. meta.typeof(x) .. "`")
        end
    end

    for which in range(
        "table",
        "number",
        "boolean",
        "function",
        "string",
        "nil"
    ) do
        --- @brief meta_is_table, meta_is_number, meta_is_boolean, meta_is_function, meta_is_string, meta_is_nil
        meta["is_" .. which] = function(x)
            return _G.type(x) == which
        end

        --- @brief meta_assert__table, meta_assert__number, meta_assert__boolean, meta_assert__function, meta_assert__string, meta_assert__nil
        meta["assert_" .. which] = function(x)
            local type = _G.type(x)
            if type ~= which then
                _G.error("In meta.assert_" .. which .. ": expected `" .. which .. "`, got `" .. type .. "`")
            end
        end
    end

    --- @brief
    function meta.is_subtype(x, type)
        local metatable = rawget(x, _metatable_index)
        if metatable == nil then return false end
        local super = metatable[_instance_metatable_super_index]
        if super == nil then return false end
        if super == type then return true end
        for super_super in values(rawget(super, _type_supers_index)) do
            if super_super == type then return true end
        end
        return false
    end

    --- @brief
    function meta.assert_is_subtype(x, type)
        if not meta.is_subtype(x, type) then
            _G.error("In meta.assert_is_subtype: expected subtype of `" .. rawget(type, _type_typename_index) .. "`, got `" .. meta.typeof(x) .. "`")
        end
    end

    --- @brief
    function meta.get_instance_metatable(type)
        return rawget(type, _type_instance_metatable_index)
    end
end -- do-end

--- @brief make it such that indexing a table will autt
function meta.make_auto_extend(x, recursive)
    if recursive == nil then recursive = false end
    local metatable = getmetatable(x)
    if metatable == nil then
        metatable = {}
        setmetatable(x, metatable)
    end

    metatable.__index = function(self, key)
        local out = {}
        self[key] = out

        if recursive then
            meta.make_auto_extend(out, recursive)
        end
        return out
    end
end

--- @brief
function meta.make_weak(t, weak_keys, weak_values)
    if weak_keys == nil then weak_keys = true end
    if weak_values == nil then weak_values = true end

    local metatable = getmetatable(t)
    if metatable == nil then
        metatable = {}
        setmetatable(t, metatable)
    end

    local mode = ""
    if weak_keys then mode = mode .. "k" end
    if weak_values then mode = mode .. "v" end
    metatable.__mode = mode

    return t
end

--- @brief adds proxy table such that original table is read-only
function meta.as_immutable(t)
    local metatable ={
        __index = function(_, key)
            local out = t[key]
            if out == nil then
                _G.error("trying to access `" .. key .. "` of `" .. tostring(t) .. "`, but this value does not exist")
                return nil
            end
            return out
        end,

        __newindex = function(_, key, value)
            _G.error("trying to modify table `" .. tostring(t) .. "`, but it is immutable")
        end
    }

    return setmetatable({}, metatable), metatable
end

-- TEST
do
    SuperA = meta.new_type("SuperA", function()
        return meta.new(SuperA, {
            _a_local = 1
        })
    end, {
        _a_global = 1
    })

    meta.add_signal(SuperA, "super_a")

    function SuperA:test_a()
        return 1
    end

    function SuperA:override()
        return 1
    end

    local instance = SuperA()
    assert(instance._a_local == 1)
    assert(instance._a_global == 1)
    assert(instance:test_a() == 1)
    assert(instance:override() == 1)

    AbstractA = meta.new_abstract_type("AbstractA" , {
        _abstract_global = 3
    })

    function AbstractA:test_abstract()
        return 3
    end

    SuperB = meta.new_type("SuperB", SuperA, AbstractA, function()
        return meta.new(SuperB, {
            _b_local = 2
        })
    end, {
        _b_global = 2
    })

    meta.add_signal(SuperB, "super_b")

    function SuperB:test_b()
        return 2
    end

    function SuperB:override()
        return 2
    end

    instance = SuperB()
    assert(instance._a_local == nil)
    assert(instance._a_global == 1)
    assert(instance:test_a() == 1)
    assert(instance._b_local == 2)
    assert(instance._b_global == 2)
    assert(instance:test_b() == 2)
    assert(instance:override() == 2)
    assert(instance._abstract_global == 3)
    assert(instance:test_abstract() == 3)

    local super_a_called = false
    instance:signal_connect("super_a", function()
        super_a_called = true
    end)

    local super_b_called = false
    instance:signal_connect("super_b", function()
        super_b_called = true
    end)

    instance:signal_emit("super_a")
    assert(super_a_called)
    instance:signal_emit("super_b")
    assert(super_b_called)
end
