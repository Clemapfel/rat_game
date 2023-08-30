--- @class ActionQueue
rt.ActionQueue = meta.new_type("ActionQueue", function()
    local out = meta.new(rt.ActionQueue, {
        queue = Queue(),
        push_action = rt.ActionQueue.push_action,
        step = rt.step,

    })

    return out
end)