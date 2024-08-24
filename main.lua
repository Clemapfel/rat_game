require "include"

state = rt.GameState()
state:initialize_debug_state()
scene = mn.InventoryScene(state)
scene = mn.OptionsScene(state)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
end)

input:signal_connect("keyboard_pressed_raw", function(_, raw, scancode)
    --dbg(raw, scancode)
end)

state:set_input_button_keyboard_key(rt.InputButton.UP, rt.KeyboardKey.A)

background = bt.Background.VORONOI_CRYSTALS()
background:realize()

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

    background:update(delta)
end

love.draw = function()
    background:draw()
    if scene ~= nil then
        scene:draw()
    end
end

love.resize = function()
    state._render_shape = rt.VertexRectangle(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    state._render_shape:set_texture(state._render_texture)

    local x, y, w, h = 0, 0, state:get_resolution()

    background:fit_into(x, y, w, h)
    if scene ~= nil then
        scene:fit_into(x, y, w, h)
    end

end

love.run = function()
    state:run()
end
