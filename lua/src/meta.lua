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
function getmetatable(x)
    return rawget(x, "__meta")
end

--- @class meta.Object
--- @brief [internal] Create new empty object
--- @param typename string type identifier
function meta._new(typename)
    meta.assert_string(typename)

    local out = {}
    out.__meta = {}
    out.__meta.typename = typename
    out.__meta.properties = {}
    out.__meta.is_private = {}
    out.__meta.is_mutable = true

    out.__meta.__index = function(this, property_name)
        local metatable = getmetatable(this)
        if metatable.is_private[property_name] == true then
            error("In " .. metatable.typename .. ".__index: Cannot access property `" .. property_name .. "`, because it was declared private.")
        end
        return metatable.properties[property_name]
    end

    out.__meta.__newindex = function(this, property_name, property_value)
        local metatable = getmetatable(this)
        if metatable.is_private[property_name] == true then
            error("In " .. metatable.typename .. ".__newindex: Cannot set property `" .. property_name .. "`, because it was declared private.")
        end
        if not metatable.is_mutable then
            error("In " .. metatable.typename .. ".__newindex: Cannot set property `" .. property_name .. "`, object was declared immutable.")
        end
        metatable.properties[property_name] = property_value

        if metatable.notify == nil then return end
        local notify = metatable.notify[property_name]
        if meta.is_table(notify) and not notify.is_blocked  then
            notify.callback(this, property_value)
        end
    end

    out.__meta.__tostring = function(this)
        return serialize("(" .. this.__meta.typename .. ")", this, false)
    end

    setmetatable(out, out.__meta)

    local function assert_has_signal(this, signal_name)
        if this.__meta.signals[signal_name] ~= nil then
            return
        end
        local info = debug.getinfo(2, "n")
        error("In " .. meta.typeof(this) .. "." .. info.name .. ": No signal with ID `" .. signal_name .. "` registered.")
    end

    local function init_notify(x, name)
        if meta.is_table(x.__meta.notify[name]) then return end
        x.__meta.notify = {}
        x.__meta.notify[name] = {
            is_blocked = false,
            callback = function()  end
        }
    end

    --- @brief block signal emission
    --- @param name String
    --- @param b Boolean
    out.set_signal_blocked = function(this, name, b)
        meta.assert_string(name) meta.assert_boolean(b)
        assert_has_signal(this, name)
        this.__meta.signals[name].is_blocked = b
    end

    --- @brief check if signal is blocked
    --- @param name String
    out.get_signal_blocked = function(this, name)
        meta.assert_string(name)
        assert_has_signal(this, name)
        return this.__meta.signals[name].is_blocked
    end

    --- @brief register a callback, called on emission
    --- @param name String
    --- @param callback Function With signature (Instance, ...) -> Any
    out.connect_signal = function(this, name, callback)
        meta.assert_string(name) meta.assert_function(callback)
        assert_has_signal(this, name)
        this.__meta.signals[name].callback = callback
    end

    --- @brief reset signal handler
    --- @param name String
    out.disconnect_signal = function(this, name)
        meta.assert_string(name)
        assert_has_signal(this, name)
        this.__meta.signals[name].callback = function () end
    end

    --- @brief emit signal
    --- @param name String
    --- @param args... any
    out.emit_signal = function(this, name, ...)
        meta.assert_string(name)
        assert_has_signal(this, name)
        this.__meta.signals[name].callback(this, ...)
    end

    --- @brief block notification
    --- @param name String
    --- @param b Boolean
    out.set_notify_blocked = function(this, name, b)
        meta.assert_string(name) meta.assert_boolean(b)
        init_notify(this, name)
        this.__meta.notify[name].is_blocked = b
    end

    --- @brief check if notification is blocked
    --- @param name String
    out.get_notify_blocked = function(this, name)
        meta.assert_string(name)
        init_notify(this, name)
        return this.__meta.notify[name].is_blocked
    end

    --- @brief register a callback, called when property with given name changes
    --- @param name String
    --- @param callback Function With signature (Instance, ...) -> Any
    out.connect_notify = function(this, name, callback)
        meta.assert_string(name) meta.assert_function(callback)
        init_notify(this, name)
        this.__meta.notify[name].callback = callback
    end

    --- @brief reset notification handler
    --- @param name String
    out.disconnect_notify = function(this, name)
        meta.assert_string(name)
        init_notify(this, name)
        this.__meta.notify[name].callback = function () end
    end

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
        local metatable = getmetatable(x)
        if meta.is_nil(metatable) then
            return meta.Table
        else
            return x.__meta.typename
        end
    end
end

--- @brief check if type is as given
--- @param x
--- @param type string
function meta.isa(x, type)
    return meta.typeof(x) == type
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

    local metatable = getmetatable(x)
    if meta.is_nil(metatable.signals) then
        metatable.signals = {}
    end

    metatable.signals[signal_name] = {
        is_blocked = false,
        callback = function() end
    }
end

--- @brief [internal] remove signal
function meta._uninstall_signal(x, signal_name)

    meta.assert_object(x)
    meta.assert_string(signal_name)

    local metatable = getmetatable(x)
    metatble.signals[signal_name] = nil

    if is_empty(metatable).signals then
        metatable.signals = nil
    end
end

--- @brief [internal] add a property, set to intial value
function meta._install_property(x, property_name, initial_value, is_private)
    meta.assert_object(x);
    meta.assert_string(property_name)
    local metatable = getmetatable(x)
    metatable.properties[property_name] = initial_value
    metatable.is_private[property_name] = (is_private == true)
end

--- @brief [internal] add a property, set to intial value
function meta._uninstall_property(x, property_name)
    meta.assert_object(x);
    meta.assert_string(property_name)
    local metatable = getmetatable(x)
    metatable.properties[property_name] = nil
    metatable.is_private[property_name] = nil
end

--- @brief [internal] make object immutable
function meta._set_is_mutable(x, b)
    meta.assert_object(x);
    meta.assert_boolean(b)
    getmetatable(x).is_mutable = b
end

--- @brief [internal] check if object is immutable
function meta._get_is_mutable(x)
    meta.assert_object(x);
    return getmetatable(x).is_mutable
end

--- @brief create a new object instance
--- @param type
--- @param fields Table property_name -> property_value
function meta.new(type, fields)

    local out = {}
    if meta.isa(typename, "Type") then
        out = meta._new(type.name)
    else
        meta.assert_string(type)
        out = meta._new(type)
    end

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

function meta.new_type(typename, ctor)
    meta.assert_string(typename) meta.assert_function(ctor)
    local out = meta._new("Type")
    out.name = typename
    getmetatable(out).__call = ctor
    meta._set_is_mutable(out, false)
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

