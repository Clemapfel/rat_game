--- @module meta Introspection and basic type sytem
meta = {}
meta.types = {}

--- @brief is x a lua string?
--- @param x any
function meta.is_string(x)
    return type(x) == "string"
end

--- @brief is x a lua table?
--- @param x any
function meta.is_table(x)
    return type(x) == "table"
end

--- @brief is x a lua number?
--- @param x any
function meta.is_number(x)
    return type(x) == "number"
end

--- @brief is x a lua boolean?
--- @param x any
function meta.is_boolean(x)
    return type(x) == "boolean"
end

--- @brief is x nil?
--- @param x any
function meta.is_nil(x)
    return type(x) == "nil"
end

---@brief is callable
--- @param x any
function meta.is_function(x)
    if type(x) == "function" then
        return true
    elseif meta.is_table(x) and getmetatable(x) ~= nil then
        return meta.is_function(getmetatable(x).__call)
    else
        return false
    end
end

meta._hash = 2^16

--- @brief [internal] Create new empty object
--- @param typename String
function meta._new(typename)
    meta.assert_string(typename)

    local out = {}
    out.__metatable = {}
    metatable = out.__metatable

    metatable.__name = typename
    metatable.__hash = meta._hash
    meta._hash = meta._hash + 1
    metatable.properties = {}
    metatable.is_mutable = true
    metatable.super = {}
    metatable.components = {}
    metatable.was_finalized = false

    metatable.__index = function(this, property_name)
        local metatable = getmetatable(this)
        return metatable.properties[property_name]
    end

    metatable.__newindex = function(this, property_name, property_value)
        local metatable = getmetatable(this)
        if not metatable.is_mutable then
            error("[rt][ERROR] In " .. metatable.__name .. ".__newindex: Cannot set property `" .. property_name .. "`, because the object was declared immutable.")
        end
        metatable.properties[property_name] = property_value

        --[[
        if metatable.components.signal == nil then return end
        local notify_signal_id = rt.SignalComponent._notify_prefix .. property_name
        if metatable.components.signal:has_signal(notify_signal_id) then
            metatable.components.signal:emit(notify_signal_id, property_value)
        end
        ]]--
    end

    metatable.__tostring = function(this)
        return "(" .. getmetatable(this).__name .. ") " .. serialize(this)
    end

    metatable.__name = metatable.__name
    metatable.__eq = function(self, other)
        meta.assert_object(other)
        return getmetatable(self).__hash == getmetatable(other).__hash
    end
    setmetatable(out, metatable)
    return out
end

--- @brief is meta object
--- @param x any
--- @return Boolean
function meta.is_object(x)
    if not meta.is_table(x) then
        return false
    end
    local metatable = getmetatable(x)
    return not (metatable == nil or metatable.__name == nil)
end

--- @brief get typename identifier
function meta.typeof(x)
    local out = ""
    if not meta.is_table(x) then
        out = type(x)
    else
        local metatable = getmetatable(x)
        if meta.is_nil(metatable) then
            out = meta.Table.name
        else
            out = getmetatable(x).__name
        end
    end
    return out
end

--- @brief check if type of object is as given
--- @param type meta.Type (or String)
--- @return Boolean
function meta.isa(x, type)

    local typename = type
    if meta.typeof(type) == "Type" then
        typename = type.name
    else
        typename = type
    end

    if meta.typeof(x) == typename then
        return true
    end

    local metatable = getmetatable(x)
    if not meta.is_nil(metatable) and not meta.is_nil(metatable.super)then
        for _, super in pairs(metatable.super) do
            if super == typename then
                return true
            end
        end
    end
    return false
end

--- @brief check if instance has type as super
function meta.inherits(x, super)
    meta.assert_object(x)
    meta.assert_isa(super, meta.Type)

    for _, name in pairs(getmetatable(x).super) do
        if name == super.name then
            return true
        end
    end
    return false
end

