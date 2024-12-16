rt.settings.game_state = {
    lower_gamma_bound = 0.4,
    upper_gamma_bound = 2.2 + 0.5
}

rt.settings.contrast = 1.0
rt.settings.motion_intensity = 1.0
rt.settings.music_level = 1.0
rt.settings.sfx_level = 1.0

--- @class rt.VSyncMode
rt.VSyncMode = meta.new_enum("VSyncMode", {
    ADAPTIVE = -1,
    OFF = 0,
    ON = 1
})

--- @class rt.MSAAQuality
rt.MSAAQuality = meta.new_enum("MSAAQuality", {
    OFF = 0,
    GOOD = 2,
    BETTER = 4,
    BEST = 8,
    MAX = 16
})

--- @brief
--- @return rt.GameState
function rt.get_active_state()
    rt.error("In rt.get_active_state: Trying to access state, but no state was initialized")
    return
end

--- @class rt.GameState
rt.GameState = meta.new_type("GameState", function()
    local state = {
        -- system settings
        vsync_mode = rt.VSyncMode.OFF,
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
        n_entities = 0,
        entity_id_to_multiplicity = {},
        entity_id_to_index = {},
        entities = {},
        turn_i = 1,
        quicksave = nil,

        global_statuses = {},
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
        _quicksave_screenshot = nil, -- helper for bt.QuicksaveIndicator
        _render_shader = rt.Shader("common/game_state_render_shader.glsl"),
        _use_coroutines = false,    -- use loading screens and background loading
        _use_scene_caching = true,  -- keep scenes after allocating them once

        _loading_screen = rt.LoadingScreen.DEFAULT(),
        _loading_screen_active = false,
        _bounds = rt.AABB(0, 0, rt.graphics.get_width(), rt.graphics.get_height()),
        _current_scene = nil,
        _scenes = {}, -- Table<meta.Type, rt.Scene>
        _active_coroutines = {}, -- Table<rt.Coroutine>
        _n_active_coroutines = 0,

        _camera = nil, -- rt.Camera
    })
    out._camera = rt.Camera(out)
    out:realize()
    return out
end)

--- @brief
function rt.GameState:realize()
    self:load_input_mapping()
    rt.get_active_state = function() return self end
    self._loading_screen:realize()
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

    local before_w, before_h = love.graphics.getWidth(), love.graphics.getHeight()

    local native_msaa = self._state.msaa_quality
    love.window.updateMode(
        window_res_x,
        window_res_y,
        {
            fullscreen = self._state.is_fullscreen,
            fullscreentype = "desktop",
            vsync = self._state.vsync_mode,
            msaa = native_msaa,
            stencil = true,
            depth = false,
            resizable = resizable,
            borderless = borderless,
            minwidth = window_res_x,
            minheight = window_res_y,
        }
    )

    love.window.updateMode(window_res_x, window_res_y, {minwidth = window_res_x, minheight = window_res_y})
    -- window does not shrink unless updateMode is called twice

    rt.settings.contrast = self._state.vfx_contrast_level
    rt.settings.motion_intensity = self._state.vfx_motion_level

    self:resize(window_res_x, window_res_y)
end

