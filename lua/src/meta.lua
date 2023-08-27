--- @module meta Introspection and basic type sytem
meta = {}

--- @class Function
meta.Function = "function"

--- @class Nil
meta.Nil = "nil"

--- @class String
meta.String = "string"

--- @class Table
meta.Table = "table"

--- @class Boolean
meta.Boolean = "boolean"

--- @class Number
meta.Number = "number"

--- @brief is x a lua string?
--- @param x any
function meta.is_string(x)
    return type(x) == meta.String
end

--- @brief is x a lua table?
--- @param x any
function meta.is_table(x)
    return type(x) == meta.Table
end

--- @brief is x a lua number?
--- @param x any
function meta.is_number(x)
    return type(x) == meta.Number
end

--- @brief is x a lua boolean?
--- @param x any
function meta.is_boolean(x)
    return type(x) == meta.Boolean
end

--- @brief is x nil?
--- @param x any
function meta.is_nil(x)
    return type(x) == meta.Nil
end

---@brief is callable
--- @param x any
function meta.is_function(x)
    if type(x) == meta.Function then
        return true
    elseif meta.is_table(x) and getmetatable(x) ~= nil then
        return meta.is_function(getmetatable(x).__call)
    else
        return false
    end
end

--- @brief [internal] create signal architecture
function meta._initialize_signals(x)

    local mt = getmetatable(x)
    if mt.signals ~= nil then
        return
    end
    mt.signals = {}

    local function init_signal(x, name)
        if meta.is_table(getmetatable(x).signals[name]) then return end
        getmetatable(x).signals[name] = {
            is_blocked = false,
            n = 0,
            callbacks = {}
        }
    end

    local function assert_has_signal(x, name, scope)
        if getmetatable(x).signals[name] == nil then
            error("In " .. meta.typeof(x) .. "." .. scope .. ": Object has no signal with name `" .. name .. "`")
        end
    end

    --- @brief allow for emission of a named signal
    --- @param name String
    x.add_signal = function(this, name)
        meta.assert_string(name)
        init_signal(x, name)
    end

    --- @brief invoke all connected signal handlers
    --- @param name String
    --- @param vararg
    x.emit_signal = function(this, name, ...)
        meta.assert_string(name)
        assert_has_signal(this, name, "emit_signal")
        local metatable = getmetatable(this)
        local signal = metatable.signals[name]
        if meta.is_nil(signal) or signal.is_blocked then return end

        for _, callback in pairs(signal.callbacks) do
            callback(this, ...)
        end
    end

    --- @brief set whether emission is blocked
    --- @param name String
    --- @param b Boolean
    x.set_signal_blocked = function(this, name, b)
        meta.assert_string(name) meta.assert_boolean(b)
        assert_has_signal(this, name, "set_signal_blocked")
        getmetatable(this).signals[name].is_blocked = b
    end

    --- @brief get whether emission is blocked
    --- @param name String
    x.get_signal_blocked = function(this, name)
        meta.assert_string(name)
        assert_has_signal(this, name, "get_signal_blocked")
        return getmetatable(this).signals[name].is_blocked
    end

    --- @brief register a callback, called when signal is emitted
    --- @param name String
    --- @param callback Function With signature (Instance, ...) -> Any
    --- @return Number handler ID
    x.connect_signal = function(this, name, callback)
        meta.assert_string(name) meta.assert_function(callback)
        assert_has_signal(this, name, "connect_signal")
        local signal = getmetatable(this).signals[name]
        signal.callbacks[signal.n] = callback
        signal.n = signal.n + 1
        return signal.n
    end

    --- @brief reset signal handler
    --- @param name String
    --- @param n Number signel handler ID or list of handler IDs
    x.disconnect_signal = function(this, name, n)
        meta.assert_string(name)
        assert_has_signal(this, name, "disconnect_signal")
        local signal = getmetatable(this).signals[name]
        if not meta.is_nil(signal) then
            if meta.is_nil(n) then
                return
            elseif meta.is_number(n) then
                signal.callbacks[n] = nil
            elseif meta.is_table(n) then
                for id in ipairs(n) do
                    signal.callbacks[id] = nil
                end
            end
        end
    end

    --- @brief get handler ids
    --- @return Table of numbers
    x.get_signal_handler_ids = function(this, name)
        meta.assert_string(name)
        assert_has_signal(this, name, "get_signal_handler_ids")
        local signal = getmetatable(this).signals[name]
        local out = {}
        for id, _ in pairs(signal.callbacks) do
            out[id] = id
        end
        return out
    end

    return x
