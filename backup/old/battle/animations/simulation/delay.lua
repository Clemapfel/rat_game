--- @class bt.Animation.DELAY
bt.Animation.DELAY = meta.new_type("DELAY", rt.QueueableAnimation, function(delay_s)
    meta.assert_number(delay_s)
    return meta.new(bt.Animation.DELAY, {
        _delay = delay_s,
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.DELAY:start()
    -- noo
end

--- @override
function bt.Animation.DELAY:update(delta)
    self._elapsed = self._elapsed + delta
    return self._elapsed < self._delay
end

--- @override
function bt.Animation.DELAY:finish()
    -- noop
end

--- @override
function bt.Animation.DELAY:draw()
    -- noop
end