--- @brief
function rt.GameState:run()
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
            love.graphics.reset()
            love.graphics.setColor(background_color.r, background_color.g, background_color.b, 1)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

            local draw_before = love.timer.getTime()
            love.draw()
            local now =  love.timer.getTime()
            draw_duration = now - draw_before
            total_duration = now - update_before
            stats = love.graphics.getStats()
            local n_batched_draws = stats.drawcallsbatched
            local n_canvas_switches = stats.canvasswitches

            if self._state.show_diagnostics == true then
                local fps = love.timer.getFPS()
                local frame_duration = 1 / 60
                local update_percentage = tostring(math.floor(durations.max_update_duration / frame_duration * 100))
                local draw_percentage = tostring(math.floor(durations.max_draw_duration / frame_duration * 100))
                local total_percentage = tostring(math.floor(durations.max_total_duration / frame_duration * 100))
                local n_draws = tostring(durations.max_n_draws)
                local n_texture_switches = tostring(durations.max_n_texture_switches)
                local gpu_side_memory = tostring(math.round(stats.texturememory / 1024 / 1024 * 10) / 10)

                local label = tostring(fps) .. " fps | " .. durations.format(update_percentage) .. "% | " ..  durations.format(draw_percentage) .. "% | " .. n_draws .. " (" .. n_batched_draws .. ")" .. " | " .. gpu_side_memory .. " mb (" .. stats.textures .. ")"
                love.graphics.setColor(1, 1, 1, 0.75)
                local margin = 3
                local label_w, label_h = love.graphics.getFont():getWidth(label), love.graphics.getFont():getHeight(label)
                love.graphics.print(label, math.floor(rt.graphics.get_width() - label_w - 2 * margin), math.floor(0.5 * margin))
            end

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
function rt.GameState:resize(new_width, new_height)
    local true_w, true_h = love.graphics.getWidth(), love.graphics.getHeight()
    self._loading_screen:fit_into(0, 0, true_w, true_h)

    if self._use_coroutines then
        self:_loading_screen_show(function()
            table.insert(self._active_coroutines, rt.Coroutine(function()
                if self._current_scene ~= nil then
                    self._current_scene:fit_into(0, 0, self._state.resolution_x, self._state.resolution_y)
                    rt.savepoint_maybe()
                end
                self._camera:set_viewport(0, 0, self._state.resolution_x, self._state.resolution_y)
                self:_loading_screen_hide()
            end))
            self._n_active_coroutines = self._n_active_coroutines + 1
        end)
    else
        if self._current_scene ~= nil then
            self._current_scene:fit_into(0, 0, self._state.resolution_x, self._state.resolution_y)
        end
        self._camera:set_viewport(0, 0, self._state.resolution_x, self._state.resolution_y)
    end
end

--- @brief
function rt.GameState:update(delta)
    rt.SoundAtlas:update(delta)

    if self._loading_screen_active then
        self._loading_screen:update(delta)
    elseif self._current_scene ~= nil then
        self._camera:update(delta)
        self._current_scene:update(delta)
        self._current_scene:signal_emit("update")
    end

    if self._use_coroutines then
        local to_remove = {}
        for i, coroutine in ipairs(self._active_coroutines) do
            if coroutine:get_is_done() then
                table.insert(to_remove, 1, i)
            else
                coroutine:resume()
            end
        end

        for i in values(to_remove) do
            table.remove(self._active_coroutines, i)
            self._n_active_coroutines = self._n_active_coroutines - 1
        end
    end
end

--- @brief
function rt.GameState:load()
    self._camera:reset()
    -- noop otherwise, work done on first update
end

--- @brief
function rt.GameState:draw()
    if self._current_scene ~= nil then
        self._camera:bind()
        self._current_scene:draw()
        self._camera:unbind()
    end

    if self._loading_screen_active then
        self._loading_screen:draw()
    end
end

--- @brief
function rt.GameState:_loading_screen_show(on_show)
    self._loading_screen:show()
    self._loading_screen_active = true
    if on_show ~= nil then
        self._loading_screen:signal_disconnect_all("shown")
        self._loading_screen:signal_connect("shown", on_show)
    end
end

--- @brief
function rt.GameState:_loading_screen_hide(on_hidden)
    self._loading_screen:hide()
    self._loading_screen:signal_disconnect_all("hidden")
    self._loading_screen:signal_connect("hidden", function(loading_screen)
        self._loading_screen_active = false
        if on_hidden ~= nil then
            on_hidden(loading_screen)
        end
    end)
end

