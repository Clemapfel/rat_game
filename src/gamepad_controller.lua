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

rt.SIGNAL_BUTTON_PRESSED = "button_pressed"
rt.SIGNAL_BUTTON_RELEASED = "button_released"
rt.SIGNAL_CONTROLLER_ADDED = "connected"
rt.SIGNAL_CONTROLLER_REMOVED = "disconnected"
rt.SIGNAL_AXIS_CHANGED = "axis"

--- @class GamepadController
rt.GamepadController = meta.new_type("GamepadController", function(instance)
    meta.assert_object(instance)
    local hash = rt.GamepadHandler._hash
    rt.GamepadHandler._hash = rt.GamepadHandler._hash + 1

    local out = meta.new(rt.GamepadController, {
        instance = instance,
        _hash = hash
    })
    rt.add_signal_component(out)
    out.signal:add(rt.SIGNAL_BUTTON_PRESSED)
    out.signal:add(rt.SIGNAL_BUTTON_RELEASED)
    out.signal:add(rt.SIGNAL_CONTROLLER_ADDED)
    out.signal:add(rt.SIGNAL_CONTROLLER_REMOVED)
    out.signal:add(rt.SIGNAL_AXIS_CHANGED)

    rt.GamepadHandler._components[hash] = out
    return out
end)

--- @brief handle joystick add
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_added(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        component.signal:emit(rt.SIGNAL_CONTROLLER_ADDED, joystick:getID())
    end
end
love.joystickadded = rt.GamepadHandler.handle_joystick_added

--- @brief handle joystick remove
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_removed(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        component.signal:emit(rt.SIGNAL_CONTROLLER_REMOVED, joystick:getID())
    end
end
love.joystickremoved = rt.GamepadHandler.handle_joystick_removed

--- @brief handle button pressed
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_pressed(joystick, button)
    meta.assert_enum(button, rt.GamepadButton)
    for _, component in pairs(rt.GamepadHandler._components) do
        component.signal:emit(rt.SIGNAL_BUTTON_PRESSED, joystick:getID(), button)
    end
end
love.gamepadpressed = rt.GamepadHandler.handle_button_pressed

--- @brief handle button released
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_released(joystick, button)
    meta.assert_enum(button, rt.GamepadButton)
    for _, component in pairs(rt.GamepadHandler._components) do
        component.signal:emit(rt.SIGNAL_BUTTON_RELEASED, joystick:getID(), button)
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
        component.signal:emit(rt.SIGNAL_AXIS_CHANGED, joystick:getID(), axis, value)
    end
end
love.gamepadaxis = rt.GamepadHandler.handle_axis_changed

--- @brief add an gamepad component
function rt.add_gamepad_controller(target)
    meta.assert_object(target)
    getmetatable(target).components.gamepad = rt.GamepadController(target)
    return getmetatable(target).components.gamepad
end

--- @brief
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
    --[[
    gamepad = rt.GamepadController(window)
    gamepad.signal:connect(rt.SIGNAL_CONTROLLER_ADDED, function(self, id)
        println("added: ", id)
    end)
    gamepad.signal:connect(rt.SIGNAL_CONTROLLER_REMOVED, function(self, id)
        println("removed: ", id)
    end)
    gamepad.signal:connect(rt.SIGNAL_BUTTON_PRESSED, function(self, id, button)
        println("pressed: ", id, " ", button)
    end)
    gamepad.signal:connect(rt.SIGNAL_BUTTON_RELEASED, function(self, id, button)
        println("released: ", id, " ", button)
    end)
    gamepad.signal:connect(rt.SIGNAL_AXIS_CHANGED, function(self, id, axis, value)
        println("axis: ", id, " ", axis, " ", value)
    end)
    ]]--
end
rt.test.gamepad_controller()

--[[
rt.GamepadHandler._hash = 1
rt.GamepadHandler._components = {}

rt.GamepadHandler._active_joystick_id = 0
rt.GamepadHandler._joysticks = {} -- JoystickID -> love.Joystick

--- @brief [internal] store love.Joystick
--- @param joystick love.Joystick
function rt.GamepadHandler._update_joystick(joystick)
    local id = joystick:getID()
    rt.GamepadHandler._active_joystick_id = id
    rt.GamepadHandler._joysticks[id] = joystick
end

--- @class rt.GamepadComponent
--- @signal added (::GamepadComponent, ::JoystickID) -> nil
--- @signal removed (::GamepadComponent, ::JoysticKID) -> nil
--- @signal button_pressed (::GamepadComponent, ::JoystickID, ::GamepadButton) -> Boolean
--- @signal button_released (::GamepadComponent, ::JoystickID, ::GamepadButton) -> Boolean
--- @signal axis_changed (::GamepadComponent, ::JoystickID, ::GamepadAxis, value) -> nil
rt.GamepadComponent = meta.new_type("GamepadComponent", function(holder)
    meta.assert_object(holder)
    local hash = rt.GamepadHandler._hash
    local out = meta.new(rt.GamepadComponent, {
        _hash = hash,
        instance = holder
    })
    rt.add_signal_component(out)

    rt.GamepadHandler._components[hash] = out
    rt.GamepadHandler._hash = hash + 1

    out.signal:add("added")
    out.signal:add("removed")
    out.signal:add("button_pressed")
    out.signal:add("button_released")
    out.signal:add("axis_changed")

    return rt.GamepadHandler._components[hash]
end)

--- @brief handle joystick add
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_added(joystick)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        if getmetatable(component.instance).is_focused == true then
            component.signal:emit("added", joystick:getID())
        end
    end
end
love.joystickadded = rt.GamepadHandler.handle_joystick_added

--- @brief handle joystick remove
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_removed(joystick)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        if getmetatable(component.instance).is_focused == true then
            component.signal:emit("removed",  joystick:getID())
        end
    end
end
love.joystickremoved = rt.GamepadHandler.handle_joystick_removed

--- @brief handle button pressed
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_pressed(joystick, button)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        if getmetatable(component.instance).is_focused == true then
            component.signal:emit("button_pressed", joystick:getID(), button)
        end
    end
end
love.gamepadpressed = rt.GamepadHandler.handle_button_pressed

--- @brief handle button released
--- @param joystick love.Joystick
--- @param button rt.GamepadButton
function rt.GamepadHandler.handle_button_released(joystick, button)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        if getmetatable(component.instance).is_focused == true then
            component.signal:emit("button_released", joystick:getID(), button)
        end
    end
end
love.gamepadreleased = rt.GamepadHandler.handle_button_released

--- @brief handle axis changed
--- @param joystick love.Joystick
--- @param axis rt.GamepadAxis
--- @param value Number
function rt.GamepadHandler.handle_axis_changed(joystick, axis, value)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in pairs(rt.GamepadHandler._components) do
        if getmetatable(component.instance).is_focused == true then
            component.signal:emit("axis_changed", joystick:getID(), axis, value)
        end
    end
end
love.gamepadaxis = rt.GamepadHandler.handle_axis_changed

--- @brief add an gamepad component as `.gamepad`
function rt.add_gamepad_component(target)
    meta.assert_object(target)
    getmetatable(target).components.gamepad = rt.GamepadComponent(target)
    return getmetatable(target).components.gamepad
end

--- @brief get gamepad component assigned
--- @return rt.GamepadComponent
function rt.get_gamepad_component(self)
    meta.assert_object(target)
    local components = getmetatable(target).components
    if meta.is_nil(components) then
        return nil
    end
    return components.keyboard
end

--- @brief [internal] test keyboard component
rt.test.gamepad_component = function()
end
rt.test.gamepad_component()
]]--
