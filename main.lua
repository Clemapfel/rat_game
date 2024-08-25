require "include"

state = rt.GameState()
state:initialize_debug_state()

inventory_scene = mn.InventoryScene(state)
inventory_scene:realize()

option_scene = mn.OptionsScene(state)
option_scene:realize()

local which_scene = true

state:set_current_scene(option_scene)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)

end)

state:set_input_button_keyboard_key(rt.InputButton.UP, rt.KeyboardKey.A)

background = bt.Background.VORONOI_CRYSTALS()
background:realize()

love.load = function()
    background:realize()
    state:_load()

    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    background:update(delta)
    state:_update(delta)
end

love.draw = function()
    background:draw()
    state:_draw()

    if canvas ~= nil then
        love.graphics.draw(canvas)
    end
end

love.resize = function(new_width, new_height)
    background:fit_into(0, 0, state:get_resolution())
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