end

--- @brief allow object to emit signals, usa `add_signal` to add them during the types ctor
function meta.add_signal(x, signal_name)
    meta.assert_object(x) meta.assert_string(signal_name)
    meta._initialize_signals(x)
    x:add_signal(signal_name)
    return x
end

--- @brief [internal] create notify architecture
function meta._initialize_notify(x)

    local mt = getmetatable(x)
    if mt.notify ~= nil then
        return
    end
    mt.notify = {}

    local function init_notify(x, name)
        local metatable = getmetatable(x)
        if meta.is_table(metatable.notify[name]) then return end
        metatable.notify[name] = {
            is_blocked = false,
            n = 0,
            callbacks = {}
        }
    end

    --- @brief block notification
    --- @param name String
    --- @param b Boolean
    x.set_notify_blocked = function(this, name, b)
        meta.assert_string(name) meta.assert_boolean(b)
        init_notify(this, name)
        getmetatable(this).notify[name].is_blocked = b
    end

    --- @brief check if notification is blocked
    --- @param name String
    x.get_notify_blocked = function(this, name)
        meta.assert_string(name)
        init_notify(this, name)
        return getmetatable(this).notify[name].is_blocked
    end

    --- @brief register a callback, called when property with given name changes
    --- @param name String
    --- @param callback Function With signature (Instance, property_value, ...) -> void
    --- @return Number handler ID
    x.connect_notify = function(this, name, callback)
        meta.assert_string(name) meta.assert_function(callback)
        init_notify(this, name)
        local notify = getmetatable(this).notify[name]
        notify.callbacks[notify.n] = callback
        notify.n = notify.n + 1
        return notify.n
    end

    --- @brief reset notification handler
    --- @param name String
    --- @param n Number signel handler ID or list of handler IDs
    x.disconnect_notify = function(this, name, n)
        meta.assert_string(name)

        init_notify(this, name)
        local notify = getmetatable(this).notify[name]
        if not meta.is_nil(notify) then
            if meta.is_nil(n) then
                return
            elseif meta.is_number(n) then
                notify.callbacks[n] = nil
            elseif meta.is_table(n) then
                for id in ipairs(n) do
                    notify.callbacks[id] = nil
                end
            end
        end
    end

    --- @brief get handler ids
    --- @return Table of numbers
    x.get_notify_handler_ids = function(this, name)
        meta.assert_string(name)
        init_notify(this, name)
        local notify = getmetatable(this).notify[name]
        local out = {}
        for id, _ in pairs(notify.callbacks) do
            out[id] = id
        end
        return out
    end

    return x
end

--- @brief allow object to emit signals, usa `add_signal` to add them during the types ctor
function meta.allow_notify(x, signal_name)
    meta.assert_object(x) meta.assert_string(signal_name)
    meta._initialize_notify(x)
    return x
end

meta.metatables = {}
meta.metatable_i = 0