--- @brief [internal] print type assertion error message
--- @param b Boolean true if no error, false otherwise
--- @param x meta.Object
--- @param type String typename
function meta._assert_aux(b, x, type)
    if b then return true end
    local name = debug.getinfo(2, "n").name
    error("[rt][ERROR] In " .. name .. ": expected `" .. type .. "`, got `" .. meta.typeof(x) .. "`")
    return false
end

--- @brief throw if false
--- @param b Boolean
function meta.assert(b)
    meta.assert_boolean(b)
    if not b then
        local name = debug.getinfo(2, "n").name
        error("[rt][ERROR] In " .. name .. ": Assertion failed")
    end
end

--- @brief throw if object is not a boolean
--- @param x any
function meta.assert_boolean(x, ...)
    meta._assert_aux(meta.is_boolean(x), x, "boolean")
    for _, n in pairs({...}) do
        meta._assert_aux(meta.is_boolean(n), n, "boolean")
    end
end

--- @brief throw if object is not a table
--- @param x any
function meta.assert_table(x, ...)
    meta._assert_aux(meta.is_table(x), x, "table")
    for _, n in pairs({...}) do
        meta._assert_aux(meta.is_table(n), n, "table")
    end
end

--- @brief throw if object is not callable
--- @param x any
function meta.assert_function(x, ...)
    meta._assert_aux(meta.is_function(x), x, "function")
    for _, n in pairs({...}) do
        meta._assert_aux(meta.is_function(n), n, "function")
    end
end

--- @brief throw if object is not a string
--- @param x any
function meta.assert_string(x, ...)
    meta._assert_aux(meta.is_string(x), x, "string")
end

--- @brief throw if object is not a number
--- @param x any
function meta.assert_number(x, ...)
    meta._assert_aux(meta.is_number(x), x, "number")
    for _, number in pairs({...}) do
        meta._assert_aux(meta.is_number(number), number, "number")
    end
end

--- @brief throw if object is not nil
--- @param x any
function meta.assert_nil(x, ...)
    meta._assert_aux(meta.is_nil(x), x, "typeof(nil)")
    for _, number in pairs({...}) do
        meta._assert_aux(meta.is_nil(number), number, "typeof(nil)")
    end
end

--- @brief assert that object was created using `meta.new`
--- @param x any
function meta.assert_object(x, ...)
    meta._assert_aux(meta.is_object(x), x, "meta.Object")
    for _, number in pairs({...}) do
        meta._assert_aux(meta.is_object(number), number, "meta.Object")
    end
end

--- @brief assert that instance inherits from type
--- @param x any
function meta.assert_inherits(x, type)
    if meta.typeof(type) == "Type" then
        meta._assert_aux(meta.inherits(x, type), x, type.name)
    else
        meta.assert_string(type)
        meta._assert_aux(meta.inherits(x, type), x, type)
    end
end

--- @brief [internal] add a property, set to intial value
--- @param x meta.Object
--- @param property_name String
--- @param initial_value any
function meta._install_property(x, property_name, initial_value)
    meta.assert_object(x);
    meta.assert_string(property_name)

    local metatable = getmetatable(x)
    metatable.properties[property_name] = initial_value
end

--- @brief [internal] add a property, set to intial value
--- @param x meta.Object
--- @param property_name String
function meta._uninstall_property(x, property_name)
    meta.assert_object(x)
    meta.assert_string(property_name)
    local metatable = getmetatable(x)
    metatable.properties[property_name] = nil
end

--- @brief get whether property is installed
--- @param x meta.Object
--- @param property_name String
--- @return Boolean
function meta.has_property(x, property_name)
    meta.assert_object(x)
    meta.assert_string(property_name)
    local metatable = getmetatable(x)
    return not meta.is_nil(metatable.properties[property_name])
end

--- @brief get list of all property names
--- @param x meta.Object
--- @return Table
function meta.get_property_names(x)
    meta.assert_object(x)
    local out = {}
    for name, _ in pairs(getmetatable(x).properties) do
        table.insert(out, name)
    end
    return out
