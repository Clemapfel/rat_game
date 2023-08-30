--- @class ActionQueue
rt.ActionQueue = meta.new_type("ActionQueue", function()
    local out = meta.new(rt.ActionQueue, {
        queue = Queue()
    })
    return out
end)

--- @class Action
--- @signal start Emitted before the actions payload triggers
--- @signal finish Emitted when actions payload is done
rt.ActionQueue.Action = meta.new_type("Action", function(f)
    meta.assert_function(f)
    local out = meta.new(rt.ActionQueue.Action, {
        apply = function(self)
            meta.assert_isa(self, rt.ActionQueue.Action)
            self:emit_signal("start")
            f()
            self:emit_signal("finish")
        end
    })

    meta.add_signal(out, "start")
    meta.add_signal(out, "finish")

    meta.set_is_mutable(out, false)
    return out
end)

--- @brief add an action to the end of the queue
rt.ActionQueue.push = function(self, action)
    meta.assert_isa(self, rt.ActionQueue)
    meta.assert_function(action)
    self.queue:push_back(rt.ActionQueue.Action(action))
end

--- @brief consume on action
rt.ActionQueue.step = function(self)
    meta.assert_isa(self, rt.ActionQueue)
    if n_steps ~= nil then meta.assert_number(n_steps) end

    local front = self.queue:pop_front()
    if not meta.is_nil(front) then
        front:apply()
    end
end

--- @brief get whether the queue has any actions left
rt.ActionQueue.is_empty = function(self)
    return self.queue:is_empty()
end

