--- @class rt.NotifyComponent
--- @signal notify (self, property_name, before, after) -> nil
rt.NotifyComponent = meta.new_type("NotifyComponent", rt.SignalEmitter, function(instance)
    meta.assert_object(instance)
    local out = meta.new(rt.NotifyComponent, {
        _instance = instance
    })

    out:_inject(instance)
    out:signal_add("notify")
    return out
end)

---@brief [internal]
function rt.NotifyComponent:_inject(object)
    local metatable = getmetatable(object)
    metatable.components.notify = self

    local __newindex_before = metatable.__newindex
    metatable.__newindex = function(self, property_name, after)
        local before = self[property_name]
        __newindex_before(self, property_name, after)
        rt.get_notify_component(self):signal_emit("notify", property_name, before, after)
    end
end

--- @brief
function rt.add_notify_component(object)
    local out = rt.NotifyComponent(object)
    return out
end

--- @brief
function rt.get_notify_component(object)
    return getmetatable(object).components.notify
end