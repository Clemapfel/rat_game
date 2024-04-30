require "include"
textbox = rt.TextBox()
rt.current_scene = textbox

input_controller = rt.InputController()
input_controller:signal_connect("pressed", function(self, which)
    if which == rt.InputButton.A then
        local text = ""
        for i = 1, rt.random.number(10, 20) do
            text = text .. rt.random.string(rt.random.number(2, 4))
            if rt.random.toss_coin(0.5) then
                text = text .. "\n"
            end
        end
        textbox:append("<b>" .. text .. "</b>")
    elseif which == rt.InputButton.UP then
        local current = textbox:get_first_visible_line()
        textbox:set_first_visible_line(current - 1)
    elseif which == rt.InputButton.DOWN then
        local current = textbox:get_first_visible_line()
        textbox:set_first_visible_line(current + 1)
    elseif which == rt.InputButton.RIGHT then
        local current = textbox:get_n_visible_lines()
        textbox:set_n_visible_lines(current + 1)
    elseif which == rt.InputButton.LEFT then
        local current = textbox:get_n_visible_lines()
        textbox:set_n_visible_lines(current - 1)
    end
end)

--- ###

love.load = function()
    rt.current_scene:realize()
    love.resize()
end

rt.graphics.frame_duration = {
    past_frames = {},
    n_frames_saved = 144,
    max = 0
}

love.draw = function()
    local before = love.timer.getTime()
    love.graphics.clear(0.8, 0.2, 0.8, 1)

    if rt.current_scene ~= nil then
        rt.current_scene:draw()
    end

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
    if rt.current_scene ~= nil and rt.current_scene.update ~= nil then
        rt.current_scene:update(delta)
    end
end

love.resize = function()
    if rt.current_scene ~= nil then
        rt.current_scene:fit_into(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
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