end

--- @brief make object immutable, this should be done inside the objects constructor
--- @param x meta.Object
--- @param b Boolean
function meta.set_is_mutable(x, b)
    meta.assert_object(x)
    meta.assert_boolean(b)
    getmetatable(x).is_mutable = b
end

--- @brief check if object is immutable
--- @param x meta.Object
--- @return Boolean
function meta.get_is_mutable(x)
    meta.assert_object(x);
    return getmetatable(x).is_mutable
end

--- @class meta.Object
meta.Object = "Object"

--- @brief create a new object instance
--- @param type meta.Type
--- @param fields Table property_name -> property_value
--- @vararg meta.Type
function meta.new(type, fields, ...)

    meta.assert_isa(type, meta.Type)

    if meta.is_nil(fields) then
        fields = {}
    else
        meta.assert_table(fields)
    end

    local out = {}
    if meta.isa(type, meta.Type) then
        out = meta._new(type.name)
    else
        meta.assert_string(type)
        out = meta._new(type)
    end

    meta.set_is_mutable(out, true)
    if meta.is_table(fields) then
        for name, value in pairs(fields) do
            meta.assert_string(name)
            meta._install_property(out, name, value)
        end
    else
        meta.assert_nil(fields)
    end

    meta._install_inheritance(out, type)

    for _, super in pairs({...}) do
        meta.assert_isa(super, meta.Type)
        meta._install_inheritance(out, super)
    end
    return out
end

--- @class meta.Enum
meta.Enum = "Enum"

--- @brief create a new immutable object
--- @param fields Table
function meta.new_enum(fields)

    meta.assert_table(fields)
    if is_empty(fields) then
        error("[rt][ERROR] In meta.new_enum: list of values cannot be empty")
    end

    local out = meta._new(meta.Enum)
    local used_values = {}

    local i = 0
    for name, value in pairs(fields) do
        meta.assert_string(name)

        if meta.is_table(value) then
            error("[rt][ERROR] In meta.new_enum: Enum value for key `" .. name .. "` is a `" .. meta.typeof(value) .. "`, which is not a primitive.")
        end

        if used_values[value] ~= nil then
            error("[rt][ERROR] In meta.new_enum: Duplicate value, key `" .. name .. "` and `" .. used_values[value] .. "` both have the same value `" .. tostring(value) .. "`")
        end
        used_values[value] = name

        meta._install_property(out, name, value)
    end

    local metatable = getmetatable(out)
    metatable.__pairs = function(this)
        return pairs(getmetatable(this).properties)
    end
    metatable.__ipairs = function(this)
        return ipairs(getmetatable(this).properties)
    end
    metatable.__index = function(this, key)
        if not meta.has_property(this, key) then
            error("[rt][ERROR] In Enum:__index: Key `" .. key .. "` does not exist for enum")
        else
            local metatable = getmetatable(this)
            return metatable.properties[key]
        end
    end

    meta.set_is_mutable(out, false)
    return out
end

--- @brief check if value is part of enum
--- @param x any
--- @param enum meta.Enum
function meta.is_enum_value(x, enum)
    meta.assert_isa(enum,  meta.Enum)
    for _, value in pairs(enum) do
        if x == value then
            return true
        end
    end
    return false
end

--- @brief throw if object is not an enum value
--- @param x any
--- @param enum meta.Enum
function meta.assert_enum(x, enum)
    if not meta.is_enum_value(x, enum) then
        error("[rt][ERROR] In assert_enum: Value `" .. tostring(x) .. "` is not a value of enum ")
    end
end

--- @brief [internal] apply properties of a type to an instance
--- @param instance meta.Object
--- @param type meta.Type
function meta._install_inheritance(instance, type)
    meta.assert_object(instance)
    meta.assert_isa(type, meta.Type)

    table.insert(getmetatable(instance).super, type.name)

    for key, value in pairs(getmetatable(type).properties) do
        if key ~= "name" and key ~= "is_abstract" and not meta.has_property(instance, key) then
            meta._install_property(instance, key, value)
        end
    end
