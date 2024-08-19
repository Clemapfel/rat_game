--- @class mn.OptionsScene
mn.OptionsScene = meta.new_type("MenuOptionsScene", rt.Scene, function(state)

    local fields = {
        _state = state,
        _items = {},
        _remappers = {},
        _remap_target_button = rt.InputButton.A,
        _remap_controller = rt.InputController(),
        _remapper_button_order = {
            rt.InputButton.A,
            rt.InputButton.B,
            rt.InputButton.X,
            rt.InputButton.Y,
            rt.InputButton.UP,
            rt.InputButton.RIGHT,
            rt.InputButton.DOWN,
            rt.InputButton.LEFT,
            rt.InputButton.L,
            rt.InputButton.R,
            rt.InputButton.START,
            rt.InputButton.SELECT
        },
        _button_to_remapper = {}
    }

    --fields._remap_controller:set_is_disabled(true)
    
    fields._vsync_label_text = "VSync"
    fields._vsync_on_label = "ON"
    fields._vsync_off_label = "OFF"
    fields._vsync_adaptive_label = "ADAPTIVE"

    fields._fullscreen_label_text = "Fullscreen"
    fields._fullscreen_true_label = "YES"
    fields._fullscreen_false_label = "NO"

    fields._borderless_label_text = "Borderless"
    fields._borderless_true_label = "YES"
    fields._borderless_false_label = "NO"

    fields._msaa_label_text = "MSAA"
    fields._msaa_0_label = "0"
    fields._msaa_2_label = "2"
    fields._msaa_4_label = "4"
    fields._msaa_8_label = "8"
    fields._msaa_16_label = "16"

    fields._resolution_label_text = "Resolution"
    fields._resolution_1280_720_label = "1280x720 (16:9)"
    fields._resolution_1600_900_label = "1600x900 (16:9)"
    fields._resolution_1920_1080_label = "1920x1080 (16:9)"
    fields._resolution_2560_1440_label = "2560x1400 (16:9)"
    fields._resolution_variable_label = "custom"

    fields._multiple_choice_layout = {
        [fields._vsync_label_text] = {
            options = {
                fields._vsync_on_label,
                fields._vsync_off_label,
                fields._vsync_adaptive_label
            },
            default = fields._vsync_adaptive_label
        },

        [fields._fullscreen_label_text] = {
            options = {
                fields._fullscreen_true_label,
                fields._fullscreen_false_label
            },
            default = fields._fullscreen_false_label
        },

        [fields._borderless_label_text] = {
            options = {
                fields._borderless_true_label,
                fields._borderless_false_label,
            },
            default = fields._borderless_false_label
        },

        [fields._msaa_label_text] = {
            options = {
                fields._msaa_0_label,
                fields._msaa_2_label,
                fields._msaa_4_label,
                fields._msaa_8_label,
                fields._msaa_16_label
            },
            default = fields._msaa_8_label
        },

        [fields._resolution_label_text] = {
            options = {
                fields._resolution_1280_720_label,
                fields._resolution_1600_900_label,
                fields._resolution_1920_1080_label,
                fields._resolution_2560_1440_label,
                fields._resolution_variable_label,
            },
            default = fields._resolution_1280_720_label
        }
    }

    fields._sfx_level_text = "Sound Effects"
    fields._music_level_text = "Music"
    fields._vfx_motion_text = "Motion Effects"
    fields._vfx_contrast_text = "Visual Effects"

    fields._level_layout = {
        [fields._sfx_level_text] = {
            range = {0, 100, 100},
            default = 50
        },

        [fields._music_level_text] = {
            range = {0, 100, 100},
            default = 50
        },

        [fields._vfx_motion_text] = {
            range = {0, 3, 3},
            default = 3
        },

        [fields._vfx_contrast_text] = {
            range = {0, 100, 1},
            default = 100
        }
    }

    local out = meta.new(mn.OptionsScene, fields)
    return out
end)

