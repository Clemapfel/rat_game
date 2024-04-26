require "include"


rt.prettyprint(
    {
        "nevermind ",
        bold = true,
        color = "red"
    },

    {
        "this",
        underline = true,
        italic = true
    },

    " ",

    {
        "took like 10mins",
        reverse = true,
        color = "yellow"
    },

    "\n"
)

love.load = function()
    profiler.activate()

    rt.current_scene = bt.BattleScene()
    local scene = rt.current_scene

    local to_synch_with = {}
    local move = bt.Move("TEST_MOVE")

    -- TODO move this to update
    input = rt.InputController()
    input:signal_connect("pressed", function(self, which)
        if which == rt.InputButton.A then
            local entities = scene._state:list_entities()
            scene:use_move(entities[1], move, entities[2])
        elseif which == rt.InputButton.B then
            --scene:remove_status(scene._state:list_entities()[1], bt.Status("DEBUG_STATUS"))
            --scene:help_up(scene._state:list_entities()[1])
            scene:skip_animation()
        elseif which == rt.InputButton.X then
            scene:kill(scene._state:list_entities()[1])
        end
    end)

    rt.current_scene:realize()
    rt.current_scene:start_battle(bt.BattleConfig("TEST_BATTLE"))
end

rt.graphics.frame_duration = {
    past_frames = {},
    n_frames_saved = 144,
    max = 0
}

love.draw = function()
    local before = love.timer.getTime()
    love.graphics.clear(0.8, 0.2, 0.8, 1)

    rt.current_scene:draw()
    do -- show fps and frame usage
        local fps = love.timer.getFPS()
        local frame_usage = math.round(rt.graphics.frame_duration.max / (1 / fps) * 100)
        local label = tostring(fps) .. " (" .. string.rep("0", math.abs(3 - #tostring(frame_usage))) .. frame_usage .. "%)"
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(label, rt.graphics.get_width() - love.graphics.getFont():getWidth(label) - 2 * margin, 0.5 * margin)
    end
end

love.update = function(delta)
    rt.AnimationHandler:update(delta)
    rt.current_scene:update(delta)
end

love.resize = function()
    rt.current_scene:size_allocate(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

love.quit = function()
    if profiler.get_is_active() then
        profiler.deactivate()
    end
end

love.run = function()
    love.window.setMode(1600 / 1.5, 900 / 1.5, {
        vsync = -1, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = 8,
        stencil = true,
        resizable = true,
        borderless = false
    })
    love.window.setTitle("rat_game")
    love.filesystem.setIdentity("rat_game")

    if love.load then love.load() end
    love.timer.step()

    local delta = 0
    while true do
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        love.timer.step()
        delta = love.timer.getDelta()

        local frame_duration = 0
        local before = love.timer.getTime()

        if love.update then love.update(delta) end
        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.reset()

            if love.draw then love.draw() end
            frame_duration = frame_duration + love.timer.getTime() - before

            love.graphics.present()
        end

        -- store max duration of last number of frames
        if rt.graphics.frame_duration.n_frames_saved > 144 * 2 then
            local to_remove = rt.graphics.frame_duration.past_frames[1]
            table.remove(rt.graphics.frame_duration.past_frames, 1)
            rt.graphics.frame_duration.n_frames_saved = rt.graphics.frame_duration.n_frames_saved - 1

            if to_remove == rt.graphics.frame_duration.max then
                local max = 0
                for _, v in _G._pairs(rt.graphics.frame_duration.past_frames) do
                    max = math.max(max, v)
                end
                rt.graphics.frame_duration.max = max
            end
        end
        table.insert(rt.graphics.frame_duration.past_frames, frame_duration)
        rt.graphics.frame_duration.n_frames_saved = rt.graphics.frame_duration.n_frames_saved + 1
        rt.graphics.frame_duration.max = math.max(rt.graphics.frame_duration.max, frame_duration)

        -- force gc
        collectgarbage("collect")

        if love.timer then love.timer.sleep(0.001) end -- limit max tick rate of while true
    end
end
