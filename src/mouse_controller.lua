--- @brief singleton, handles mouse input
rt.MouseHandler = {}

--- @class rt.MouseButton
rt.MouseButton = meta.new_enum({
    LEFT = 1,
    MIDDLE = 2,
    RIGHT = 3
})

rt.MouseHandler._hash = 1
rt.MouseHandler._components = {}
meta.make_weak(rt.MouseHandler._components, false, true)

--- @class rt.MouseController
--- @param instance meta.Object
rt.MouseController = meta.new_type("MouseController", function(instance)
    meta.assert_object(instance)
    local hash = rt.MouseHandler._hash
    rt.MouseHandler._hash = rt.MouseHandler._hash + 1

    if meta.is_nil(instance.get_bounds) then
        error("[rt][ERROR] In MouseCompoent: instance of type `" .. instance .. "` does not have a `get_bounds` function")
    end

    local out = meta.new(rt.MouseController, {
        instance = instance,
        _hash = hash,
        _active = false
    }, rt.SignalEmitter)

    out:signal_add("button_pressed")
    out:signal_add("button_released")
    out:signal_add("motion_enter")
    out:signal_add("motion")
    out:signal_add("motion_leave")

    rt.MouseHandler._components[hash] = out
    return out
end)

--- @brief check if cursor is over holder
--- @param x Number
--- @param y Number
function rt.MouseController:is_cursor_in_bounds(x, y)
    meta.assert_isa(self, rt.MouseController)
    meta.assert_number(x, y)
    return self.instance:get_bounds():contains(x, y)
end

--- @brief handle mouse button press
--- @param x Number
--- @param y Number
--- @param button_id MouseButton
--- @param is_touch Boolean
function rt.MouseHandler.handle_button_pressed(x, y, button_id, is_touch)
    for _, component in pairs(rt.MouseHandler._components) do
        if component:is_cursor_in_bounds(x, y) then
            component:signal_emit("button_pressed", x, y, button_id)
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
        if component:is_cursor_in_bounds(x, y) then
            component:signal_emit("button_released", x, y, button_id)
        end
    end
end
love.mousereleased = rt.MouseHandler.handle_button_released

--- @brief handle mouse button press
--- @param x Number
--- @param y Number
--- @param dx Number
--- @param dy Number
--- @param is_touch Boolean
function rt.MouseHandler.handle_motion(x, y, dx, dy, is_touch)
    for _, component in pairs(rt.MouseHandler._components) do
        local instance = component.instance
        local current = component._is_active
        local next = component:is_cursor_in_bounds(x, y)

        if current == false and next == true then
            component._is_active = true
            component:signal_emit("motion_enter", x, y)
        end

        if next then
            component:signal_emit("motion", x, y, dx, dy)
        end

        if current == true and next == false then
            component._is_active = false
            component:signal_emit("motion_leave", x, y)
        end
    end
end
love.mousemoved = rt.MouseHandler.handle_motion

--- @brief add an mouse component
--- @param target meta.Object
--- @return rt.MouseComponent
function rt.add_mouse_controller(target)
    meta.assert_object(target)
    getmetatable(target).components.mouse = rt.MouseController(target)
    return getmetatable(target).components.mouse
end

--- @brief
function rt.get_mouse_controller(target)
    meta.assert_object(target)
    local components = getmetatable(target).components
    if meta.is_nil(components) then
        return nil
    end
    return components.mouse
end

--- @brief
function rt.test.test_mouse_controller()
    -- TODO
end