--- @override
function mn.OptionsScene:realize()
    if self._is_realized then return end
    self._is_realized = true

    local scene = self

    local label_prefix, label_postfix = "<b>", "</b>"
    local create_button_and_label = function(name, text, handler)
        local label = rt.Label(label_prefix .. text .. label_postfix)
        label:set_justify_mode(rt.JustifyMode.LEFT)
        label:realize()

        local entry = scene._multiple_choice_layout[text]
        local button = mn.OptionButton(table.unpack(entry.options))
        button:set_option(entry.default)
        button:realize()

        scene["_" .. name .. "_label"] = label
        scene["_" .. name .. "_option_button"] = button
        scene["_" .. name .. "_option_button"]:signal_connect("selection", handler)

        local frame = rt.Frame()
        frame:realize()

        table.insert(scene._items, {
            label = label,
            widget = button,
            frame = frame
        })
    end

    create_button_and_label("vsync", self._vsync_label_text, function(_, which)
        local mode
        if which == scene._vsync_on_label then
            mode = rt.VSyncMode.ON
        elseif which == scene._vsync_off_label then
            mode = rt.VSyncMode.OFF
        elseif which == scene._vsync_adaptive_label then
            mode = rt.VSyncMode.ADAPTIVE
        end
        scene._state:set_vsync_mode(mode)
    end)

    create_button_and_label("fullscreen", self._fullscreen_label_text, function(_, which)
        local on
        if which == scene._fullscreen_true_label then
            on = true
        elseif which == scene._fullscreen_false_label then
            on = false
        end
        scene._state:set_fullscreen(on)
    end)

    create_button_and_label("borderless", self._borderless_label_text, function(_, which)
        local on
        if which == scene._borderless_true_label then
            on = true
        elseif which == scene._borderless_false_label then
            on = false
        end
        scene._state:set_borderless(on)
    end)

    create_button_and_label("msaa", self._msaa_label_text, function(_, which)
        local level
        if which == scene._msaa_0_label then
            level = 0
        elseif which == scene._msaa_2_label then
            level = 2
        elseif which == scene._msaa_4_label then
            level = 4
        elseif which == scene._msaa_8_label then
            level = 8
        elseif which == scene._msaa_16_label then
            level = 16
        end
        scene._state:set_msaa_level(level)
    end)

    create_button_and_label("resolution", self._resolution_label_text, function(_, which)
        if which == scene._resolution_variable_label then
            scene._state:set_window_resizable(true)
            return
        end

        local x_res, y_res
        if which == scene._resolution_1280_720_label then
            x_res, y_res = 1280, 720
        elseif which == scene._resolution_1600_900_label then
            x_res, y_res = 1600, 900
        elseif which == scene._resolution_1920_1080_label then
            x_res, y_res = 1920, 1080
        elseif which == scene._resolution_2560_1440_label then
            x_res, y_res = 2560, 1440
        end

        scene._state:set_resizable(false)
        scene._state:set_resolution(x_res, y_res)
    end)

    --

    local create_button_and_scale = function(name, text, handler)
        local label = rt.Label(label_prefix .. text .. label_postfix)
        label:set_justify_mode(rt.JustifyMode.LEFT)
        label:realize()

        local item = self._level_layout[text]
        local scale = mn.Scale(
            item.range[1],
            item.range[2],
            item.range[3],
            item.default
        )

        scale:realize()
        scale:signal_connect("value_changed", handler)

        local frame = rt.Frame()
        frame:realize()

        table.insert(scene._items, {
            label = label,
            widget = scale,
            frame = frame
        })
    end

    create_button_and_scale("sfx_level", self._sfx_level_text, function(_, fraction)
        scene._state:set_sfx_level(fraction)
    end)

    create_button_and_scale("music_level", self._music_level_text, function(_, fraction)
        scene._state:set_music_level(fraction)
    end)

    create_button_and_scale("vfx_motion", self._vfx_motion_text, function(_, fraction)
        scene._state:set_vfx_motion_level(fraction)
    end)

    create_button_and_scale("vfx_contrast", self._vfx_contrast_text, function(_, fraction)
        scene._state:set_vfx_contrast_level(fraction)
    end)


    for button in values(self._remapper_button_order) do
        local remapper =  mn.KeybindingIndicator(self._state, button)
        remapper:realize()
        table.insert(self._remappers, remapper)
        self._button_to_remapper[button] = remapper
    end

    self._remap_controller:signal_connect("keyboard_pressed_raw", function(_, name, scancode)
        local remapper = scene._button_to_remapper[scene._remap_target_button]
        remapper:set_keyboard_key_label(string.upper(name))
        scene._state:set_input_button_keyboard_key(scene._remap_target_button, rt.KeyboardKeyPrefix .. scancode)
    end)
end

--- @override
function mn.OptionsScene:create_from_state(state)
    self._state = state

    for button in values(self._remapper_button_order) do
        local remapper = self._button_to_remapper[button]
        local current = self._state:input_button_to_keyboard_key(button)
        remapper:set_keyboard_key_label(rt.keyboard_key_to_string(current))

        current = self._state:input_button_to_gamepad_button(button)
        remapper:set_gamepad_button_label(rt.gamepad_button_to_string(current))
    end
end

--- @override
function mn.OptionsScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local start_y = y + outer_margin
    local current_x, current_y = x + outer_margin, start_y

    local max_label_w = NEGATIVE_INFINITY
    local label_ws, label_hs = {}, {}
    for item in values(self._items) do
        local label_w, label_h = item.label:measure()
        table.insert(label_ws, label_w)
        table.insert(label_hs, label_h)
        max_label_w = math.max(max_label_w, label_w)
    end

    local w = 0.5 * width
    local label_xm = 5 * m
    for i, item in ipairs(self._items) do
        local label_h, label_w = label_hs[i], label_ws[i]
        local frame_h = label_h + 2 * m
        item.frame:fit_into(current_x, current_y, w - 2 * outer_margin, frame_h)
        item.label:fit_into(current_x + m, current_y + 0.5 * frame_h - 0.5 * label_h, POSITIVE_INFINITY)
        local widget_w = w - 2 * outer_margin - m - max_label_w - 2 * label_xm
        item.widget:fit_into(
            current_x + m + max_label_w + label_xm,
            current_y + 0.5 * frame_h - 0.5 * label_h,
            widget_w,
            label_h
        )
        current_y = current_y + frame_h
    end

    local rest_h = height - 2 * outer_margin - (current_y - start_y)
    local rest_w = width - 2 * outer_margin
    local remapper_w = rest_w / 3
    local remapper_h = rest_h / 4

    local remapper_x, remapper_y = current_x, current_y
    local row_i, col_i = 1, 1

    for i = 1, 12 do
        local remapper = self._remappers[i]
        remapper:fit_into(current_x + (col_i - 1) * remapper_w, current_y + (row_i - 1) * remapper_h, remapper_w, remapper_h)
        row_i = row_i + 1
        if row_i > 4 then
            row_i = 1
            col_i = col_i + 1
        end
    end
end

--- @override
function mn.OptionsScene:draw()
    for item in values(self._items) do
        item.frame:draw()
        item.label:draw()
        item.widget:draw()
    end

    for remapper in values(self._remappers) do
        remapper:draw()
    end
end

--- @override
function mn.OptionsScene:update(delta)
    for item in values(self._items) do
        item.widget:update(delta)
    end
end
