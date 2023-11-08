--- @brief
function rt.load_input_mapping()
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
    out[rt.InputButton.RIGHT] = {
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
end