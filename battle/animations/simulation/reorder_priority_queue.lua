--- @class bt.Animation.REORDER_PRIORITY_QUEUE
bt.Animation.REORDER_PRIORITY_QUEUE = meta.new_type("REORDER_PRIORITY_QUEUE", rt.QueueableAnimation, function(scene, new_order)
    return meta.new(bt.Animation.REORDER_PRIORITY_QUEUE, {
        _scene = scene,
        _new_order = new_order,
    })
end)

--- @override
function bt.Animation.REORDER_PRIORITY_QUEUE:start()
    self._scene:set_priority_order(self._new_order)
end

--- @override
function bt.Animation.REORDER_PRIORITY_QUEUE:update(delta)
    return self._scene:get_is_priority_reorder_done()
end

--- @override
function bt.Animation.REORDER_PRIORITY_QUEUE:finish()
    -- noop
end

--- @override
function bt.Animation.REORDER_PRIORITY_QUEUE:draw()
    -- noop
end