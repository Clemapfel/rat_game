rt.settings.input = {}
rt.settings.input = {
    trigger_threshold = 0.1,
    deadzone = 0.25,
    convert_left_trigger_to_dpad = false,
    convert_right_trigger_to_dpad = false
}

--- @class rt.InputController
--- @brief combines all input methods into one, fully abstracted controller
--- @signal pressed   (self, rt.InputButton) -> nil
--- @signal released  (self, rt.InputButton) -> nil
--- @signal joystick  (self, x, y, rt.JoystickPosition) -> nil
--- @signal controller_connected  (self, id) -> nil
--- @signal controller_disconnected  (self, id) -> nil
--- @signal enter     (self, x, y) -> nil
--- @signal motion    (self, x, y, dx, dy) -> nil
--- @signal leave     (self, x, y) -> nil
rt.InputController = meta.new_type("InputController", rt.SignalEmitter, function(holder)
    local out = meta.new(rt.InputController, {
        _instance = holder,
        _cursor_in_bounds = false,
        _is_disabled = false
    })

    out:signal_add("pressed")
    out:signal_add("released")
    out:signal_add("joystick")
    out:signal_add("controller_connected")
    out:signal_add("controller_disconnected")
    out:signal_add("enter")
    out:signal_add("motion")
    out:signal_add("leave")

    rt.InputHandler.components[meta.hash(out)] = out
    return out
end)

--- @brief
function rt.InputController:is_down(key)
    return rt.InputHandler.state[key] == true
end

--- @brief
function rt.InputController:is_up(key)
    return rt.InputHandler.state[key] == false
end

--- @brief
function rt.InputController:get_axis(joystick_position)
    if joystick_position == rt.JoystickPosition.LEFT then
        local x = rt.InputHandler.axis_state[rt.GamepadAxis.LEFT_X]
        local y = rt.InputHandler.axis_state[rt.GamepadAxis.LEFT_Y]
        return x, y
    elseif joystick_position == rt.joystickPosition.RIGHT then
        local x = rt.InputHandler.axis_state[rt.GamepadAxis.RIGHT_X]
        local y = rt.InputHandler.axis_state[rt.GamepadAxis.RIGHT_Y]
        return x, y
    else
        rt.error("In rt.InputController:get_axis: unknown joystick position `" .. joystick_position .. "`")
        return 0, 0
    end
end

--- @brief KEYBOARD KEY PRESSED
love.keypressed = function (key)
    key = rt.KeyboardKeyPrefix .. key
    local button = rt.InputHandler.reverse_mapping[key]
    if button ~= nil then
        rt.InputHandler.state[button] = true
        for _, component in pairs(rt.InputHandler.components) do
            if component._is_disabled == false then
                component:signal_emit("pressed", button)
            end
        end
    end
end

--- @brief KEYBOARD KEY RELEASED
love.keyreleased = function (key)
    key = rt.KeyboardKeyPrefix .. key
    local button = rt.InputHandler.reverse_mapping[key]
    if button ~= nil then
        rt.InputHandler.state[button] = false
        for _, component in pairs(rt.InputHandler.components) do
            if component._is_disabled == false then
                component:signal_emit("released", button)
            end
        end
    end
end

--- @brief MOUSE BUTTON PRESSED
love.mousepressed = function (x, y, button_id, is_touch, n_presses)
    if button_id == rt.MouseButton.LEFT or is_touch then
        rt.InputHandler.state[rt.InputButton.A] = true
        for _, component in pairs(rt.InputHandler.components) do
            if not component._is_disabled then
                if component._instance == nil then
                    component:signal_emit("pressed", rt.InputButton.A)
                else
                    if rt.aabb_contains(component._instance:get_bounds(), x, y) then
                        component:signal_emit("pressed", rt.InputButton.A)
                    end
                end
            end
        end
    end
end

