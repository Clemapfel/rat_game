rt.settings.game_state = {
    lower_gamma_bound = 0.4,
    upper_gamma_bound = 2.2 + 0.5
}

rt.settings.contrast = 1.0
rt.settings.motion_intensity = 1.0
rt.settings.music_level = 1.0
rt.settings.sfx_level = 1.0

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
        -- system settings
        vsync_mode = rt.VSyncMode.ADAPTIVE,
        msaa_quality = rt.MSAAQuality.BEST,
        gamma = 1,
        is_fullscreen = false,
        resolution_x = 1280,
        resolution_y = 720,
        sfx_level = 1,
        music_level = 1,
        vfx_motion_level = 1,
        vfx_contrast_level = 1,
        show_diagnostics = true,

        -- keybindings
        input_mapping = (function()
            local out = {}
            for key in values(meta.instances(rt.InputButton)) do
                out[key] = {}
            end
            return out
        end)(),

        -- battle
        n_enemies = 0,
        n_allies = 0,
        entity_id_to_multiplicity = {},
        entity_id_to_index = {},
        entities = {},

        shared_moves = {},
        shared_equips = {},
        shared_consumables = {},

        template_id_counter = 0,
        templates = {}
    }

    local out = meta.new(rt.GameState, {
        _state = state,
        _entity_index_to_entity = {},   -- Table<Number, bt.Entity>
        _entity_to_entity_index = {},   -- Table<bt.Entity, Number>
        _grabbed_object = nil, -- helper for mn.InventoryScene
        _render_shape = rt.VertexRectangle(0, 0, 1, 1),
        _render_texture = rt.RenderTexture(1, 1),
        _render_shader = rt.Shader("common/game_state_render_shader.glsl"),

        _current_scene = nil,
        _active_coroutines = {} -- Table<rt.Coroutine>
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
                gamepad = rt.GamepadButton.RIGHT,
                keyboard = rt.KeyboardKey.SPACE
            },

            B = {
                gamepad = rt.GamepadButton.BOTTOM,
                keyboard = rt.KeyboardKey.B
            },

            X = {
                gamepad = rt.GamepadButton.TOP,
                keyboard = rt.KeyboardKey.X,
            },

            Y = {
                gamepad = rt.GamepadButton.LEFT,
                keyboard = rt.KeyboardKey.Y
            },

            L = {
                gamepad = rt.GamepadButton.LEFT_SHOULDER,
                keyboard = rt.KeyboardKey.L
            },

            R = {
                gamepad = rt.GamepadButton.RIGHT_SHOULDER,
                keyboard = rt.KeyboardKey.R
            },

            START = {
                gamepad = rt.GamepadButton.START,
                keyboard = rt.KeyboardKey.M
            },

            SELECT = {
                gamepad = rt.GamepadButton.SELECT,
                keyboard = rt.KeyboardKey.N
            },

            UP = {
                gamepad = rt.GamepadButton.DPAD_UP,
                keyboard = rt.KeyboardKey.ARROW_UP,
            },

            RIGHT = {
                gamepad = rt.GamepadButton.DPAD_RIGHT,
                keyboard = rt.KeyboardKey.ARROW_RIGHT,
            },

            DOWN = {
                gamepad = rt.GamepadButton.DPAD_DOWN,
                keyboard = rt.KeyboardKey.ARROW_DOWN,
            },

            LEFT = {
                gamepad = rt.GamepadButton.DPAD_LEFT,
                keyboard = rt.KeyboardKey.ARROW_LEFT,
            },

            DEBUG = {
                gamepad = rt.GamepadButton.HOME,
                keyboard = rt.KeyboardKey.ESCAPE
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
            meta.assert_table(value)
            for id in range("gamepad", "keyboard") do
                local mapped = value[id]
                state.input_mapping[key][id] = mapped

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

--- @brief
function rt.GameState:set_input_button_gamepad_button(input_button, new_gamepad_button)
    meta.assert_enum(input_button, rt.InputButton)
    meta.assert_enum(new_gamepad_button, rt.GamepadButton)
    local current = self._state.input_mapping[input_button].gamepad

    if current ~= new_gamepad_button then
        self._state.input_mapping[input_button].gamepad = new_gamepad_button
        rt.InputControllerState.load_from_state(self)
    end
end

--- @brief
function rt.GameState:set_input_button_keyboard_key(input_button, keyboard_key)
    meta.assert_enum(input_button, rt.InputButton)

    if not meta.is_enum_value(keyboard_key, rt.KeyboardKey) then
        rt.warning("In rt.GameState:set_input_button_keyboard_key: key `" .. keyboard_key .. "` is not a supported keyboard key")
        return
    end

    local current = self._state.input_mapping[input_button].keyboard
    if current ~= keyboard_key then
        self._state.input_mapping[input_button].keyboard = keyboard_key
        rt.InputControllerState.load_from_state(self)
    end
end

--- @brief
function rt.GameState:input_button_to_gamepad_button(input_button)
    meta.assert_enum(input_button, rt.InputButton)
    return self._state.input_mapping[input_button].gamepad
end

--- @brief
function rt.GameState:input_button_to_keyboard_key(input_button)
    meta.assert_enum(input_button, rt.InputButton)
    return self._state.input_mapping[input_button].keyboard
end

--- @brief
function rt.GameState:get_is_controller_active()
    return rt.InputControllerState.is_controller_active
end

--- @brief
function rt.GameState:_update_window_mode()
    local window_res_x, window_res_y = self._state.resolution_x, self._state.resolution_y
    local resizable = true
    local borderless = false

    if self._state.is_fullscreen then
        window_res_x, window_res_y = 0, 0 -- screen size
        resizable = false
        borderless = true
    end

    love.window.updateMode(
        window_res_x,
        window_res_y,
        {
            fullscreen = false,
            fullscreentype = "desktop",
            vsync = self._state.vsync_mode,
            msaa = 0, --self._state.msaa_quality,
            stencil = true,
            depth = false,
            resizable = resizable,
            borderless = borderless,
            minwidth = window_res_x,
            minheight = window_res_y,
        }
    )

    love.window.updateMode(window_res_x, window_res_y, {minwidth = window_res_x, minheight = window_res_y})
    -- for some reason window does not shrink unless updateMode is called twice

    self._render_texture = rt.RenderTexture(
        self._state.resolution_x,
        self._state.resolution_y,
        self._state.msaa_quality
    )
    self._render_texture:set_scale_mode(rt.TextureScaleMode.LINEAR)
    self:_resize(love.graphics.getWidth(), love.graphics.getHeight())

    rt.settings.contrast = self._state.vfx_contrast_level
    rt.settings.motion_intensity = self._state.vfx_motion_level
end

--- @brief
function rt.GameState:_run()
    love.window.setTitle("rat_game")
    love.window.setIcon(love.image.newImageData("assets/favicon.png"))
    love.filesystem.setIdentity("rat_game")
    self:_update_window_mode()

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

        if self._frame_durations == nil then
            self._frame_durations = {
                n_frames = 0,
                last_fps = love.timer.getFPS(),

                max_update_duration = 0,
                max_draw_duration = 0,
                max_total_duration = 0,
                max_n_draws = 0,
                max_n_texture_switches = 0,

                update_durations = {},
                draw_durations = {},
                total_durations = {},
                n_draws = {},
                n_texture_switches = {},

                format = function(str)
                    while #str < 3 do
                        str = "0" .. str
                    end
                    return str
                end
            }
        end

        local durations = self._frame_durations
        local update_duration = 0
        local draw_duration = 0
        local total_duration = 0

        rt.graphics.frame_start = love.timer.getTime()

        local update_before = love.timer.getTime()
        love.update(delta)
        update_duration = love.timer.getTime() - update_before

        local stats
        local background_color = rt.Palette.TRUE_MAGENTA
        if love.graphics.isActive() then
            self._render_texture:bind_as_render_target()

            love.graphics.clear(true, true, true)
            rt.graphics.reset()
            love.graphics.setColor(background_color.r, background_color.g, background_color.b, 1)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

            local draw_before = love.timer.getTime()
            love.draw()
            local now =  love.timer.getTime()
            draw_duration = now - draw_before
            total_duration = now - update_before
            stats = love.graphics.getStats()

            if self._state.show_diagnostics == true then
                local fps = love.timer.getFPS()
                local frame_duration = 1 / 60
                local update_percentage = tostring(math.floor(durations.max_update_duration / frame_duration * 100))
                local draw_percentage = tostring(math.floor(durations.max_draw_duration / frame_duration * 100))
                local total_percentage = tostring(math.floor(durations.max_total_duration / frame_duration * 100))
                local n_draws = tostring(durations.max_n_draws)
                local n_texture_switches = tostring(durations.max_n_texture_switches)

                local label = tostring(fps) .. " | " .. durations.format(update_percentage) .. "% | " ..  durations.format(draw_percentage) .. "% | " ..  durations.format(total_percentage) .. "% | " .. n_draws
                love.graphics.setColor(1, 1, 1, 0.75)
                local margin = 3
                local label_w, label_h = love.graphics.getFont():getWidth(label), love.graphics.getFont():getHeight(label)
                love.graphics.print(label, math.floor(rt.graphics.get_width() - label_w - 2 * margin), math.floor(0.5 * margin))
            end

            self._render_texture:unbind_as_render_target()
            love.graphics.clear()
            love.graphics.reset()
            self._render_shader:bind()
            self._render_shader:send("gamma", self._state.gamma)
            self._render_shape:draw()
            self._render_shader:unbind()
            love.graphics.present()
        end

        durations.n_frames = durations.n_frames + 1

        if durations.n_frames > 90 and self._state.show_diagnostics == true then
            table.insert(durations.update_durations, update_duration)
            table.insert(durations.draw_durations, draw_duration)
            table.insert(durations.total_durations, total_duration)
            table.insert(durations.n_draws, stats.drawcalls)
            table.insert(durations.n_texture_switches, stats.canvasswitches)

            local update_update = durations.update_durations[1] == durations.max_update_duration
            local update_draw = durations.draw_durations[1] == durations.max_draw_duration
            local update_total = durations.total_durations[1] == durations.max_total_duration
            local update_draws = durations.n_draws[1] == durations.max_n_draws
            local update_texture_switches = durations.n_texture_switches[1] == durations.max_n_texture_switches

            durations.n_frames = durations.n_frames - 1
            table.remove(durations.update_durations, 1)
            table.remove(durations.draw_durations, 1)
            table.remove(durations.total_durations, 1)
            table.remove(durations.n_draws, 1)
            table.remove(durations.n_texture_switches, 1)

            if update_update then durations.max_update_duration = NEGATIVE_INFINITY end
            if update_draw then durations.max_draw_duration = NEGATIVE_INFINITY end
            if update_total then durations.max_total_duration = NEGATIVE_INFINITY end
            if update_draws then durations.max_n_draws = NEGATIVE_INFINITY end
            if update_texture_switches then durations.max_n_texture_switches = NEGATIVE_INFINITY end

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

                if update_draws then
                    durations.max_n_draws = math.max(durations.max_n_draws, durations.n_draws[i])
                end

                if update_texture_switches then
                    durations.max_n_texture_switches = math.max(durations.max_n_texture_switches, durations.n_texture_switches[i])
                end
            end
        else
            table.insert(durations.update_durations, update_duration)
            table.insert(durations.draw_durations, draw_duration)
            table.insert(durations.total_durations, total_duration)
            table.insert(durations.n_draws, stats.drawcalls + stats.drawcallsbatched)
            table.insert(durations.n_texture_switches, stats.canvasswitches)

            durations.max_update_duration = math.max(durations.max_update_duration, update_duration)
            durations.max_draw_duration = math.max(durations.max_draw_duration, draw_duration)
            durations.max_total_duration = math.max(durations.max_total_duration, total_duration)
            durations.max_n_draws = math.max(durations.max_n_draws, stats.drawcalls + stats.drawcallsbatched)
            durations.max_n_texture_switches = math.max(durations.max_n_texture_switches, stats.canvasswitches)
        end

        collectgarbage("collect")
        if love.timer then love.timer.sleep(0.001) end -- limit max tick rate of while true
    end
end

--- @brief
function rt.GameState:_resize(new_width, new_height)
    self._render_shape = rt.VertexRectangle(0, 0, new_width, new_height)
    self._render_shape:set_texture(self._render_texture)

    table.insert(self._active_coroutines, rt.Coroutine(function()
        rt.savepoint_maybe()
        if self._current_scene ~= nil then
            self._current_scene:fit_into(0, 0, self._state.resolution_x, self._state.resolution_y)
        end
        rt.savepoint_maybe()
    end))
end

--- @brief
function rt.GameState:_update(delta)
    local n = sizeof(self._active_coroutines)

    local to_remove = {}
    local max_n_routines = 2;
    local n_routines = 0;
    for i, routine in ipairs(self._active_coroutines) do
        if not routine:get_is_done() then
            routine:resume()
            return; -- work trough all routines until first update
        else
            table.insert(to_remove, i)
        end
    end

    table.sort(to_remove, function(a, b) return a > b end)
    for i in values(to_remove) do
        table.remove(self._active_coroutines, i)
    end

    if self._current_scene ~= nil then
        self._current_scene:update(delta)
    end
end

--- @brief
function rt.GameState:_load()
    -- noop, done on first update
end

--- @brief
function rt.GameState:_draw()
    if self._current_scene ~= nil then
        self._current_scene:draw()
    end
end

--- @brief
function rt.GameState:set_current_scene(scene)
    meta.assert_isa(scene, rt.Scene)
    table.insert(self._active_coroutines, rt.Coroutine(function()
        if self._current_scene ~= nil then
            self._current_scene:set_is_active(false)
        end
        self._current_scene = scene
        self._current_scene:set_is_active(true)
        rt.savepoint_maybe()
        self._current_scene:realize()
        rt.savepoint_maybe()
        self._current_scene:fit_into(0, 0, self._state.resolution_x, self._state.resolution_y)
        rt.savepoint_maybe()
    end))
end

rt.VSyncMode = {
    ADAPTIVE = -1,
    OFF = 0,
    ON = 1
}

--- @brief
function rt.GameState:set_vsync_mode(mode)
    meta.assert_enum(mode, rt.VSyncMode)
    self._state.vsync_mode = mode
    love.window.setVSync(mode)
end

--- @brief
function rt.GameState:get_vsync_mode(mode)
    return self._state.vsync_mode
end

--- @brief
function rt.GameState:set_is_fullscreen(on)
    meta.assert_boolean(on)
    self._state.is_fullscreen = on
    self:_update_window_mode()
end

--- @brief
function rt.GameState:get_is_fullscreen()
    return self._state.is_fullscreen
end

--- @brief
function rt.GameState:set_gamma_level(level)
    self._state.gamma = level
end

--- @brief
function rt.GameState:get_gamma_level()
    return self._state.gamma
end

--- @brief
function rt.GameState:set_msaa_quality(msaa)
    meta.assert_enum(msaa, rt.MSAAQuality)
    if msaa ~= self._state.msaa_quality then
        self._state.msaa_quality = msaa
        self:_update_window_mode()
    end
end

--- @brief
function rt.GameState:get_msaa_quality()
    return self._state.msaa_quality
end

--- @brief
function rt.GameState:set_resolution(width, height)
    meta.assert_number(width, height)
    local current_x, current_y = self._state.resolution_x, self._state.resolution_y
    if current_x ~= width or current_y ~= height then
        self._state.resolution_x = width
        self._state.resolution_y = height
        self:_update_window_mode()
    end
end

--- @brief
function rt.GameState:get_resolution()
    return self._state.resolution_x, self._state.resolution_y
end

--- @brief
function rt.GameState:set_sfx_level(fraction)
    meta.assert_number(fraction)
    if fraction < 0 or fraction > 1 then
        rt.error("In rt.GameState:set_sfx_level: level `" .. fraction .. "` is outside [0, 1]")
        fraction = clamp(fraction, 0, 1)
    end
    self._state.sfx_level = fraction
end

--- @brief
function rt.GameState:get_sfx_level()
    return self._state.sfx_level
end

--- @brief
function rt.GameState:set_music_level(fraction)
    meta.assert_number(fraction)
    if fraction < 0 or fraction > 1 then
        rt.error("In rt.GameState:set_music_level: level `" .. fraction .. "` is outside [0, 1]")
        fraction = clamp(fraction, 0, 1)
    end
    self._state.music_level = fraction
end

--- @brief
function rt.GameState:get_music_level()
    return self._state.music_level
end

--- @brief
function rt.GameState:set_motion_intensity(fraction)
    meta.assert_number(fraction)
    if fraction < 0 or fraction > 1 then
        rt.error("In rt.GameState:set_motion_intensity: level `" .. fraction .. "` is outside [0, 1]")
        fraction = clamp(fraction, 0, 1)
    end
    self._state.vfx_motion_level = fraction
    rt.settings.motion_intensity = fraction
end

--- @brief
function rt.GameState:get_vfx_motion_level()
    return self._state.vfx_motion_level
end

--- @brief
function rt.GameState:set_vfx_contrast_level(fraction)
    meta.assert_number(fraction)
    if fraction < 0 or fraction > 1 then
        rt.error("In rt.GameState:set_vfx_contrast_level: level `" .. fraction .. "` is outside [0, 1]")
        fraction = clamp(fraction, 0, 1)
    end
    self._state.vfx_contrast_level = clamp(fraction, 0, 1)
    rt.settings.battle.background.contrast = fraction
end

--- @brief
function rt.GameState:get_vfx_contrast_level()
    return self._state.vfx_contrast_level
end
