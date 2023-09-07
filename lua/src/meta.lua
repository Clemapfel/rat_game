--- @module meta Introspection and basic type sytem
meta = {}

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

--- @brief [internal] Create new empty object
--- @param typename String
function meta._new(typename)
    meta.assert_string(typename)

    local out = {}
    out.__metatable = {}
    metatable = out.__metatable

    metatable.__name = typename
    metatable.properties = {}
    metatable.is_private = {}
    metatable.is_mutable = true
    metatable.components = {}

    metatable.__index = function(this, property_name)
        local metatable = getmetatable(this)
        if metatable.is_private[property_name] == true then
            error("[rt] In " .. metatable.__name .. ".__index: Cannot access property `" .. property_name .. "`, because it was declared private.")
        end
        return metatable.properties[property_name]
    end

    metatable.__newindex = function(this, property_name, property_value)
        local metatable = getmetatable(this)
        if metatable.is_private[property_name] == true then
            error("[rt] In " .. metatable.__name .. ".__newindex: Cannot set property `" .. property_name .. "`, because it was declared private.")
        end
        if not metatable.is_mutable then
            error("[rt] In " .. metatable.__name .. ".__newindex: Cannot set property `" .. property_name .. "`, because the object was declared immutable.")
        end
        metatable.properties[property_name] = property_value

        -- trigger notify signals, c.f. `signal_component.lua`
        if metatable.signals == nil then return end
        this.signals:emit(rt.SignalComponent._notify_prefix .. property_name, property_value)
    end

    metatable.__tostring = function(this)
        return serialize("(" .. getmetatable(this).__name .. ")", this, false)
    end

    metatable.__name = metatable.__name
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
    if not meta.is_table(x) then
        return type(x)
    else
        local metatable = getmetatable(x)
        if meta.is_nil(metatable) then
            return meta.Table.name
        else
            return meta[getmetatable(x).__name]
        end
    end
end

--- @brief check if type of object is as given
--- @return Boolean
function meta.isa(x, type)
    return meta.typeof(x) == type
end

--- @brief [internal] print type assertion error message
--- @param b Boolean true if no error, false otherwise
--- @param x meta.Object
--- @param type String typename
function meta._assert_aux(b, x, type)
    if b then return true end
    local name = debug.getinfo(2, "n").name
    error("[rt] In " .. name .. ": expected `" .. type .. "`, got `" .. meta.typeof(x) .. "`")
    return false
end

--- @brief throw if false
--- @param b Boolean
function meta.assert(b)
    meta.assert_boolean(b)
    if not b then
        local name = debug.getinfo(2, "n").name
        error("[rt] In " .. name .. ": Assertion failed")
    end
end

--- @brief throw if object is not a boolean
--- @param x any
function meta.assert_boolean(x, ...)
    meta._assert_aux(meta.is_boolean(x), x, "boolean")
    for _, n in ipairs({...}) do
        meta._assert_aux(meta.is_boolean(n), n, "boolean")
    end
end

--- @brief throw if object is not a table
--- @param x any
function meta.assert_table(x, ...)
    meta._assert_aux(meta.is_table(x), x, "table")
    for _, n in ipairs({...}) do
        meta._assert_aux(meta.is_table(n), n, "table")
    end
end

--- @brief throw if object is not callable
--- @param x any
function meta.assert_function(x, ...)
    meta._assert_aux(meta.is_function(x), x, "function")
    for _, n in ipairs({...}) do
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
    for _, number in ipairs({...}) do
        meta._assert_aux(meta.is_number(number), number, "number")
    end
end

--- @brief throw if object is not nil
--- @param x any
function meta.assert_nil(x, ...)
    meta._assert_aux(meta.is_nil(x), x, "typeof(nil)")
    for _, number in ipairs({...}) do
        meta._assert_aux(meta.is_nil(number), number, "typeof(nil)")
    end
end

--- @brief assert that object was created using `meta.new`
--- @param x any
function meta.assert_object(x, ...)
    meta._assert_aux(meta.is_object(x), x, "meta.Object")
    for _, number in ipairs({...}) do
        meta._assert_aux(meta.is_object(number), number, "meta.Object")
    end
end

--- @brief [internal] add a property, set to intial value
--- @param x meta.Object
--- @param property_name String
--- @param initial_value any
--- @param is_private Boolean
function meta._install_property(x, property_name, initial_value, is_private)
    meta.assert_object(x);
    meta.assert_string(property_name)
    if not meta.is_nil(is_private) then
        meta.assert_boolean(is_private)
    end
    local metatable = getmetatable(x)
    metatable.properties[property_name] = initial_value
    metatable.is_private[property_name] = (is_private == true)