--- @brief MOUSE BUTTON RELEASED
love.mousereleased = function (x, y, button_id, is_touch, n_presses)
    if button_id == rt.MouseButton.LEFT or is_touch then
        rt.InputHandler.state[rt.InputButton.A] = false
        for _, component in pairs(rt.InputHandler.components) do
            if not component._is_disabled then
                -- sic, release emitted even if cursor is out of bounds of _instance
                component:signal_emit("released", rt.InputButton.A)
            end
        end
    end
end

--- @brief MOUSE MOTION
love.mousemotion = function (x, y, dx, dy, is_touch)
    for _, component in pairs(rt.InputHandler.components) do
        if not component._is_disabled and not meta.is_nil(component._instance) then
            local current = component._cursor_in_bounds
            local next = rt.aabb_contains(component._instance:get_bounds(), x, y)

            if current == false and next == true then
                component._cursor_in_bounds = true
                component:signal_emit("motion_enter", x, y)
            end

            if next then
                component:signal_emit("motion", x, y, dx, dy)
            end

            if current == true and next == false then
                component._cursor_in_bounds = false
                component:signal_emit("motion_leave", x, y)
            end
        end
    end
end

--- @brief GAMEPAD ADDED
love.joystickadded = function (joystick)
    for _, component in pairs(rt.InputHandler.components) do
        if not component._is_diabled then
            component:signal_emit("controller_connected", joystick:getID())
        end
    end
end

--- @brief GAMEPAD REMOVED
love.joystickremoved = function (joystick)
    for _, component in pairs(rt.InputHandler.components) do
        if not component._is_diabled then
            component:signal_emit("controller_disconnected", joystick:getID())
        end
    end
end

--- @brief GAMEPAD BUTTON PRESSED
love.gamepadpressed = function (joystick, which)
    if joystick:getID() ~= rt.InputHandler.active_joystick then return end
    which = rt.GamepadButtonPrefix .. which
    local button = rt.InputHandler.reverse_mapping[which]
    if button ~= nil then
        rt.InputHandler.state[button] = true
        for _, component in pairs(rt.InputHandler.components) do
            if component._is_disabled == false then
                component:signal_emit("pressed", button)
            end
        end
    end
end

--- @brief GAMEPAD BUTTON RELEASED
love.gamepadreleased = function (joystick, which)
    if joystick:getID() ~= rt.InputHandler.active_joystick then return end
    which = rt.GamepadButtonPrefix .. which
    local button = rt.InputHandler.reverse_mapping[which]
    if button ~= nil then
        rt.InputHandler.state[button] = false
        for _, component in pairs(rt.InputHandler.components) do
            if component._is_disabled == false then
                component:signal_emit("released", button)
            end
        end
    end
end

--- @brief GAMEPAD AXIS
love.gamepadaxis = function (joystick, axis, value)
    if joystick:getID() ~= rt.InputHandler.active_joystick then return end
    rt.InputHandler.axis_state[axis] = value

    if axis == rt.GamepadAxis.LEFT_X or axis == rt.GamepadAxis.LEFT_Y then
        local x = rt.InputHandler.axis_state[rt.GamepadAxis.LEFT_X]
        local y = rt.InputHandler.axis_state[rt.GamepadAxis.LEFT_Y]
        for _, component in pairs(rt.InputHandler.components) do
            if component._is_disabled == false then
                component:signal_emit("joystick", x, y, rt.JoystickPosition.LEFT)
            end
        end
    elseif axis == rt.GamepadAxis.RIGHT_X or axis == rt.GamepadAxis.RIGHT_Y then
        local x = rt.InputHandler.axis_state[rt.GamepadAxis.RIGHT_X]
        local y = rt.InputHandler.axis_state[rt.GamepadAxis.RIGHT_Y]
        for _, component in pairs(rt.InputHandler.components) do
            if component._is_disabled == false then
                component:signal_emit("joystick", x, y, rt.JoystickPosition.RIGHT)
            end
        end
    else
        -- unknown axis
    end
end

--- @brief
function rt.add_input_controller(object)
    local to_add = rt.InputController(object)
    rawget(object, 1).components.input = to_add
    return to_add
end

--- @brief
function rt.get_input_controller(object)
    return rawget(object, 1).components.input
end
