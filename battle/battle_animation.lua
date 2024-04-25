--- @class bt.Animation
bt.Animation = meta.new_abstract_type("BattleAnimation", {
    _is_started = false,
    _is_finished = false,
    _is_ready_for_synch = false,
    _synch_targets = {}, -- Table<bt.Animation>
    _wait_for_queues = {}
})

--- @class bt.AnimationResult
bt.AnimationResult = {
    CONTINUE = true,
    DISCONTINUE = false
}

--- @brief
function bt.Animation:start()
    rt.error("In bt.Animation.start: abstract method called")
end

--- @brief
function bt.Animation:finish()
    rt.error("In bt.Animation.finish: abstract method called")
end

--- @brief
function bt.Animation:update(delta)
    rt.error("In bt.Animation.update: abstract method called")
end

--- @overload
function bt.Animation:draw()
    rt.error("In bt.Animation.draw: abstract method called")
end

--- @brief
function bt.Animation:get_is_started()
    return self._is_started
end

--- @brief
function bt.Animation:register_finish_callback(callback)
    meta.assert_function(callback)
    if self._finish_callbacks == nil then
        self._finish_callbacks = {}
    end
    table.insert(self._finish_callbacks, callback)
end

--- @brief
function bt.Animation:register_start_callback(callback)
    meta.assert_function(callback)
    if self._start_callbacks == nil then
        self._start_callbacks = {}
    end
    table.insert(self._start_callbacks, callback)
end

--- @brief make it so both animation wait for each other, starting at the same time only when both are ready
function bt.Animation:synch_with(other)
    if #self._synch_targets == 0 then self._synch_targets = {} end
    self._synch_targets[other] = true

    if #other._synch_targets == 0 then other._synch_targets = {} end
    other._synch_targets[self] = true
end

--- @brief make it so animation will only play when all other animation queues are empty
function bt.Animation:wait_for(queue)

end