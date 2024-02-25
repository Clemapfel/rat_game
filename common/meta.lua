--- @module meta Introspection and basic type sytem
meta = {}
meta.types = {}

if _G._pairs == nil then _G._pairs = pairs end

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

meta._hash = 1

--- @brief [internal] Create new empty object
--- @param typename String
function meta._new(typename)
    -- uses indices instead of proper names or getmetatable for micro optimization
    local out = {}
    out[1] = {}  -- metatable
    metatable = out[1]

    metatable.__name = typename._typename
    metatable.__hash = meta._hash
    meta._hash = meta._hash + 1
    metatable[1] = {}       -- properties
    metatable[2] = true     -- is_mutable
    metatable.components = {}
    metatable.super = {}

    metatable.__index = function(this, property_name)
        return this[1][1][property_name]
    end

    metatable.__newindex = function(this, property_name, property_value)
        local metatable = this[1]
        if not metatable[2] then
            rt.error("In " .. metatable.__name .. ".__newindex: Cannot set property `" .. property_name .. "`, because the object was declared immutable.")
        end
        metatable[1][property_name] = property_value
    end

    metatable.__tostring = function(this)
        return "(" .. this[1].__name .. ") " .. meta.serialize(this)
    end

    metatable.__eq = function(self, other)
        return self[1].__hash == other[1].__hash
    end

    metatable.__pairs = function(self)
        return _G._pairs(self[1][1])
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
        return x[1].__name
    else
        return type(x)
    end
end

--- @brief check if instance has type as super
function meta.inherits(x, super)
    if meta.is_object(x) then
        for _, name in _G._pairs(x[1].super) do
            if name == super._typename then
                return true
            end
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
    for n in range(...) do
        meta._assert_aux(meta.is_boolean(n), n, "boolean")
    end
end

--- @brief throw if object is not a table
--- @param x any
function meta.assert_table(x, ...)
    meta._assert_aux(meta.is_table(x), x, "table")
    for n in range(...) do
        meta._assert_aux(meta.is_table(n), n, "table")
    end
end

--- @brief throw if object is not callable
--- @param x any
function meta.assert_function(x, ...)
    meta._assert_aux(meta.is_function(x), x, "function")
    for n in range(...) do
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
    for number in range(...) do
        meta._assert_aux(meta.is_number(number), number, "number")
    end
end

--- @brief throw if object is not nil
--- @param x any
function meta.assert_nil(x, ...)
    meta._assert_aux(meta.is_nil(x), x, "typeof(nil)")
    for number in range(...) do
        meta._assert_aux(meta.is_nil(number), number, "typeof(nil)")
    end
end

--- @brief assert that object was created using `meta.new`
--- @param x any
function meta.assert_object(x, ...)
    meta._assert_aux(meta.is_object(x), x, "meta.Object")
    for number in range(...) do
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
function meta.uninstall_property(x, property_name)
    x[1][1][property_name] = nil
end

--- @brief add property after construction
function meta.install_property(x, name, value)
    x[1][1][name] = value
end

--- @brief get whether property is installed
--- @param x meta.Object
--- @param property_name String
--- @return Boolean
function meta.has_property(x, property_name)
    return not meta.is_nil(x[1][1][property_name])
end

--- @brief get list of all property names
--- @param x meta.Object
--- @return Table
function meta.get_property_names(x)
    local out = {}
    for name, _ in _G._pairs(x[1][1]) do
        table.insert(out, name)
    end
    return out
end

--- @brief get single property
--- @return Table
function meta.get_property(x, name)
    return x[1][1][name]
end

--- @brief get list of properties
--- @return Table
function meta.get_properties(x)
    return x[1][1]
end

--- @brief add list of properties, useful for types
--- @param x meta.Type
--- @param properties Table
function meta.add_properties(x, properties)
    for name, value in _G._pairs(properties) do
        meta.install_property(x, name, value)
    end
end

--- @brief make object immutable, this should be done inside the objects constructor
--- @param x meta.Object
--- @param b Boolean
function meta.set_is_mutable(x, b)
    x[1][2] = b
end

--- @brief check if object is immutable
--- @param x meta.Object
--- @return Boolean
function meta.get_is_mutable(x)
    return x[1][2]
end

--- @class meta.Object
meta.Object = "Object"

--- @brief [internal] recursively install all types and super types of types, used in meta.new
function meta._install_super(super)
    if metatable.super[super._typename] ~= true then
        metatable.super[super._typename] = true
        for key, value in _G._pairs(super[1][1]) do  -- getmetatable(super).properties
            if metatable[1][key] == nil then -- properties[key]
                metatable[1][key] = value
            end
        end

        for _, supersuper in _G._pairs(super._super) do
            meta._install_super(supersuper)
        end
    end
end

