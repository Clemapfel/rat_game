rt.settings.input = {}
rt.settings.input = {
    trigger_threshold = 0.1,
    deadzone = 0.25,
    convert_left_trigger_to_dpad = false,
    convert_right_trigger_to_dpad = false
}

rt.InputHandler = {}

--- @class rt.InputButton
rt.InputButton = meta.new_enum({
    A = "INPUT_BUTTON_A",
    B = "INPUT_BUTTON_B",
    X = "INPUT_BUTTON_X",
    Y = "INPUT_BUTTON_Y",
    UP = "INPUT_BUTTON_UP",
    RIGHT = "INPUT_BUTTON_RIGHT",
    DOWN = "INPUT_BUTTON_DOWN",
    LEFT = "INPUT_BUTTON_LEFT",
    START = "INPUT_BUTTON_START",
    SELECT = "INPUT_BUTTON_SELECT",
    L = "INPUT_BUTTON_L",
    R = "INPUT_BUTTON_R"
})

--- @class
rt.JoystickPosition = meta.new_enum({
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    UNKNOWN = "UNKNON"
})

--- @brief
function rt.InputHandler._load_input_mapping()
    local out = {}

    -- A
    out[rt.InputButton.A] = {
        gamepad = {
            rt.GamepadButton.RIGHT
        },
        keyboard = {
            rt.KeyboardKey.SPACE
        }
    }

    -- B
    out[rt.InputButton.B] = {
        gamepad = {
            rt.GamepadButton.BOTTOM
        },
        keyboard = {
            rt.KeyboardKey.B
        }
    }

    -- X
    out[rt.InputButton.X] = {
        gamepad = {
            rt.GamepadButton.TOP
        },
        keyboard = {
            rt.KeyboardKey.X
        }
    }

    -- Y
    out[rt.InputButton.Y] = {
        gamepad = {
            rt.GamepadButton.LEFT
        },
        keyboard = {
            rt.KeyboardKey.Y
        }
    }

    -- UP
    out[rt.InputButton.UP] = {
        gamepad = {
            rt.GamepadButton.DPAD_UP
        },
        keyboard = {
            rt.KeyboardKey.ARROW_UP
        }
    }

    -- RIGHT
    out[rt.InputButton.RIGHT] = {
        gamepad = {
            rt.GamepadButton.DPAD_RIGHT
        },
        keyboard = {
            rt.KeyboardKey.ARROW_RIGHT
        }
    }

    -- DOWN
    out[rt.InputButton.DOWN] = {
        gamepad = {
            rt.GamepadButton.DPAD_DOWN
        },
        keyboard = {
            rt.KeyboardKey.ARROW_DOWN
        }
    }

    -- LEFT
    out[rt.InputButton.LEFT] = {
        gamepad = {
            rt.GamepadButton.DPAD_LEFT
        },
        keyboard = {
            rt.KeyboardKey.ARROW_LEFT
        }
    }

    -- START
    out[rt.InputButton.START] = {
        gamepad = {
            rt.GamepadButton.START
        },
        keyboard = {
            rt.KeyboardKey.M
        }
    }

    -- SELECT
    out[rt.InputButton.SELECT] = {
        gamepad = {
            rt.GamepadButton.SELECT
        },
        keyboard = {
            rt.KeyboardKey.N
        }
    }

    -- L
    out[rt.InputButton.L] = {
        gamepad = {
            rt.GamepadButton.LEFT_SHOULDER
        },
        keyboard = {
            rt.KeyboardKey.L,
            rt.KeyboardKey.N
        }
    }

    -- R
    out[rt.InputButton.R] = {
        gamepad = {
            rt.GamepadButton.RIGHT_SHOULDER
        },
        keyboard = {
            rt.KeyboardKey.R,
            rt.KeyboardKey.M
        }
    }

    rt.InputHandler._mapping = out

    local gamepad_mapping = {}
    local keyboard_mapping = {}

    for key, binding in pairs(rt.InputHandler._mapping) do
        for _, gamepad_button in pairs(binding.gamepad) do
            gamepad_mapping[gamepad_button] = key
        end

        for _, keyboard_key in pairs(binding.keyboard) do
            keyboard_mapping[keyboard_key] = key
        end
    end

    rt.InputHandler._reverse_mapping = {
        gamepad = gamepad_mapping,
        keyboard = keyboard_mapping
    }
end

