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
    GAMEPAD = true
})

--- @class rt.InputController
--- @brief combines all input methods into one, fully abstracted controller
--- @signal pressed   (self, rt.InputButton) -> nil
--- @signal released  (self, rt.InputButton) -> nil
--- @signal joystick  (self, x, y, rt.JoystickPosition) -> nil
--- @signal controller_connected  (self, id) -> nil
--- @signal controller_disconnected  (self, id) -> nil
--- @signal motion    (self, x, y, dx, dy) -> nil
--- @signal keyboard_pressed  (self, rt.KeyboardKey) -> nil
--- @signal keyboard_released (self, rt.KeyboardKey) -> nil
--- @signal gamepad_pressed   (self, rt.GamepadButton) -> nil
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
    out:signal_add("input_method_changed")

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

--- @brief
function rt.InputController:is_keyboard_key_up(key)
    return not self:is_keyboard_key_down()
end

--- @brief
function rt.InputController:get_input_method()
    return rt.InputControllerState:get_input_method()
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
    meta.assert_boolean(next)
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
love.keyreleased = function(native, scancode)
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
    local key = rt.GamepadButtonPrefix .. native
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
    local no_keyboard_input_buttons = {}
    local no_gamepad_input_buttons = {}
    local double_bound_gamepad_buttons = {} -- Table<rt.GamepadButton, Table<rt.InputButton>>
    local double_bound_keyboard_keys = {} -- Table<rt.Keyboradkey, Table<rt.InputButton>>

    local is_valid = true

    local keyboard_to_button = {}
    local gamepad_to_button = {}

    for button in values(meta.instances(rt.InputButton)) do
        local keyboard_mapped, gamepad_mapped = false, false
        for native in values(self.mapping[button]) do
            if  meta.is_enum_value(native, rt.KeyboardKey) then
                keyboard_mapped = true
                if keyboard_to_button[native] == nil then
                    keyboard_to_button[native] = {}
                end
                table.insert(keyboard_to_button[native], button)
            elseif  meta.is_enum_value(native, rt.GamepadButton) then
                gamepad_mapped = true
                if gamepad_to_button[native] == nil then
                    gamepad_to_button[native] = {}
                end
                table.insert(gamepad_to_button[native], button)
            else
                rt.error("In rt.InputController.validate_input_mapping: unexpected value `" .. native .. "` for mapping of `" .. button .. "`")
            end
        end

        if keyboard_mapped == false then
            table.insert(no_keyboard_input_buttons, button)
            is_valid = false
        end

        if gamepad_mapped == false then
            table.insert(no_gamepad_input_buttons, button)
            is_valid = false
        end
    end

    for native, buttons in pairs(keyboard_to_button) do
        if sizeof(buttons) > 1 then
            double_bound_keyboard_keys[native] = buttons
            is_valid = false
        end
    end

    for native, buttons in pairs(gamepad_to_button) do
        if sizeof(buttons) > 1 then
            double_bound_gamepad_buttons[native] = buttons
            is_valid = false
        end
    end

    local prefix = string.rep(" ", 8)
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
            table.insert(error_message, "The following gamepad buttons are bound to multiple actions :\n")
            for native, buttons in pairs(double_bound_gamepad_buttons) do
                table.insert(error_message, prefix .. rt.gamepad_button_to_string(native) .. " (bound to: ")
                local n_buttons = #buttons
                for i, button in ipairs(buttons) do
                    if i < n_buttons then
                        table.insert(error_message, button .. ", ")
                    else
                        table.insert(error_message, button .. ")\n")
                    end
                end
            end
        end

        if sizeof(double_bound_keyboard_keys) ~= 0 then
            table.insert(error_message, "The following keyboard keys are bound to multiple actions :\n")
            for native, buttons in pairs(double_bound_keyboard_keys) do
                table.insert(error_message, prefix .. rt.keyboard_key_to_string(native) .. " (bound to: ")
                local n_buttons = #buttons
                for i, button in ipairs(buttons) do
                    if i < n_buttons then
                        table.insert(error_message, button .. ", ")
                    else
                        table.insert(error_message, button .. ")\n")
                    end
                end
            end
        end
    end

    return is_valid, table.concat(error_message)
