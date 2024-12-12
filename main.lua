require "include"

profiler_active = false

state = rt.GameState()
state:set_loading_screen(rt.LoadingScreen.DEFAULT)
state:initialize_debug_state()

camera = state:get_camera()


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
    elseif which == rt.KeyboardKey.FIVE then
        state:set_current_scene(rt.LeakScene)
    elseif which == rt.KeyboardKey.ZERO then
        state:set_current_scene(nil)
    elseif which == rt.KeyboardKey.RETURN then
        profiler_active = not profiler_active
    elseif which == rt.KeyboardKey.ESCAPE then
    end

    if which == rt.KeyboardKey.SPACE then
        --camera:set_angle(rt.random.number(-math.pi, math.pi))
        --camera:set_scale(rt.random.number(1 / 4, 4))
        --camera:set_position(love.mouse.getPosition())
    elseif which == rt.KeyboardKey.B then
        --camera:shake(10 / 60)
    elseif which == rt.KeyboardKey.X then
        --camera:skip()
    end
end)

love.load = function()
    state:load()

    state:set_current_scene(bt.BattleScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())

    twinkle = rt.Twinkle()
    twinkle:realize()
    twinkle:fit_into(500, 500, 64, 64)
    twinkle:fit_into(0, 0, love.graphics.getDimensions())

end

love.update = function(delta)
    state:update(delta)

    twinkle:update(delta)
end

love.draw = function()
    state:draw()

    twinkle:draw()
end

love.resize = function(new_width, new_height)
    state:resize(new_width, new_height)
end

love.run = function()
    state:run()
end
