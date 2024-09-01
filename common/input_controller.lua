rt.settings.input_controller_state = {
    keybindings_path = "keybindings.lua"
}

--- @class rt.InputControllerState
--- @note if two controllers are connected, both write to the same state, this is intended
rt.InputControllerState = {
    components = {},      -- Table<rt.InputController>
    mapping = {},         -- Table<rt.InputButton, Table<Union<rt.GamepadButton, rt.KeyboardKey>>>
    reverse_mapping = {}, -- Table<love.KeyConstant, Union<rt.GamepadButton, rt.Keyboardkey>>
    state = {},           -- Table<rt.InputButton, Bool>
    axis_state = {        -- Table<rt.GampeadAxis, Number>
        [rt.GamepadAxis.LEFT_X] = 0,
        [rt.GamepadAxis.LEFT_Y] = 0,
        [rt.GamepadAxis.RIGHT_X] = 0,
        [rt.GamepadAxis.RIGHT_Y] = 0,
        [rt.GamepadAxis.LEFT_TRIGGER] = 0,
        [rt.GamepadAxis.RIGHT_TRIGGER] = 0,
    },
    gamepad_active = false,
    is_initialized = false
}

--- @class rt.InputMethod
rt.InputMethod = meta.new_enum({
    KEYBOARD = false,
    CONTROLLER = true
})

--- @class rt.InputController
--- @brief combines all input methods into one, fully abstracted controller
--- @signal pressed   (self, rt.InputButton) -> nil
--- @signal released  (self, rt.InputButton) -> nil
--- @signal joystick  (self, x, y, rt.JoystickPosition) -> nil
--- @signal controller_connected  (self, id) -> nil
--- @signal controller_disconnected  (self, id) -> nil
--- @signal motion    (self, x, y, dx, dy) -> nil
--- @signal keyboard_pressed (self, rt.KeyboardKey) -> nil
--- @signal keyboard_released (self, rt.KeyboardKey) -> nil
--- @signal gamepad_pressed (self, rt.GamepadButton) -> nil
--- @signal gamepad_released (self, rt.GamepadButton) -> nil
--- @signal input_method_changed (self, rt.InputMethod) -> nil
rt.InputController = meta.new_type("InputController", rt.SignalEmitter, function(bounds)
    if bounds ~= nil then meta.assert_aabb(bounds) end
    local out = meta.new(rt.InputController, {
        _is_disabled = false,
        _aabb = bounds, -- Optional<rt.AABB>
    })

    out:signal_add("keyboard_pressed")
    out:signal_add("keyboard_released")
    out:signal_add("gamepad_pressed")
    out:signal_add("gamepad_released")

    out:signal_add("pressed")
    out:signal_add("released")
    out:signal_add("joystick")
    out:signal_add("controller_connected")
    out:signal_add("controller_disconnected")
    
    out:signal_add("motion")
    
    out:signal_add("leave")
    out:signal_add("text_input")

    rt.InputControllerState.components[meta.hash(out)] = out
    return out
end)

--- @brief
function rt.InputController:is_down(key)
    return rt.InputControllerState.state[key] == true
end

--- @brief
function rt.InputController:is_up(key)
    return rt.InputControllerState.state[key] == false
end

--- @brief
function rt.InputController:is_keyboard_key_down(key)
    return love.keyboard.isDown(rt.keyboard_key_to_native(key))
end

function rt.InputController:is_keyboard_key_up(key)
    return not self:is_keyboard_key_down()
end

--- @brief
function rt.InputController:is_gamepad_button_down(button, joystick_id)
    local joysticks = love.joystick.getJoysticks()
    if love.joystick.getJoystickCount() == 0 then return false end

    if joystick_id == nil then
        return joysticks[1]:isGamepadDown(rt.gamepad_button_to_native(button))
    else
        local joystick = joysticks[joystick_id]
        if joystick == nil then return false end
        return joystick:isGamepadDown(rt.gamepad_button_to_native(button))
    end
end

--- @brief
function rt.InputController:is_gamepad_button_up(button, joystick_id)
    return not self:is_gamepad_button_down(button, joystick_id)
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
function rt.InputController:get_joystick(joystick_position)
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
function rt.InputControllerState:set_gamepad_active(next)
    local current = rt.InputControllerState.gamepad_active
    rt.InputControllerState.gamepad_active = next

    if current ~= next then
        for _, component in pairs(rt.InputControllerState.components) do
            if not component._is_disabled then
                component:signal_emit("input_method_changed", current)
            end
        end
    end
