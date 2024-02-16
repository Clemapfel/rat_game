--- @brief singleton, handles mouse input
rt.MouseHandler = {}

--- @class rt.MouseButton
rt.MouseButton = meta.new_enum({
    LEFT = 1,
    MIDDLE = 2,
    RIGHT = 3,
    TOUCH = 4
})

rt.MouseHandler._components = {}
meta.make_weak(rt.MouseHandler._components, false, true)

--- @class rt.MouseController
--- @signal click_pressed  (self, x, y, rt.ButtonID, n_presses) -> nil
--- @signal click_released (self, x, y, rt.ButtonID, n_presses) -> nil
--- @signal motion_enter    (self, x, y) -> nil 
--- @signal motion          (self, x, y, dx, dy) -> nil
--- @signal motion_leave    (self, x, y) -> nil
rt.MouseController = meta.new_type("MouseController", rt.SignalEmitter, function(instance)
    local out = meta.new(rt.MouseController, {
        instance = instance,
        _active = false
    })

    out:signal_add("click_pressed")
    out:signal_add("click_released")
    out:signal_add("motion_enter")
    out:signal_add("motion")
    out:signal_add("motion_leave")

    rt.MouseHandler._components[meta.hash(out)] = out
    return out
end)

--- @brief check if cursor is over holder
--- @param x Number
--- @param y Number
function rt.MouseController:is_cursor_in_bounds(x, y)
    local bounds = self.instance:get_bounds()
    return x >= bounds.x and x <= bounds.x + bounds.width and y >= bounds.y and y <= bounds.y + bounds.height
end

--- @brief handle mouse button press
--- @param x Number
--- @param y Number
--- @param button_id rt.MouseButton
--- @param is_touch Boolean
function rt.MouseHandler.handle_click_pressed(x, y, button_id, is_touch, n_presses)
    for _, component in pairs(rt.MouseHandler._components) do
        component:signal_emit("click_pressed", x, y, ternary(is_touch, rt.MouseButton.TOUCH, button_id), n_presses)
    end
end
love.mousepressed = rt.MouseHandler.handle_click_pressed

--- @brief handle mouse button release
--- @param x Number
--- @param y Number
--- @param button_id rt.MouseButton
--- @param is_touch Boolean
function rt.MouseHandler.handle_click_released(x, y, button_id, is_touch, n_presses)
    for _, component in pairs(rt.MouseHandler._components) do
        component:signal_emit("click_released", x, y, ternary(is_touch, rt.MouseButton.TOUCH, button_id), n_presses)
    end
end
love.mousereleased = rt.MouseHandler.handle_click_released

--- @brief handle mouse button press
--- @param x Number
--- @param y Number
--- @param dx Number
--- @param dy Number
--- @param is_touch Boolean
function rt.MouseHandler.handle_motion(x, y, dx, dy, is_touch)

    local check_enter_or_leave = function()
        local window_w, window_h = love.window.getMode()
        if x + dx < 0 then
            println("exit left")
        end
        if y + dy < 0 then
            println("exit top")
        end

        if x + dx > window_w then
            println("exit right")
        end
        if y + dy > window_h then
            println("exit bottom")
        end
    end

    for _, component in pairs(rt.MouseHandler._components) do
        local instance = component.instance
        local current = component._active
        local next = component:is_cursor_in_bounds(x, y)
        
        if current == false and next == true then
            component._active = true
            component:signal_emit("motion_enter", x, y)
        end

        if next then
            component:signal_emit("motion", x, y, dx, dy)
        end

        if current == true and next == false then
            component._active = false
            component:signal_emit("motion_leave", x, y)
        end
    end
end
love.mousemoved = rt.MouseHandler.handle_motion

--- @brief get absolute cursor position
--- @return Number, Number
function rt.MouseController:get_cursor_position()

    return love.mouse.getPosition()
end

--- @brief add an mouse component
--- @param target meta.Object
--- @return rt.MouseController
function rt.add_mouse_controller(target)

    getmetatable(target).components.mouse = rt.MouseController(target)
    return getmetatable(target).components.mouse
end

--- @brief
function rt.get_mouse_controller(target)

    local components = getmetatable(target).components
    if meta.is_nil(components) then
        return nil
    end
    return components.mouse
end

--- @brief
function rt.test.test_mouse_controller()
    error("TODO")
end

