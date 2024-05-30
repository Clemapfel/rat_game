--- @class bt.SceneState
bt.SceneState = meta.new_abstract_type("BattleSceneState")

--- @brief
function bt.SceneState:update(delta)
    rt.error("In " .. meta.typeof(self) .. ".update: abstract method called")
end

--- @brief
function bt.SceneState:enter()
    rt.error("In " .. meta.typeof(self) .. ".enter: abstract method called")
end

--- @brief
function bt.SceneState:exit()
    rt.error("In " .. meta.typeof(self) .. ".exit: abstract method called")
end

--- @brief
function bt.SceneState:draw()
    rt.error("In " .. meta.typeof(self) .. ".draw: abstract method called")
end

--- @brief
function bt.SceneState:handle_button_pressed(which)
    -- noop
end

--- @brief
function bt.SceneState:handle_button_released(which)
    -- noop
end
