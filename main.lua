require "include"

state = rt.GameState()
state:initialize_debug_state()

local background = rt.Background()
background:set_implementation(rt.Background.BUBBLEGUM)

local loading_screen = rt.LoadingScreen()
loading_screen:realize()

local draw_state = true
input = rt.InputController()
input:signal_connect("keyboard_pressed", function(_, which)
    if which == rt.KeyboardKey.ONE then
        state:set_current_scene(mn.InventoryScene)
    elseif which == rt.KeyboardKey.TWO then
        state:set_current_scene(mn.OptionsScene)
    elseif which == rt.KeyboardKey.THREE then
        state:set_current_scene(mn.KeybindingScene)
    elseif which == rt.KeyboardKey.ESCAPE then
        background._shader:recompile()
    end
end)

input:signal_connect("keyboard_released", function(_, which)
    if which == rt.KeyboardKey.ESCAPE then
        draw_state = true
    end
end)


input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        loading_screen:show()
        --rt.SoundAtlas:play("test/alarm")
    elseif which == rt.InputButton.B then
        loading_screen:hide()
    end
end)

love.load = function()
    background:realize()
    state:_load()
    state:set_current_scene(mn.InventoryScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    background:update(delta)
    loading_screen:update(delta)
    state:_update(delta)
end

love.draw = function()
    background:draw()
    if draw_state then
        --state:_draw()
    end

    loading_screen:draw()
end

love.resize = function(new_width, new_height)
    background:fit_into(0, 0, new_width, new_height)
    loading_screen:fit_into(0, 0, new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end