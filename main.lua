require "include"

profiler_active = false

STATE = rt.GameState()
STATE:set_loading_screen(rt.LoadingScreen.DEFAULT)
STATE:initialize_debug_state()

camera = STATE:get_camera()

local draw_state = true
input = rt.InputController()
input:signal_connect("keyboard_pressed", function(_, which)
    if which == rt.KeyboardKey.ONE then
        STATE:set_current_scene(mn.InventoryScene)
    elseif which == rt.KeyboardKey.TWO then
        STATE:set_current_scene(mn.OptionsScene)
    elseif which == rt.KeyboardKey.THREE then
        STATE:set_current_scene(mn.KeybindingScene)
    elseif which == rt.KeyboardKey.FOUR then
        STATE:set_current_scene(bt.BattleScene)
    elseif which == rt.KeyboardKey.FIVE then
        STATE:set_current_scene(rt.LeakScene)
    elseif which == rt.KeyboardKey.ZERO then
        STATE:set_current_scene(nil)
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
    STATE:load()

    STATE:set_current_scene(mn.InventoryScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())

    twinkle = rt.Twinkle()
    twinkle:realize()
    twinkle:fit_into(500, 500, 64, 64)
    twinkle:fit_into(0, 0, love.graphics.getDimensions())
end

love.update = function(delta)
    STATE:update(delta)

    twinkle:update(delta)
end

love.draw = function()
    STATE:draw()

    twinkle:draw()
end

love.resize = function(new_width, new_height)
    STATE:resize(new_width, new_height)
end

love.run = function()
    STATE:run()
end
