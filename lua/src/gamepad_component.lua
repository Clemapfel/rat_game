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
    RIGHT_TRIGGER = "triggeright"
})

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
    local instance = meta._new("Object")
    instance.gamepad = rt.GamepadComponent(instance)

    local dummy = {
        getID = function() return 0 end
    }

    local added_called = false
    instance.gamepad.signal:connect("added", function(self, id)
        added_called = true
    end)
    rt.GamepadHandler.handle_joystick_added(dummy)

    local button_pressed_called = false
    instance.gamepad.signal:connect("button_pressed", function(self, id, button)
        assert(id == rt.GamepadHandler._active_joystick_id)
        button_pressed_called = true
    end)
    rt.GamepadHandler.handle_button_pressed(dummy, rt.GamepadButton.START)

    local button_released_called = false
    instance.gamepad.signal:connect("button_released", function(self, id, button)
        assert(id == rt.GamepadHandler._active_joystick_id)
        button_released_called = true
    end)
    rt.GamepadHandler.handle_button_released(dummy, rt.GamepadButton.START)

    local n_axis_called = 0
    instance.gamepad.signal:connect("axis_changed", function(self, id, axis, value)
        assert(id == rt.GamepadHandler._active_joystick_id)
        n_axis_called = n_axis_called + 1
    end)

    for axis, _ in pairs(rt.GamepadAxis) do
        rt.GamepadHandler.handle_axis_changed(dummy, axis, 0.1)
    end

    assert(added_called)
    assert(not is_empty(rt.GamepadHandler._joysticks))
    assert(n_axis_called == 6)
    assert(button_released_called)
    assert(button_pressed_called)

    local removed_called = false
    instance.gamepad.signal:connect("removed", function(self, id)
        removed_called = true
    end)
    rt.GamepadHandler.handle_joystick_removed(dummy)
    assert(removed_called)
end
rt.test.gamepad_component()