--- @brief create a new object instance
--- @param type meta.Type
--- @param fields Table property_name -> property_value
function meta.new(type, fields)
    out, metatable = meta._new(type)
    metatable[2] = true -- out:set_mutable

    if fields ~= nil then
        for name, value in _G._pairs(fields) do
            metatable[1][name] = value
        end
    end

    for key, value in _G._pairs(type[1][1]) do   -- getmetatable(type).properties
        metatable[1][key] = value
    end

    meta._install_super(type)
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

    local i = 0
    for name, value in _G.pairs(fields) do
        if meta.is_table(value) then
            rt.error("In meta.new_enum: Enum value for key `" .. name .. "` is a `" .. meta.typeof(value) .. "`, which is not a primitive.")
        end
        metatable[1][name] = value
    end

    metatable.__pairs = function(this)
        return _G._pairs(this[1][1])
    end
    metatable.__ipairs = function(this)
        return ipairs(this[1][1])
    end
    metatable.__index = function(this, key)
        return this[1][1][key]
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
    for _, value in _G._pairs(enum) do
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
        rt.error("In assert_enum: Value `" .. meta.typeof(x) .. "` is not a value of enum `" .. serialize(enum[1][1]) .. "`")
    end
end

--- @brief throw if object is not of given type
--- @param x any
--- @param type meta.Type
function meta.assert_isa(x, type)
    meta._assert_aux(meta.isa(x, type), x, type._typename)
end

--- @brief [internal] add meta.is_* and meta.assert_* given type
function meta._define_type_assertion(typename)

    if string.len(typename) == 0 or typename == "nil" or typename == "number" or typename == "table" or typename == "boolean" or typename == "function" or typename == "userdata" then return end

    function string.to_snake_case(str, screaming)
        local out = {""}
        table.insert(out, string.lower(string.sub(str, 1, 1)))
        for i = 2, string.len(str) do
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

--- @brief [internal]
function meta._default_ctor(self)
    return meta.new(self)
end

function meta.new_type(typename, ...)
    local out = meta._new("Type")
    local metatable = out[1]
    metatable.__name = "Type"
    metatable.super = {
        ["Type"] = true
    }

    local super, fields, ctor = {}, {}, nil
    local fields_seen, ctor_seen = false, false
    for _, value in _G._pairs({...}) do
        if meta.isa(value, meta.Type) then
            table.insert(super, value)
        elseif meta.is_function(value) then
            ctor = value
            if ctor_seen then
                rt.error("In meta.new_type: more than one constructor in variadic argument")
            end
            ctor_seen = true
        elseif meta.is_table(value) then
            fields = value
            if fields_seen then
                rt.error("In meta.new_type: more than one property table in variadic argument")
            end
            fields_seen = true
        else
            rt.error("In meta.new_type: Unrecognized variadic argument `" .. tostring(value) .. "` of type `" .. meta.typeof(value) .. "`")
        end
    end

    metatable[1]._typename = typename
    metatable[1]._type_id = string.hash(typename)
    metatable[1]._super = which(super, {})

    if not meta.is_nil(ctor) then
        -- custom constructor
        metatable.__call = function(self, ...)
            local out = ctor(...)
            if not meta.isa(out, self) then
                rt.error("In " .. self._typename .. ".__call: Constructor does not return object of type `" .. self._typename .. "`.")
            end
            return out
        end
    else
        -- default constructor
        metatable.__call = meta._default_ctor
    end

    if not meta.is_nil(meta.types[typename]) then
        rt.error("In meta.new_type: A type with name `" .. typename .. "` already exists.")
    end
    meta.types[typename] = out
    meta._define_type_assertion(typename)

    for key, value in _G._pairs(fields) do
        meta.install_property(out, key, value)
    end
    return out
end

function meta.new_abstract_type(name, ...)
    local to_splat = {}
    table.insert(to_splat, function()
        rt.error("In " .. name .. "._call: Type `" .. name .. "` is abstract, it cannot be instanced")
    end)

    for value in range(...) do
        table.insert(to_splat, value)
    end

    return meta.new_type(name, splat(to_splat))
end

--- @brief get all super types of instance or type
function meta.get_supertypes(instance)
    return instance[1].super
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
    return x[1].__hash
end

--- @brief serialize meta.Object
function meta.serialize(x, skip_functions)
    meta.assert_object(x)
    skip_functions = which(skip_functions, true)
    local out = {}
    table.insert(out, "#" .. tostring(meta.hash(x)) .. " = {\n")
    for key, value in _G._pairs(x[1][1]) do
        if not meta.is_function(value) then
            table.insert(out, "\t" .. tostring(key)  .. " = " .. serialize(value) .. "\n")
        end
    end

    table.insert(out, "}\n")
    return table.concat(out)
end
