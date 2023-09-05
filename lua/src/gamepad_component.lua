--- @brief singleton, handles controller input
rt.GamepadHandler = {}

--- @class GamepadButton
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

--- @class GamepadAxis
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
    local id = love.getID(joystick)
    rt.GamepadHandler._active_joystick_id = id
    if meta.is_nil(rt.GamepadHandler._joysticks[id]) then
        rt.GamepadHandler._joysticks[id] = joystick
    end
end

--- @class GamepadComponent
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
        _instance = holder
    })
    rt.add_signal_component(out)
   
    rt.GamepadHandler._components[hash] = out
    rt.GamepadHandler._hash = hash + 1

    local metatable = getmetatable(holder)
    if not meta.is_boolean(metatable.is_focused) then
        metatable.is_focused = true
    end

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
    for _, component in ipairs(rt.GamepadHandler._components) do
        if getmetatable(component._instance).is_focused == true then
            component.signal:emit("added", love.getID(joystick))
        end
    end
end
love.joystickadded = rt.GamepadHandler.handle_joystick_added

--- @brief handle joystick remove
--- @param joystick love.Joystick
function rt.GamepadHandler.handle_joystick_removed(joystick)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in ipairs(rt.GamepadHandler._components) do
        if getmetatable(component._instance).is_focused == true then
            component.signal:emit("removed",  love.getID(joystick))
        end
    end
end
love.joystickremoved = rt.GamepadHandler.handle_joystick_removed

--- @brief handle button pressed
--- @param joystick love.Joystick
--- @param button GamepadButton
function rt.GamepadHandler.handle_button_pressed(joystick, button)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in ipairs(rt.GamepadHandler._components) do
        if getmetatable(component._instance).is_focused == true then
            component.signal:emit("button_pressed", love.getID(joystick), button)
        end
    end
end
love.gamepadpressed = rt.GamepadHandler.handle_button_pressed

--- @brief handle button released
--- @param joystick love.Joystick
--- @param button GamepadButton
function rt.GamepadHandler.handle_button_released(joystick, button)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in ipairs(rt.GamepadHandler._components) do
        if getmetatable(component._instance).is_focused == true then
            component.signal:emit("button_released", love.getID(joystick), button)
        end
    end
end
love.gamepadreleased = rt.GamepadHandler.handle_button_released

--- @brief handle axis changed
--- @param joystick love.Joystick
--- @param axis GamepadAxis
--- @param value Number
function rt.GamepadHandler.handle_axis_changed(joystick, axis, value)
    rt.GamepadHandler._update_joystick(joystick)
    for _, component in ipairs(rt.GamepadHandler._components) do
        if getmetatable(component._instance).is_focused == true then
            component.signal:emit("axis_changed", love.getID(joystick), axis, value)
        end
    end
end
love.gamepadaxis = rt.GamepadHandler.handle_axis_changed

--- @brief [internal] test keyboard component
rt.test.gamepad_component = function()
    local instance = meta._new("Object")
    instance.gamepad = rt.GamepadComponent(instance)

    local added_called = false
    instance.gamepad.signal:connect("added", function(self, id)
        added_called = true
    end)

    local removed_called = false
    instance.gamepad.signal:connect("removed", function(self, id)
        removed_called = true
    end)

    local button_pressed_called = false
    instance.gamepad.signal:connect("button_pressed", function(self, id, button)
        assert(id == rt.GamepadHandler._active_joystick_id)
        button_pressed_called = true
    end)
    instance.gamepad.signal:emit("button_pressed", 0, rt.GamepadButton.START)

    local button_released_called = false
    instance.gamepad.signal:connect("button_released", function(self, id, button)
        assert(id == rt.GamepadHandler._active_joystick_id)
        button_released_called = true
    end)
    instance.gamepad.signal:emit("button_released", 0, rt.GamepadButton.START)

    local n_axis_called = 0
    instance.gamepad.signal:connect("axis_changed", function(self, id, axis, value)
        assert(id == rt.GamepadHandler._active_joystick_id)
        n_axis_called = n_axis_called + 1
    end)

    for axis, _ in pairs(rt.GamepadAxis) do
        instance.gamepad.signal:emit("axis_changed", 0, axis, 0)
    end

    -- assert(added_called)
    -- assert(not isempty(rt.GamepadComponent._joysticks))
    -- assert(removed_called)
    assert(n_axis_called == 6)
    assert(button_released_called)
    assert(button_pressed_called)
end
rt.test.gamepad_component()

