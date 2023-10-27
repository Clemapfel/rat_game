--- @class rt.SignalComponent
--- @param holder meta.Object
rt.SignalComponent = meta.new_type("SignalComponent", function(holder)
    meta.assert_object(holder)
    return meta.new(rt.SignalComponent, {
        _instance = holder,
        _signals = {}
    })
end)

--- @brief [internal] access signal component
--- @param object meta.Object
function rt.get_signal_component(object)
    meta.assert_object(object)
    return getmetatable(object).components.signal
end

--- @brief add a signal component to object, use `object.signal:add_signal` to add new signals
--- @param object meta.Object
function rt.add_signal_component(object)
    meta.assert_object(object)

    if not meta.is_nil(getmetatable(object).components.signal) then
        error("[rt][ERROR] In add_signal_component: Object already has a signal component")
    end

    local component = rt.SignalComponent(object)
    getmetatable(object).components.signal = component
    return component
end

--- @brief access signal component
--- @return rt.SignalComponent
function rt.get_signal_component(object)
    meta.assert_object(object)
    return getmetatable(object).components.signal
end

--- @brief [internal] initialize signal of given name
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent:_init_signal(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    self._signals[name] = {
        is_blocked = false,
        n = 0,
        data = {},     -- CallbackID -> Data
        callbacks = {} -- CallbackID -> Function
    }
end

--- @brief [internal] assert that object has a signal with given name
--- @param component rt.SignalComponent
--- @param name String
--- @param scope String
function rt._assert_has_signal(scope, component, signal_id)
    meta.assert_isa(component, rt.SignalComponent)
    meta.assert_string(scope, signal_id)

    if not component:has_signal(signal_id) then
        error("[rt][ERROR] In SignalComponent." .. scope .. ": Object of type `" .. meta.typeof(component._instance) .. "`has no signal with name `" .. signal_id .. "`")
    end
end

--- @brief check if instance has a signal with given name
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent:has_signal(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    return not meta.is_nil(self._signals[name])
end

--- @brief add a signal, afterwards, all other rt.SignalComponent functions will become available
--- @param component rt.SignalComponent
--- @param name String
function rt.SignalComponent:add(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    if self:has_signal(name) then return end
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
    rt._assert_has_signal("emit", self, name)

    local metatable = getmetatable(self._instance)
    local signal = self._signals[name]

    if meta.is_nil(signal) then
        error("[rt][ERROR] In SignalComponent:emit: Object of type `" .. meta.typeof(self._instance) .. "` has no signal with name `" .. name .. "`")
    end

    if signal.is_blocked then return end
    local res = nil
    for id, callback in pairs(signal.callbacks) do
        res = callback(self._instance, ..., signal.data[id])
    end
    return res
end

--- @brief register a callback, called when signal is emitted
--- @param name String
--- @param callback Function With signature (Instance, ...) -> Any
--- @return Number handler ID
function rt.SignalComponent:connect(name, callback, data)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    meta.assert_function(callback)
    rt._assert_has_signal("connect", self, name)

    local signal = self._signals[name]
    local callback_id = signal.n
    signal.callbacks[callback_id] = callback
    signal.data[callback_id] = data
    signal.n = signal.n + 1

    return callback_id
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

    local signal = self._signals[name]
    if meta.is_nil(handler_id) then
        signal.callbacks = {}
        signal.data = {}
    elseif meta.is_table(handler_id) then
        for _, id in ipairs(handler_id) do
            meta.assert_number(id)
            signal.callbacks[id] = nil
            signal.data[id] = nil
        end
    else
        meta.assert_number(handler_id)
        signal.callbacks[handler_id] = nil
        signal.data[handler_id] = nil
    end
end

--- @brief block handler temporarily
--- @param component rt.SignalComponent
--- @param name String
--- @param b Boolean
function rt.SignalComponent:set_is_blocked(name, b)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    rt._assert_has_signal("set_is_blocked", self, name)
    self._signals[name].is_blocked = b
end

--- @brief check whether signal handler is not connected or currently blocked
--- @param component rt.SignalComponent
--- @param name String
--- @return Boolean
function rt.SignalComponent:get_is_blocked(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    rt._assert_has_signal("get_is_blocked", self, name)
    return self._signals[name].is_blocked
end

--- @brief get all handler ids for given signal
--- @param component rt.SignalComponent
--- @param name String
--- @return Table list of handler IDs
function rt.SignalComponent:get_handler_ids(name)
    meta.assert_isa(self, rt.SignalComponent)
    meta.assert_string(name)
    rt._assert_has_signal("get_signal_handler_ids", self, name)
    local signal = self._signals[name]
    local out = {}
    for id, _ in pairs(signal.callbacks) do
        out[id] = id
    end
    return out
end

--- @brief get holder of component
--- @return meta.Object
function rt.SignalComponent:get_emitter_instance()
    meta.assert_isa(self, rt.SignalComponent)
    return self._instance
end

--- @class SignalEmitter
rt.SignalEmitter = meta.new_abstract_type("SignalEmitter")

--- @see rt.SignalComponent.has_signal
function rt.SignalEmitter:signal_has_signal(name)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:has_signal(name)
end

--- @see rt.SignalComponent.add
function rt.SignalEmitter:signal_add(name)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:add(name)
end

--- @see rt.SignalComponent.emit
function rt.SignalEmitter:signal_emit(name, ...)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:emit(name, ...)
end

--- @see rt.SignalComponent.connect
function rt.SignalEmitter:signal_connect(name, callback, data)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:connect(name, callback, data)
end

--- @see rt.SignalComponent.disconnect
function rt.SignalEmitter:signal_disconnect(name, handler_id)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:disconnect(name, handler_id)
end

--- @see rt.SignalComponent.set_is_blocked
function rt.SignalEmitter:signal_set_is_blocked(name, b)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:set_is_blocked(name, b)
end

--- @see rt.SignalComponent.get_is_blocked
function rt.SignalEmitter:signalgset_is_blocked(name)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:get_is_blocked(name)
end

--- @see rt.SignalComponent.get_handler_ids
function rt.SignalEmitter:signal_get_handler_ids(name)
    meta.assert_isa(self, rt.SignalEmitter)
    local component = rt.get_signal_component(self)
    if meta.is_nil(component) then component = rt.add_signal_component(self) end
    return component:get_handler_ids(name)
end

--- @brief [internal] test signal component
rt.test.signal_component = function()
    local instance = meta._new("Object")
    meta._install_property(instance, "property", 1234)
    local signal = "test"

    local component = rt.add_signal_component(instance, true)
    component:add(signal)
    assert(component:has_signal(signal) == true)

    assert(component:get_is_blocked(signal) == false)
    local called = false
    component:connect(signal, function()
        called = true
    end)
    assert(component:get_is_blocked(signal) == false)

    component:emit(signal)
    assert(called)

    component:set_is_blocked(signal, true)
    assert(component:get_is_blocked(signal) == true)

    called = false
    component:emit(signal)
    assert(not called)
    component:set_is_blocked(signal, false)
    component:disconnect(signal)
    component:emit(signal)
    assert(not called)
end
rt.test.signal_component()