--- @class rt.SignalComponent
--- @param holder meta.Object
rt.SignalComponent = meta.new_type("SignalComponent", function(holder)
    meta.assert_object(holder)
    return meta.new(rt.SignalComponent, {
        _instance = holder
    })
end)

--- @brief add a signal component to object, use `object.signals:add_signal` to add new signals
--- @param object meta.Object
function rt.add_signal_component(object)
    meta.assert_object(object)
    if not meta.is_nil(object.signals) then
        error("[rt] In add_signal_component: Object already has a signal component")
    end

    object.signals = rt.SignalComponent(object)
    for _, property in ipairs(meta.get_property_names(object)) do
        object.signals:add("notfiy::" .. property)
    end
    return object
end

--- @brief [internal] initialize signal of given name
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent._init_signal(component, name)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    local metatable = getmetatable(component._instance)
    if meta.is_nil(metatable.signals) then
        metatable.signals = {}
    end
    metatable.signals[name] = {
        is_blocked = false,
        n = 0,
        callbacks = {}
    }
end

--- @brief [internal] assert that object has a signal with given name
--- @param component rt.SignalComponent
--- @param name String
--- @param scope String
function rt.SignalComponent._assert_has_signal(component, name, scope)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    meta.assert_string(scope)

    if getmetatable(component._instance).signals[name] == nil then
        error("[rt] In SignalComponent." .. scope .. ": Object of type `" .. meta.typeof(component._instance) .. "`has no signal with name `" .. name .. "`")
    end
end

--- @brief check if instance has a signal with given name
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent.has_signal(component, name)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    return not meta.is_nil(getmetatable(component._instance).signals[name])
end

--- @brief add a signal, afterwards, all other rt.SignalComponent functions will become available
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent.add(component, name)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    component:_init_signal(name)
end

--- @brief invoke all connected signal handlers
--- @param component rt.SignalComponent
--- @param name String
--- @param vararg any
function rt.SignalComponent.emit(component, name, ...)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    component:_assert_has_signal(name, "emit")

    local metatable = getmetatable(component._instance)
    local signal = metatable.signals[name]

    if meta.is_nil(signal) or signal.is_blocked then return end
    for _, callback in pairs(signal.callbacks) do
        callback(component._instance, ...)
    end
end

--- @brief register a callback, called when signal is emitted
--- @param name String
--- @param callback Function With signature (Instance, ...) -> Any
--- @return Number handler ID
function rt.SignalComponent.connect(component, name, callback)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    meta.assert_function(callback)
    component:_assert_has_signal(name, "connect")

    local signal = getmetatable(component._instance).signals[name]
    signal.callbacks[signal.n] = callback
    signal.n = signal.n + 1
    return signal.n
end

--- @brief disconnect handler permanently
--- @param component rt.SignalComponent
--- @param name String
--- @param handler_ids
function rt.SignalComponent.disconnect(component, name, handler_ids)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)

    if not component:has_signal(name) then
        return
    end

    local signal = getmetatable(component._instance).signals[name]
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
function rt.SignalComponent.set_is_blocked(component, name, b)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    component:_assert_has_signal(name, "set_is_blocked")
    getmetatable(component._instance).signals[name].is_blocked = b
end

--- @brief check whether signal handler is not connected or currently blocked
--- @param component rt.SignalComponent
--- @param name String
--- @return Boolean
function rt.SignalComponent.get_is_blocked(component, name)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    component:_assert_has_signal(name, "get_is_blocked")
    return getmetatable(component._instance).signals[name].is_blocked
end

--- @brief get all handler ids for given signal
--- @param component rt.SignalComponent
--- @param name String
--- @return Table list of handler IDs
function rt.SignalComponent.get_handler_ids(component, name)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(name)
    component:_assert_has_signal(this, name, "get_signal_handler_ids")
    local signal = getmetatable(component._instance).signals[name]
    local out = {}
    for id, _ in pairs(signal.callbacks) do
        out[id] = id
    end
    return out
end

--- @brief [internal] test signal component
rt.test.signal_component = function()
    
    local instance = meta._new("Object", {})
    local signal = "test"

    rt.add_signal_component(instance)
    instance.signals:add(signal)
    assert(instance.signals:has_signal(signal) == true)

    assert(instance.signals:get_is_blocked(signal) == false)
    local called = false
    instance.signals:connect(signal, function()
        called = true
    end)
    assert(instance.signals:get_is_blocked(signal) == false)
    
    instance.signals:emit(signal)
    assert(called)
    
    instance.signals:set_is_blocked(signal, true)
    assert(instance.signals:get_is_blocked(signal) == true)

    called = false
    instance.signals:emit(signal)
    assert(not called)
    instance.signals:set_is_blocked(signal, false)
    instance.signals:disconnect(signal)
    instance.signals:emit(signal)
    assert(not called)
end
rt.test.signal_component()

