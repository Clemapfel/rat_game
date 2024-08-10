--- @class rt.SceneState
rt.SceneState = meta.new_abstract_type("SceneState")

--- @brief
function rt.SceneState:update(delta)
    rt.error("In " .. meta.typeof(self) .. ".update: abstract method called")
end

--- @brief
function rt.SceneState:enter()
    rt.error("In " .. meta.typeof(self) .. ".enter: abstract method called")
end

--- @brief
function rt.SceneState:exit()
    rt.error("In " .. meta.typeof(self) .. ".exit: abstract method called")
end

--- @brief
function rt.SceneState:draw()
    rt.error("In " .. meta.typeof(self) .. ".draw: abstract method called")
end

--- @brief
function rt.SceneState:handle_button_pressed(which)
    -- noop
end

--- @brief
function rt.SceneState:handle_button_released(which)
    -- noop
end