end

--- @brief
love.keypressed = function(_, scancode)
    local key = rt.KeyboardKeyPrefix .. scancode
    local button = rt.InputControllerState.reverse_mapping[key]

    if button ~= nil then rt.InputControllerState.state[button] = true end
    rt.InputControllerState:set_gamepad_active(false)

    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_disabled then
            if button ~= nil then
                component:signal_emit("pressed", button)
            end
            component:signal_emit("keyboard_pressed", key)
        end
    end
end

--- @brief
love.keyreleased = function(native)
    local scancode = love.keyboard.getScancodeFromKey(native)
    local key = rt.KeyboardKeyPrefix .. scancode
    local button = rt.InputControllerState.reverse_mapping[key]

    if button ~= nil then rt.InputControllerState.state[button] = false end
    rt.InputControllerState:set_gamepad_active(false)

    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_disabled then
            if button ~= nil then
                component:signal_emit("released", button)
            end
            component:signal_emit("keyboard_released", key)
        end
    end
end

--- @brief
love.textinput = function(letter)
    rt.InputControllerState:set_gamepad_active(false)
    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_disabled then
            component:signal_emit("text_input", letter)
        end
    end
end

--- @brief
love.mousepressed = function(x, y, button_id, is_touch, n_presses)
    if button_id == rt.MouseButton.LEFT or is_touch then
        for _, component in pairs(rt.InputControllerState.components) do
            if not component._is_disabled then
                local bounds = component._aabb
                if bounds ~= nil and rt.aabb_contains(bounds, x, y) then
                    component:signal_emit("pressed", rt.InputButton.A)
                end
            end
        end
    end
end

--- @brief
love.mousereleased = function(x, y, button_id, is_touch, n_pressed)
    if button_id == rt.MouseButton.LEFT or is_touch then
        for _, component in pairs(rt.InputControllerState.components) do
            if not component._is_disabled then
                local bounds = component._aabb
                if bounds ~= nil and rt.aabb_contains(bounds, x, y) then
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
            component:signal_emit("motion", x, y, dx, dy)
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
love.gamepadpressed = function(joystick, native)
    local key = rt.GamepadButtonPrefix .. native
    local button = rt.InputControllerState.reverse_mapping[rt.GamepadButtonPrefix .. native]

    if button ~= nil then rt.InputControllerState.state[button] = true end
    rt.InputControllerState:set_gamepad_active(true)

    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_disabled then
            if button ~= nil then
                component:signal_emit("pressed", button)
            end
            component:signal_emit("gamepad_pressed", key)
        end
    end
end

--- @brief
love.gamepadreleased = function(joystick, native)
    local key = rt.GamepdButtonPrefix .. native
    local button = rt.InputControllerState.reverse_mapping[rt.GamepadButtonPrefix .. native]

    if button ~= nil then rt.InputControllerState.state[button] = true end
    rt.InputControllerState:set_gamepad_active(true)

    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_disabled then
            if button ~= nil then
                component:signal_emit("released", button)
            end
            component:signal_emit("gamepad_released", key)
        end
    end
end

--- @brief
love.gamepadaxis = function(joystick, axis, value)
    local previous_state = rt.InputControllerState.axis_state[axis]
    rt.InputControllerState.axis_state[axis] = value

    if axis == rt.gamepadAxis.LEFT_X or axis == rt.GamepadAxis.LEFT_Y then
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
    elseif axis == rt.GamepadAxis.LEFT_TRIGGER then
        if previous_state > 0.5 and value <= 0.5 then
            love.gamepadpressed(joystick, "leftshoulder")
        end
    elseif axis == rt.GamepadAxis.RIGHT_TRIGGER then
        if previous_state > 0.5 and value <= 0.5 then
            love.gamepadpressed(joystick, "rightshoulder")
        end
    else
        -- unhandled axis ignored
    end
end

