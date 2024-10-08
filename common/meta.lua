if meta == nil then meta = {} end
meta._current_hash = 3

do
    -- use consecutive indices instead of string keys for better performance
    local _metatable_index = 1

    local _properties_index = 1
    local _is_mutable_index = 2
    local _instance_hash_index = 3
    local _typename_hash_index = 4
    local _super_hashes_index = 5
    local _signal_component_index = 6
    local _enum_instances_index = 7
    local _enum_typename_index = 8

    --- @param typename_hash Number
    function meta._new(typename_hash)
        local out = {}
        local metatable = {}
        out[_metatable_index] = metatable

        metatable[_properties_index] = {}                    -- Table<String, Any>
        metatable[_is_mutable_index] = true                  -- Boolean
        metatable[_typename_hash_index] = typename_hash      -- Number
        metatable[_super_hashes_index] = {}                  -- Set<Number>
        metatable[_instance_hash_index] = meta._current_hash -- Number

        meta._current_hash = meta._current_hash + 1

        local properties = metatable[_properties_index]
        metatable.__index = properties
        metatable.__newindex = function(self, key, value)
            properties[key] = value
        end

        setmetatable(out, metatable)
        return out, metatable
    end

    --- @brief
    function meta.hash(x)
        return rawget(x, _metatable_index)[_instance_hash_index]
    end

    --- @brief
    function meta.typeof(x)
        local native_type = type(x)
        if native_type == "table" then
            local metatable = rawget(x, _metatable_index)
            if metatable == nil then return native_type end
            local typename_hash = metatable[_typename_hash_index]
            if typename_hash == nil then return native_type end
            local typename = meta._type_hash_to_name[typename_hash]
            if typename == nil then return native_type end
            return typename
        else
            return native_type
        end
    end

    local _typeof = meta.typeof

    local _is_mutable_newindex = function(self, _, _)
        error("In " .. _typeof(self) .. ".__newindex: trying to modifiyng object, but it was declared immutable")
    end

    --- @brief
    function meta.set_is_mutable(x, b)
        local metatable = rawget(x, _metatable_index) -- faster than `getmetatable`
        if b == false then
            metatable.__newindex = _is_mutable_newindex
        else
            metatable.__newindex = metatable[_properties_index]
        end
    end

    --- @brief
    function meta.get_is_mutable(x)
        local metatable = rawget(x, _metatable_index)
        return metatable.__newindex == metatable[_properties_index]
    end

    local _type_typename_hash = 1

    meta._types = {}
    meta._type_hash_to_name = {
        [_type_typename_hash] = "Type"
    }

    local _select = _G._select

    local _new_type_default_constructor = function(self)
        return meta.new(self, {})
    end

    local _new_type_define_type_assertion = function(typename_hash)
        local typename = meta._type_hash_to_name[typename_hash]
        local as_snake_case = {}
        table.insert(as_snake_case, string.lower(string.sub(typename, 1, 1)))
        for i = 2, #typename do
            local c = string.sub(typename, i, i)
            if string.is_upper(c) then
                table.insert(as_snake_case, "_")
            end
            table.insert(as_snake_case, string.lower(c))
        end
        as_snake_case = table.concat(as_snake_case)

        local assert_name = "assert_" .. as_snake_case
        local is_name = "is_" .. as_snake_case

        --- @brief
        meta[is_name] = function(x)
            local metatable = rawget(x, _metatable_index)
            if metatable == nil or type(metatable) ~= "table" then return false end
            return metatable[_typename_hash_index] == typename_hash
        end

        --- @brief
        meta[assert_name] = function(x)
            local should_error = false
            local metatable = rawget(x, _metatable_index)
            if metatable == nil or type(metatable) ~= "table" then
                should_error = true
                goto throw
            end
            if metatable[_typename_hash_index] == typename_hash then
                should_error = true
                goto throw
            end

            ::throw::
            if should_error then
                error("In meta." .. assert_name .. ": expected `" .. typename .. "`, got `" .. _typeof(x) .. "`")
            end
        end
    end

    local function _new_type_collect_fields_and_signals(self, fields, signals, super_hashes)
        local metatable = rawget(self, _metatable_index)
        super_hashes[metatable.typename_hash] = true

        for name, value in pairs(metatable.fields) do
            if fields[name] == nil then
                fields[name] = value
            end
        end

        for name, _ in pairs(metatable.signals) do
            signals[name] = true
        end

        for super, _ in pairs(metatable.supers) do
            _new_type_collect_fields_and_signals(super, fields, signals, super_hashes)
        end
    end

    --- @brief
    function meta.new_type(typename, ...)
        assert(type(typename) == "string", "In meta.new_type: expected typename as string for argument #1, got `" .. type(typename) .. "`")
        local out, metatable = meta._new(_type_typename_hash)

        metatable.supers = {}   -- Set<Type>
        metatable.fields = {}   -- Table<String, Any>
        metatable.signals = {}  -- Set<String>
        local constructor = nil
        metatable.typename = typename   -- String
        metatable.typename_hash = meta._current_hash -- Number
        metatable.super_hashes = {} -- Set<Number>
        meta._current_hash = meta._current_hash + 1

        local n_args = _select("#", ...)
        for i = 1, n_args do
            local arg = _select(i, ...)
            if type(arg) == "function" then
                if constructor ~= nil then
                    error("In meta.new_type: more than one constructor specified when creating type `" .. typename .. "`")
                end
                constructor = arg
            elseif type(arg) == "table" then
                if _typeof(arg) == "Type" then
                    metatable.supers[arg] = true
                else
                    metatable.fields = arg
                end
            else
                error("In meta.new_type: more than one table of static fields when creating type `" .. typename .. "`")
            end
        end

        if constructor == nil then
            constructor = _new_type_default_constructor
        end

        -- collect all fields / signals from super types
        _new_type_collect_fields_and_signals(out, metatable.fields, metatable.signals, metatable.super_hashes)

        if meta._type_hash_to_name[metatable.typename_hash]  ~= nil then
            error("In meta.new_type: A type with name `" .. typename .. "` already exists")
        end
        meta._type_hash_to_name[metatable.typename_hash] = metatable.typename

        local fields = metatable.fields
        metatable.__index = fields
        metatable.__newindex = function(_, key, value)
            fields[key] = value
        end

        metatable.__tostring = function(_)
            return typename
        end

        metatable.__call = function(_, ...)
            local out = constructor(...)
            -- check if type of returned instance is self
            if _typeof(out) ~= typename then
                error("In " .. typename .. "__call: Constructor does not return an object of type `" .. typename .. "`")
            end
            return out
        end

        _new_type_define_type_assertion(metatable.typename_hash)
        return out
    end

    function meta.add_signals(type, ...)
        local n_args = _select("#", ...)
        local metatable = rawget(type, _metatable_index)
        for i = 1, n_args do
            local arg = _select(i, ...)
            assert(_G.type(arg) == "string")
            metatable.signals[arg] = true
        end
    end
    meta.add_signal = meta.add_signals

    local _new_abstract_type_constructor = function(self)
        error("In " .. self.typename .. ".__call: Trying to instantiate abstract type")
        return nil
    end

    --- @brief
    function meta.new_abstract_type(name, ...)
        local out = meta.new_type(name, ...)
        rawget(out, _metatable_index).__call = _new_abstract_type_constructor
        return out
    end

    local _signal_is_blocked_index = 1
    local _signal_callbacks_index = 2
    local _signal_n_callbacks_index = 3

    --- @brief
    function meta.new(type, fields)
        local type_metatable = rawget(type, _metatable_index)
        local out, metatable = meta._new(type_metatable.typename_hash)
        local properties = metatable[_properties_index]

        -- install inherited static fields
        for name, value in pairs(type_metatable.fields) do
            properties[name] = value
        end

        -- install per-instance fields
        if fields ~= nil then
            for name, value in pairs(fields) do
                properties[name] = value
            end
        end

        -- install super hash (reference)
        metatable[_super_hashes_index] = type_metatable.super_hashes

        -- install signals
        local signals = type_metatable.signals
        local is_initialized, signal_component = false, nil
        for name, _ in pairs(signals) do
            if is_initialized == false then
                metatable[_signal_component_index] = {}
                signal_component = metatable[_signal_component_index]
                is_initialized = true
            end

            signal_component[name] = {
                [_signal_is_blocked_index] = false,
                [_signal_callbacks_index] = {},
                [_signal_n_callbacks_index] = 0
            }
        end

        properties.signal_emit = meta.signal_emit
        properties.signal_connect = meta.signal_connect
        properties.signal_disconnect = meta.signal_disconnect
        properties.signal_list_handler_ids = meta.signal_list_handler_ids
        properties.signal_disconnect_all = meta.signal_disconnect_all
        properties.signal_set_is_blocked = meta.signal_set_is_blocked
        properties.signal_get_is_blocked = meta.signal_get_is_blocked
        properties.signal_has_signal = meta.signal_has_signal

        return out
    end

    --- @brief
    function meta.new_enum(name, fields)
        assert(type(name) == "string", "In meta.new_enum: wrong argument #1, expected `string`, got `" .. _typeof(name) .. "`")

        local typename_hash = meta._current_hash
        local typename = name
        meta._current_hash = meta._current_hash + 1

        if meta._type_hash_to_name[typename_hash]  ~= nil then
            error("In meta.new_enum: A type with name `" .. typename .. "` already exists")
        end

        meta._type_hash_to_name[typename_hash] = typename

        local out, metatable = meta._new(typename_hash)
        local properties = metatable[_properties_index]
        local values = {} -- for fast checking if value is in enum
        for name, value in pairs(fields) do
            properties[name] = value
            values[value] = true
        end

        metatable[_enum_instances_index] = values
        metatable[_enum_typename_index] = name
        metatable.__index = function(self, key)
            local res = metatable[1][key]
            if res == nil then
                error("In " .. name .. ".__index: enum has no member with name `" .. key .. "`")
            end
            return res
        end

        meta.set_is_mutable(out, false)
        return out
    end

    --- @brief
    function meta.instances(enum)
        return rawget(enum, _metatable_index)[_properties_index]
    end

    --- @brief
    function meta.is_enum_value(value, enum)
        return rawget(enum, _metatable_index)[_enum_instances_index][value] == true
    end

    --- @brief
    function meta.assert_enum_value(value, enum)
        local metatable = rawget(enum, _metatable_index)
        if metatable[_enum_instances_index][value] ~= true then
            error("In meta.assert_enum_value_value: value `" .. tostring(value) .. "` is not part of enum `" .. metatable[_enum_typename_index] .. "`")
        end
    end

    --- @type Type
    meta.Type = "Type"

    --- @type Enum
    meta.Enum = "Enum"

    --- @type Table
    meta.Table = "table"

    --- @type Number
    meta.Number = "number"

    --- @type Boolean
    meta.Boolean = "boolean"

    --- @type Function
    meta.Function = "function"

    --- @brief
    function meta.isa(x, super)
        if type(super) == "string" then
            return _typeof(x) == super
        else
            if type(x) ~= "table" then
                return false
            end

            local metatable = rawget(x, _metatable_index)
            if metatable == nil then
                return false
            end

            local typename_hash = rawget(super, _metatable_index).typename_hash
            for hash, _ in pairs(metatable[_super_hashes_index]) do
                if hash == typename_hash then return true end
            end

            return false
        end
    end

    local _assert_isa_throw = function(x, super)
        error("In meta.assert_isa: expected `" .. tostring(super) .. "`, got `" .. _typeof(x) .. "`")
    end

    --- @brief
    function meta.assert_isa(x, super)
        if type(super) == "string" then
            if _typeof(x) ~= super then
                error("In meta.assert_isa: expected `" .. super .. "`, got `" .. _typeof(x) .. "`")
            end
        else
            if type(x) ~= "table" then
                _assert_isa_throw(x, super)
            end

            local metatable = rawget(x, _metatable_index)
            if metatable == nil then
                _assert_isa_throw(x, super)
            end

            local typename_hash = rawget(super, _metatable_index).typename_hash
            for hash, _ in pairs(metatable[_super_hashes_index]) do
                if hash == typename_hash then return end
            end

            _assert_isa_throw(x, super)
        end
    end

    for _, which in pairs({
        "table",
        "number",
        "boolean",
        "function",
        "string"
    }) do
        --- @brief
        meta["is_" .. which] = function(x)
            return type(x) == which
        end

        --- @brief
        meta["assert_" .. which] = function(...)
            local n_args = _select("#", ...)
            for i = 1, n_args do
                local arg = _select(i, ...)
                if type(arg) ~= which then
                    error("In meta.assert_" .. which .. ": expected `" .. which .. "`, got `" .. _typeof(arg) .. "`")
                end
            end
        end
    end

    --- @brief
    function meta.is_signed(x)
        return type(x) == "number" and math.fmod(x, 1) == 0
    end

    --- @brief
    function meta.is_unsigned(x)
        return type(x) == "number" and math.fmod(x, 1) == 0 and x >= 0
    end

    --- @brief
    function meta.is_inf(x)
        return x == POSITIVE_INFINITY or x == NEGATIVE_INFINITY
    end

    --- @brief
    function meta.is_subtype(sub, super)
        local supers = rawget(sub, _metatable_index).supers
        for type, _ in pairs(supers) do
            if type == super then return true end
        end
        return false
    end

    --- @brief
    function meta.assert_is_subtype(sub, super)
        local supers = rawget(sub, _metatable_index).supers
        for type, _ in pairs(supers) do
            if type == super then return end
        end
        error("In meta.assert_is_subtype: type `" .. tostring(sub) .. "` is not a subtype of `" .. tostring(super) .. "`")
    end

    --- @brief
    function meta.get_properties(x)
        return rawget(x, _metatable_index)[_properties_index]
    end
    
    --- @brief
    meta.signal_emit = function(self, name, ...)
        local handler = self[_metatable_index][_signal_component_index][name]
        local outputs = {}
        if handler[_signal_is_blocked_index] ~= true then
            for i = 1, handler[_signal_n_callbacks_index] do
                local results = {handler[_signal_callbacks_index][i](self, ...)}
                for _, v in pairs(results) do
                    table.insert(outputs, v)
                end
            end
        end

        return table.unpack(outputs)
    end
    
    --- @brief
    meta.signal_connect = function(self, name, callback)
        local handler = self[_metatable_index][_signal_component_index][name]
        if handler == nil then
            error("In " .. _typeof(self) .. ".signal_connect: object has no signal with id `" .. name .. "`")
            return
        end
        
        table.insert(handler[_signal_callbacks_index], callback)
        local handler_index = handler[_signal_n_callbacks_index]
        handler[_signal_n_callbacks_index] = handler_index + 1
        return handler_index
    end

    --- @brief
    meta.signal_disconnect = function(self, name, handler_id)
        local handler = self[_metatable_index][_signal_component_index][name]
        if handler == nil then
            error("In " .. _typeof(self) .. ".signal_disconnect: object has no signal with id `" .. name .. "`")
            return
        end

        if handler_id == nil then
            handler[_signal_callbacks_index] = {}
            handler[_signal_n_callbacks_index] = 0
        elseif handler[_signal_callbacks_index][handler_id] ~= nil then
            handler[_signal_callbacks_index][handler_id] = nil
            handler[_signal_n_callbacks_index] = handler[_signal_n_callbacks_index] - 1
        end
    end

    --- @brief
    meta.signal_list_handler_ids = function(self, name)
        local handler = self[_metatable_index][_signal_component_index][name]
        if handler == nil then
            error("In " .. _typeof(self) .. ".signal_list_handler_ids: object has no signal with id `" .. name .. "`")
            return
        end

        local out = {}
        for i = 1, handler[_signal_n_callbacks_index] do
            table.insert(out, i)
        end
        return out
    end

    --- @brief
    meta.signal_disconnect_all = function(self, name)
        if name == nil then
            local component = self[_metatable_index][_signal_component_index]
            for _, handler in pairs(component) do
                handler[_signal_callbacks_index] = {}
                handler[_signal_n_callbacks_index] = 0
            end
        else
            local handler = self[_metatable_index][_signal_component_index][name]
            if handler == nil then
                error("In " .. _typeof(self) .. ".signal_disconnect_all: object has no signal with id `" .. name .. "`")
                return
            end

            handler[_signal_callbacks_index] = {}
            handler[_signal_n_callbacks_index] = 0
        end
    end

    --- @brief
    meta.signal_set_is_blocked = function(self, name, is_blocked)
        local handler = self[_metatable_index][_signal_component_index][name]
        if handler == nil then
            error("In " .. _typeof(self) .. ".signal_set_is_blocked: object has no signal with id `" .. name .. "`")
            return
        end

        handler[_signal_is_blocked_index] = is_blocked
    end
    
    --- @brief
    meta.signal_get_is_blocked = function(self, name)
        local handler = self[_metatable_index][_signal_component_index][name]
        if handler == nil then
            error("In " .. _typeof(self) .. ".signal_get_is_blocked: object has no signal with id `" .. name .. "`")
            return
        end
        
        return handler[_signal_is_blocked_index]
    end

    --- @brief
    meta.signal_has_signal = function(self, name)
        local handler = self[_metatable_index][_signal_component_index][name]
        return handler ~= nil
    end
end

--- @brief make it such that indexing a table will autt
function meta.make_auto_extend(x, recursive)
    if recursive == nil then recursive = false end
    local metatable = getmetatable(x)
    if metatable == nil then
        metatable = {}
        setmetatable(x, metatable)
    end

    if metatable.__index ~= nil then
        error("In make_auto_extend_table: table already has a metatable with an __index method")
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

    metatable.__mode = ""
    if weak_keys then
        metatable.__mode = metatable.__mode .. "k"
    end

    if weak_values then
        metatable.__mode = metatable.__mode .. "v"
    end

    return t
end

-- TEST
do
    SuperA = meta.new_type("SuperA")
    function SuperA:new_function(x)
        return 1234
    end
    meta.add_signal(SuperA, "super_test")

    Sub = meta.new_type("Sub", SuperA, function()
        return meta.new(Sub)
    end)
    meta.add_signal(Sub, "sub_test")
    function Sub:test_new_function(x)
        return self:new_function(1234)
    end

    instance = Sub()
    instance:signal_connect("super_test", function() end)
    instance:signal_connect("sub_test", function() end)
    assert(instance:test_new_function() == 1234)
end