end

--- @brief [internal] add a property, set to intial value
--- @param x meta.Object
--- @param property_name String
function meta._uninstall_property(x, property_name)
    meta.assert_object(x)
    meta.assert_string(property_name)
    local metatable = getmetatable(x)
    metatable.properties[property_name] = nil
    metatable.is_private[property_name] = nil
end

--- @brief get whether property is installed
--- @param x meta.Object
--- @param property_name String
--- @return Boolean
function meta.has_property(x, property_name)
    meta.assert_object(x)
    meta.assert_string(property_name)
    local metatable = getmetatable(x)
    if metatable == nil or metatable.is_private == nil then
        return false
    end
    return meta.is_boolean(metatable.is_private[property_name])
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

--- @brief declare property as immutable
--- @param x any
function meta.set_is_private(x, property_name, b)
    meta.assert_object(x)
    meta.assert_string(property_name)
    meta.assert_boolean(b)
    
    local private_table = getmetatable(x).is_private
    if not meta.is_boolean(private_table[property_name]) then
        error("[rt] In meta.set_is_private: Object of type `" ..  meta.typeof(x) .. "` does not yet have a property named `" ..  property_name .. "`")
    end
    private_table[property_name] = b
end

--- @brief get whether property was declared private
--- @param x meta.Object
--- @param property_name String
function meta.get_is_private(x, property_name)
    meta.assert_object(x)
    meta.assert_string(property_name)
    local private_table = getmetatable(x).is_private

    if not meta.is_boolean(private_table[property_name]) then
        error("[rt] In meta.get_is_private: Object of type `" ..  meta.typeof(x) .. "` does not yet have a property named `" ..  property_name .. "`")
    end
    return getmetatable(x).is_private[property_name]
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
function meta.new(type, fields)

    meta.assert_isa(type, "Type")
    meta.assert_table(fields)

    local out = {}
    if meta.isa(type, "Type") then
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
    return out
end

--- @class meta.Enum
meta.Enum = "Enum"

--- @brief create a new immutable object
--- @param fields Table
function meta.new_enum(fields)

    meta.assert_table(fields)
    if is_empty(fields) then
        error("[rt] In meta.new_enum: list of values cannot be empty")
    end

    local out = meta._new(meta.Enum)
    local used_values = {}

    local i = 0
    for name, value in pairs(fields) do
        meta.assert_string(name)

        if meta.is_table(value) then
            error("[rt] In meta.new_enum: Enum value for key `" .. name .. "` is a `" .. meta.typeof(value) .. "`, which is not a primitive.")
        end

        if used_values[value] ~= nil then
            error("[rt] In meta.new_enum: Duplicate value, key `" .. name .. "` and `" .. used_values[value] .. "` both have the same value `" .. tostring(value) .. "`")
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

    meta.set_is_mutable(out, false)
    return out
end

--- @brief check if value is part of enum
--- @param x any
--- @param enum meta.Enum
function meta.is_enum(x, enum)
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
    if not meta.is_enum(x, enum) then
        error("[rt] In assert_enum: Value `" .. tostring(x) .. "` is not a value of enum")
    end
end

--- @class meta.Type
meta.Type = "Type"

--- @brief create a new type with given constructor
--- @param typename String
--- @param ctor Function
function meta.new_type(typename, ctor)
    meta.assert_string(typename)
    meta.assert_function(ctor)

    local out = meta._new(meta.Type)
    out.name = typename

    getmetatable(out).__call = function(self, ...)
        local out = ctor(...)
        if not meta.isa(out, self.name) then
            error("[rt] In " .. self.name .. ".__call: Constructor does not return object of type `" .. self.name .. "`.")
        end

        -- automatically add any fields or functions that were defined for the type
        for key, value in pairs(getmetatable(self).properties) do
            if not meta.has_property(out, key) then
                meta._install_property(out, key, value)
            end
        end
        return out
    end

    if meta[typename] ~= nil then
        error("[rt] In meta.new_type: A type with name `" .. typename .. "` already exists.")
    end
    meta[typename] = typename
    return out
end

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

    if meta.typeof(type) == "Type" then
        meta._assert_aux(meta.typeof(x) == type.name, x, type.name)
    else
        meta.assert_string(type)
        meta._assert_aux(meta.typeof(x) == type, x, type)
    end
end
