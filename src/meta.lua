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
    return x == true or x == false
end

--- @brief is x nil?
--- @param x any
function meta.is_nil(x)
    return x == nil
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
    local out = {}
    out.__metatable = {}
    metatable = out.__metatable

    metatable.__name = typename._typename
    metatable.__hash = meta._hash
    meta._hash = meta._hash + 1
    metatable.properties = {}
    metatable.is_mutable = true
    metatable.super = {}
    metatable.components = {}

    metatable.__index = function(this, property_name)
        return getmetatable(this).properties[property_name]
    end

    metatable.__newindex = function(this, property_name, property_value)
        local metatable = getmetatable(this)
        if not metatable.is_mutable then
            rt.error("In " .. metatable.__name .. ".__newindex: Cannot set property `" .. property_name .. "`, because the object was declared immutable.")
        end
        metatable.properties[property_name] = property_value
    end


    metatable.__tostring = function(this)
        return "(" .. getmetatable(this).__name .. ") " .. serialize(this)
    end

    metatable.__eq = function(self, other)
        return getmetatable(self).__hash == getmetatable(other).__hash
    end
    setmetatable(out, metatable)

    return out, metatable
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
    if meta.is_object(x) then
        return getmetatable(x).__name
    else
        return type(x)
    end
end

--- @brief check if instance has type as super
function meta.inherits(x, super)
    for _, name in pairs(getmetatable(x).super) do
        if name == super._typename then
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
    rt.error("In " .. name .. ": expected `" .. type .. "`, got `" .. meta.typeof(x) .. "`")
    return false
end

--- @brief throw if false
--- @param b Boolean
function meta.assert(b)
    if not b then
        local name = debug.getinfo(2, "n").name
        rt.error("In " .. name .. ": Assertion failed")
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
        meta._assert_aux(meta.inherits(x, type), x, type._typename)
    else
        meta._assert_aux(meta.inherits(x, type), x, type)
    end
end

--- @brief [internal] add a property, set to intial value
--- @param x meta.Object
--- @param property_name String
function meta._uninstall_property(x, property_name)
    local metatable = getmetatable(x)
    metatable.properties[property_name] = nil
end

--- @brief get whether property is installed
--- @param x meta.Object
--- @param property_name String
--- @return Boolean
function meta.has_property(x, property_name)
    local metatable = getmetatable(x)
    return not meta.is_nil(metatable.properties[property_name])
end

--- @brief get list of all property names
--- @param x meta.Object
--- @return Table
function meta.get_property_names(x)
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
    getmetatable(x).is_mutable = b
end

--- @brief check if object is immutable
--- @param x meta.Object
--- @return Boolean
function meta.get_is_mutable(x)
    return getmetatable(x).is_mutable
end

--- @class meta.Object
meta.Object = "Object"

--- @brief create a new object instance
--- @param type meta.Type
--- @param fields Table property_name -> property_value
--- @vararg meta.Type
function meta.new(type, fields, ...)
    if meta.is_nil(fields) then
        fields = {}
    end

    out, metatable = meta._new(type)
    meta.set_is_mutable(out, true)

    if meta.is_table(fields) then
        for name, value in pairs(fields) do
            metatable.properties[name] = value
        end
    end

    --[[
    local metatable = getmetatable(instance)
    metatable.super[type._typename] = true

    for key, value in pairs(getmetatable(type).properties) do
        if instance[key] == nil then
            metatable.properties[key] = value
        end
    end
    ]]--

    local installed = {}
    for key, value in pairs(getmetatable(type).properties) do
        metatable.properties[key] = value
    end

    metatable.super[type._typename] = true

    for _, super in pairs({...}) do
        metatable.super[super._typename] = true
        for key, value in pairs(getmetatable(super).properties) do
            if metatable.properties[key] == nil then
                metatable.properties[key] = value
            end
        end
    end
    return out
end

--- @class meta.Enum
meta.Enum = "Enum"

--- @brief create a new immutable object
--- @param fields Table
function meta.new_enum(fields)
    if is_empty(fields) then
        rt.error("In meta.new_enum: list of values cannot be empty")
    end

    local out, metatable = meta._new(meta.Enum)
    local used_values = {}

    local i = 0
    for name, value in pairs(fields) do

        if meta.is_table(value) then
            rt.error("In meta.new_enum: Enum value for key `" .. name .. "` is a `" .. meta.typeof(value) .. "`, which is not a primitive.")
        end

        if used_values[value] ~= nil then
            rt.error("In meta.new_enum: Duplicate value, key `" .. name .. "` and `" .. used_values[value] .. "` both have the same value `" .. tostring(value) .. "`")
        end
        used_values[value] = name

        metatable.properties[name] = value
    end

    metatable.__pairs = function(this)
        return pairs(getmetatable(this).properties)
    end
    metatable.__ipairs = function(this)
        return ipairs(getmetatable(this).properties)
    end
    metatable.__index = function(this, key)
        if not meta.has_property(this, key) then
            rt.error("In Enum:__index: Key `" .. key .. "` does not exist for enum")
        else
            local metatable = getmetatable(this)
            return metatable.properties[key]
        end
    end

    meta.set_is_mutable(out, false)
    return out
