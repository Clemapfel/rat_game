require "include"

profiler_active = false

STATE = rt.GameState()
STATE:set_loading_screen(rt.LoadingScreen.DEFAULT)
STATE:initialize_debug_state()

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
        STATE:set_current_scene(mn.ObjectGetScene)
    elseif which == rt.KeyboardKey.ZERO then
        STATE:set_current_scene(nil)
    elseif which == rt.KeyboardKey.RETURN then
        profiler_active = not profiler_active
    elseif which == rt.KeyboardKey.ESCAPE then
    end
end)

love.load = function()
    STATE:load()
    STATE:set_current_scene(mn.ObjectGetScene)--mn.InventoryScene)
    STATE:resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    STATE:update(delta)
end

love.draw = function()
    STATE:draw()
end

love.resize = function(new_width, new_height)
    STATE:resize(new_width, new_height)
end

love.run = function()
    STATE:run()
end