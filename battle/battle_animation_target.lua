--- @class
bt.BattleAnimationTarget = meta.new_abstract_type("BattleAnimationTarget", rt.Widget)

--- @brief
function bt.BattleAnimationTarget:sync()
    rt.error("In bt.BattleAnimationTarget:sync: abstract function called")
end

--- @brief
function bt.BattleAnimationTarget:update(delta)
end

--- @brief
function bt.BattleAnimationTarget:snapshot()
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:set_is_visible(b)
    self._is_visible = b
end

--- @brief
function bt.BattleAnimationTarget:get_is_visible()
    return which(self._is_visible, true)
end

--- @brief
function bt.BattleAnimationTarget:set_opacity(alpha)
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:set_ui_is_visible(b)
    self._ui_is_visible = b
end

--- @brief
function bt.BattleAnimationTarget:get_ui_is_visible()
    return which(self._ui_is_visible, false)
end

--- @brief
function bt.BattleAnimationTarget:set_hp(value, value_max)
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:add_status(status)
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:activate_status(status)
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:remove_status(status)
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:set_priority(priority)
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:set_state(state)
    -- noop
end

--- @brief
function bt.BattleAnimationTarget:add_animation(animation)
    if self._animation_queue == nil then
        self._animation_queue = bt.AnimationQueue()
    end
    self._animation_queue:add_animation(animation)
end
