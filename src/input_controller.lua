rt.InputHandler = {}
rt.InputHandler._components = {}
meta.make_weak(rt.InputHandler._components, false, true)

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
            rt.KeyboardKey.A
        }
    }

    -- R
    out[rt.InputButton.R] = {
        gamepad = {
            rt.GamepadButton.RIGHT_SHOULDER
        },
        keyboard = {
            rt.KeyboardKey.S
        }
    }

    rt.InputHandler._mapping = out

    local gamepad_mapping = {}
    local keyboard_mapping = {}

    for key, binding in pairs(rt.InputHandler._mapping) do
        meta.assert_enum(key, rt.InputButton)

        meta.assert_table(binding.gamepad)
        for _, gamepad_button in pairs(binding.gamepad) do
            meta.assert_enum(gamepad_button, rt.GamepadButton)
            gamepad_mapping[gamepad_button] = key
        end

        meta.assert_table(binding.keyboard)
        for _, keyboard_key in pairs(binding.keyboard) do
            meta.assert_enum(keyboard_key, rt.KeyboardKey)
            keyboard_mapping[keyboard_key] = key
        end
    end

    rt.InputHandler._reverse_mapping = {
        gamepad = gamepad_mapping,
        keyboard = keyboard_mapping
    }
end

--- @class rt.InputController
--- @signal pressed     (self, rt.InputButton) -> nil
--- @signal released    (self, rt.InputButton) -> nil
rt.InputController = meta.new_type("InputController", function(holder)
    meta.assert_isa(self, rt.Widget)

    local out = meta.new(rt.InputController, {
        _instance = holder,
        _gamepad = rt.GamepadController(holder),
        _keyboard = rt.KeyboardController(holder),
        _mouse = rt.MouseController(holder),
        _state = {}
    }, rt.SignalEmitter)

    if sizeof(rt.InputHandler._mapping) == 0 then
        rt.InputHandler._mapping = rt.InputHandler._load_input_mapping()
    end
    if sizeof(rt.InputHandler._reverse_mapping) == 0 then
        rt.InputHandler._reverse_mapping = rt.InputHandler._generate_reverse_mapping()
    end

    for _, key in pairs(rt.InputButton) do
        out._state[key] = false
    end

    out:signal_add("pressed")
    out:signal_add("released")

    out._gamepad:signal_connect("button_pressed", function(_, id, button, self)
        meta.assert_enum(button, rt.GamepadButton)
        local action = rt.InputHandler._reverse_mapping.gamepad[button]
        if not meta.is_nil(action) then self:signal_emit("pressed", action) end
        self._state[action] = true
    end, out)

    out._gamepad:signal_connect("button_released", function(_, id, button, self)
        meta.assert_enum(button, rt.GamepadButton)
        local action = rt.InputHandler._reverse_mapping.gamepad[button]
        if not meta.is_nil(action) then self:signal_emit("released", action) end
        self._state[action] = false
    end, out)

    out._keyboard:signal_connect("key_pressed", function(_, key, self)
        meta.assert_enum(key, rt.KeyboardKey)
        local action = rt.InputHandler._reverse_mapping.keyboard[key]
        if not meta.is_nil(action) then self:signal_emit("pressed", action) end
        self._state[action] = true
    end, out)

    out._keyboard:signal_connect("key_released", function(_, key, self)
        meta.assert_enum(key, rt.KeyboardKey)
        local action = rt.InputHandler._reverse_mapping.keyboard[key]
        if not meta.is_nil(action) then self:signal_emit("released", action) end
        self._state[action] = false
    end, out)

    return out
end)

