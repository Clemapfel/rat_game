--- @class ActionQueue
rt.ActionQueue = meta.new_type("ActionQueue", function()
    return meta.new(rt.ActionQueue, {
        queue = Queue()
    })
end)

--- @class Action
rt.ActionQueue.Action = meta.new_type("Action", function(f)
    meta.assert_function(f)
    return meta.new(rt.ActionQueue.Action, {
        apply = f
    })
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
        front.apply()
    end
end

--- @brief get whether the queue has any actions left
rt.ActionQueue.is_empty = function(self)
    return self.queue:is_empty()
end

