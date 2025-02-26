require "common.aabb"
require "common.input_button"

rt.settings.input_controller_state = {
    keybindings_path = "keybindings.lua"
}

--- @class rt.InputControllerState
--- @note if two controllers are connected, both write to the same state, this is intended
rt.InputControllerState = {
    components = meta.make_weak({}),      -- Table<rt.InputController>
    mapping = {},         -- Table<rt.InputButton, Table<Union<rt.GamepadButton, rt.KeyboardKey>>>
    reverse_mapping = {}, -- Table<love.KeyConstant, Union<rt.GamepadButton, rt.Keyboardkey>>
    deadzone = 0.1,       -- in [0, 1)
    button_state = {},    -- Table<rt.InputButton, Bool>
    axis_state = {        -- Table<rt.GampeadAxis, Number>
        [rt.GamepadAxis.LEFT_X] = 0,
        [rt.GamepadAxis.LEFT_Y] = 0,
        [rt.GamepadAxis.RIGHT_X] = 0,
        [rt.GamepadAxis.RIGHT_Y] = 0,
        [rt.GamepadAxis.LEFT_TRIGGER] = 0,
        [rt.GamepadAxis.RIGHT_TRIGGER] = 0,
    },
    previous_gamepad_direction = nil,
    gamepad_active = false,
    is_initialized = false,
    active_state = nil
}

--- @class rt.InputMethod
rt.InputMethod = meta.enum("InputMethod", {
    KEYBOARD = false,
    GAMEPAD = true
})

--- @class rt.InputController
--- @brief combines all input methods into one, fully abstracted controller
rt.InputController = meta.class("InputController")

function rt.InputController:instantiate(bounds)
    if bounds ~= nil then meta.assert_aabb(bounds) end
    meta.install(self, {
        _is_disabled = false,
        _treat_left_joystick_as_dpad = true,
        _aabb = bounds, -- Optional<rt.AABB>
    })

    rt.InputControllerState.components[meta.hash(self)] = self
end

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
--- @signal input_mapping_changed (self) -> nil
meta.add_signals(rt.InputController,
    "keyboard_pressed",
    "keyboard_released",
    "gamepad_pressed",
    "gamepad_released",
    "input_method_changed",
    "input_mapping_changed",

    "pressed",
    "released",
    "joystick",
    "controller_connected",
    "controller_disconnected",

    "motion",

    "leave",
    "text_input"
)

--- @brief
function rt.InputController:get_is_down(key)
    return rt.InputControllerState.button_state[key] == true
end

--- @brief
function rt.InputController:get_is_up(key)
    return rt.InputControllerState.button_state[key] == false
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
function rt.InputController:set_treat_left_joystick_as_dpad(b)
    self._treat_left_joystick_as_dpad = b
end

