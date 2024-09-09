rt.settings.game_state = {
    lower_gamma_bound = 0.4,
    upper_gamma_bound = 2.2 + 0.5
}

rt.settings.contrast = 1.0
rt.settings.motion_intensity = 1.0
rt.settings.music_level = 1.0
rt.settings.sfx_level = 1.0

--- @class rt.VSyncMode
rt.VSyncMode = {
    ADAPTIVE = -1,
    OFF = 0,
    ON = 1
}

--- @class rt.MSAAQuality
rt.MSAAQuality = {
    OFF = 0,
    GOOD = 2,
    BETTER = 4,
    BEST = 8,
    MAX = 16
}

--- @brief
--- @return rt.GameState
function rt.get_active_state()
    rt.error("In rt.get_active_state: Trying to access state, but no state was initialized")
    return nil
end

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
        deadzone = 0.15,
        show_diagnostics = true,
        keybinding = {}, -- Table<rt.InputButton, Table<Union<rt.GamepadButton, rt.KeyboardKey>>>

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
        _scenes = {}, -- Table<meta.Type, rt.Scene>
        _active_coroutines = {} -- Table<rt.Coroutine>
    })

    out:realize()
    return out
end)

--- @brief
function rt.GameState:realize()
    self:load_input_mapping()
    rt.get_active_state = function() return self end
end

--- @brief
function rt.GameState:_get_default_mapping()
    return {
        [rt.InputButton.A] = {
            keyboard = rt.KeyboardKey.SPACE,
            gamepad = rt.GamepadButton.RIGHT
        },

        [rt.InputButton.B] = {
            keyboard = rt.KeyboardKey.B,
            gamepad = rt.GamepadButton.BOTTOM
        },

        [rt.InputButton.X] = {
            keyboard = rt.KeyboardKey.X,
            gamepad = rt.GamepadButton.TOP
        },

        [rt.InputButton.Y] = {
            keyboard = rt.KeyboardKey.Z,
            gamepad = rt.GamepadButton.LEFT
        },

        [rt.InputButton.L] = {
            keyboard = rt.KeyboardKey.L,
            gamepad = rt.GamepadButton.LEFT_SHOULDER
        },

        [rt.InputButton.R] = {
            keyboard = rt.KeyboardKey.R,
            gamepad = rt.GamepadButton.RIGHT_SHOULDER
        },

        [rt.InputButton.START] = {
            keyboard = rt.KeyboardKey.M,
            gamepad = rt.GamepadButton.START
        },

        [rt.InputButton.SELECT] = {
            keyboard = rt.KeyboardKey.N,
            gamepad = rt.GamepadButton.SELECT
        },

        [rt.InputButton.UP] = {
            keyboard = rt.KeyboardKey.ARROW_UP,
            gamepad = rt.GamepadButton.DPAD_UP,
        },

        [rt.InputButton.RIGHT] = {
            keyboard = rt.KeyboardKey.ARROW_RIGHT,
            gamepad = rt.GamepadButton.DPAD_RIGHT
        },

        [rt.InputButton.DOWN] = {
            keyboard = rt.KeyboardKey.ARROW_DOWN,
            gamepad = rt.GamepadButton.DPAD_DOWN
        },

        [rt.InputButton.LEFT] = {
            keyboard = rt.KeyboardKey.ARROW_LEFT,
            gamepad = rt.GamepadButton.DPAD_LEFT
        },

        [rt.InputButton.DEBUG] = {
            keyboard = rt.KeyboardKey.ESCAPE,
            gamepad = rt.GamepadButton.RIGHT_STICK,
        }
    }
end

--- @brief
function rt.GameState:load_input_mapping()
    local mapping = self:_get_default_mapping()

    self._state.keybinding = mapping
    rt.InputControllerState:load_mapping(mapping)
    rt.InputControllerState.deadzone = self._state.deadzone
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
            msaa = 16, --self._state.msaa_quality,
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
    rt.settings.sfx_level = self._state.sfx_level
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
    rt.settings.music_level = self._state.music_level
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

--- @brief
function rt.GameState:get_deadzone()
    return rt.InputControllerState.deadzone
end

--- @brief
function rt.GameState:set_deadzone(fraction)
    meta.assert_number(fraction)
    if not (fraction >= 0 and fraction < 1) then
        rt.error("In rt.GameState:set_deadzone: value `" .. fraction .. "` is outside [0, 1)")
    end
    self._state.deadzone = fraction
    rt.InputControllerState.deadzone = self._state.deadzone
end

--- @brief
--- @return (rt.KeyboardKey, rt.GamepadButton)
function rt.GameState:get_keybinding(input_button)
    meta.assert_enum(input_button, rt.InputButton)
    local binding = self._state.keybinding[input_button]
    return binding.keyboard, binding.gamepad
end

--- @brief
function rt.GameState:get_default_keybinding(input_button)
    meta.assert_enum(input_button, rt.InputButton)
    local binding = self:_get_default_mapping()[input_button]
    return binding.keyboard, binding.gamepad
end

--- @brief
function rt.GameState:set_keybinding(input_button, keyboard_binding, gamepad_binding, notify_controller_state)
    meta.assert_enum(input_button, rt.InputButton)
    meta.assert_enum(keyboard_binding, rt.KeyboardKey)
    meta.assert_enum(gamepad_binding, rt.GamepadButton)

    local binding = self._state.keybinding[input_button]
    binding.keyboard = keyboard_binding
    binding.gamepad = gamepad_binding

    if notify_controller_state then
        rt.InputControllerState:load_mapping(self._state.keybinding)
    end
end