end

--- @brief
function rt.InputControllerState:load_default_mapping()
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
            rt.KeyboardKey.Z,
            rt.GamepadButton.LEFT
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
            rt.KeyboardKey.RETURN,
            rt.GamepadButton.START
        },

        [rt.InputButton.SELECT] = {
            rt.KeyboardKey.N,
            rt.KeyboardKey.RIGHT_SQUARE_BRACKET,
            rt.KeyboardKey.BACKSLASH,
            rt.GamepadButton.SELECT
        },

        [rt.InputButton.UP] = {
            rt.KeyboardKey.ARROW_UP,
            rt.KeyboardKey.W,
            rt.KeyboardKey.KEYPAD_EIGHT,
            rt.GamepadButton.DPAD_UP,
        },

        [rt.InputButton.RIGHT] = {
            rt.KeyboardKey.ARROW_RIGHT,
            rt.KeyboardKey.D,
            rt.KeyboardKey.KEYPAD_SIX,
            rt.GamepadButton.DPAD_RIGHT
        },

        [rt.InputButton.DOWN] = {
            rt.KeyboardKey.ARROW_DOWN,
            rt.KeyboardKey.S,
            rt.KeyboardKey.KEYPAD_FIVE,
            rt.KeyboardKey.KEYPAD_TWO,
            rt.GamepadButton.DPAD_DOWN
        },

        [rt.InputButton.LEFT] = {
            rt.KeyboardKey.ARROW_LEFT,
            rt.KeyboardKey.A,
            rt.KeyboardKey.KEYPAD_FOUR,
            rt.GamepadButton.DPAD_LEFT
        },

        [rt.InputButton.DEBUG] = {
            rt.KeyboardKey.ESCAPE,
            rt.GamepadButton.LEFT_STICK,
            rt.GamepadButton.RIGHT_STICK
        }
    }

    self.mapping = {}
    for button in values(meta.instances(rt.InputButton)) do
        self.mapping[button] = {}
    end

    self.reverse_mapping = {}
    for input_button, natives in pairs(default_mapping) do
        for native in values(natives) do
            table.insert(self.mapping[input_button], native)
            self.reverse_mapping[native] = input_button
        end
    end

    local is_valid, message = self:validate_input_mapping()
    if not is_valid then
        rt.error("[FATAL] In rt.InputControllerState:load_default_mapping: " .. message)
    end
end

--- @brief
function rt.InputControllerState:set_keybinding(input_button, new_gamepad_button)
    meta.assert_enum(input_button, rt.InputButton)

    local before = self.reverse_mapping[new_gamepad_button]
    self.reverse_mapping[new_gamepad_button] = input_button
    if not self:validate_input_mapping() then
        self.reverse_mapping[new_gamepad_button] = before
        return false
    else
        return true
    end
end

--- @brief
--- @return (rt.KeyboardKey, rt.GamepadButton)
function rt.InputControllerState:get_keybinding(input_button)
    local first_keyboard_key, first_gamepad_button = nil, nil
    for x in values(self.mapping[input_button]) do
        if meta.is_enum_value(x, rt.KeyboardKey) and not first_keyboard_key then
            first_keyboard_key = x
        elseif meta.is_enum_value(x, rt.GamepadButton) and not first_gamepad_button then
            first_gamepad_button = x
        end

        if first_gamepad_button ~= nil and first_keyboard_key ~= nil then
            return first_keyboard_key, first_gamepad_button
        end
    end

    rt.error("In rt.InputControllerState: no keybinding for `" .. input_button .. "`")
    return nil, nil
end

--- @brief
function rt.InputControllerState:get_input_method()
    if self.gamepad_active then
        return rt.InputMethod.GAMEPAD 
    else 
        return rt.InputMethod.KEYBOARD 
    end
end
