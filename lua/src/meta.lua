meta = {}

--- @brief [internal] Create new empty object
function meta._new(typename)
    local out = {}
    out.__meta = {}
    out.__meta.typename = typename
    out.__meta.__tostring = function(this)
        return serialize("(" .. this.__meta.typename .. ")", this, false)
    end

    out.__meta.signals = {}
    out.__meta.properties = {}
    setmetatable(out, out.__meta)
    return out
end

--- @brief is x a lua string?
function meta.is_string(x)
    return type(x) == "string"
end

--- @brief is x a lua table?
function meta.is_table(x)
    return type(x) == "table"
end

--- @brief is x a lua number?
function meta.is_number(x)
    return type(x) == "number"
end

--- @brief is x a lua boolean?
function meta.is_boolean(x)
    return type(x) == "boolean"
end

--- @brief is x nil?
function meta.is_nil(x)
    return type(x) == "nil"
end

---@brief is callable
function meta.is_function(x)
    if type(x) == "function" then
        return true
    elseif getmetatable(x) ~= nil then
        return meta.is_function(getmetatable(x).__call)
    end
end

--- @brief is meta object
function meta.is_object(x)
    return not (x.__meta == nil or x.__meta.typename == "")
end

--- @brief get typename identifier
function meta.typeof(x)
    assert(meta.is_object(x))
    return x.__meta.typename
end

--- @class Signal
function meta.Signal(name, instance)

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
        return this.callback(this.instance, ...)
    end
    out.connect = function(this, f)
        this.callback = f
    end
    out.disconnect = function(this)
        this.callback = function() end
    end
    return out
end

--- @brief [internal] add support for named signal to meta.Object
function meta._install_signal(x, signal_name)
    assert(meta.is_object(x))
    rawget(x, "__meta").signals[signal_name] = meta.Signal(signal_name, x)
    rawset(x, "set_signal_" .. signal_name .. "_blocked", function(self, b)
        assert(meta.is_boolean(b))
        rawget(x, "__meta").signals[signal_name]:set_is_blocked(b)
    end)
    rawset(x, "get_signal_" .. signal_name .. "_blocked", function(self)
        return rawget(x, "__meta").signals[signal_name]:get_is_blocked()
    end)
    rawset(x, "emit_signal_" .. signal_name, function(self, ...)
        rawget(x, "__meta").signals[signal_name]:emit(...)
    end)
    rawset(x, "connect_signal_" .. signal_name, function(self, f)
        assert(meta.is_function(f))
        rawget(x, "__meta").signals[signal_name]:connect(f)
    end)
    rawset(x, "disconnect_signal_" .. signal_name, function(self)
        rawget(x, "__meta").signals[signal_name]:disconnect()
    end)
end

--- @brief [internal] override the objects metatable such that no property of it can be changed
function meta._make_immutable(x)
    assert(meta.is_table(x))
    local m = getmetatable(x)
    m.__newindex = function(this, key)
        error("In " .. meta.typeof(this) ".__newindex: Trying to modify a table value, but the table was declared immutable.")
    end
end