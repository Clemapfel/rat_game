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
        _button_to_remapper = {},
        _verbose_info = mn.VerboseInfoPanel(),
        _selection_graph = rt.SelectionGraph()
    }

    fields._vsync_label_text = "VSync"
    fields._vsync_on_label = "ON"
    fields._vsync_off_label = "OFF"
    fields._vsync_adaptive_label = "ADAPTIVE"
    fields._vsync_label = nil
    fields._vsync_option_button = nil

    fields._vsync_mode_to_vsync_label = {
        [rt.VSyncMode.ON] = fields._vsync_on_label,
        [rt.VSyncMode.OFF] = fields._vsync_off_label,
        [rt.VSyncMode.ADAPTIVE] = fields._vsync_adaptive_label
    }

    fields._vsync_label_to_vsync_mode = {}
    for key, value in pairs(fields._vsync_mode_to_vsync_label) do
        fields._vsync_label_to_vsync_mode[value] = key
    end

    fields._fullscreen_label_text = "Fullscreen"
    fields._fullscreen_true_label = "YES"
    fields._fullscreen_false_label = "NO"
    fields._fullscreen_label = nil
    fields._fullscreen_option_button = nil

    fields._borderless_label_text = "Borderless"
    fields._borderless_true_label = "YES"
    fields._borderless_false_label = "NO"
    fields._borderless_label = nil
    fields._borderless_option_button = nil

    fields._msaa_label_text = "MSAA"
    fields._msaa_off_label = "OFF"
    fields._msaa_good_label = "Good"
    fields._msaa_better_label = "Better"
    fields._msaa_best_label = "Best"
    fields._msaa_max_label = "Maximum"
    fields._msaa_label = nil
    fields._msaa_option_button = nil

    fields._msaa_quality_to_msaa_label = {
        [rt.MSAAQuality.OFF] = fields._msaa_off_label,
        [rt.MSAAQuality.GOOD] = fields._msaa_good_label,
        [rt.MSAAQuality.BETTER] = fields._msaa_better_label,
        [rt.MSAAQuality.BEST] = fields._msaa_best_label,
        [rt.MSAAQuality.MAX] = fields._msaa_max_label,
    }

    fields._msaa_label_to_msaa_quality = {}
    for key, value in pairs(fields._msaa_quality_to_msaa_label) do
        fields._msaa_label_to_msaa_quality[value] = key
    end

    fields._resolution_label_text = "Resolution"
    fields._resolution_1280_720_label = "1280x720 (16:9)"
    fields._resolution_1600_900_label = "1600x900 (16:9)"
    fields._resolution_1920_1080_label = "1920x1080 (16:9)"
    fields._resolution_2560_1440_label = "2560x1400 (16:9)"
    fields._resolution_label = nil
    fields._resolution_option_button = nil

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
                fields._msaa_off_label,
                fields._msaa_good_label,
                fields._msaa_better_label,
                fields._msaa_best_label,
                fields._msaa_best_label
            },
            default = fields._msaa_best_label
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
    fields._sfx_level_label = nil
    fields._sfx_level_scale = nil

    fields._music_level_text = "Music"
    fields._music_level_label = nil
    fields._music_level_scale = nil

    fields._vfx_motion_text = "Motion Effects"
    fields._vfx_motion_label = nil
    fields._vfx_motion_scale = nil

    fields._vfx_contrast_text = "Visual Effects"
    fields._vfx_contrast_label = nil
    fields._vfx_contrast_scale = nil

    fields._level_layout = {
        [fields._sfx_level_text] = {
            range = {0, 1, 100},
            default = 50
        },

        [fields._music_level_text] = {
            range = {0, 1, 100},
            default = 50
        },

        [fields._vfx_motion_text] = {
            range = {0, 1, 3},
            default = 3
        },

        [fields._vfx_contrast_text] = {
            range = {0, 1, 1},
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
        button:realize()
        button:set_option(entry.default)

        scene["_" .. name .. "_label"] = label
        scene["_" .. name .. "_option_button"] = button
        scene["_" .. name .. "_option_button"]:signal_connect("selection", handler)

        local frame = rt.Frame()
        frame:realize()

        table.insert(scene._items, {
            label = label,
            widget = button,
            frame = frame,
            x_offset = 0
        })
    end
    
    create_button_and_label("vsync", self._vsync_label_text, function(_, which)
        scene._state:set_vsync_mode(scene._vsync_label_to_vsync_mode[which])
    end)

    create_button_and_label("fullscreen", self._fullscreen_label_text, function(_, which)
        local on
        if which == scene._fullscreen_true_label then
            on = true
        elseif which == scene._fullscreen_false_label then
            on = false
        end
        scene._state:set_is_fullscreen(on)
    end)

    create_button_and_label("borderless", self._borderless_label_text, function(_, which)
        local on
        if which == scene._borderless_true_label then
            on = true
        elseif which == scene._borderless_false_label then
            on = false
        end
        scene._state:set_is_borderless(on)
    end)

    create_button_and_label("msaa", self._msaa_label_text, function(_, which)
        local level = scene._msaa_label_to_msaa_quality[which]
        scene._state:set_msaa_quality(level)
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

        scene._state:set_resolution(x_res, y_res)
    end)

    --

    local create_scale_and_label = function(name, text, handler)
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

        scene["_" .. name .. "_label"] = label
        scene["_" .. name .. "_scale"] = scale

        table.insert(scene._items, {
            label = label,
            widget = scale,
            frame = frame,
            x_offset = 0,
        })
    end

    create_scale_and_label("sfx_level", self._sfx_level_text, function(_, fraction)
        scene._state:set_sfx_level(fraction)
    end)

    create_scale_and_label("music_level", self._music_level_text, function(_, fraction)
        scene._state:set_music_level(fraction)
    end)

    create_scale_and_label("vfx_motion", self._vfx_motion_text, function(_, fraction)
        scene._state:set_vfx_motion_level(fraction)
    end)

    create_scale_and_label("vfx_contrast", self._vfx_contrast_text, function(_, fraction)
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

    self:create_from_state(self._state)

    self._verbose_info_panel:realize()
end

--- @override
function mn.OptionsScene:create_from_state(state)
    self._state = state

    local set_option = function(button, option)
        button:signal_set_is_blocked("selection", true)
        button:set_option(option)
        button:signal_set_is_blocked("selection", false)
    end

    set_option(self._vsync_option_button, self._vsync_mode_to_vsync_label[self._state:get_vsync_mode()])
    
    set_option(self._fullscreen_option_button, ternary(
        self._state:get_is_fullscreen(), 
        self._fullscreen_true_label, 
        self._fullscreen_false_label
    ))
    
    set_option(self._borderless_option_button, ternary(
        self._state:get_is_borderless(),
        self._borderless_true_label,
        self._borderless_false_label
    ))

    set_option(self._msaa_option_button, self._msaa_quality_to_msaa_label[self._state:get_msaa_quality()])

    local res_x, res_y = self._state:get_resolution()
    local resolution_label = self["_resolution_" .. res_x .. "_" .. res_y .. "_label"]
    if resolution_label == nil then
        resolution_label = self._resolution_variable_label
    end

    set_option(self._resolution_option_button, resolution_label)

    local set_scale = function(scale, value)
        scale:signal_set_is_blocked("value_changed", true)
        scale:set_value(value)
        scale:signal_set_is_blocked("value_changed", false)
    end

    set_scale(self._sfx_level_scale, self._state:get_sfx_level())
    set_scale(self._music_level_scale, self._state:get_music_level())
    set_scale(self._vfx_motion_scale, self._state:get_vfx_motion_level())
    set_scale(self._vfx_contrast_scale, self._state:get_vfx_contrast_level())

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
        item.label:fit_into(current_x + 2 * m, current_y + 0.5 * frame_h - 0.5 * label_h, POSITIVE_INFINITY)
        local widget_x = current_x + m + max_label_w + label_xm
        local widget_w = x + w - outer_margin - 4 * m - widget_x
        item.widget:fit_into(
            widget_x,
            current_y + 0.5 * frame_h - 0.5 * label_h,
            widget_w,
            label_h
        )
        item.x_offset = widget_x - widget_x + 0.5 * widget_w - 0.5 * select(1, item.widget:measure())
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

        rt.graphics.translate(item.x_offset, 0)
        item.widget:draw()
        rt.graphics.translate(-item.x_offset, 0)
    end

    self._verbose_info_panel:draw()

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

--- @brief
function mn.OptionsScene:_regenerate_selection_nodes()
    local vsync_node = rt.SelectionGraphNode(self._vsync_option_button:get_bounds())
end