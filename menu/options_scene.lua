rt.settings.menu.options_scene = {
    scale_n_ticks_per_second = 32,
    scale_delay = 1 / 3, -- seconds
}

--- @class mn.OptionsScene
mn.OptionsScene = meta.class("MenuOptionsScene", rt.Scene)

--- @brief
function mn.OptionsScene:instantiate(state)
    local fields = {
        _state = state,
        _items = {},
        _verbose_info = mn.VerboseInfoPanel(state),
        _selection_graph = rt.SelectionGraph(),
        _default_node = nil, -- rt.SelectionGraphNode
        _input_controller = rt.InputController(),
        _control_indicator = rt.ControlIndicator(),
        _keymap_item_active = false,

        _heading_label = nil, -- rt.Label
        _heading_frame = rt.Frame(),

        _scale_is_selected = false,
        _selected_scale = nil,
        _scale_delay_elapsed = 0,
        _scale_delay_duration = rt.settings.menu.options_scene.scale_delay,
        _scale_tick_elapsed = 0,
        _scale_tick_duration = 1 / rt.settings.menu.options_scene.scale_n_ticks_per_second,
        _scale_tick_direction = true, -- true = right

        _snapshot = nil, -- rt.RenderTexture
        _active_frame = nil, -- rt.Frame
        _active_label = nil  -- rt.Label
    }

    -- nil items set during :realize

    local translation = rt.Translation.options_scene
    fields._heading_label = rt.Label(translation.heading)

    fields._vsync_label_text = translation.vsync
    fields._vsync_on_label = translation.vsync_on
    fields._vsync_off_label = translation.vsync_off
    fields._vsync_adaptive_label = translation.vsync_adaptive
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

    fields._fullscreen_label_text = translation.fullscreen
    fields._fullscreen_true_label = translation.fullscreen_on
    fields._fullscreen_false_label = translation.fullscreen_off
    fields._fullscreen_label = nil
    fields._fullscreen_option_button = nil
    fields._fullscreen_item = nil

    fields._msaa_label_text = translation.msaa
    fields._msaa_off_label = translation.msaa_off
    fields._msaa_good_label = translation.msaa_good
    fields._msaa_better_label = translation.msaa_better
    fields._msaa_best_label = translation.msaa_best
    fields._msaa_max_label = translation.msaa_max
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

    fields._resolution_label_text = translation.resolution
    fields._resolution_1280_720_label = translation.resolution_1280_720
    fields._resolution_1366_768_label = translation.resolution_1366_768
    fields._resolution_1600_900_label = translation.resolution_1600_900
    fields._resolution_1920_1080_label = translation.resolution_1920_1080
    fields._resolution_2560_1440_label = translation.resolution_2560_1440
    fields._resolution_1280_800_label = translation.resolution_1280_800
    fields._resolution_1440_900_label = translation.resolution_1440_900
    fields._resolution_1680_1050_label = translation.resolution_1680_1050
    fields._resolution_1920_1200_label = translation.resolution_1920_1200
    fields._resolution_2560_1600_label = translation.resolution_2560_1600
    fields._resolution_2560_1080_label = translation.resolution_2560_1080
    fields._resolution_native_label = translation.resolution_native

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
                fields._resolution_native_label,
                fields._resolution_1280_720_label,
                fields._resolution_1280_800_label,
                fields._resolution_1366_768_label,
                fields._resolution_1440_900_label,
                fields._resolution_1600_900_label,
                fields._resolution_1680_1050_label,
                fields._resolution_1920_1080_label,
                fields._resolution_1920_1200_label,
                fields._resolution_2560_1440_label,
                fields._resolution_2560_1600_label,
                fields._resolution_2560_1080_label,
            },
            default = fields._resolution_1280_720_label
        }
    }

    fields._sfx_level_text = translation.sfx_level
    fields._sfx_level_label = nil
    fields._sfx_level_scale = nil
    fields._sfx_level_item = nil

    fields._music_level_text = translation.music_level
    fields._music_level_label = nil
    fields._music_level_scale = nil
    fields._music_level_item = nil

    fields._text_speed_text = translation.text_speed
    fields._text_speed_label = nil
    fields._text_speed_scale = nil
    fields._text_speed_item = nil

    fields._vfx_contrast_text = translation.vfx_contrast
    fields._vfx_contrast_label = nil
    fields._vfx_contrast_scale = nil
    fields._vfx_contrast_item = nil

    fields._deadzone_text = translation.deadzone
    fields._deadzone_label = nil
    fields._deadzone_scale = nil
    fields._deadzone_item = nil

    fields._level_layout = {

        [fields._sfx_level_text] = {
            range = {0, 1, 100},
            default = 50
        },

        [fields._music_level_text] = {
            range = {0, 1, 100},
            default = 50
        },

        [fields._text_speed_text] = {
            range = {0.1, 2, 100},
            default = 1
        },

        [fields._vfx_contrast_text] = {
            range = {0, 1, 100},
            default = 100
        },

        [fields._deadzone_text] = {
            range = {0, 0.95, 100},
            default = 0.15
        }
    }

    fields._keymap_text = translation.keymap
    fields._keymap_label = nil
    fields._keymap_arrow = nil
    fields._keymap_item = nil

    meta.install(self, fields)
