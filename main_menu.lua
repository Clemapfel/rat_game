require "include"

rt.current_scene = mn.Scene()
scene = rt.current_scene

state = mn.InventoryState()
for move_id in range(
    "DEBUG_MOVE",
    "INSPECT",
    "PROTECT",
    "STRUGGLE",
    "SURF",
    "WISH"
) do
    state.shared_moves[bt.Move(move_id)] = rt.random.integer(1, 5)
end

for equip_id in range(
    "DEBUG_EQUIP",
    "DEBUG_CLOTHING",
    "DEBUG_FEMALE_CLOTHING",
    "DEBUG_MALE_CLOTHING",
    "DEBUG_WEAPON",
    "DEBUG_TRINKET"
) do
    state.shared_equips[bt.Equip(equip_id)] = rt.random.integer(1, 5)
end

for consumable_id in range(
    "DEBUG_CONSUMABLE",
    "ONE_CHERRY",
    "TWO_CHERRY"
) do
    state.shared_consumables[bt.Consumable(consumable_id)] = rt.random.integer(1, 5)
end

local entities = {bt.Entity("MC"), bt.Entity("RAT"), bt.Entity("PROF"), bt.Entity("GIRL")}

for entity in values(entities) do
    local to_insert = entity
    for move in range(
        "DEBUG_MOVE",
        "INSPECT",
        "PROTECT",
        "STRUGGLE",
        "SURF",
        "WISH"
    ) do
        entity:add_move(bt.Move(move))
    end

    entity:add_consumable(bt.Consumable("DEBUG_CONSUMABLE"))
    entity:add_equip(bt.Equip("DEBUG_EQUIP"))

    table.insert(state.entities, entity)
end

--- ###

love.load = function()
    scene._state = state
    rt.current_scene:realize()
    love.resize()
end

rt.settings.show_rulers = false
rt.settings.show_fps = true

love.draw = function()
    if rt.current_scene ~= nil then
        rt.current_scene:draw()
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
    love.window.setMode(1600, 900, {
        vsync = -1, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = 8,
        stencil = true,
        resizable = true,
        borderless = false
    })
    love.window.setTitle("rat_game")
    love.filesystem.setIdentity("rat_game")

    local major, minor = love.getVersion()
    println("Love2D " .. major .. "." .. minor .. " | " .. jit.version)

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

        if rt.graphics.frame_duration == nil then
            rt.graphics.frame_duration = {
                n_frames = 0,
                last_fps = love.timer.getFPS(),

                max_update_duration = 0,
                max_draw_duration = 0,
                max_total_duration = 0,

                update_durations = {},
                draw_durations = {},
                total_durations = {},

                format = function(str)
                    while #str < 3 do
                        str = "0" .. str
                    end
                    return str
                end
            }
        end

        local durations = rt.graphics.frame_duration
        local update_duration = 0
        local draw_duration = 0
        local total_duration = 0

        local update_before = love.timer.getTime()
        love.update(delta)
        update_duration = love.timer.getTime() - update_before

        local background_color = rt.Palette.TRUE_MAGENTA
        if love.graphics.isActive() then
            love.graphics.clear(true, true, true)
            rt.graphics.reset()
            love.graphics.setColor(background_color.r, background_color.g, background_color.b, 1)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

            local draw_before = love.timer.getTime()
            love.draw()
            local now =  love.timer.getTime()
            draw_duration = now - draw_before
            total_duration = now - update_before

            if rt.settings.show_fps == true then
                local fps = love.timer.getFPS()
                local frame_duration = 1 / fps
                local update_percentage = tostring(math.floor(durations.max_update_duration / frame_duration * 100))
                local draw_percentage = tostring(math.floor(durations.max_draw_duration / frame_duration * 100))
                local total_percentage = tostring(math.floor(durations.max_total_duration / frame_duration * 100))

                local label = tostring(fps) .. " | " .. durations.format(update_percentage) .. "% | " ..  durations.format(draw_percentage) .. "% | " ..  durations.format(total_percentage) .. "%"
                love.graphics.setColor(1, 1, 1, 0.75)
                local margin = 3
                love.graphics.print(label, math.floor(rt.graphics.get_width() - love.graphics.getFont():getWidth(label) - 2 * margin), math.floor(0.5 * margin))
            end

            love.graphics.present()
        end

        durations.n_frames = durations.n_frames + 1
        if durations.n_frames > 90 and rt.settings.show_fps == true then
            table.insert(durations.update_durations, update_duration)
            table.insert(durations.draw_durations, draw_duration)
            table.insert(durations.total_durations, total_duration)

            local update_update = durations.update_durations[1] == durations.max_update_duration
            local update_draw = durations.draw_durations[1] == durations.max_draw_duration
            local update_total = durations.total_durations[1] == durations.max_total_duration

            durations.n_frames = durations.n_frames - 1
            table.remove(durations.update_durations, 1)
            table.remove(durations.draw_durations, 1)
            table.remove(durations.total_durations, 1)

            -- only recompute new max duration if necessary
            if update_update then durations.max_update_duration = 0 end
            if update_draw then durations.max_draw_duration = 0 end
            if update_total then durations.max_total_duration = 0 end

            for i = 1, durations.n_frames do
                if update_update then
                    durations.max_update_duration = math.max(durations.max_update_duration, durations.update_durations[i])
                end

                if update_draw then
                    durations.max_draw_duration = math.max(durations.max_draw_duration, durations.draw_durations[i])
                end

                if update_total then
                    durations.max_total_duration = math.max(durations.max_total_duration, durations.total_durations[i])
                end
            end
        else
            table.insert(durations.update_durations, update_duration)
            table.insert(durations.draw_durations, draw_duration)
            table.insert(durations.total_durations, total_duration)

            durations.max_update_duration = math.max(durations.max_update_duration, update_duration)
            durations.max_draw_duration = math.max(durations.max_draw_duration, draw_duration)
            durations.max_total_duration = math.max(durations.max_total_duration, total_duration)
        end

        collectgarbage("collect") -- force gc

        if love.timer then love.timer.sleep(0.001) end -- limit max tick rate of while true
    end
end

