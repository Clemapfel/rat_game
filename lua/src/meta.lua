--- @module meta Introspection and basic type sytem
meta = {}

--- @class String
meta.String = "string"

--- @brief is x a lua string?
--- @param x any
function meta.is_string(x)
    return type(x) == meta.String
end

--- @class Table
meta.Table = "table"

--- @brief is x a lua table?
--- @param x any
function meta.is_table(x)
    return type(x) == meta.Table
end

--- @class Number
meta.Number = "number"

--- @brief is x a lua number?
--- @param x any
function meta.is_number(x)
    return type(x) == "number"
end

--- @class Boolean
meta.Boolean = "boolean"

--- @brief is x a lua boolean?
--- @param x any
function meta.is_boolean(x)
    return type(x) == meta.Boolean
end

--- @class Nil
meta.Nil = "nil"

--- @brief is x nil?
--- @param x any
function meta.is_nil(x)
    return type(x) == meta.Nil
end

--- @class Function
meta.Function = "function"

---@brief is callable
--- @param x any
function meta.is_function(x)
    if type(x) == meta.Function then
        return true
    elseif getmetatable(x) ~= nil then
        return meta.is_function(getmetatable(x).__call)
    end
end

--- @brief [internal] access metatable used by module meta
function meta._get_metatable(x)
    return rawget(x, "__meta")
end

--- @brief [internal] Create new empty object
--- @param typename string type identifier
function meta._new(typename)
    meta.assert_string(typename)

    local out = {}
    out.__meta = {}
    out.__meta.typename = typename
    out.__meta.signals = {}
    out.__meta.properties = {}
    out.__meta.is_private = {}
    out.__meta.is_mutable = true
    out.__meta.notify = {}

    out.__meta.__index = function(this, property_name)
        local metatable = meta._get_metatable(this)

        if metatable.is_private[property_name] == true then
            error("In " .. metatable.typename .. ".__index: Cannot access property `" .. property_name .. "`, because it was declared private.")
        end
        return metatable.properties[property_name]
    end

    out.__meta.__newindex = function(this, property_name, property_value)
        local metatable = meta._get_metatable(this)
        if metatable.is_private[property_name] == true then
            error("In " .. metatable.typename .. ".__newindex: Cannot set property `" .. property_name .. "`, because it was declared private.")
        end
        if not metatable.is_mutable then
            error("In " .. metatable.typename .. ".__newindex: Cannot set property `" .. property_name .. "`, object was declared immutable.")
        end
        metatable.properties[property_name] = property_value
        local notify_cb_maybe = metatable.notify[property_name]
        if meta.is_function(notify_cb_maybe) then
            notify_cb_maybe(this, property_value)
        end
    end

    out.__meta.__tostring = function(this)
        return serialize("(" .. this.__meta.typename .. ")", this, false)
    end

    setmetatable(out, out.__meta)
    return out
end

--- @class Object
meta.Object = "object"

--- @brief is meta object
function meta.is_object(x)
    if not meta.is_table(x) then
        return false
    end
    return not (x.__meta == nil or x.__meta.typename == nil)
end

--- @brief get typename identifier
--- @return String
function meta.typeof(x)
    if not meta.is_table(x) then
        return type(x)
    else
        local metatable = meta._get_metatable(x)
        if meta.is_nil(metatable) then
            return meta.Table
        else
            return x.__meta.typename
        end
    end
end

--- @brief [internal] print type assertion error message
--- @param b Boolean true if no error, false otherwise
--- @param x Object
--- @param type String typename
function meta._assert_aux(b, x, type)
    if b then return true end
    local name = debug.getinfo(2, "n").name
    error("In " .. name .. ": expected `" .. type .. "`, got `" .. meta.typeof(x) .. "`")
    return false
end

--- @brief throw if object is not a boolean
function meta.assert_boolean(x)
    meta._assert_aux(meta.typeof(x) ==  meta.Boolean, x, meta.Boolean)
end

--- @brief throw if object is not a table
function meta.assert_table(x)
    meta._assert_aux(meta.typeof(x) ==  meta.Table, x, meta.Table)
end

--- @brief throw if object is not callable
function meta.assert_function(x)
    meta._assert_aux(meta.is_function(x), x, meta.Function)
end

--- @brief throw if object is not a string
function meta.assert_string(x)
    meta._assert_aux(meta.typeof(x) ==  meta.String, x, meta.String)
