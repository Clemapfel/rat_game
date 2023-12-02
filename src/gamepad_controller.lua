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

--- @class rt.GamepadController
--- @signal button_pressed  (self, controller_id, rt.GamepadButton) -> nil
--- @signal button_released (self, controller_id, rt.GamepadButton) -> nil
--- @signal connected       (self, controller_id) -> nil
--- @signal disconnected    (self, controller_id) -> nil
--- @signal axis_changed    (self, controller_id, rt.GamepadAxis, Number) -> nil
--- @param instance meta.Object
rt.GamepadController = meta.new_type("GamepadController", function(instance)

    local hash = rt.GamepadHandler._hash
    rt.GamepadHandler._hash = rt.GamepadHandler._hash + 1

    local out = meta.new(rt.GamepadController, {
        instance = instance,
        _hash = hash
    }, rt.SignalEmitter)
    out:signal_add("button_pressed")
    out:signal_add("button_released")
    out:signal_add("connected")
    out:signal_add("disconnected")
    out:signal_add("axis_changed")

    rt.GamepadHandler._components[hash] = out
    return out
end)

--- @brief handle joystick add
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_added(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit("connected", joystick:getID())
    end
end
love.joystickadded = rt.GamepadHandler.handle_joystick_added

--- @brief handle joystick remove
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_removed(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit("disconnected", joystick:getID())
    end
end
love.joystickremoved = rt.GamepadHandler.handle_joystick_removed

--- @brief handle button pressed
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_pressed(joystick, button)

    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit("button_pressed", joystick:getID(), button)
    end
end
love.gamepadpressed = rt.GamepadHandler.handle_button_pressed

--- @brief handle button released
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_released(joystick, button)

    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit("button_released", joystick:getID(), button)
    end
end
love.gamepadreleased = rt.GamepadHandler.handle_button_released

--- @brief handle axis changed
--- @param joystick love.Joystick
--- @param axis rt.GamepadAxis
--- @param value Number
function rt.GamepadHandler.handle_axis_changed(joystick, axis, value)

    for _, component in pairs(rt.GamepadHandler._components) do
        component:signal_emit("axis_changed", joystick:getID(), axis, value)
    end
end
love.gamepadaxis = rt.GamepadHandler.handle_axis_changed

--- @brief get current axis position
--- @param vararg rt.GamepadAxis
function rt.GamepadHandler.get_axes(controller_id, ...)
    local out = {}
    local joystick
    local joysticks = love.joystick.getJoysticks()
    for i, x in ipairs(joysticks) do
        if i == controller_id then
            joystick = x
        end
    end

    if joystick == nil then
        rt.error("In rt.GamepadHandler.get_axes: no controller with id `" .. tostring(controller_id) .. "` available")
    end

    local raw = {joystick:getAxes()}
    local axes = {}
    axes[rt.GamepadAxis.LEFT_X] = raw[1]
    axes[rt.GamepadAxis.LEFT_Y] = raw[2]
    axes[rt.GamepadAxis.LEFT_TRIGGER] = raw[3]
    axes[rt.GamepadAxis.RIGHT_X] = raw[4]
    axes[rt.GamepadAxis.RIGHT_Y] = raw[5]
    axes[rt.GamepadAxis.RIGHT_TRIGGER] = raw[6]

    local out = {}
    for _, which in pairs({...}) do
        table.insert(out, axes[which])
    end
    return table.unpack(out)
end

--- @brief add a gamepad controller
--- @param target meta.Object
--- @return rt.GamepadController
function rt.add_gamepad_controller(target)

    getmetatable(target).components.gamepad = rt.GamepadController(target)
    return getmetatable(target).components.gamepad
end

--- @brief get gamepade controller
--- @param target meta.Object
--- @return rt.GamepadController (or nil)
function rt.get_gamepad_controller(target)

    local components = getmetatable(target).components
    if meta.is_nil(components) then
        return nil
    end
    return components.gamepad
end

--- @brief [internal] test gamepad controller
function rt.test.gamepad_controller()
    error("TODO")
end