--- @brief
function rt.GameState:set_current_scene(scene_type)
    if scene_type == nil then
        if self._current_scene ~= nil then
            self._current_scene:make_inactive()
        end
        self._current_scene = nil
        return
    end

    local new_scene
    if self._use_scene_caching then
        new_scene = self._scenes[scene_type]
        if new_scene == nil then
            new_scene = scene_type(self)
            self._scenes[scene_type] = new_scene
        end
    else
        new_scene = scene_type(self)
    end

    if self._use_coroutines then
        table.insert(self._active_coroutines, rt.Coroutine(function()
            rt.savepoint_maybe()
            local use_loading_screen = not new_scene:get_is_realized()

            if use_loading_screen then
                self:_loading_screen_show(function()
                    -- code duplication because make_inactive and make active have to happen behind loading screen
                    if self._current_scene ~= nil then
                        self._current_scene:make_inactive()
                        rt.savepoint_maybe()
                    end

                    self._current_scene = new_scene
                    self._current_scene:realize()
                    rt.savepoint_maybe()
                    self._current_scene:fit_into(0, 0, self._state.resolution_x, self._state.resolution_y)
                    rt.savepoint_maybe()
                    self._current_scene:make_active()

                    self:_loading_screen_hide()
                end)
            else
                if self._current_scene ~= nil then
                    self._current_scene:make_inactive()
                    rt.savepoint_maybe()
                end

                self._current_scene = new_scene
                self._current_scene:make_active()
            end
        end))
        self._n_active_coroutines = self._n_active_coroutines + 1
    else
        if self._current_scene ~= nil then
            self._current_scene:make_inactive()
        end

        self._current_scene = new_scene
        local before = love.timer.getTime()
        if self._current_scene:get_is_realized() == false then
            self._current_scene:realize()
            self._current_scene:fit_into(0, 0, self._state.resolution_x, self._state.resolution_y)
        end
        self._current_scene:make_active()
    end
end

--- @brief
function rt.GameState:get_current_scene()
    return self._current_scene
end

--- @brief
function rt.GameState:set_vsync_mode(mode)
    meta.assert_enum_value(mode, rt.VSyncMode)
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
    self._render_shader:send("gamma", self._state.gamma)
end

--- @brief
function rt.GameState:get_gamma_level()
    return self._state.gamma
end

--- @brief
function rt.GameState:set_msaa_quality(msaa)
    meta.assert_enum_value(msaa, rt.MSAAQuality)
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
        fraction = clamp(fraction, 0, 1)
    end
    self._state.deadzone = fraction
    rt.InputControllerState.deadzone = self._state.deadzone
end

--- @brief
--- @return (rt.KeyboardKey, rt.GamepadButton)
function rt.GameState:get_keybinding(input_button)
    meta.assert_enum_value(input_button, rt.InputButton)
    local binding = self._state.keybinding[input_button]
    return binding.keyboard, binding.gamepad
end

--- @brief
function rt.GameState:get_default_keybinding(input_button)
    meta.assert_enum_value(input_button, rt.InputButton)
    local binding = self:_get_default_mapping()[input_button]
    return binding.keyboard, binding.gamepad
end

--- @brief
function rt.GameState:set_keybinding(input_button, keyboard_binding, gamepad_binding, notify_controller_state)
    meta.assert_enum_value(input_button, rt.InputButton)
    meta.assert_enum_value(keyboard_binding, rt.KeyboardKey)
    meta.assert_enum_value(gamepad_binding, rt.GamepadButton)

    local binding = self._state.keybinding[input_button]
    binding.keyboard = keyboard_binding
    binding.gamepad = gamepad_binding

    if notify_controller_state then
        rt.InputControllerState:load_mapping(self._state.keybinding)
    end
end

--- @brief
function rt.GameState:set_loading_screen(loading_screen_type)
    meta.assert_isa(loading_screen_type, meta.Type)
    self._loading_screen = loading_screen_type()
    self._loading_screen:realize()
    self._loading_screen:fit_into(self._bounds)
end

--- @brief
function rt.GameState:get_camera()
    return self._camera
end