require "include"

state = rt.GameState()
state:initialize_debug_state()

world = b2.World

local background = rt.Background()
background:set_implementation(rt.Background.BUBBLEGUM)

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

component = rt.SoundComponent()
component:signal_connect("finished", function(_)
    println("done")
end)

input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
       component:play("test/alarm")
    elseif which == rt.InputButton.B then

    end
end)

angle = 0
radius = 100
local centerX, centerY

love.load = function()
    background:realize()
    state:_load()
    state:set_current_scene(mn.InventoryScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    background:update(delta)
    state:_update(delta)

    angle = math.fmod(angle + delta, 2 * math.pi)
end

love.draw = function()
    background:draw()
    if draw_state then
        state:_draw()
    end
end

love.resize = function(new_width, new_height)
    background:fit_into(0, 0, new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
