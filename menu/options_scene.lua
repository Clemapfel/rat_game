rt.settings.menu.option_scene = {
    scale_n_ticks_per_second = 32,
    scale_delay = 1 / 3 -- seconds
}

--- @class mn.OptionsScene
mn.OptionsScene = meta.new_type("MenuOptionsScene", rt.Scene, function(state)
    local fields = {
        _state = state,
        _items = {},
        _verbose_info = mn.VerboseInfoPanel(),
        _selection_graph = rt.SelectionGraph(),
        _input_controller = rt.InputController(),
        _control_indicator = rt.ControlIndicator(),

        _scale_is_selected = false,
        _selected_scale = nil,
        _scale_delay_elapsed = 0,
        _scale_delay_duration = rt.settings.menu.option_scene.scale_delay,
        _scale_tick_elapsed = 0,
        _scale_tick_duration = 1 / rt.settings.menu.option_scene.scale_n_ticks_per_second,
        _scale_tick_direction = true, -- true = right

        _load_coroutine = nil, -- rt.Coroutine
    }

    -- nil items set during :realize

    fields._vsync_label_text = "VSync"
    fields._vsync_on_label = "ON"
    fields._vsync_off_label = "OFF"
    fields._vsync_adaptive_label = "ADAPTIVE"
    fields._vsync_label = nil
    fields._vsync_option_button = nil
    fields._vsync_item = nil

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
    fields._fullscreen_item = nil

    fields._msaa_label_text = "MSAA"
    fields._msaa_off_label = "OFF"
    fields._msaa_good_label = "Good"
    fields._msaa_better_label = "Better"
    fields._msaa_best_label = "Best"
    fields._msaa_max_label = "Maximum"
    fields._msaa_label = nil
    fields._msaa_option_button = nil
    fields._msaa_item = nil

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
    fields._resolution_item = nil

    fields._multiple_choice_layout = {
        [fields._fullscreen_label_text] = {
            options = {
                fields._fullscreen_false_label,
                fields._fullscreen_true_label
            },
            default = fields._fullscreen_false_label
        },

        [fields._vsync_label_text] = {
            options = {
                fields._vsync_off_label,
                fields._vsync_on_label,
                fields._vsync_adaptive_label
            },
            default = fields._vsync_adaptive_label
        },

        [fields._msaa_label_text] = {
            options = {
                fields._msaa_off_label,
                fields._msaa_good_label,
                fields._msaa_better_label,
                fields._msaa_best_label,
                fields._msaa_max_label
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

    fields._gamma_text = "Gamma"
    fields._gamma_label = nil
    fields._gamma_scale = nil
    fields._gamma_item = nil

    fields._sfx_level_text = "Sound Effects"
    fields._sfx_level_label = nil
    fields._sfx_level_scale = nil
    fields._sfx_level_item = nil

    fields._music_level_text = "Music"
    fields._music_level_label = nil
    fields._music_level_scale = nil
    fields._music_level_item = nil

    fields._vfx_motion_text = "Motion Effects"
    fields._vfx_motion_label = nil
    fields._vfx_motion_scale = nil
    fields._vfx_motion_item = nil

    fields._vfx_contrast_text = "Visual Effects"
    fields._vfx_contrast_label = nil
    fields._vfx_contrast_scale = nil
    fields._vfx_contrast_item = nil

    fields._level_layout = {
        [fields._gamma_text] = {
            range = {0.3, 2.2, 100},
            default = 1.0
        },

        [fields._sfx_level_text] = {
            range = {0, 1, 100},
            default = 50
        },

        [fields._music_level_text] = {
            range = {0, 1, 100},
            default = 50
        },

        [fields._vfx_motion_text] = {
            range = {0, 1, 100},
            default = 3
        },

        [fields._vfx_contrast_text] = {
            range = {0, 1, 100},
            default = 100
        }
    }

    fields._keymap_text = "Controls"
    fields._keymap_label = nil
    fields._keymap_arrow = nil
    fields._keymap_item = nil

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

        local item = {
            label = label,
            widget = button,
            frame = frame,
            default = self._multiple_choice_layout[text].default,
            x_offset = 0
        }

        self["_" .. name .. "_item"] = item
        table.insert(scene._items, item)
    end

    create_button_and_label("fullscreen", self._fullscreen_label_text, function(_, which)
        local on
        if which == scene._fullscreen_true_label then
            on = true
        elseif which == scene._fullscreen_false_label then
            on = false
        end
        scene._state:set_is_fullscreen(on)
    end)

    create_button_and_label("vsync", self._vsync_label_text, function(_, which)
        scene._state:set_vsync_mode(scene._vsync_label_to_vsync_mode[which])
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

        local item = {
            label = label,
            widget = scale,
            frame = frame,
            x_offset = 0,
            default = 1
        }

        self["_" .. name .. "_item"] = item
        table.insert(scene._items, item)
    end

    create_scale_and_label("gamma", self._gamma_text, function(_, fraction)
        scene._state:set_gamma_level(fraction)
    end)

    create_scale_and_label("sfx_level", self._sfx_level_text, function(_, fraction)
        scene._state:set_sfx_level(fraction)
    end)

    create_scale_and_label("music_level", self._music_level_text, function(_, fraction)
        scene._state:set_music_level(fraction)
    end)

    create_scale_and_label("vfx_motion", self._vfx_motion_text, function(_, fraction)
        scene._state:set_motion_intensity(fraction)
    end)

    create_scale_and_label("vfx_contrast", self._vfx_contrast_text, function(_, fraction)
        scene._state:set_vfx_contrast_level(fraction)
    end)

    self:create_from_state(self._state)
    self._verbose_info:realize()

    local keymap_item = {
        label = rt.Label(label_prefix .. self._keymap_text .. label_postfix),
        widget = rt.DirectionIndicator(rt.Direction.RIGHT),
        frame = rt.Frame(),
        x_offset = 0,
    }
    table.insert(self._items, keymap_item)
    self._keymap_item = keymap_item

    for widget in range(keymap_item.label, keymap_item.widget, keymap_item.frame) do
        widget:realize()
    end

    local _, label_h = keymap_item.label:measure()
    keymap_item.widget:set_minimum_size(label_h, label_h)

    self._input_controller:signal_disconnect_all()
    self._input_controller:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

    self._input_controller:signal_connect("released", function(_, which)
        if self._scale_is_selected then
            self._scale_delay_elapsed = 0
            self._scale_tick_elapsed = 0
        end
    end)

    self._control_indicator:realize()
    self:_update_control_indicator(true)
    self:create_from_state(self._state)
end

--- @brief
function mn.OptionsScene:_update_control_indicator(left_right_allowed)
    meta.assert_boolean(left_right_allowed)
    local left_right_label = "Change Value"
    if not left_right_allowed then
        left_right_label = "<s><color=GRAY>" .. left_right_label .. "</s></color>"
    end

    self._control_indicator:create_from({
        {rt.ControlIndicatorButton.B, "Exit"},
        {rt.ControlIndicatorButton.X, "Apply"},
        {rt.ControlIndicatorButton.Y, "Set Default"},
        {rt.ControlIndicatorButton.LEFT_RIGHT, left_right_label},
        {rt.ControlIndicatorButton.UP_DOWN, "Select"}
    })
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

    set_scale(self._gamma_scale, self._state:get_gamma_level())
    set_scale(self._sfx_level_scale, self._state:get_sfx_level())
    set_scale(self._music_level_scale, self._state:get_music_level())
    set_scale(self._vfx_motion_scale, self._state:get_vfx_motion_level())
    set_scale(self._vfx_contrast_scale, self._state:get_vfx_contrast_level())
end

--- @override
function mn.OptionsScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local start_y = y + outer_margin
    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(x + width - outer_margin - control_w, start_y, control_w, control_h)

    start_y = start_y + control_h + m

    local max_label_w, max_label_h = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local label_ws, label_hs = {}, {}
    local n_items = 0
    for item in values(self._items) do
        local label_w, label_h = item.label:measure()
        table.insert(label_ws, label_w)
        table.insert(label_hs, label_h)
        max_label_w = math.max(max_label_w, label_w)
        max_label_h = math.max(max_label_h, label_h)
        n_items = n_items + 1
    end

    local label_left_m = outer_margin
    local label_right_m = 7 * m
    local widget_right_m = 2 * outer_margin
    local button_area_left_m = outer_margin
    local button_area_right_m = m
    local verbose_info_right_m = outer_margin

    local verbose_info_w = (width - (button_area_left_m + label_left_m + max_label_w + label_right_m + widget_right_m + button_area_right_m + verbose_info_right_m)) / 2
    local item_vertical_m = 0.5 * m
    local item_h = (y + height - start_y - outer_margin - (n_items - 1) * item_vertical_m) / n_items
    local item_w = label_left_m + max_label_w + label_right_m + verbose_info_w + widget_right_m

    local current_x, current_y = x + button_area_left_m, start_y
    for i, item in ipairs(self._items) do
        item.label:fit_into(current_x + label_left_m, current_y + 0.5 * item_h - 0.5 * max_label_h, POSITIVE_INFINITY)
        item.widget:fit_into(
            current_x + label_left_m + max_label_w + label_right_m,
            current_y + 0.5 * item_h - 0.5 * max_label_h,
            verbose_info_w,
            max_label_h
        )
        item.frame:fit_into(current_x, current_y, item_w, item_h)
        current_y = current_y + item_h + item_vertical_m
    end

    self._verbose_info:fit_into(
        x + width - verbose_info_right_m - verbose_info_w,
        start_y,
        verbose_info_w,
        y + height - start_y - outer_margin
    )

    self:_regenerate_selection_nodes()
end

--- @brief
function mn.OptionsScene:_regenerate_selection_nodes()
    self._selection_graph:clear()

    local nodes = {}
    local item_to_node = {}
    for item in values(self._items) do
        local node = rt.SelectionGraphNode(item.frame:get_bounds())
        table.insert(nodes, node)
        item_to_node[item] = node
        self._selection_graph:add(node)
    end

    for i = 1, #nodes do
        nodes[i]:set_up(nodes[i-1])
        nodes[i]:set_down(nodes[i+1])
    end

    nodes[1]:set_up(nodes[#nodes])
    nodes[#nodes]:set_down(nodes[1])

    local scene = self
    for item_verbose_info_object in range(
        {self._vsync_item, rt.VerboseInfoObject.VSYNC},
        {self._fullscreen_item, rt.VerboseInfoObject.FULLSCREEN},
        {self._gamma_item, {rt.VerboseInfoObject.GAMMA, rt.VerboseInfoObject.GAMMA_WIDGET}},
        {self._msaa_item, {rt.VerboseInfoObject.MSAA, rt.VerboseInfoObject.MSAA_WIDGET}},
        {self._resolution_item, rt.VerboseInfoObject.RESOLUTION},
        {self._sfx_level_item, rt.VerboseInfoObject.SOUND_EFFECTS},
        {self._music_level_item, rt.VerboseInfoObject.MUSIC_LEVEL},
        {self._vfx_motion_item, {rt.VerboseInfoObject.MOTION_EFFECTS, rt.VerboseInfoObject.MOTION_EFFECTS_WIDGET}},
        {self._vfx_contrast_item, {rt.VerboseInfoObject.VISUAL_EFFECTS, rt.VerboseInfoObject.VISUAL_EFFECTS_WIDGET}}
        --{self._keymap_item, rt.VerboseInfoObject.KEYMAP}
    ) do
        local item = item_verbose_info_object[1]
        local verbose_info_object = item_verbose_info_object[2]
        if not meta.is_table(verbose_info_object) then
            verbose_info_object = {verbose_info_object}
        end

        local node = item_to_node[item]
        node:signal_connect("enter", function(_)
            scene._verbose_info:show(table.unpack(verbose_info_object))
            item.frame:set_selection_state(rt.SelectionState.ACTIVE)
            if meta.isa(item.widget, mn.Scale) then
                scene._scale_is_selected = true
                scene._selected_scale = item.widget
            end
            scene._scale_tick_elapsed = 0
            scene._scale_delay_elapsed = 0
        end)

        node:signal_connect("exit", function(_)
            item.frame:set_selection_state(rt.SelectionState.INACTIVE)
            scene._scale_is_selected = false
            scene._selected_scale = nil
        end)

        node:signal_connect(rt.InputButton.RIGHT, function(_)
            item.widget:move_right()
            self._scale_tick_direction = true
        end)

        node:signal_connect(rt.InputButton.LEFT, function(_)
            item.widget:move_left()
            self._scale_tick_direction = false
        end)

        node:signal_connect(rt.InputButton.Y, function(_)
            if meta.isa(item.widget, mn.OptionButton) then
                item.widget:set_option(item.default)
            elseif meta.isa(item.widget, mn.Scale) then
                item.widget:set_value(item.default)
            end
        end)
    end

    local keymap_node = item_to_node[self._keymap_item]
    keymap_node:signal_connect("enter", function(_)
        scene._keymap_item.frame:set_selection_state(rt.SelectionState.ACTIVE)
    end)

    keymap_node:signal_connect("exit", function(_)
        scene._keymap_item.frame:set_selection_state(rt.SelectionState.INACTIVE)
    end)

    self._selection_graph:set_current_node(item_to_node[self._items[1]])
end

--- @override
function mn.OptionsScene:draw()
    if self._is_realized ~= true then return end
    for item in values(self._items) do
        item.frame:draw()
        item.label:draw()

        rt.graphics.translate(item.x_offset, 0)
        item.widget:draw()
        rt.graphics.translate(-item.x_offset, 0)
    end

    self._verbose_info:draw()
    self._control_indicator:draw()
end

--- @override
function mn.OptionsScene:update(delta)
    if self._is_active ~= true then return end

    for item in values(self._items) do
        if item.widget.update ~= nil then
            item.widget:update(delta)
        end
    end

    if self._scale_is_selected then
        self._scale_delay_elapsed = self._scale_delay_elapsed + delta
        if self._scale_delay_elapsed >= self._scale_delay_duration then
            self._scale_tick_elapsed = self._scale_tick_elapsed + delta
            while self._scale_tick_elapsed > self._scale_tick_duration do
                self._scale_tick_elapsed = self._scale_tick_elapsed - self._scale_tick_duration
                if self._scale_tick_direction == true and self._input_controller:is_down(rt.InputButton.RIGHT) then
                    self._selected_scale:move_right()
                elseif self._input_controller:is_down(rt.InputButton.LEFT) then
                    self._selected_scale:move_left()
                end
            end
        end
    end

    local speed = rt.settings.menu.inventory_scene.verbose_info_scroll_speed
    if self._input_controller:is_down(rt.InputButton.L) then
        if self._verbose_info:can_scroll_down() then
            self._verbose_info:advance_scroll(delta * speed)
        end
    end

    if self._input_controller:is_down(rt.InputButton.R) then
        if self._verbose_info:can_scroll_up() then
            self._verbose_info:advance_scroll(delta * speed * -1)
        end
    end

    self._verbose_info:update(delta)
end

--- @brief
function mn.OptionsScene:_handle_button_pressed(which)
    if self._is_active ~= true then return end

    self._selection_graph:handle_button(which)
end