end


--- @brief check if type of object is as given
--- @param type meta.Type (or String)
--- @return Boolean
function meta.isa(x, type)
    local metatable = getmetatable(x)
    if meta.is_nil(metatable) or meta.is_nil(metatable.super) then
        return false
    else
        return metatable.super[type._typename] == true
    end

end

--- @brief check if value is part of enum
--- @param x any
--- @param enum meta.Enum
function meta.is_enum_value(x, enum)
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
        rt.error("In assert_enum: Value `" .. meta.typeof(x) .. "` is not a value of enum `" .. serialize(getmetatable(enum).properties) .. "`")
    end
end

--- @brief throw if object is not of given type
--- @param x any
--- @param type meta.Type
function meta.assert_isa(x, type)
    if not meta.is_string(type) and (not meta.is_object(type) or not getmetatable(type).__typename == "Type") then
        rt.error("In meta.assert_isa: object `" .. meta.typeof(type) .. "` is not a type")
    end
    meta._assert_aux(meta.isa(x, type), x, type._typename)
end

--- @brief [internal] add meta.is_* and meta.assert_* given type
function meta._define_type_assertion(typename)

    if #typename == 0 or typename == "nil" or typename == "number" or typename == "table" or typename == "boolean" or typename == "function" or typename == "userdata" then return end

    function string.to_snake_case(str, screaming)
        local out = {""}
        table.insert(out, string.lower(string.sub(str, 1, 1)))
        for i = 2, #str do
            local c = string.sub(str, i, i)
            if string.is_upper(c) then
                table.insert(out, "_")
            end
            table.insert(out, ternary(screaming == true, string.upper(c), string.lower(c)))
        end
        return table.concat(out)
    end

    local assert_name = "assert_" .. string.to_snake_case(typename)
    local is_name = "is_" .. string.to_snake_case(typename)

    if type(meta[assert_name] == "nil") then
        load("function meta." .. assert_name .. "(x)\n meta.assert_isa(x, meta.types[\"" .. typename .. "\"])\nend")()
    end

    if type(meta[is_name] == "nil") then
        load("function meta." .. is_name .. "(x)\n return meta.isa(x, meta.types[\"" .. typename .. "\"])\nend")()
    end
end

meta._typenames = {}

--- @brief [internal]
function meta._type_id_to_typename(id)
    return meta._typenames[id]
end

--- @brief create a new type with given constructor, this also defines `meta.is_*` and `meta.assert_*` for typename
--- @param typename String
--- @param ctor Function
function meta.new_type(typename, ctor)
    local out = meta._new("Type")
    local metatable = getmetatable(out)

    local type_id = string.hash(typename)
    rawset(metatable.properties, "_typename", typename)
    rawset(metatable.properties, "_type_id", type_id)

    metatable.__call = function(self, ...)
        local out = ctor(...)
        if not meta.isa(out, self) then
            rt.error("In " .. self._typename .. ".__call: Constructor does not return object of type `" .. self._typename .. "`.")
        end
        return out
    end

    if not meta.is_nil(meta.types[typename]) then
        rt.error("In meta.new_type: A type with name `" .. typename .. "` already exists.")
    end
    meta.types[typename] = out
    meta._define_type_assertion(typename)
    return out
end

--- @brief declare abstract type, this is a type that cannot be instanced
--- @param name String
function meta.new_abstract_type(name)
    local out = meta.new_type(name, function()
        rt.error("In " .. name .. "._call: Type `" .. name .. "` is abstract, it cannot be instanced")
    end)
    return out
end

--- @class meta.Type
meta.Type = meta.new_type("Type", function()
    return meta.new(meta.Type)
end)

--- @class Function
--- @class Nil
--- @class String
--- @class Table
--- @class Boolean
--- @class Number

--- @brief make table weak, meaning it does not increase the reference count of its values
--- @param x Table
--- @param weak_keys Boolean
--- @param weak_values Boolean
function meta.make_weak(table, weak_keys, weak_values)

    if meta.is_nil(weak_keys) then weak_keys = true end
    if meta.is_nil(weak_values) then weak_values = true end

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

--- @brief create an empty weak table
--- @param weak_keys Boolean
--- @param weak_values Boolean
function meta.weak_table(weak_keys, weak_values)
    local out = {}
    meta.make_weak(out, weak_keys, weak_values)
    return out
end

--- @brief Add abstract method that needs to be overloaded or an assertion is raised
--- @param super meta.Type
--- @param name String
function meta.declare_abstract_method(super, name)
    super[name] = function(self)
        rt.error("In " .. super._typename .. "." .. name .. ": Abstract method called by object of type `" .. meta.typeof(self) .. "`")
    end
end

--- @brief hash object, each instance has a unique ID
function meta.hash(x)
    return getmetatable(x).__hash
end
