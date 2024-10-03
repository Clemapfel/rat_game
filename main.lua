require "include"

require "midi.midi"

state = rt.GameState()
state:initialize_debug_state()

world = b2.World

local background = rt.Background()
background:set_implementation(rt.Background.VECTOR_FIELD)

local draw_state = true
input = rt.InputController()
input:signal_connect("keyboard_pressed", function(_, which)
    if which == rt.KeyboardKey.ONE then
        state:set_current_scene(mn.InventoryScene)
    elseif which == rt.KeyboardKey.TWO then
        state:set_current_scene(mn.OptionsScene)
    elseif which == rt.KeyboardKey.THREE then
        state:set_current_scene(mn.KeybindingScene)
    elseif which == rt.KeyboardKey.FOUR then
        state:set_current_scene(bt.BattleScene)
    elseif which == rt.KeyboardKey.ESCAPE then
        rt.profiler.report()
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
        --component:play("test/alarm")
    elseif which == rt.InputButton.B then

    elseif which == rt.InputButton.DEBUG then
    end
end)

love.load = function()
    background:realize()
    state:_load()
    state:set_current_scene(bt.BattleScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    if love.keyboard.isDown("space") then
        background:update(delta)
    elseif love.keyboard.isDown("b") then
        background:update(-delta)
    end
    state:_update(delta)
end

love.draw = function()
    background:draw()
    if draw_state then
        --state:_draw()
    end
end

love.resize = function(new_width, new_height)
    background:fit_into(0, 0, new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
