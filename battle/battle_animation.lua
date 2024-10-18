--- @class bt.Animation
bt.Animation = meta.new_abstract_type("BattleAnimation", rt.QueueableAnimation, {
    _elapsed = 0
})

--- @brief
function bt.Animation:start()
    error("abstract method called")
end

--- @brief
function bt.Animation:update()
    error("abstract method called")
end

--- @brief
function bt.Animation:finish()
    error("abstract method called")
end

--- @brief
function bt.Animation:draw()
    error("abstract method called")
end