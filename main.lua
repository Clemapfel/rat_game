require "include"

state = rt.GameState()
state:initialize_debug_state()

inventory_scene = mn.InventoryScene(state)
option_scene = mn.OptionsScene(state)

which_scene = true

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.L then
        which_scene = not which_scene
        if which_scene then
            state:set_current_scene(inventory_scene)
        else
            state:set_current_scene(option_scene)
        end
    end
end)

love.load = function()
    state:_load()
    state:set_current_scene(inventory_scene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    state:_update(delta)
end

love.draw = function()
    state:_draw()
end

love.resize = function(new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
