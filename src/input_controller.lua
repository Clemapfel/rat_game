rt.InputHandler = {}
rt.InputHander._components = {}
meta.make_weak(rt.InputHandler._components, false, true)

--- @brief [internal]
function rt.InputHandler:_generate_reverse_mapping()
    meta.assert_table(rt.InputHandler._mapping)

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

    return {
        gamepad = gamepad_mapping,
        keyboard = keyboard_mapping
    }
end

--- @class rt.InputButton
rt.InputButton = meta.new_enum({
    A = "INPUT_BUTTON_A",
    B = "INPUT_BUTTON_B",
    X = "INPUT_BUTTON_X",
    Y = "INPUT_BUTTON_Y",
    UP = "INPUT_BUTTON_UP",
    RIGHT = "INPUT_BUTTON_RIGHT",
    BOTTOM = "INPUT_BUTTON_BOTTOM",
    LEFT = "INPUT_BUTTON_LEFT",
    START = "INPUT_BUTTON_START",
    SELECT = "INPUT_BUTTON_SELECT",
    L = "INPUT_BUTTON_L",
    R = "INPUT_BUTTON_R"
})

rt.InputHandler._mapping = rt.load_input_mapping()
rt.InputHandler._reverse_mapping = rt.InputHandler._generate_reverse_mapping()


--- @class rt.InputAction
rt.InputAction = meta.new_enum({
    ACTIVATE = "ACTIVATE",
    CANCEL = "CANCEL",
    NEXT = "NEXT",
    PREVIOUS = "PREVIOUS",
    INCREASE = "INCREASE",
    DECREASE = "DECREASE",
    UNDO = "UNDO",
    REDO = "REDO"
})

--- @class rt.InputController
rt.InputController = meta.new_type("InputController", function(holder)
    meta.assert_object(holder)
    local out = meta.new(rt.InputController, {
        _instance = holder
    }, rt.SignalEmitter)

    out:signal_add("pressed")
    out:signal_add("tick")
    out:signal_add("released")
    return out
end)