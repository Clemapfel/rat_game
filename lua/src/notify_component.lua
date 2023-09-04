--- @brief [internal] create notify architecture
function meta._initialize_notify(x)

    local mt = getmetatable(x)
    if mt.notify ~= nil then
        return
    end
    mt.notify = {}

    local function init_notify(x, property_name)
        if not meta.has_property(x, property_name) then
            error("[rt] In meta.notify: Object of type `" .. meta.typeof(x) .. "` does not have a property with name `" .. property_name .. "`")
        end
        local metatable = getmetatable(x)
        if meta.is_table(metatable.notify[property_name]) then return end
        metatable.notify[property_name] = {
            is_blocked = false,
            n = 0,
            callbacks = {}
        }
    end

    --- @brief block notification
    x.set_notify_blocked = function(this, property_name, b)
        meta.assert_string(property_name) meta.assert_boolean(b)
        init_notify(this, property_name)
        getmetatable(this).notify[property_name].is_blocked = b
    end

    --- @brief check if notification is blocked
    x.get_notify_blocked = function(this, property_name)
        meta.assert_string(property_name)
        init_notify(this, property_name)
        return getmetatable(this).notify[property_name].is_blocked
    end

    --- @brief register a callback, called when property with given property_name changes
    --- @param name String
    --- @param callback Function With signature (Instance, property_value, ...) -> void
    --- @return Number handler ID
    x.connect_notify = function(this, property_name, callback)
        meta.assert_string(property_name) meta.assert_function(callback)
        init_notify(this, property_name)
        local notify = getmetatable(this).notify[property_name]
        notify.callbacks[notify.n] = callback
        notify.n = notify.n + 1
        return notify.n
    end

    --- @brief reset notification handler
    x.disconnect_notify = function(this, property_name, n)
        meta.assert_string(property_name)

        init_notify(this, property_name)
        local notify = getmetatable(this).notify[property_name]
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

    --- @brief get IDs of connected notify handlers
    x.get_notify_handler_ids = function(this, property_name)
        meta.assert_string(property_name)
        init_notify(this, property_name)
        local notify = getmetatable(this).notify[property_name]
        local out = {}
        for id, _ in pairs(notify.callbacks) do
            out[id] = id
        end
        return out
    end

    return x
end

--- @brief allow connecting notify handler to properties
function meta.add_notify_component(x)
    meta.assert_object(x)
    meta._initialize_notify(x)
    return x
end