--- @brief
function rt.InputController:get_treat_left_joystick_as_dpad()
    return self._treat_left_joystick_as_dpad
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

    if button ~= nil then rt.InputControllerState.button_state[button] = true end
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

    if button ~= nil then rt.InputControllerState.button_state[button] = false end
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

    if button ~= nil then rt.InputControllerState.button_state[button] = true end
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

    if button ~= nil then rt.InputControllerState.button_state[button] = false end
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
    rt.InputControllerState:set_gamepad_active(true)

    if axis == rt.GamepadAxis.LEFT_X or axis == rt.GamepadAxis.LEFT_Y then
        local x = rt.InputControllerState.axis_state[rt.GamepadAxis.LEFT_X]
        local y = rt.InputControllerState.axis_state[rt.GamepadAxis.LEFT_Y]

        local distance = math.sqrt(x^2 + y^2)
        if distance < rt.InputControllerState.deadzone then
            rt.InputControllerState.previous_gamepad_direction = nil
            return
        end

        -- convert analog to digital
        local before = rt.InputControllerState.previous_gamepad_direction
        local angle = math.atan2(y, x) % (2 * math.pi)
        local dpad
        if (angle >= 7 * math.pi / 4 or angle < math.pi / 4) then
            dpad = rt.GamepadButton.DPAD_DOWN
        elseif (angle >= math.pi / 4 and angle < 3 * math.pi / 4) then
            dpad = rt.GamepadButton.DPAD_RIGHT
        elseif (angle >= 3 * math.pi / 4 and angle < 5 * math.pi / 4) then
            dpad = rt.GamepadButton.DPAD_UP
        else
            dpad = rt.GamepadButton.DPAD_LEFT
        end
        local button = rt.InputControllerState.reverse_mapping[dpad]
        rt.InputControllerState.previous_gamepad_direction = dpad

        for _, component in pairs(rt.InputControllerState.components) do
            if component._is_disabled == false then
                component:signal_emit("joystick", x, y, rt.JoystickPosition.LEFT)

                if dpad ~= before and component._treat_left_joystick_as_dpad then
                    if button ~= nil then
                        component:signal_emit("pressed", button)
                    end
                    component:signal_emit("gamepad_pressed", dpad)
                end
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
function rt.InputControllerState:validate_input_mapping(mapping)
    local no_keyboard_input_buttons = {}
    local no_gamepad_input_buttons = {}
    local double_bound_gamepad_buttons = {} -- Table<rt.GamepadButton, Table<rt.InputButton>>
    local double_bound_keyboard_keys = {} -- Table<rt.Keyboradkey, Table<rt.InputButton>>

    local is_valid = true

    local keyboard_to_button = {}
    local gamepad_to_button = {}

    for button in values(meta.instances(rt.InputButton)) do
        if button ~= rt.InputButton.DEBUG then
            local keyboard_mapped, gamepad_mapped = false, false
            local pair = mapping[button]
            if meta.is_enum_value(pair.keyboard, rt.KeyboardKey) then
                keyboard_mapped = true
                if keyboard_to_button[pair.keyboard] == nil then
                    keyboard_to_button[pair.keyboard] = {}
                end
                table.insert(keyboard_to_button[pair.keyboard], button)
            else
                rt.error("In rt.InputController.validate_input_mapping: unexpected keyboard value `" .. meta.typeof(pair.keyboard) .. "` for mapping of `" .. button .. "`")
            end

            if meta.is_enum_value(pair.gamepad, rt.GamepadButton) then
                gamepad_mapped = true
                if gamepad_to_button[pair.gamepad] == nil then
                    gamepad_to_button[pair.gamepad] = {}
                end
                table.insert(gamepad_to_button[pair.gamepad], button)
            else
                rt.error("In rt.InputController.validate_input_mapping: unexpected  gamepad value`" .. meta.typeof(pair.gamepad) .. "` for mapping of `" .. button .. "`")
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
                        table.insert(error_message, rt.input_button_to_string(button) .. ", ")
                    else
                        table.insert(error_message, rt.input_button_to_string(button) .. ")\n")
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
                        table.insert(error_message, rt.input_button_to_string(button) .. ", ")
                    else
                        table.insert(error_message, rt.input_button_to_string(button) .. ")\n")
                    end
                end
            end
        end
    end

    return is_valid, table.concat(error_message)
end

--- @brief
function rt.InputControllerState:load_mapping(mapping)
    for button in values(meta.instances(rt.InputButton)) do
        self.mapping[button] = {}
    end

    self.reverse_mapping = {}
    for input_button, natives in pairs(mapping) do
        for native in range(natives.keyboard, natives.gamepad) do
            self.mapping[input_button] = {
                keyboard = natives.keyboard,
                gamepad = natives.gamepad
            }
            self.reverse_mapping[native] = input_button
        end
    end

    local is_valid, message = self:validate_input_mapping(self.mapping)
    if not is_valid then
        rt.error("In rt.InputControllerState:load_mapping: Mapping is invalid.\n" .. message)
        return
    end

    for _, component in pairs(rt.InputControllerState.components) do
        if not component._is_disabled then
            component:signal_emit("input_mapping_changed")
        end
    end
end

--- @brief
function rt.InputControllerState:get_input_method()
    if self.gamepad_active then
        return rt.InputMethod.GAMEPAD 
    else 
        return rt.InputMethod.KEYBOARD 
    end
end
