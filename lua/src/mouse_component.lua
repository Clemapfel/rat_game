--- @brief singleton, handles mouse input
rt.MouseHandler = {}

--- @class MouseButton
rt.MouseButton = meta.new_enum({
    LEFT = 1,
    MIDDLE = 2,
    RIGHT = 3
})

rt.MouseHandler._hash = 1
rt.MouseHandler._components = {}

--- @class MouseComponent
--- @signal button_pressed (::MouseComponent, x::Number, y::Number, ::MouseButton) -> Boolean
--- @signal button_released (::MouseComponent, x::Number, y::Number, ::MouseButton) -> Boolean
--- @signal motion (::MouseComponent, x::Number, y::Number, dx::Number, dy::Number) -> nil
--- @signal motion_enter (::MouseComponent, x::Number, y::Number) -> nil
--- @signal motion_leave (::MouseComponent, x::Number, y::Number) -> nil
rt.MouseComponent = meta.new_type("MouseComponent", function(holder)
    meta.assert_object(holder)
    local hash = rt.MouseHandler._hash
    local out = meta.new(rt.MouseComponent, {
        _hash = hash,
        _is_active = false, -- whether cursor is inside objects bounds
        _instance = holder
    })
    rt.add_signal_component(out)

    rt.MouseHandler._components[hash] = out
    rt.MouseHandler._hash = hash + 1

    local metatable = getmetatable(holder)
    if not meta.is_boolean(metatable.is_focused) then
        metatable.is_focused = true
    end

    out.signal:add("button_pressed")
    out.signal:add("button_released")
    out.signal:add("motion_enter")
    out.signal:add("motion")
    out.signal:add("motion_leave")

    local metatable = getmetatable(holder)
    metatable.components.mouse = out
    metatable.__gc = function(self)
        rt.MouseHandler._components[self._hash] = nil
    end

    return out
end)

--- @brief check if mouse cursor is inside objects bounds
--- @param x Number
--- @param y Number
--- @param object
function rt.MouseHandler.is_cursor_in_bounds(x, y, object)
    local allocation_maybe = getmetatable(object).components.allocation
    if not meta.is_nil(allocation) then
        meta.assert_isa(allocation_maybe, rt.AllocationComponent)
        return allocation_maybe:get_bounds():contains(x, y)
    else
        return true
    end
end

--- @brief handle mouse button press
--- @param x Number
--- @param y Number
--- @param dx Number
--- @param dy Number
--- @param is_touch Boolean
function rt.MouseHandler.handle_motion(x, y, dx, dy, is_touch)
    for _, component in pairs(rt.MouseHandler._components) do
        if not getmetatable(component._instance).is_focused then
            goto continue
        end

        local instance = component._instance
        local current = component._is_active
        local next = rt.MouseHandler.is_cursor_in_bounds(x, y, instance)

        if current == false and next == true then
            component._is_active = true
            component.signal:emit("motion_enter", x, y)
        end

        if next then
            component.signal:emit("motion", x, y, dx, dy)
        end

        if current == true and next == false then
            component._is_active = false
            component.signal:emit("motion_leave", x, y)
        end
        ::continue::
    end
end
love.mousemoved = rt.MouseHandler.handle_motion

--- @brief handle mouse button press
--- @param x Number
--- @param y Number
--- @param button_id MouseButton
--- @param is_touch Boolean
function rt.MouseHandler.handle_button_pressed(x, y, button_id, is_touch)
    for _, component in pairs(rt.MouseHandler._components) do
        if rt.MouseHandler.is_cursor_in_bounds(x, y, component._instance) and getmetatable(component._instance).is_focused == true then
            local out = component.signal:emit("button_pressed", x, y, button_id)
            if out == true then
                break
            end
        end
    end
end
love.mousepressed = rt.MouseHandler.handle_button_pressed

--- @brief handle mouse button release
--- @param x Number
--- @param y Number
--- @param button_id MouseButton
--- @param is_touch Boolean
function rt.MouseHandler.handle_button_released(x, y, button_id, is_touch)
    for _, component in pairs(rt.MouseHandler._components) do
        if rt.MouseHandler.is_cursor_in_bounds(x, y, component._instance) and getmetatable(component._instance).is_focused == true then
            local out = component.signal:emit("button_released", x, y, button_id)
            if out == true then
                break
            end
        end
    end
end
love.mousereleased = rt.MouseHandler.handle_button_released

--- @brief check whether a mouse button is pressed
--- @param button_id MouseButton
--- @return Boolean
function rt.MouseHandler.is_down(button_id)
    return love.mouse.isDown(button_id)
end

--- @brief get current cursor position
--- @return (Number, Number)
function rt.MouseHandler.get_position()
    return love.mouse.getX(), love.mouse.getY()
end

--- @brief move cursor to given position
--- @param x Number
--- @param y Number
function rt.MouseHandler.set_position(x, y)
    local current_x, current_y = rt.MouseHandler.get_position()
    love.mouse.setPosition(x, y)
    rt.MouseHandler.handle_motion(x, y, current_x - x, current_y - y, false)
end

--- @brief add an mouse component as `.mouse`
function rt.add_mouse_component(self)
    meta.assert_object(self)

    if not meta.is_nil(self.mouse) then
        error("[rt] In add_mouse_component: Object of type `" .. meta.typeof(self) .. "` already has a member called `mouse`")
    end

    meta._install_property(self, "mouse", rt.AllocationComponent(self))
    return rt.get_mouse_component(self)
end

--- @brief get mouse component assigned
--- @return rt.AllocationComponent
function rt.get_mouse_component(self)
    return self.mouse
end

--- @brief [internal] test mouse component
rt.test.mouse_component = function()
    local instance = meta._new("Object")
    instance.mouse = rt.MouseComponent(instance)

    local pressed_called = false
    instance.mouse.signal:connect("button_pressed", function(self, x, y, id)
        pressed_called = true
    end)
    rt.MouseHandler.handle_button_pressed(0, 0, rt.MouseButton.LEFT)

    local released_called = false
    instance.mouse.signal:connect("button_released", function(self, x, y, id)
        released_called = true
    end)
    rt.MouseHandler.handle_button_released(0, 0, rt.MouseButton.RIGHT)

    local motion_enter_called = false
    instance.mouse.signal:connect("motion_enter", function(self, x, y)
        motion_enter_called = true
    end)

    local motion_leave_called = false
    instance.mouse.signal:connect("motion_leave", function(self, x, y)
        motion_leave_called = true
    end)

    local motion_called = false
    instance.mouse.signal:connect("motion", function(self, x, y, dx, dy)
        motion_called = true
    end)
    rt.MouseHandler.handle_motion(0, 0, 0, 0, false)

    -- assert(pressed_called)
    -- assert(released_called)
    -- assert(motion_called)
    -- assert(motion_enter_called)
    -- assert(motion_leave_called)
end
rt.test.mouse_component()