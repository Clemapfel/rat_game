rt.settings.input_controller = {
    keybindings_path = "keybindings.lua"
}

rt.InputControllerState = {
    components = {},      -- Table<rt.InputController>
    reverse_mapping = {}, -- Table<love.KeyConstant, rt.GamepadButton>
    state = {},           -- Table<rt.InputButton, Bool>
    axis_state = {        -- Table<rt.GampeadAxis, Number>
        [rt.GamepadAxis.LEFT_X] = 0,
        [rt.GamepadAxis.LEFT_Y] = 0,
        [rt.GamepadAxis.RIGHT_X] = 0,
        [rt.GamepadAxis.RIGHT_Y] = 0,
        [rt.GamepadAxis.LEFT_TRIGGER] = 0,
        [rt.GamepadAxis.RIGHT_TRIGGER] = 0,
    },
    is_initialized = false
}

--- @class rt.InputController
--- @brief combines all input methods into one, fully abstracted controller
--- @signal pressed   (self, rt.InputButton) -> nil
--- @signal released  (self, rt.InputButton) -> nil
--- @signal joystick  (self, x, y, rt.JoystickPosition) -> nil
--- @signal controller_connected  (self, id) -> nil
--- @signal controller_disconnected  (self, id) -> nil
--- @signal motion    (self, x, y, dx, dy) -> nil
rt.InputController = meta.new_type("InputController", rt.SignalEmitter, function(instance)
    if instance ~= nil then
        if not meta.is_function(instance.get_bounds) then
            rt.error("In rt.InputController: Instance of type `" .. meta.typeof(instance) .. "` does not have `get_bounds` method")
        end
    end

    local out = meta.new(rt.InputController, {
        _is_disabled = false,
        _instance = instance,
    })

    out:signal_add("pressed")
    out:signal_add("released")
    out:signal_add("joystick")
    out:signal_add("controller_connected")
    out:signal_add("controller_disconnected")
    out:signal_add("enter")
    out:signal_add("motion")
    out:signal_add("leave")
    out:signal_add("text_input")

    rt.InputControllerState.components[meta.hash(out)] = out

    if rt.InputControllerState.is_initialized == false then
        rt.error("In rt.InputController: InputControllerState is not yet initialized")
    end

    return out
end)

--- @brief
function rt.InputControllerState.load_from_state(state)
    local mapping = state:get_input_mapping()
    for input_button in values(meta.instances(rt.InputButton)) do
        for mapped in values(mapping[input_button]) do
            rt.InputControllerState.reverse_mapping[mapped] = input_button
        end
        rt.InputControllerState.state[input_button] = false
    end

    rt.InputControllerState.axis_state = {}
    for axis in range() do
        rt.InputControllerState.axis_state[axis] = 0
    end

    rt.InputControllerState.is_initialized = true
end

--- @brief
function rt.InputController:is_down(key)
    return rt.InputControllerState.state[key] == true
end

--- @brief
function rt.InputController:is_up(key)
    return rt.InputControllerState.state[key] == false
end

--- @brief
function rt.InputController:set_is_disabled(b)
    self._is_diabled = b
end

--- @brief
function rt.InputController:get_is_disabled()
    return self._is_disabled
end

--- @brief
function rt.InputController:get_axis(joystick_position)
    if joystick_position == rt.JoystickPosition.LEFT then
        local x = rt.InputControllerState.axis_state[rt.GamepadAxis.LEFT_X]
        local y = rt.InputControllerState.axis_state[rt.GamepadAxis.LEFT_Y]
        return x, y
    elseif joystick_position == rt.JoystickPosition.RIGHT then
        local x = rt.InputControllerState.axis_state[rt.GamepadAxis.RIGHT_X]
        local y = rt.InputControllerState.axis_state[rt.GamepadAxis.RIGHT_Y]
        return x, y
    else
        rt.error("In rt.InputController:get_axis: unknown joystick position `" .. joystick_position .. "`")
        return 0, 0
    end
end