--- @class meta.Object
--- @brief [internal] Create new empty object
--- @param typename string type identifier
function meta._new(typename)
    meta.assert_string(typename)

    local out = {}
    out.__metatable = {}
    metatable = out.__metatable

    metatable.__name = typename
    metatable.properties = {}
    metatable.is_private = {}
    metatable.is_mutable = true

    metatable.__index = function(this, property_name)
        local metatable = getmetatable(this)
        if metatable.is_private[property_name] == true then
            error("In " .. metatable.__name .. ".__index: Cannot access property `" .. property_name .. "`, because it was declared private.")
        end
        return metatable.properties[property_name]
    end

    metatable.__newindex = function(this, property_name, property_value)
        local metatable = getmetatable(this)
        if metatable.is_private[property_name] == true then
            error("In " .. metatable.__name .. ".__newindex: Cannot set property `" .. property_name .. "`, because it was declared private.")
        end
        if not metatable.is_mutable then
            error("In " .. metatable.__name .. ".__newindex: Cannot set property `" .. property_name .. "`, object was declared immutable.")
        end
        metatable.properties[property_name] = property_value

        if metatable.notify == nil then return end
        local notify = metatable.notify[property_name]
        if meta.is_nil(notify) or notify.is_blocked then return end
        for _, callback in pairs(notify.callbacks) do
            callback(this, property_value)
        end
    end

    metatable.__tostring = function(this)
        return serialize("(" .. getmetatable(this).__name .. ")", this, false)
    end

    metatable.__name = metatable.__name
    setmetatable(out, metatable)
    return out
end

--- @brief is meta object
function meta.is_object(x)
    if not meta.is_table(x) then
        return false
    end
    local metatable = getmetatable(x)
    return not (metatable == nil or metatable.__name == nil)
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
            return meta[getmetatable(x).__name]
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
    meta._assert_aux(meta.typeof(x) ==  meta.Boolean, x, meta.Boolean.name)
end

--- @brief throw if object is not a table
function meta.assert_table(x)
    meta._assert_aux(meta.typeof(x) ==  meta.Table, x, meta.Table.name)
end

--- @brief throw if object is not callable
function meta.assert_function(x)
    meta._assert_aux(meta.is_function(x), x, meta.Function.name)
end

--- @brief throw if object is not a string
function meta.assert_string(x)
    meta._assert_aux(meta.typeof(x) ==  meta.String, x, meta.String.name)
end

--- @brief throw if object is not a number
function meta.assert_number(x)
    meta._assert_aux(meta.typeof(x) ==  meta.Number, x, meta.Number.name)
end

--- @brief throw if object is not nil
function meta.assert_nil(x)
    meta._assert_aux(meta.typeof(x) ==  meta.Nil, x, meta.Nil.name)
end

--- @brief throw if object is not a meta.Object
function meta.assert_object(x)
    meta._assert_aux(meta.is_object(x), x, meta.Object.name)
end

--- @brief throw if object is not of given type
--- @param x
--- @param type String
function meta.assert_isa(x, type)
    meta.assert_string(type)
    meta._assert_aux(meta.typeof(x) == type, x, type.name)
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
    meta.assert_object(x)
    meta.assert_string(property_name)
    local metatable = getmetatable(x)
    metatable.properties[property_name] = nil
    metatable.is_private[property_name] = nil
end

--- @brief [internal] make object immutable
function meta._set_is_mutable(x, b)
    meta.assert_object(x)
    meta.assert_boolean(b)
    getmetatable(x).is_mutable = b
end

--- @brief [internal] check if object is immutable
function meta._get_is_mutable(x)
    meta.assert_object(x);
    return getmetatable(x).is_mutable
end

--- @class meta.Object
meta.Object = "Object"

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
    if fields ~= nil then
        for name, value in pairs(fields) do
            meta.assert_string(name)
            meta._install_property(out, name, value)
        end
    end
    return out
end

--- @class meta.Enum
meta.Enum = "Enum"

--- @brief create a new immutable object
--- @param fields Table
function meta.new_enum(fields)
    meta.assert_table(fields)
    local out = meta._new(meta.Enum)
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

--- @class meta.Type
meta.Type = "Type"

--- @brief create a new type with given constructor
function meta.new_type(typename, ctor)
    meta.assert_string(typename)
    local out = meta._new(meta.Type)
    out.name = typename

    if meta.is_nil(ctor) then
        getmetatable(out).__call = function(self)
            return meta.new(self.name)
        end
    else
        getmetatable(out).__call = ctor
    end

    if meta[typename] ~= nil then
        error("In meta.new_type: A type with name `" .. typename .. "` already exists.")
    end
    meta[typename] = typename
    return out
end
