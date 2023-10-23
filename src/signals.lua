--- @class rt.SignalComponent
--- @param holder meta.Object
rt.SignalComponent = meta.new_type("SignalComponent", function(holder)
    meta.assert_object(holder)
    return meta.new(rt.SignalComponent, {
        instance = holder
    })
end)

rt.SignalComponent._notify_prefix = "notify::"

--- @brief [internal] access signal component
function rt.get_signal_component(object)
    meta.assert_object(object)
    return getmetatable(object).components.signal
end

--- @brief add a signal component to object, use `object.signal:add_signal` to add new signals
--- @param object meta.Object
--- @param implement_notify Boolean whether the `notify::` signals should be initialized
function rt.add_signal_component(object, implement_notify)
    meta.assert_object(object)

    if not meta.is_nil(object.signal) then
        error("[rt] In add_signal_component: Object already has a signal component")
    end

    local component = rt.SignalComponent(object)
    getmetatable(object).components.signal = component

    if meta.is_nil(implement_notify) then
        implement_notify = false
    end
    meta.assert_boolean(implement_notify)

    if implement_notify then
        for _, property in pairs(meta.get_property_names(object)) do
            component:add(rt.SignalComponent._notify_prefix .. property)
        end
    end
    meta._install_property(object, "signal", component)
    return object
end

--- @brief access signal component
--- @return rt.SignalComponent
function rt.get_signal_component(object)
    meta.assert_object(object)
    return object.signal
end

--- @brief [internal] initialize signal of given name
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent:_init_signal(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    local metatable = getmetatable(self.instance)
    if meta.is_nil(metatable.signal) then
        metatable.signal = {}
    end
    metatable.signal[name] = {
        is_blocked = false,
        n = 0,
        data = {},
        callbacks = {}
    }
end

--- @brief [internal] assert that object has a signal with given name
--- @param component rt.SignalComponent
--- @param name String
--- @param scope String
function rt.SignalComponent:_assert_has_signal(name, scope)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    meta.assert_string(scope)

    if not self:has_signal(name) then
        error("[rt] In SignalComponent." .. scope .. ": Object of type `" .. meta.typeof(self.instance) .. "`has no signal with name `" .. name .. "`")
    end
end

--- @brief check if instance has a signal with given name
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent:has_signal(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)

    local metatable = getmetatable(self.instance)
    return not meta.is_nil(metatable.signal) and not meta.is_nil(metatable.signal[name])
end

--- @brief add a signal, afterwards, all other rt.SignalComponent functions will become available
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent:add(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    self:_init_signal(name)
end

--- @brief invoke all connected signal handlers
--- @param component rt.SignalComponent
--- @param name String
--- @param vararg any
--- @return any result last callback
function rt.SignalComponent:emit(name, ...)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    self:_assert_has_signal(name, "emit")

    local metatable = getmetatable(self.instance)
    local signal = metatable.signal[name]

    if meta.is_nil(signal) or signal.is_blocked then return end
    local res = nil
    for _, callback in pairs(signal.callbacks) do
        res = callback(self.instance, ...)
    end
    return res
end

--- @brief register a callback, called when signal is emitted
--- @param name String
--- @param callback Function With signature (Instance, ...) -> Any
--- @return Number handler ID
function rt.SignalComponent:connect(name, callback)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    meta.assert_function(callback)
    self:_assert_has_signal(name, "connect")

    local signal = getmetatable(self.instance).signal[name]
    signal.callbacks[signal.n] = callback
    signal.n = signal.n + 1
    return signal.n
end

--- @brief disconnect handler permanently
--- @param component rt.SignalComponent
--- @param name String
--- @param handler_ids
function rt.SignalComponent:disconnect(name, handler_id)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)

    if not self:has_signal(name) then
        return
    end

    local signal = getmetatable(self.instance).signal[name]
    if meta.is_nil(handler_id) then
        signal.callbacks = {}
    elseif meta.is_table(handler_id) then
        for id in pairs(handler_id) do
            signal[handler_id] = nil
        end
    else
        meta.assert_number(handler_id)
        signal.callbacks[handler_id] = nil
    end
end

--- @brief block handler temporarily
--- @param component rt.SignalComponent
--- @param name String
--- @param b Boolean
function rt.SignalComponent:set_is_blocked(name, b)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    self:_assert_has_signal(name, "set_is_blocked")
    getmetatable(self.instance).signal[name].is_blocked = b
end

--- @brief check whether signal handler is not connected or currently blocked
--- @param component rt.SignalComponent
--- @param name String
--- @return Boolean
function rt.SignalComponent:get_is_blocked(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    self:_assert_has_signal(name, "get_is_blocked")
    return getmetatable(self.instance).signal[name].is_blocked
end

--- @brief get all handler ids for given signal
--- @param component rt.SignalComponent
--- @param name String
--- @return Table list of handler IDs
function rt.SignalComponent:get_handler_ids(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    self:_assert_has_signal(name, "get_signal_handler_ids")
    local signal = getmetatable(self.instance).signal[name]
    local out = {}
    for id, _ in pairs(signal.callbacks) do
        out[id] = id
    end
    return out
end

--- @brief [internal] test signal component
rt.test.signal_component = function()
    -- TODO
end
rt.test.signal_component()