--- @brief
love.keypressed = function(key)
    key = rt.KeyboardKeyPrefix .. key
    local button = rt.InputControllerState.reverse_mapping[key]
    if button ~= nil then
        rt.InputControllerState.state[button] = true
        for _, component in pairs(rt.InputControllerState.components) do
            if component._is_disabled == false then
                component:signal_emit("pressed", button)
            end
        end
    end
end

--- @brief
love.keyreleased = function(key)
    key = rt.KeyboardKeyPrefix .. key
    local button = rt.InputControllerState.reverse_mapping[key]
    if button ~= nil then
        rt.InputControllerState.state[button] = false
        for _, component in pairs(rt.InputControllerState.components) do
            if component._is_disabled == false then
                component:signal_emit("released", button)
            end
        end
    end
end

--- @brief
love.textinput = function(str)
    for _, component in pairs(rt.InputControllerState.components) do
        if component._is_disabled == false then
            component:signal_emit("text_input", str)
        end
    end
end

--- @brief
love.mousepressed = function(x, y, button_id, is_touch, n_presses)
    if button_id == rt.MouseButton.LEFT or is_touch then
        for _, component in pairs(rt.InputControllerState.components) do
            if not component._is_disabled then
                local bounds = component._instance:get_bounds()
                if rt.aabb_contains(bounds, x, y) then
                    component:signal_emit("pressed", rt.InputButton.A)
                end
            end
        end
    end
end

--- @brief
love.mousereleased = function(x, y, button_id, is_touch, n_presses)
    if button_id == rt.MouseButton.LEFT or is_touch then
        for _, component in pairs(rt.InputControllerState.components) do
            if not component._is_disabled then
                local bounds = component._instance:get_bounds()
                if rt.aabb_contains(bounds, x, y) then
                    component:signal_emit("released", rt.InputButton.A)
                end
            end
        end
    end
end

--- @brief
love.mousemoved = function(x, y, dx, dy, is_touch)
    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_disabled then
            component:signal_emit("motion", x, y)
        end
    end
end

--- @brief
love.joystickadded = function(joystick)
    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_diabled then
            component:signal_emit("controller_connected", joystick:getID())
        end
    end
end

--- @brief
love.joystickremoved = function(joystick)
    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_diabled then
            component:signal_emit("controller_disconnected", joystick:getID())
        end
    end
end

--- @brief
love.gamepadpressed = function(joystick, which)
    local button = rt.InputControllerState.reverse_mapping[rt.GamepadButtonPrefix ..which]
    if button ~= nil then
        rt.InputControllerState.state[button] = true
        for _, component in pairs(rt.InputControllerState.components) do
            if component._is_disabled == false then
                component:signal_emit("pressed", button)
            end
        end
    end
end

--- @brief
love.gamepadreleased = function(joystick, which)
    local button = rt.InputControllerState.reverse_mapping[rt.GamepadButtonPrefix ..which]
    if button ~= nil then
        rt.InputControllerState.state[button] = true
        for _, component in pairs(rt.InputControllerState.components) do
            if component._is_disabled == false then
                component:signal_emit("released", button)
            end
        end
    end
end

--- @brief
love.gamepadaxis = function(joystick, axis, value)
    rt.InputControllerState.axis_state[axis] = value
    if axis == rt.GamepadAxis.LEFT_X or axis == rt.GamepadAxis.LEFT_Y then
        local x = rt.InputControllerState.axis_state[rt.GamepadAxis.LEFT_X]
        local y = rt.InputControllerState.axis_state[rt.GamepadAxis.LEFT_Y]
        for _, component in pairs(rt.InputControllerState.components) do
            if component._is_disabled == false then
                component:signal_emit("joystick", x, y, rt.JoystickPosition.LEFT)
            end
        end
    elseif axis == rt.GamepadAxis.RIGHT_X or axis == rt.GamepadAxis.RIGHT_Y then
        local x = rt.InputControllerState.axis_state[rt.GamepadAxis.RIGHT_X]
        local y = rt.InputControllerState.axis_state[rt.GamepadAxis.RIGHT_Y]
        for _, component in pairs(rt.InputControllerState.components) do
            if component._is_disabled == false then
                component:signal_emit("joystick", x, y, rt.JoystickPosition.RIGHT)
            end
        end
    else
        -- unhandled axis
    end
end