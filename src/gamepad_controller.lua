--- @brief rt.GamepadHandler
rt.GamepadHandler = {}

--- @class rt.GamepadButton
rt.GamepadButton = meta.new_enum({
    TOP = "y",
    RIGHT = "b",
    BOTTOM = "a",
    LEFT = "x",
    DPAD_UP = "dpup",
    DPAD_DOWN = "dpdown",
    DPAD_LEFT = "dpleft",
    DPAD_RIGHT = "dpright",
    START = "start",
    SELECT = "back",
    HOME = "guide",
    LEFT_STICK = "leftstick",
    RIGHT_STICK = "rightstick",
    LEFT_SHOULDER = "leftshoulder",
    RIGHT_SHOULDER = "rightshoulder"
})

--- @class rt.GamepadAxis
rt.GamepadAxis = meta.new_enum({
    LEFT_X = "leftx",
    LEFT_Y = "lefty",
    RIGHT_X = "rightx",
    RIGHT_Y = "righty",
    LEFT_TRIGGER = "triggerleft",
    RIGHT_TRIGGER = "triggerright"
})

rt.GamepadHandler = {}
rt.GamepadHandler._hash = 0
rt.GamepadHandler._components = {}
meta.make_weak(rt.GamepadHandler._components, false, true)

rt.SIGNAL_BUTTON_PRESSED = "button_pressed"
rt.SIGNAL_BUTTON_RELEASED = "button_released"
rt.SIGNAL_CONTROLLER_ADDED = "connected"
rt.SIGNAL_CONTROLLER_REMOVED = "disconnected"
rt.SIGNAL_AXIS_CHANGED = "axis"

--- @class rt.GamepadController
--- @param instance meta.Object
rt.GamepadController = meta.new_type("GamepadController", function(instance)
    meta.assert_object(instance)
    local hash = rt.GamepadHandler._hash
    rt.GamepadHandler._hash = rt.GamepadHandler._hash + 1

    local out = meta.new(rt.GamepadController, {
        instance = instance,
        _hash = hash
    }, rt.SignalEmitter)
    out:signal_add(rt.SIGNAL_BUTTON_PRESSED)
    out:signal_add(rt.SIGNAL_BUTTON_RELEASED)
    out:signal_add(rt.SIGNAL_CONTROLLER_ADDED)
    out:signal_add(rt.SIGNAL_CONTROLLER_REMOVED)
    out:signal_add(rt.SIGNAL_AXIS_CHANGED)

    rt.GamepadHandler._components[hash] = out
    return out
end)

--- @brief handle joystick add
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_added(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit(rt.SIGNAL_CONTROLLER_ADDED, joystick:getID())
    end
end
love.joystickadded = rt.GamepadHandler.handle_joystick_added

--- @brief handle joystick remove
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_removed(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit(rt.SIGNAL_CONTROLLER_REMOVED, joystick:getID())
    end
end
love.joystickremoved = rt.GamepadHandler.handle_joystick_removed

--- @brief handle button pressed
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_pressed(joystick, button)
    meta.assert_enum(button, rt.GamepadButton)
    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit(rt.SIGNAL_BUTTON_PRESSED, joystick:getID(), button)
    end
end
love.gamepadpressed = rt.GamepadHandler.handle_button_pressed

--- @brief handle button released
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_released(joystick, button)
    meta.assert_enum(button, rt.GamepadButton)
    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit(rt.SIGNAL_BUTTON_RELEASED, joystick:getID(), button)
    end
end
love.gamepadreleased = rt.GamepadHandler.handle_button_released

--- @brief handle axis changed
--- @param joystick love.Joystick
--- @param axis rt.GamepadAxis
--- @param value Number
function rt.GamepadHandler.handle_axis_changed(joystick, axis, value)
    meta.assert_enum(axis, rt.GamepadAxis)
    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit(rt.SIGNAL_AXIS_CHANGED, joystick:getID(), axis, value)
    end
end
love.gamepadaxis = rt.GamepadHandler.handle_axis_changed

--- @brief add a gamepad controller
--- @param target meta.Object
--- @return rt.GamepadController
function rt.add_gamepad_controller(target)
    meta.assert_object(target)
    getmetatable(target).components.gamepad = rt.GamepadController(target)
    return getmetatable(target).components.gamepad
end

--- @brief get gamepade controller
--- @param target meta.Object
--- @return rt.GamepadController (or nil)
function rt.get_gamepad_controller(target)
    meta.assert_object(target)
    local components = getmetatable(target).components
    if meta.is_nil(components) then
        return nil
    end
    return components.gamepad
end

--- @brief [internal] test gamepad controller
function rt.test.gamepad_controller()
    -- TODO
end
