require "include"

rt.current_scene = bt.Scene()
scene = rt.current_scene
scene:set_background("GRADIENT_DERIVATIVE")

local slot = mn.EquipSlot(bt.EquipType.WEAPON) --bt.Consumable("DEBUG_CONSUMABLE"))
slot:realize()
slot:fit_into(50, 50, 1000, 1000)

local item = mn.ListItem(bt.Move("DEBUG_MOVE"), 91)
item:realize()
item:fit_into(50, 50, rt.graphics.get_width() * 0.5, 100)

info = mn.EntityInfo(bt.Entity("GIRL"))
info:realize()
info:fit_into(50, 50, 100, 100)

--- ###

love.load = function()
    rt.current_scene:realize()
    love.resize()
    --scene:start_battle(bt.Battle("DEBUG_BATTLE"))
    --scene:transition(bt.SceneState.SIMULATION(scene))
    --scene._state_manager:start_turn()
end

rt.graphics.frame_duration = {
    past_frames = {},
    n_frames_saved = 144,
    max = 0
}
rt.settings.show_rulers = false
rt.settings.show_fps = true

love.draw = function()
    local before = love.timer.getTime()
    love.graphics.clear(0.8, 0.2, 0.8, 1)

    if rt.current_scene ~= nil then
        rt.current_scene:draw()
    end

    info:draw()

    if rt.settings.show_fps == true then
        local fps = love.timer.getFPS()
        local frame_usage = math.round(rt.graphics.frame_duration.max / (1 / fps) * 100)
        local label = tostring(fps) .. " (" .. string.rep("0", math.abs(3 - #tostring(frame_usage))) .. frame_usage .. "%)"
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(label, math.floor(rt.graphics.get_width() - love.graphics.getFont():getWidth(label) - 2 * margin), math.floor(0.5 * margin))
    end

    if rt.settings.show_rulers == true then
        love.graphics.setLineWidth(1)
        local intensity = 0.1
        love.graphics.setColor(intensity, intensity, intensity, 1)
        rt.graphics.set_blend_mode(rt.BlendMode.ADD)
        local x, y, width, height = 0, 0, rt.graphics.get_width(), rt.graphics.get_height()
        local m = 2 * rt.settings.margin_unit
        love.graphics.line(x + m, y, x + m, y + height)
        love.graphics.line(x + width - m, y, x + width - m, y + height)
        love.graphics.line(x, y + m, x + width, y + m)
        love.graphics.line(x, y + height - m, x + width, y + height - m)

        love.graphics.line(x, y + 0.5 * height, x + width, y + 0.5 * height)
        love.graphics.line(x + 0.5 * width, y, x + 0.5 * width, height)
        rt.graphics.set_blend_mode()
    end

    love.graphics.reset()
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

    item:fit_into(50, 50, rt.graphics.get_width() * 0.5, 100)
end

love.run = function()
    love.window.setMode(1920 / 1.5, 1080 / 1.5, {
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

        love.update(delta)

        if love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.reset()
            love.draw()
            love.graphics.present()

            frame_duration = frame_duration + love.timer.getTime() - before
        end

        -- store max duration of last number of frames
        if rt.graphics.frame_duration.n_frames_saved > 180 then
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

