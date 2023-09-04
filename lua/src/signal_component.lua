--- @class SignalComponent
--- @param holder object the component should control
rt.SignalComponent = meta.new_type("SignalComponent", function(holder)
    meta.assert_object(holder)
    return meta.new(meta.SignalComponent, {
        instance = holder
    })
end)

--- @brief [internal] initialize named signal
function rt.SignalComponent._init_signal(x, name)
    if meta.is_table(getmetatable(x).signals[name]) then return end
    getmetatable(x).signals[name] = {
        is_blocked = false,
        n = 0,
        callbacks = {}
    }
end

--- @brief [internal] check if object has signal with given name
function rt.SignalComponent._assert_has_signal(x, name, scope)
    if getmetatable(x).signals[name] == nil then
        error("[rt] In " .. meta.typeof(x) .. "." .. scope .. ": Object has no signal with name `" .. name .. "`")
    end
end

--- @brief allow for emission of a named signal
rt.SignalComponent.add = function(this, name)
    meta.assert_string(name)
    init_signal(x, name)
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
            error("[rt] In " .. meta.typeof(x) .. "." .. scope .. ": Object has no signal with name `" .. name .. "`")
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

--- @brief allow object to emit signals, use `add_signal` to add them during the types ctor
function meta.add_signal_component(x)
    meta.assert_object(x)
    meta._initialize_signals(x)
    return x
end
