require "include"

local animation = rt.TimedAnimation(1, 0, 2, rt.InterpolationFunctions.LINEAR)
animation:signal_connect("done", function(self)
    dbg("done")
end)

state = rt.GameState()
state:set_loading_screen(rt.LoadingScreen.DEFAULT)
state:initialize_debug_state()

world = b2.World

local background = rt.Background()
background:set_implementation(rt.Background.TEMP_TRIANGLE_TILING)

label = rt.Label("Lorem ipsum dolor sit amet,\n consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
label:set_justify_mode(rt.JustifyMode.RIGHT)
label:realize()
label:fit_into(50, 50, 500)

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
    background:update(delta)
    state:_update(delta)
    --midi:update(delta)
end

love.draw = function()
    --background:draw()
    if draw_state then
        --state:_draw()
    end

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, rt.graphics.get_width(), rt.graphics.get_height())
    love.graphics.setColor(1, 1, 1, 1)
    label:draw()

    love.graphics.rectangle("line", 50, 50, 500, 10000)
end

love.resize = function(new_width, new_height)
    background:fit_into(0, 0, new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