--- @class rt.InputController
--- @brief combines all input methods into one, fully abstracted controller
--- @signal pressed   (self, rt.InputButton) -> nil
--- @signal released  (self, rt.InputButton) -> nil
--- @signal joystick  (self, x, y, rt.JoystickPosition) -> nil
--- @signal enter     (self, x, y) -> nil
--- @signal motion    (self, x, y, dx, dy) -> nil
--- @signal leave     (self, x, y) -> nil
rt.InputController = meta.new_type("InputController", rt.SignalEmitter, function(holder)
    local out = meta.new(rt.InputController, {
        _instance = holder,
        _gamepad = rt.GamepadController(holder),
        _keyboard = rt.KeyboardController(holder),
        _mouse = rt.MouseController(holder),
        _state = {},
        _axis_state = {},
        _is_disabled = false
    })

    if sizeof(rt.InputHandler._mapping) == 0 then
        rt.InputHandler._mapping = rt.InputHandler._load_input_mapping()
    end

    for _, key in pairs(rt.InputButton) do
        out._state[key] = false
    end

    for _, axis in pairs(rt.GamepadAxis) do
        out._axis_state[axis] = 0
    end

    out:signal_add("pressed")
    out:signal_add("released")
    out:signal_add("joystick")
    out:signal_add("enter")
    out:signal_add("motion")
    out:signal_add("leave")

    out._gamepad:signal_connect("button_pressed", function(_, id, button, self)

        local action = rt.InputHandler._reverse_mapping.gamepad[button]
        local current = self._state[action]
        self._state[action] = true
        if current == false and not self._is_disabled then
            self:signal_emit("pressed", action)
        end
    end, out)

    out._gamepad:signal_connect("button_released", function(_, id, button, self)

        local action = rt.InputHandler._reverse_mapping.gamepad[button]
        local current = self._state[action]
        self._state[action] = false
        if current == true and not self._is_disabled then
            self:signal_emit("released", action)
        end
    end, out)

    out._gamepad:signal_connect("axis_changed", function(_, id, which_axis, value, self)

        local in_range = function(x, a, b)
            local lower = math.min(a, b)
            local upper = math.max(a, b)
            return x >= lower and x <= upper
        end

        if which_axis == rt.GamepadAxis.LEFT_X or which_axis == rt.GamepadAxis.LEFT_Y then
            local x, y = rt.GamepadHandler.get_axes(id, rt.GamepadAxis.LEFT_X, rt.GamepadAxis.LEFT_Y)
            if rt.magnitude(x, y) < rt.settings.input.deadzone then
                x, y = 0, 0
            end

            if not self._is_disabled then
                self:signal_emit("joystick", x, y, rt.JoystickPosition.LEFT)
            end

            if rt.settings.input.convert_left_trigger_to_dpad then
                local angle = rt.radians(rt.angle(x, y)):as_degrees()
                if in_range(angle, 180 - 45, 180) or in_range(angle, -180 + 45, -180) then -- top
                    if self._state[rt.InputButton.UP] == false then
                        self._state[rt.InputButton.UP] = true
                        self._state[rt.InputButton.DOWN] = false
                        self._state[rt.InputButton.LEFT] = false
                        self._state[rt.InputButton.RIGHT] = false
                        if not self._is_disabled then
                            self:signal_emit("pressed", rt.InputButton.UP)
                        end
                    end
                elseif in_range(angle, 90 + 45, 90 - 45) then -- right
                    if self._state[rt.InputButton.RIGHT] == false then
                        self._state[rt.InputButton.UP] = false
                        self._state[rt.InputButton.DOWN] = false
                        self._state[rt.InputButton.LEFT] = false
                        self._state[rt.InputButton.RIGHT] = true
                        if not self._is_disabled then
                            self:signal_emit("pressed", rt.InputButton.RIGHT)
                        end
                    end
                elseif in_range(angle, 0 - 45, 0 + 45) then -- bottom
                    if self._state[rt.InputButton.DOWN] == false then
                        self._state[rt.InputButton.UP] = false
                        self._state[rt.InputButton.DOWN] = true
                        self._state[rt.InputButton.LEFT] = false
                        self._state[rt.InputButton.RIGHT] = false
                        if not self._is_disabled then
                            self:signal_emit("pressed", rt.InputButton.DOWN)
                        end
                    end
                elseif  in_range(angle, -90 - 45, -90 + 45) then -- left
                    if self._state[rt.InputButton.LEFT] == false then
                        self._state[rt.InputButton.UP] = false
                        self._state[rt.InputButton.DOWN] = false
                        self._state[rt.InputButton.LEFT] = true
                        self._state[rt.InputButton.RIGHT] = false
                        if not self._is_disabled then
                            self:signal_emit("pressed", rt.InputButton.LEFT)
                        end
                    end
                end
            end
        end

        if which_axis == rt.GamepadAxis.RIGHT_X or which_axis == rt.GamepadAxis.RIGHT_Y then
            local x, y = rt.GamepadHandler.get_axes(id, rt.GamepadAxis.RIGHT_X, rt.GamepadAxis.RIGHT_Y)

            if rt.magnitude(x, y) < rt.settings.input.deadzone then
                x, y = 0, 0
            end

            if not self._is_disabled then
                self:signal_emit("joystick", x, y, rt.JoystickPosition.RIGHT)
            end

            if rt.settings.input.convert_right_trigger_to_dpad then
                local distance = math.sqrt((x - 0)^2 + (y - 0)^2)
                local angle = rt.radians(math.atan2(x - 0, y - 0)):as_degrees()

                local out = {}
                local joystick
                local joysticks = love.joystick.getJoysticks()
                for i, x in ipairs(joysticks) do
                    if i == id then
                        joystick = x
                    end
                end

                if distance >= rt.settings.input.deadzone then
                    if in_range(angle, 180 - 45, 180) or in_range(angle, -180 + 45, -180) then -- top
                        if self._state[rt.InputButton.UP] == false then
                            self._state[rt.InputButton.UP] = true
                            self._state[rt.InputButton.DOWN] = false
                            self._state[rt.InputButton.LEFT] = false
                            self._state[rt.InputButton.RIGHT] = false
                            if not self._is_disabled then
                                self:signal_emit("pressed", rt.InputButton.UP)
                            end
                        end
                    elseif in_range(angle, 90 + 45, 90 - 45) then -- right
                        if self._state[rt.InputButton.RIGHT] == false then
                            self._state[rt.InputButton.UP] = false
                            self._state[rt.InputButton.DOWN] = false
                            self._state[rt.InputButton.LEFT] = false
                            self._state[rt.InputButton.RIGHT] = true
                            if not self._is_disabled then
                                self:signal_emit("pressed", rt.InputButton.RIGHT)
                            end
                        end
                    elseif in_range(angle, 0 - 45, 0 + 45) then -- bottom
                        if self._state[rt.InputButton.DOWN] == false then
                            self._state[rt.InputButton.UP] = false
                            self._state[rt.InputButton.DOWN] = true
                            self._state[rt.InputButton.LEFT] = false
                            self._state[rt.InputButton.RIGHT] = false
                            if not self._is_disabled then
                                self:signal_emit("pressed", rt.InputButton.DOWN)
                            end
                        end
                    elseif  in_range(angle, -90 - 45, -90 + 45) then -- left
                        if self._state[rt.InputButton.LEFT] == false then
                            self._state[rt.InputButton.UP] = false
                            self._state[rt.InputButton.DOWN] = false
                            self._state[rt.InputButton.LEFT] = true
                            self._state[rt.InputButton.RIGHT] = false
                            if not self._is_disabled then
                                self:signal_emit("pressed", rt.InputButton.LEFT)
                            end
                        end
                    end
                end
            end
        elseif which_axis == rt.GamepadAxis.LEFT_TRIGGER then
            local eps = rt.settings.input.trigger_threshold
            if self._axis_state[rt.GamepadAxis.LEFT_TRIGGER] < eps and value > eps then
                if self._state[rt.InputButton.L] == false then
                    self._state[rt.InputButton.L] = true
                    if not self._is_disabled then self:signal_emit("pressed", rt.InputButton.L) end
                end
            elseif self._axis_state[rt.GamepadAxis.LEFT_TRIGGER] > eps and value < eps then
                if self._state[rt.InputButton.L] == true then
                    self._state[rt.InputButton.L] = false
                    if not self._is_disabled then self:signal_emit("released", rt.InputButton.L) end
                end
            end
        elseif which_axis == rt.GamepadAxis.RIGHT_TRIGGER then
            local eps = rt.settings.input.trigger_threshold
            if self._axis_state[rt.GamepadAxis.RIGHT_TRIGGER] < eps and value > eps then
                if self._state[rt.InputButton.R] == false then
                    self._state[rt.InputButton.R] = true
                    if not self._is_disabled then self:signal_emit("pressed", rt.InputButton.R) end
                end
            elseif self._axis_state[rt.GamepadAxis.RIGHT_TRIGGER] > eps and value < eps then
                if self._state[rt.InputButton.R] == true then
                    self._state[rt.InputButton.R] = false
                    if not self._is_disabled then self:signal_emit("released", rt.InputButton.R) end
                end
            end
        end
        self._axis_state[which_axis] = value
    end, out)

    out._keyboard:signal_connect("key_pressed", function(_, key, self)
        if not meta.is_enum_value(key, rt.KeyboardKey) then return end
        local action = rt.InputHandler._reverse_mapping.keyboard[key]
        if meta.is_nil(action) then return end

        local current = self._state[action]
        self._state[action] = true
        if current == false and not self._is_disabled then
            self:signal_emit("pressed", action)
        end
    end, out)

    out._keyboard:signal_connect("key_released", function(_, key, self)
        if not meta.is_enum_value(key, rt.KeyboardKey) then return end
        local action = rt.InputHandler._reverse_mapping.keyboard[key]
        if meta.is_nil(action) then return end

        local current = self._state[action]
        self._state[action] = false
        if current == true and not self._is_disabled then
            self:signal_emit("released", action)
        end
    end, out)

    out._mouse:signal_connect("click_pressed", function(_, x, y, button_id, n_presses, self)

        local current = self._state[rt.InputButton.A]
        self._state[rt.InputButton.A] = true
        if current == false and not self._is_disabled and rt.aabb_contains(self._instance:get_bounds(), x, y) then
            self:signal_emit("pressed", rt.InputButton.A)
        end
    end, out)

    out._mouse:signal_connect("click_released", function(_, x, y, button_id, n_presses, self)

        local current = self._state[rt.InputButton.A]
        self._state[rt.InputButton.A] = false
        if current == true and not self._is_disabled and rt.aabb_contains(self._instance:get_bounds(), x, y) then
            self:signal_emit("released", rt.InputButton.A)
        end
    end, out)

    out._mouse:signal_connect("motion_enter", function(_, x, y, self)
        if not self._is_disabled then self:signal_emit("enter", x, y) end
    end, out)

    out._mouse:signal_connect("motion", function(_, x, y, dx, dy, self)
        if not self._is_disabled then self:signal_emit("motion", x, y, dx, dy) end
    end, out)

    out._mouse:signal_connect("motion_leave", function(_, x, y, self)
        if not self._is_disabled then self:signal_emit("leave", x, y) end
    end, out)
    
    return out
end)

