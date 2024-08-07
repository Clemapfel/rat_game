require "include"

THREAD_ID = 0
require "common.rope_thread"

-- ###

threads = {}
n_threads = 32

ropes = {}
n_ropes = 10
rope_length = 400
rope_n_nodes = 16
n_iterations = 50
friction = 0.97

rope_shader = rt.Shader("common/rope_shader.glsl")

local active = false

love.load = function()
    for i = 1, n_threads do
        local thread = {
            main_to_worker = love.thread.newChannel(),
            worker_to_main = love.thread.newChannel(),
            native = love.thread.newThread("common/rope_thread.lua"),
            ropes = {},
            n_ropes = 0
        }

        thread.native:start(thread.main_to_worker, thread.worker_to_main)
        threads[i] = thread
    end

    local min_x, max_x, y = 100, rt.graphics.get_width() - 100, 200
    local current_x, current_y = min_x, y
    local step = (max_x - min_x) / n_ropes

    local gravity_x, gravity_y = 0, 100
    for i = 1, n_ropes do
        local rope = _new_rope(
            current_x,
            current_y,
            rope_length,
            rope_n_nodes,
            gravity_x,
            gravity_y
        )
        rope.id = i
        ropes[rope.id] = rope

        current_x = current_x + step
    end

    local n_pushed = n_ropes
    local thread_i, rope_i = 1, 1
    while rope_i <= n_ropes do
        local thread = threads[thread_i]
        table.insert(thread.ropes, ropes[rope_i])
        thread.n_ropes = thread.n_ropes + 1
        rope_i = rope_i + 1
        thread_i = (thread_i % n_threads) + 1
    end
end

love.update = function(delta)
    if love.keyboard.isDown("space") then active = true end
    if active ~= true then return end
    local mouse_x, mouse_y = love.mouse.getPosition()

    -- request
    for thread_i = 1, n_threads do
        local thread = threads[thread_i]
        for rope_i = 1, thread.n_ropes do
            local rope = thread.ropes[rope_i]
            thread.main_to_worker:push({
                id = rope.id,
                n_iterations = n_iterations,
                delta = delta,
                n_nodes = rope.n_nodes,
                node_distance = rope.node_distance,
                gravity_x = rope.gravity_x,
                gravity_y = rope.gravity_y,
                friction = friction,
                anchor_x = mouse_x, --rope.anchor_x,
                anchor_y = mouse_y, --rope.anchor_y,
                positions = rope.positions,
                old_positions = rope.old_positions
            })
        end
    end

    -- collect
    for thread_i = 1, n_threads do
        local thread = threads[thread_i]
        while thread.worker_to_main:getCount() > 0 do
            local message = thread.worker_to_main:pop()
            local rope = ropes[message.id]
            rope.positions = message.positions
            rope.old_positions = message.old_positions
        end
    end
end

-- ###

rt.settings.show_rulers = false
rt.settings.show_fps = true

local debug = {}
for i = 1, 16 do
    table.insert(debug, 50 + i / 16 * 600)
    table.insert(debug, 400)
end

love.draw = function()
    love.graphics.clear(0.3, 0, 0.3, 1)
    love.graphics.setLineWidth(50)

    local mesh = _positions_to_mesh(ropes[1].n_nodes, ropes[1].positions)
    love.graphics.draw(mesh)

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

love.run = function()
    love.window.setMode(1280, 720, {
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