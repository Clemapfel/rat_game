--- @class bt.Animation
bt.Animation = meta.new_abstract_type("BattleAnimation", {
    _is_started = false,
    _is_finished = false
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