end

--- @override
function mn.OptionsScene:realize()
    if self:already_realized() then return end

    local scene = self

    self._heading_label:realize()
    self._heading_frame:realize()

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
        if which == self._resolution_native_label then
            x_res, y_res = love.window.getDesktopDimensions()
        else
            x_res, y_res = string.match(which, "(%d+)%s*x%s*(%d+)") -- first two numbers with x between
        end
        scene._state:set_resolution(tonumber(x_res),tonumber(y_res))
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

    create_scale_and_label("sfx_level", self._sfx_level_text, function(_, fraction)
        scene._state:set_sfx_level(fraction)
    end)

    create_scale_and_label("music_level", self._music_level_text, function(_, fraction)
        scene._state:set_music_level(fraction)
    end)

    create_scale_and_label("text_speed", self._text_speed_text, function(_, fraction)
        scene._state:set_text_speed(fraction)
    end)

    create_scale_and_label("vfx_contrast", self._vfx_contrast_text, function(_, fraction)
        scene._state:set_vfx_contrast_level(fraction)
    end)

    create_scale_and_label("deadzone", self._deadzone_text, function(_, fraction)
        scene._state:set_deadzone(fraction)
    end)

    self:create_from_state(self._state)
    self._verbose_info:realize()
    self._verbose_info:set_frame_visible(true)

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
        if self._is_active == false then return end
        self:_handle_button_pressed(which)
    end)

    self._input_controller:signal_connect("released", function(_, which)
        if self._is_active == false then return end
        if self._scale_is_selected then
            self._scale_delay_elapsed = 0
            self._scale_tick_elapsed = 0
        end
    end)

    self._control_indicator:realize()
    self:_update_control_indicator()
    self:create_from_state(self._state)
end

--- @brief
function mn.OptionsScene:_update_control_indicator()
    local labels = rt.Translation.options_scene

    if self._keymap_item_active == false then
        local left_right_label = labels.control_indicator_a
        left_right_label = "<s><color=GRAY>" .. left_right_label .. "</s></color>"

        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.LEFT_RIGHT, labels.control_indicator_left_right},
            {rt.ControlIndicatorButton.Y, labels.control_indicator_y},
            {rt.ControlIndicatorButton.B, labels.control_indicator_b}
        })
    else
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.A, labels.control_indicator_keymap_item_select}
        })
    end

    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local start_y = self._bounds.y + outer_margin
    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(self._bounds.x + self._bounds.width - outer_margin - control_w, start_y, control_w, control_h)
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

    set_scale(self._sfx_level_scale, self._state:get_sfx_level())
    set_scale(self._music_level_scale, self._state:get_music_level())
    set_scale(self._text_speed_scale, self._state:get_text_speed())
    set_scale(self._vfx_contrast_scale, self._state:get_vfx_contrast_level())
    set_scale(self._deadzone_scale, self._state:get_deadzone())
end

--- @override
function mn.OptionsScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local start_y = y + outer_margin
    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(x + width - outer_margin - control_w, start_y, control_w, control_h)

    local heading_w, heading_h = self._heading_label:measure()
    self._heading_frame:fit_into(x + outer_margin, start_y, heading_w + 2 * outer_margin, control_h)
    self._heading_label:fit_into(x + outer_margin + outer_margin, start_y + 0.5 * control_h - 0.5 * heading_h, POSITIVE_INFINITY)

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

    for info in range(self._verbose_info) do
        info:fit_into(
            x + width - verbose_info_right_m - verbose_info_w,
            start_y,
            verbose_info_w,
            y + height - start_y - outer_margin
        )
    end

    self:_update_snapshot()
    self:_regenerate_selection_nodes()
end