--- @brief
function rt.InputController:is_down(key)
    return self._state[key] == true
end

--- @brief
function rt.InputController:is_up(key)
    return self._state[key] == false
end

--- @brief
--- @return Number, Number
function rt.InputController:get_left_joystick()
    return self._axis_state[rt.GamepadAxis.LEFT_X], self._axis_state[rt.GamepadAxis.LEFT_Y]
end

--- @brief
--- @return Number, Number
function rt.InputController:get_right_joystick()
    return self._axis_state[rt.GamepadAxis.RIGHT_X], self._axis_state[rt.GamepadAxis.RIGHT_Y]
end

--- @brief
--- @return Number, Number
function rt.InputController:get_cursor_position()
    return self._mouse:get_cursor_position()
end

--- @brief
function rt.add_input_controller(object)
    local to_add = rt.InputController(object)
    getmetatable(object).components.input = to_add
    return to_add
end

--- @brief
function rt.get_input_controller(object)
    return getmetatable(object).components.input
end

--- @brief
function rt.InputController:set_is_disabled(b)
    self._is_disabled = b
end

--- @brief
function rt.InputController:get_is_disabled()
    return self._is_disabled
end

--- @brief [internal]
rt.test.input_controller = function()
    --[[
    input = rt.InputController(window)
    input:signal_connect("pressed", function(self, button)
        if button == rt.InputButton.A then
            println("A")
        elseif button == rt.InputButton.B then
            println("B")
        elseif button == rt.InputButton.X then
            println("X")
        elseif button == rt.InputButton.Y then
            println("Y")
        elseif button == rt.InputButton.UP then
            println("up")
        elseif button == rt.InputButton.RIGHT then
            println("right")
        elseif button == rt.InputButton.DOWN then
            println("down")
        elseif button == rt.InputButton.LEFT then
            println("left")
        elseif button == rt.InputButton.START then
            println("start")
        elseif button == rt.InputButton.SELECT then
            println("select")
        elseif button == rt.InputButton.L then
            println("l")
        elseif button == rt.InputButton.R then
            println("r")
        end
    end)

    input:signal_connect("joystick", function(self, x, y)
        println(x, " ", y)
    end)

    input:signal_connect("enter", function(motion, x, y)
        println("enter")
    end)

    input:signal_connect("leave", function(motion, x, y)
        println("leave")
    end)

    input:signal_connect("motion", function(motion, x, y, dx, dy)
        println(x, " ", y, " ", dx, " ", dy)
    end)
    ]]--
end



