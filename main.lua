require "include"

state = rt.GameState()
state:initialize_debug_state()

inventory_scene = mn.InventoryScene(state)
option_scene = mn.OptionsScene(state)
keybinding_scene = mn.KeybindingScene(state)

state:set_keybinding(rt.InputButton.A, rt.KeyboardKey.NINE)

input = rt.InputController()
input:signal_connect("keyboard_pressed", function(_, which)
    if which == rt.KeyboardKey.ONE then
        state:set_current_scene(inventory_scene)
    elseif which == rt.KeyboardKey.TWO then
        state:set_current_scene(option_scene)
    elseif which == rt.KeyboardKey.THREE then
        state:set_current_scene(keybinding_scene)
    end
end)

love.load = function()
    state:_load()
    state:set_current_scene(keybinding_scene)
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