--- @brief
function mn.OptionsScene:_update_snapshot()
    if self._snapshot == nil or self._snapshot:get_width() ~= self._bounds.width or self._snapshot:get_height() ~= self._bounds.height then
        if self._snapshot ~= nil then self._snapshot:free() end
        self._snapshot = rt.RenderTexture(self._bounds.width, self._bounds.height, self._state:get_msaa_quality())
    end

    self._snapshot:bind()
    for item in values(self._items) do
        local before = item.frame:get_selection_state()
        item.frame:set_selection_state(rt.SelectionState.INACTIVE)
        item.frame:draw()
        item.frame:set_selection_state(before)
        item.label:draw()
    end

    self._heading_frame:draw()
    self._heading_label:draw()

    self._snapshot:unbind()
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
        {self._msaa_item, {rt.VerboseInfoObject.MSAA, rt.VerboseInfoObject.MSAA_WIDGET}},
        {self._resolution_item, rt.VerboseInfoObject.RESOLUTION},
        {self._sfx_level_item, rt.VerboseInfoObject.SOUND_EFFECTS},
        {self._music_level_item, rt.VerboseInfoObject.MUSIC},
        {self._text_speed_item, {rt.VerboseInfoObject.TEXT_SPEED}},
        {self._vfx_contrast_item, {rt.VerboseInfoObject.VISUAL_EFFECTS, rt.VerboseInfoObject.VISUAL_EFFECTS_WIDGET}},
        {self._deadzone_item, {rt.VerboseInfoObject.DEADZONE}},
        {self._keymap_item, rt.VerboseInfoObject.KEYMAP}
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

            scene._active_frame = item.frame
            scene._active_label = item.label

            local current = scene._keymap_item_active
            scene._keymap_item_active = item == scene._keymap_item
            self:_update_control_indicator()
        end)

        node:signal_connect("exit", function(_)
            item.frame:set_selection_state(rt.SelectionState.INACTIVE)
            scene._scale_is_selected = false
            scene._selected_scale = nil

            scene._active_frame = nil
            scene._active_label = nil
            scene._keymap_item_active = false
        end)

        node:set_right(function(_)
            if item.widget.move_right ~= nil then
                item.widget:move_right()
            end
            self._scale_tick_direction = true
        end)

        node:set_left(function(_)
            if item.widget.move_left ~= nil then
                item.widget:move_left()
            end
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
        scene._active_frame = scene._keymap_item.frame
        scene._active_label = scene._keymap_item.label
    end)

    keymap_node:signal_connect("exit", function(_)
        scene._keymap_item.frame:set_selection_state(rt.SelectionState.INACTIVE)
        scene._active_frame = nil
        scene._active_label = nil
    end)

    keymap_node:signal_connect(rt.InputButton.A, function(_)
        self._state:set_current_scene(mn.KeybindingScene)
    end)

    self._default_node = item_to_node[self._items[1]]
    self._selection_graph:set_current_node(self._default_node)
end

--- @override
function mn.OptionsScene:draw()
    if not self:get_is_allocated() then return end
    if self._snapshot ~= nil then
        self._snapshot:draw()
    end

    self._control_indicator:draw()

    if self._active_frame ~= nil then
        self._active_frame:draw()
    end

    if self._active_label ~= nil then
        self._active_label:draw()
    end

    for item in values(self._items) do
        rt.graphics.translate(item.x_offset, 0)
        item.widget:draw()
        rt.graphics.translate(-item.x_offset, 0)
    end

    self._verbose_info:draw()
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
                if self._scale_tick_direction == true and self._input_controller:get_is_down(rt.InputButton.RIGHT) then
                    self._selected_scale:move_right()
                elseif self._input_controller:get_is_down(rt.InputButton.LEFT) then
                    self._selected_scale:move_left()
                end
            end
        end
    end

    local speed = rt.settings.menu.inventory_scene.verbose_info_scroll_speed
    if self._input_controller:get_is_down(rt.InputButton.L) then
        if self._verbose_info:can_scroll_down() then
            self._verbose_info:advance_scroll(delta * speed)
        end
    end

    if self._input_controller:get_is_down(rt.InputButton.R) then
        if self._verbose_info:can_scroll_up() then
            self._verbose_info:advance_scroll(delta * speed * -1)
        end
    end

    self._verbose_info:update(delta)
end

--- @brief
function mn.OptionsScene:_handle_button_pressed(which)
    if self._is_active ~= true then return end

    if which == rt.InputButton.B then
        self._state:set_current_scene(mn.InventoryScene)
    else
        self._selection_graph:handle_button(which)
    end
end

--- @override
function mn.OptionsScene:make_active()
    if self._is_realized == false then self:realize() end
    self._is_active = true
    self._selection_graph:set_current_node(self._default_node)
    self:_update_snapshot()
    self._input_controller:signal_unblock_all()
    self._state:set_is_battle_active(false)
end

--- @override
function mn.OptionsScene:make_inactive()
    self._is_active = false
    self._snapshot = nil
    self._input_controller:signal_block_all()
end