end

--- @brief create a new type with given constructor
--- @param typename String
--- @param ctor Function
--- @param dtor Function
function meta.new_type(typename, ctor, dtor)
    meta.assert_string(typename)
    meta.assert_function(ctor)
    if not meta.is_nil(dtor) then meta.assert_function(dtor) end

    local out = meta._new("Type")
    out.name = typename
    out.is_abstract = false

    getmetatable(out).__call = function(self, ...)
        local out = ctor(...)
        if not meta.isa(out, self.name) then
            error("[rt][ERROR] In " .. self.name .. ".__call: Constructor does not return object of type `" .. self.name .. "`.")
        end
        getmetatable(out).__gc = dtor
        return out
    end

    if not meta.is_nil(meta.types[typename]) then
        error("[rt][ERROR] In meta.new_type: A type with name `" .. typename .. "` already exists.")
    end
    meta.types[typename] = out
    return out
end

--- @brief invoke destructor
--- @param x meta.Object
function meta.finalize(x)
    meta.assert_object(x)
    local metatable = getmetatable(x)
    if not meta.is_nil(metatable.__gc) and metatable.was_finalized == false then
        metatable.__gc(x)
        metatable.was_finalized = true
    end
end

--- @brief declare abstract type, this is a type that cannot be instanced
--- @param name String
function meta.new_abstract_type(name)
    local out = meta.new_type(name, function()
        error("[rt][ERROR] In " .. name .. "._call: Type `" .. name .. "` is abstract, it cannot be instanced")
    end)
    out.is_abstract = true
    return out
end

--- @class meta.Type
meta.Type = meta.new_type("Type", function()
    return meta.new(meta.Type)
end)

--- @class Function
meta.Function = meta.new_type("function", function()
    return function() end
end)

--- @class Nil
meta.Nil = meta.new_type("nil", function()
    return nil
end)

--- @class String
meta.String = meta.new_type("string", function()
    return ""
end)

--- @class Table
meta.Table = meta.new_type("table", function()
    return {}
end)

--- @class Boolean
meta.Boolean = meta.new_type("boolean", function()
    return false
end)

--- @class Number
meta.Number = meta.new_type("number", function()
    return 0
end)

--- @brief throw if object is not of given type
--- @param x any
--- @param type meta.Type
function meta.assert_isa(x, type)
    assert(not meta.is_nil(type))
    meta._assert_aux(meta.isa(x, type), x, type.name)
end

--- @brief make table weak, meaning it does not increase the reference count of its values
--- @param x Table
--- @param weak_keys Boolean
--- @param weak_values Boolean
function meta.make_weak(table, weak_keys, weak_values)

    if meta.is_nil(weak_keys) then weak_keys = true end
    if meta.is_nil(weak_values) then weak_values = true end

    meta.assert_table(table)
    meta.assert_boolean(weak_keys, weak_values)

    local metatable = getmetatable(table)
    if meta.is_nil(metatable) then
        metatable = {}
        setmetatable(table, metatable)
    end

    metatable.__mode = ""
    if weak_keys then
        metatable.__mode = metatable.__mode .. "k"
    end

    if weak_values then
        metatable.__mode = metatable.__mode .. "v"
    end

    return table
end

--- @brief Add abstract method that needs to be overloaded or an assertion is raised
--- @param super meta.Type
--- @param name String
function meta.declare_abstract_method(super, name)
    meta.assert_object(super)
    super[name] = function(self)
        error("[rt][ERROR] In " .. super.name .. "." .. name .. ": Abstract method called by object of type `" .. meta.typeof(self) .. "`")
    end
end

--- @brief hash object, each instance has a unique ID
function meta.hash(x)
    meta.assert_object(x)
    return getmetatable(x).__hash
end