end

--- @brief throw if object is not a number
function meta.assert_number(x)
    meta._assert_aux(meta.typeof(x) ==  meta.Number, x, meta.Number)
end

--- @brief throw if object is not nil
function meta.assert_nil(x)
    meta._assert_aux(meta.typeof(x) ==  meta.Nil, x, meta.Nil)
end

--- @brief throw if object is not a meta.Object
function meta.assert_object(x)
    meta._assert_aux(meta.is_object(x), x, "meta.Object")
end

--- @brief throw if object is not of given type
--- @param x
--- @param type String
function meta.assert_isa(x, type)
    meta._assert_aux(meta.typeof(x) == type, x, type)
end

--- @brief [internal] add signal
function meta._install_signal(x, signal_name)

    meta.assert_object(x)
    meta.assert_string(signal_name)

    function Signal(name, instance)

        local out = meta._new("Signal")
        out.name = name
        out.is_blocked = false
        out.callback = function() end
        out.instance = instance
        out.set_is_blocked = function(this, b)
            this.is_blocked = b
        end
        out.get_is_blocked = function(this)
            return this.is_blocked
        end
        out.emit = function(this, ...)
            return this.callback(...)
        end
        out.connect = function(this, f)
            this.callback = f
        end
        out.disconnect = function(this)
            this.callback = function() end
        end
        return out
    end

    assert(meta.is_object(x))
    meta._get_metatable(x).signals[signal_name] = Signal(signal_name, x)
    rawset(x, "set_signal_" .. signal_name .. "_blocked", function(self, b)
        meta.assert_boolean(b)
        meta._get_metatable(x).signals[signal_name]:set_is_blocked(b)
    end)
    rawset(x, "get_signal_" .. signal_name .. "_blocked", function(self)
        return meta._get_metatable(x).signals[signal_name]:get_is_blocked()
    end)
    rawset(x, "emit_signal_" .. signal_name, function(self, ...)
        meta._get_metatable(x).signals[signal_name]:emit(...)
    end)
    rawset(x, "connect_signal_" .. signal_name, function(self, f)
        meta.assert_function(f)
        meta._get_metatable(x).signals[signal_name]:connect(f)
    end)
    rawset(x, "disconnect_signal_" .. signal_name, function(self)
        meta._get_metatable(x).signals[signal_name]:disconnect()
    end)
end

--- @brief [internal] add a property, set to intial value
function meta._install_property(x, property_name, initial_value, is_private)
    meta.assert_object(x);
    meta.assert_string(property_name)
    local metatable = meta._get_metatable(x)
    metatable.properties[property_name] = initial_value
    metatable.is_private[property_name] = (is_private == true)
end

--- @brief [internal] make object immutable
function meta._set_is_mutable(x, b)
    meta.assert_object(x);
    meta.assert_boolean(b)
    meta._get_metatable(x).is_mutable = b
end

--- @brief [internal] check if object is immutable
function meta._get_is_mutable(x)
    meta.assert_object(x);
    return meta._get_metatable(x).is_mutable
end

--- @brief create a new object instance
--- @param typename String type
--- @param fields Table property_name -> property_value
function meta.new(typename, fields)
    meta.assert_string(typename)
    local out = meta._new(typename)
    meta._set_is_mutable(out, true)
    if fiels ~= nil then
        for name, value in pairs(fields) do
            meta.assert_string(name)
            meta._install_property(out, name, value)
        end
    end
    return out
end

--- @brief create a new immutable object
--- @param fields Table
function meta.new_enum(fields)
    meta.assert_table(fields)
    local out = meta._new("Enum")
    meta._set_is_mutable(out, false)
    for name, value in pairs(fields) do
        meta.assert_string(name)
        if meta.is_table(value) or meta.is_nil(value) then
            error("In meta.new_enum: Enum value for key `" .. name .. "` is a `" .. meta.typeof(value) .. "`, which is not a primitive.")
        end
        meta._install_property(out, name, value)
    end
    return out
end

--- @brief add architecture for a signal to an object
--- @param x meta.Object
--- @param signal_name String
function meta.add_signal(x, signal_name)
    meta.assert_object(x) meta.assert_string(signal_name)

    if not meta._get_is_mutable(x) then
        error("In meta.add_signal: Object of type `" .. meta.typeof(x) .. "` was declared immutable.")
    end

    meta._install_signal(x, signal_name)
    return x
end

