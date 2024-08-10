rt.VSyncMode = {
    ADAPTIVE = -1,
    OFF = 0,
    ON = 1
}

rt.MSAAQuality = {
    OFF = 0,
    GOOD = 2,
    BETTER = 4,
    BEST = 8,
    MAX = 16
}

--- @class rt.GameState
rt.GameState = meta.new_type("GameState", function()
    local state = {
        -- graphics settings
        config = {
            vsync = rt.VSyncMode.ADAPTIVE,
            msaa = rt.MSAAQuality.BEST,
            resolution_x = 1280,
            resolution_y = 720,
            show_fps = true
        },

        -- keybindings
        input_mapping = (function()
            local out = {}
            for key in values(meta.instances(rt.InputButton)) do
                out[key] = {}
            end
            return out
        end)(),
    }

    local out = meta.new(rt.GameState, {
        _state = state
    })

    out:load_input_mapping()
    return out
end)

--- @brief
function rt.GameState:load_input_mapping()
    local file = rt.settings.input_controller.keybindings_path
    local chunk, error_maybe = love.filesystem.load(file)
    if error_maybe ~= nil then
        rt.error("In rt.GameState.load_input_mapping: Unable to load file at " .. love.filesystem.getSourceBaseDirectory() .. "/" .. file .. "`: " .. error_maybe)
        rt.warning("Custom keybindings not available, loaded default keybindings instead")
        self._state.input_mapping =  {
            A = {
                rt.GamepadButton.RIGHT,
                rt.KeyboardKey.SPACE
            },

            B = {
                rt.GamepadButton.BOTTOM,
                rt.KeyboardKey.B
            },

            X = {
                rt.GamepadButton.TOP,
                rt.KeyboardKey.X,
            },

            Y = {
                rt.GamepadButton.LEFT,
                rt.KeyboardKey.Y
            },

            L = {
                rt.GamepadButton.LEFT_SHOULDER,
                rt.KeyboardKey.L
            },

            R = {
                rt.GamepadButton.RIGHT_SHOULDER,
                rt.KeyboardKey.R
            },

            START = {
                rt.GamepadButton.START,
                rt.KeyboardKey.M
            },

            SELECT = {
                rt.GamepadButton.SELECT,
                rt.KeyboardKey.N
            },

            UP = {
                rt.GamepadButton.DPAD_UP,
                rt.KeyboardKey.ARROW_UP,
                rt.KeyboardKey.W
            },

            RIGHT = {
                rt.GamepadButton.DPAD_RIGHT,
                rt.KeyboardKey.ARROW_RIGHT,
                rt.KeyboardKey.D
            },

            DOWN = {
                rt.GamepadButton.DPAD_DOWN,
                rt.KeyboardKey.ARROW_DOWN,
                rt.KeyboardKey.S
            },

            LEFT = {
                rt.GamepadButton.DPAD_LEFT,
                rt.KeyboardKey.ARROW_LEFT,
                rt.KeyboardKey.A
            },

            DEBUG = {
                rt.KeyboardKey.ESCAPE
            }
        }

        rt.InputControllerState.load_from_state(self)
        return
    end

    local state = self._state

    local mapping = chunk()
    local valid_keys = {}
    local reverse_mapping_count = {}
    for key in values(meta.instances(rt.InputButton)) do
        valid_keys[key] = 0
        state.input_mapping[key] = {}
    end

    for key, value in pairs(mapping) do
        if valid_keys[key] == nil then
            rt.error("In rt.GameState.load_input_mapping: encountered unexpected key `" .. key .. "`")
        else
            if meta.is_table(value) then
                for mapped in values(value) do
                    table.insert(state.input_mapping[key], mapped)
                    if reverse_mapping_count[mapped] == nil then
                        reverse_mapping_count[mapped] = {key}
                    else
                        table.insert(reverse_mapping_count[mapped], key)
                    end
                end
            else
                local mapped = value
                table.insert(state.input_mapping[key], mapped)
                if reverse_mapping_count[mapped] == nil then
                    reverse_mapping_count[mapped] = {key}
                else
                    table.insert(reverse_mapping_count[mapped], key)
                end
            end

            valid_keys[key] = valid_keys[key] + 1
        end
    end

    for key, count in pairs(valid_keys) do
        if count == 0 then
            rt.error("In rt.GameState.load_input_mapping: Key `" .. key .. "` does not have any keys or buttons assigned to it")
        end
    end

    for key, assigned in pairs(reverse_mapping_count) do
        if sizeof(assigned) > 1 then
            local error = "In rt.GameState.load_input_mapping: Constant `" .. key .. "` is assigned to multiple keys: "
            for k in values(assigned) do
                error = error .. k .. " "
            end
            rt.error(error)
        end
    end

    rt.InputControllerState.load_from_state(self)
    rt.log("Succesfully loaded input mapping from `" .. file .. "`")
end

--- @brief
function rt.GameState:get_input_mapping()
    return self._state.input_mapping
end

function rt.GameState:run()
    love.window.setMode(self._state.config.resolution_x, self._state.config.resolution_y, {
        vsync = self._state.config.vsync, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = self._state.config.msaa,
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

            if self._state.config.show_fps == true then
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
        if durations.n_frames > 90 and self._state.config.show_fps == true then
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