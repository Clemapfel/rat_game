require "include"

rt.current_scene = bt.Scene()
scene = rt.current_scene


--[[
add_consumable
remove_consumable
set_consumable_n_leftg
activate_consumable
]]--

battle = bt.Battle("DEBUG_BATTLE")
scene:set_background("DOT_MATRIX")
--scene:set_music("assets/music/test_music_04.mp3")

local to_spawn = {
    id = "WALKING_SPROUT",
    status = {
        "DEBUG_STATUS"
    },
    consumables = {
        "DEBUG_CONSUMABLE"
    },
    equips = {
        "DEBUG_EQUIP"
    },
    moveset = {
        "DEBUG_MOVE",
        "INSPECT",
        "PROTECT",
        "STRUGGLE",
        "SURF",
        "WISH"
    }
}

local verbose_info = bt.VerboseInfo()
verbose_info:realize()
verbose_info:fit_into(50, 50, rt.graphics.get_width() - 50, rt.graphics.get_height() - 50)

input_controller = rt.InputController()
input_controller:signal_connect("pressed", function(self, which)
    if which == rt.InputButton.A then
        verbose_info:show(rt.random.choose(scene._state.entities[1]:list_moves()))
    elseif which == rt.InputButton.B then
        scene:skip()
    elseif which == rt.InputButton.X then
        scene:remove_global_status(bt.GlobalStatus("DEBUG_GLOBAL_STATUS"))
    elseif which == rt.InputButton.Y then
        scene:remove_status(battle.entities[1], bt.Status("DEBUG_STATUS"))
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.R then
        scene:set_fast_forward_active(true)
    elseif which == rt.InputButton.UP then
        scene._selection_handler:move_up()
    elseif which == rt.InputButton.RIGHT then
        scene._selection_handler:move_right()
    elseif which == rt.InputButton.DOWN then
        scene._selection_handler:move_down()
    elseif which == rt.InputButton.LEFT then
        scene._selection_handler:move_left()
    elseif which == rt.InputButton.DEBUG then
        love.event.quit()
    end
end)

input_controller:signal_connect("released", function(self, which)
    if which == rt.InputButton.R then
        scene:set_fast_forward_active(false)
    end
end)

--- ###

love.load = function()
    rt.current_scene:realize()
    love.resize()
    scene:start_battle(battle)
    scene:add_global_status(bt.GlobalStatus("DEBUG_GLOBAL_STATUS"))
    --scene:kill(battle.entities[1])
    --scene:kill(battle.entities[2])
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

    verbose_info:draw()

    do -- show fps and frame usage
        local fps = love.timer.getFPS()
        local frame_usage = math.round(rt.graphics.frame_duration.max / (1 / fps) * 100)
        local label = tostring(fps) .. " (" .. string.rep("0", math.abs(3 - #tostring(frame_usage))) .. frame_usage .. "%)"
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(label, rt.graphics.get_width() - love.graphics.getFont():getWidth(label) - 2 * margin, 0.5 * margin)
    end

    do -- show rulers
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

        if love.update ~= nil then
            love.update(delta)
        end

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

