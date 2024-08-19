require "include"

state = rt.GameState()
state:initialize_debug_state()
--scene = mn.InventoryScene(state)
scene = mn.OptionsScene(state)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    dbg(which)
end)

input:signal_connect("keyboard_pressed_raw", function(_, raw, scancode)
    --dbg(raw, scancode)
end)

state:set_input_button_keyboard_key(rt.InputButton.UP, rt.KeyboardKey.A)

love.load = function()
    if scene ~= nil then
        scene:realize()
        scene:create_from_state(state)
        love.resize()
    end
end

love.update = function(delta)
    if scene ~= nil then
        scene:update(delta)
    end
end

love.draw = function()
    if scene ~= nil then
        scene:draw()
    end

end

love.resize = function()
    local x, y, w, h = 0, 0, rt.graphics.get_width(), rt.graphics.get_height()
    if scene ~= nil then
        scene:fit_into(x, y, w, h)
    end
end

love.run = function()
    state:run()
end
