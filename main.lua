require "include"

local animation = rt.TimedAnimation(1, 0, 2, rt.InterpolationFunctions.LINEAR)
animation:signal_connect("done", function(self)
    dbg("done")
end)

profiler_active = false

state = rt.GameState()
state:set_loading_screen(rt.LoadingScreen.DEFAULT)
state:initialize_debug_state()


world = b2.World

local background = rt.Background()

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
    elseif which == rt.KeyboardKey.RETURN then
        profiler_active = true
        dbg("activated profiler")
    elseif which == rt.KeyboardKey.ESCAPE then
        println(rt.profiler.report())
    end
end)

local offset = 1
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.UP then
        offset = offset + 0.5
        rt.Label.render_shader:send("shake_offset", offset)
    elseif which == rt.InputButton.DOWN then
        offset = offset - 0.5
        rt.Label.render_shader:send("shake_offset", offset)
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
    for scene in range(
        mn.InventoryScene,
        mn.KeybindingScene,
        mn.OptionsScene,
        bt.BattleScene
    ) do
        state:set_current_scene(scene)
    end
    --state:set_current_scene(bt.BattleScene)
    state:set_current_scene(nil)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    if profiler_active then
        rt.profiler.push("update")
    end

    state:_update(delta)

    if profiler_active then
        rt.profiler.pop("update")
    end
    --midi:update(delta)
end

love.draw = function()
    background:draw()
    if draw_state then
        if profiler_active then
            rt.profiler.push("draw")
        end

        state:_draw()

        if profiler_active then
            rt.profiler.pop("draw")
        end
    end
end

love.resize = function(new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
