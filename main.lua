require "include"

profiler_active = false

state = rt.GameState()
state:set_loading_screen(rt.LoadingScreen.DEFAULT)
state:initialize_debug_state()

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
        println(rt.profiler.report())
        background._implementation._shader:recompile()
    end

    if which == rt.KeyboardKey.SPACE then
        camera:set_angle(rt.random.number(-math.pi, math.pi))
        --camera:set_scale(rt.random.number(1 / 4, 4))
    end
end)

camera = rt.Camera()

love.load = function()
    state:_load()

    --[[
    -- pre load scenes
    for scene in range(
        mn.InventoryScene,
        mn.KeybindingScene,
        mn.OptionsScene,
        bt.BattleScene
    ) do
        state:set_current_scene(scene)
    end
    ]]--


    state:set_current_scene(bt.BattleScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    if profiler_active then
        rt.profiler.push("update")
    end

    state:_update(delta)
    camera:update(delta)
    camera:set_position(love.mouse.getPosition())

    if profiler_active then
        rt.profiler.pop("update")
    end
end

love.draw = function()
    if draw_state then
        if profiler_active then
            rt.profiler.push("draw")
        end

        camera:bind()
        state:_draw()
        camera:unbind()
        camera:draw()

        --[[
        if state._current_scene ~= nil and state._current_scene._animation_queue ~= nil then
            state._current_scene._animation_queue:draw()
        end
        ]]--

        if profiler_active then
            rt.profiler.pop("draw")
        end
    end
end

love.resize = function(new_width, new_height)
    state:_resize(new_width, new_height)
    camera:set_viewport(0, 0, new_width, new_height)
    camera:set_position(0.5 * new_width, 0.5 * new_height)
end

love.run = function()
    state:_run()
end