--- @brief
--- @return (Boolean, String) is_valid, reason
function rt.InputControllerState:validate_input_mapping()
    -- one assignment for all input buttons for both gamepad and keyboad
    -- no keyboard key or gampedbutton assigned to two input buttons
    local input_button_to_gamepad = {}
    local input_button_to_keyboard = {}
    local gamepad_to_input_button = {}
    local keyboard_to_input_button = {}

    for button in values(meta.instances(rt.InputButton)) do
        input_button_to_gamepad[button] = {}
        input_button_to_keyboard[button] = {}
    end

    for native, button in pairs(self.reverse_mapping) do
        meta.assert_enum(button, rt.InputButton)
        if meta.is_enum_value(native, rt.GamepadButton) then
            table.insert(input_button_to_gamepad[button], native)
            local current = gamepad_to_input_button[native]
            if current == nil then
                gamepad_to_input_button[native] = {button}
            else
                table.insert(current, button)
            end
        elseif meta.is_enum_value(native, rt.KeyboardKey) then
            table.insert(input_button_to_keyboard[button], native)
            local current = keyboard_to_input_button[native]
            if current == nil then
                keyboard_to_input_button[native] = {button}
            else
                table.insert(current, button)
            end
        end
    end

    local no_keyboard_input_buttons = {}
    local no_gamepad_input_buttons = {}
    local double_bound_gamepad_buttons = {} -- Table<rt.GamepadButton, Table<rt.InputButton>>
    local double_bound_keyboard_keys = {} -- Table<rt.Keyboradkey, Table<rt.InputButton>>

    local is_valid = true

    for button, bindings in pairs(input_button_to_keyboard) do
        if sizeof(bindings) == 0 then
            table.insert(no_keyboard_input_buttons, button)
            is_valid = false
        end
    end

    for button, bindings in pairs(input_button_to_gamepad) do
        if sizeof(bindings) == 0 then
            table.insert(no_gamepad_input_buttons, button)
            is_valid = false
        end
    end

    for native, buttons in pairs(keyboard_to_input_button) do
        if sizeof(buttons) > 1 then
            double_bound_keyboard_keys[native] = buttons
            is_valid = false
        end
    end

    for native, buttons in pairs(gamepad_to_input_button) do
        if sizeof(buttons) > 1 then
            double_bound_gamepad_buttons[native] = buttons
            is_valid = false
        end
    end

    local prefix = "\t+ "
    local error_message = {}
    if not is_valid then
        table.insert(error_message, "Error while validating keybindings, mapping is invalid.\n")

        if sizeof(no_keyboard_input_buttons) ~= 0 then
            table.insert(error_message, "The following actions have no assigned keyboard keys :\n")
            for button in values(no_keyboard_input_buttons) do
                table.insert(error_message, prefix .. rt.input_button_to_string(button) .. "\n")
            end
        end

        if sizeof(no_gamepad_input_buttons) ~= 0 then
            table.insert(error_message, "The following actions have no assigned gamepad buttons :\n")
            for button in values(no_gamepad_input_buttons) do
                table.insert(error_message, prefix .. rt.input_button_to_string(button) .. "\n")
            end
        end

        if sizeof(double_bound_gamepad_buttons) ~= 0 then
            table.insert(error_message, "The following buttons are bound to multiple actions :\n")
            for native, buttons in pairs(double_bound_gamepad_buttons) do
                table.insert(error_message, prefix .. rt.gamepad_button_to_string(native) .. "\n")
            end
        end

        if sizeof(double_bound_keyboard_keys) ~= 0 then
            table.insert(error_message, "The following keyboard keys are bound to multiple actions :\n")
            for native, buttons in pairs(double_bound_keyboard_keys) do
                table.insert(error_message, prefix .. rt.keyboard_key_to_string(native) .. "\n")
            end
        end
    end

    return is_valid, table.concat(error_message)
end

--- @brief
function rt.InputControllerstate:load_default_mapping()
    local default_mapping = {
        [rt.InputButton.A] = {
            rt.KeyboardKey.SPACE,
            rt.GamepadButton.RIGHT
        },

        [rt.InputButton.B] = {
            rt.KeyboardKey.B,
            rt.GamepadButton.BOTTOM
        },

        [rt.InputButton.X] = {
            rt.KeyboardKey.X,
            rt.GamepadButton.TOP
        },

        [rt.InputButton.Y] = {
            rt.KeyboardKey.Y,
            rt.GamepadButton.RIGHT
        },

        [rt.InputButton.L] = {
            rt.KeyboardKey.L,
            rt.GamepadButton.LEFT_SHOULDER
        },

        [rt.InputButton.R] = {
            rt.KeyboardKey.R,
            rt.GamepadButton.RIGHT_SHOULDER
        },

        [rt.InputButton.START] = {
            rt.KeyboardKey.M,
            rt.GamepadButton.START
        },

        [rt.InputButton.SELECT] = {
            rt.KeyboardKey.N,
            rt.GamepadButton.SELECT
        },

        [rt.InputButton.UP] = {
            rt.KeyboardKey.ARROW_UP,
            rt.KeyboardKey.W,
            rt.KeyboardKey.NUMPAD_EIGHT,
            rt.GamepadButton.DPAD_UP,
        },

        [rt.InputButton.RIGHT] = {
            rt.KeyboardKey.ARROW_RIGHT,
            rt.KeyboardKey.D,
            rt.KeyboardKey.NUMPAD_SIX,
            rt.GamepadButton.DPAD_RIGHT
        },

        [rt.InputButton.DOWN] = {
            rt.KeyboardKey.ARROW_DOWN,
            rt.KeyboardKey.S,
            rt.KeyboardKey.NUMPAD_FIVE,
            rt.KeyboardKey.NUPAD_TWO,
            rt.GamepadButton.DPAD_DOWN
        },

        [rt.InputButton.LEFT] = {
            rt.KeyboardKey.ARROW_LEFT,
            rt.KeyboardKey.A,
            rt.KeyboardKey.NUMPAD_FOUR,
            rt.GamepdButton.DPAD_LEFT
        },

        [rt.InputButton.DEBUG] = {
            rt.KeyboardKey.ESCAPE,
            rt.GamepadButton.LEFT_STICK,
            rt.GamepadButton.RIGHT_STICK
        }
    }

    local pathologic_mapping = {
        [rt.InputButton.A] = {
            -- unmapped
        },

        [rt.InputButton.B] = {
            rt.KeyboardKey.B,
            rt.GamepadButton.BOTTOM
        },

        [rt.InputButton.X] = {
            rt.KeyboardKey.X,
            rt.GamepadButton.TOP
        },

        [rt.InputButton.Y] = {
            rt.KeyboardKey.Y,
            rt.GamepadButton.RIGHT
        },

        [rt.InputButton.L] = {
            rt.KeyboardKey.L,
            rt.GamepadButton.LEFT_SHOULDER
        },

        [rt.InputButton.R] = { -- double mapping
            rt.KeyboardKey.L,
            rt.GamepadButton.LEFT_SHOULDER
        },

        [rt.InputButton.START] = {
            rt.KeyboardKey.M,
            rt.GamepadButton.START
        },

        [rt.InputButton.SELECT] = {
            rt.KeyboardKey.N,
            rt.GamepadButton.SELECT
        },

        [rt.InputButton.UP] = {
            rt.KeyboardKey.ARROW_UP,
            rt.KeyboardKey.W,
            rt.KeyboardKey.NUMPAD_EIGHT,
            rt.GamepadButton.DPAD_UP,
        },

        [rt.InputButton.RIGHT] = {
            rt.KeyboardKey.ARROW_RIGHT,
            rt.KeyboardKey.D,
            rt.KeyboardKey.NUMPAD_SIX,
            rt.GamepadButton.DPAD_RIGHT
        },

        [rt.InputButton.DOWN] = {
            rt.KeyboardKey.ARROW_DOWN,
            rt.KeyboardKey.S,
            rt.KeyboardKey.NUMPAD_FIVE,
            rt.KeyboardKey.NUPAD_TWO,
            rt.GamepadButton.DPAD_DOWN
        },

        [rt.InputButton.LEFT] = {
            rt.KeyboardKey.ARROW_LEFT,
            rt.KeyboardKey.A,
            rt.KeyboardKey.NUMPAD_FOUR,
            rt.GamepdButton.DPAD_LEFT
        },

        [rt.InputButton.DEBUG] = {
            rt.KeyboardKey.ESCAPE,
            rt.GamepadButton.LEFT_STICK,
            rt.GamepadButton.RIGHT_STICK
        }
    }

    default_mapping = pathologic_mapping

    self.reverse_mapping = {}
    for input_button, natives in pairs(default_mapping) do
        for native in values(natives) do
            self.reverse_mapping[native] = input_button
        end
    end

    if not self:valid_input_mapping() then
        rt.error("[FATAL] In rt.InputControllerState:reset_input_mapping: default input mapping is not valid")
    end
end

--- @brief
function rt.InputControllerState:set_keybinding(input_button, new_gamepad_button)
    meta.assert_enum(input_button, rt.InputButton)

    local before = self.reverse_mapping[new_gamepad_button]
    self.reverse_mapping[new_gamepad_button] = input_button
    if not self:valid_input_mapping() then
        self.reverse_mapping[new_gamepad_button] = before
        return false
    else
        return true
    end
end

