rt.settings.menu.verbose_info_panel = {
    indicator_highlight_duration = 0.25,
    indicator_base_color = rt.Palette.FOREGROUND
}

rt.VerboseInfoObject = meta.new_enum("VerboseInfoObject", {
    MOVE = "move",
    CONSUMABLE = "consumable",
    EQUIP = "equip",
    TEMPLATE = "template",
    STATUS = "status",
    GLOBAL_STATUS = "global_status",
    HP = "hp",
    ATTACK = "attack",
    DEFENSE = "defense",
    SPEED = "speed",
    OPTIONS = "options",
    VSYNC = "vsync",
    FULLSCREEN = "fullscreen",
    GAMMA = "gamma",
    GAMMA_WIDGET = "gamma_widget",
    MSAA = "msaa",
    MSAA_WIDGET = "msaa_widget",
    RESOLUTION = "resolution",
    SOUND_EFFECTS = "sfx_level",
    MUSIC = "music_level",
    MOTION_EFFECTS = "vfx_motion_level",
    MOTION_EFFECTS_WIDGET= "vfx_motion_level_widget",
    VISUAL_EFFECTS = "vfx_contrast_level",
    VISUAL_EFFECTS_WIDGET = "vfx_contrast_level_widget",
    KEYMAP = "keymap",
    DEADZONE = "deadzone",
    DEADZONE_WIDGET = "deadzone_widget",
    QUICKSAVE = "quicksave",
    BATTLE_LOG = "battle_log"
})

--- @class mn.VerboseInfoPanel
mn.VerboseInfoPanel = meta.new_type("MenuVerboseInfoPanel", rt.Widget, function(state)
    return meta.new(mn.VerboseInfoPanel, {
        _state = state,
        _items = {},
        _current_item_i = 0,
        _n_items = 0,
        _y_offset = 0,
        _total_height = 0,
        _frame = rt.Frame(),
        _frame_visible = true,
        _scroll_up_indicator = mn.ScrollIndicator(),
        _scroll_up_indicator_visible = true,
        _scroll_down_indicator = mn.ScrollIndicator(),
        _scroll_down_indicator_visible = true,
        _indicator_up_duration = POSITIVE_INFINITY,
        _indicator_down_duration = POSITIVE_INFINITY,
        _selection_state = rt.SelectionState.INACTIVE
    })
end)

--- @brief
function mn.VerboseInfoPanel:show(...)
    self._items = {}

    -- recursively list all items and their see_also
    local function process_item(object)
        local item = mn.VerboseInfoPanel.Item()
        item._state = self._state
        item:create_from(object)
        if self._frame_visible then
            item.frame:set_corner_radius(0)
        else
            item.frame:set_corner_radius(rt.settings.frame.corner_radius)
        end

        item:realize()
        table.insert(self._items, item)
        rt.savepoint_maybe()

        if meta.is_table(object) and object.see_also ~= nil then
            for other in values(object.see_also) do
                process_item(other)
            end
        end
    end

    for object in range(...) do
        process_item(object)
    end

    self._n_items = sizeof(self._items)
    self:_set_current_item(ternary(self._n_items > 0, 1, 0))
    self:reformat()
end

--- @override
function mn.VerboseInfoPanel:realize()
    if self:already_realized() then return end
    self._frame:realize()
end

--- @override
function mn.VerboseInfoPanel:size_allocate(x, y, width, height)
    self._frame:fit_into(x, y, width, height)

    local m = rt.settings.margin_unit
    local angle = (2 * math.pi) / 3
    local arrow_width = 6 * m
    local thickness = m
    local up_x, up_y = x + 0.5 * width, y - thickness
    self._scroll_up_indicator:reformat(up_x, up_y, angle, arrow_width, thickness)

    local down_x, down_y = x + 0.5 * width, y + height + thickness
    self._scroll_down_indicator:reformat(down_x, down_y, (2 * math.pi) - angle, arrow_width, thickness)

    local current_x, current_y = x, y
    local total_height = 0
    local n_items = sizeof(self._items)
    self._total_height = 0
    for i = 1, n_items do
        local item = self._items[i]
        item:fit_into(current_x, current_y, width, POSITIVE_INFINITY)
        local h = select(2, item:measure())

        item.height_above = total_height
        item.aabb = rt.AABB(current_x, current_y, width, h)
        total_height = total_height + h
        current_y = current_y + h

        self._total_height = self._total_height + h
    end

    local reverse_height = 0
    for i = n_items, 1, -1 do
        local item = self._items[i]
        reverse_height = reverse_height + item.aabb.height
        item.height_below = reverse_height
    end

    self._y_offset = 0
    self:_update_scroll_indicators()
end

--- @override
function mn.VerboseInfoPanel:draw()
    if self._frame_visible then
        self._frame:draw()
        self._frame:bind_stencil()
    end

    rt.graphics.translate(0, self._y_offset)

    for item in values(self._items) do
        if self._frame_visible then
            item.divider:draw()
        else
            item.frame:draw()
        end
        item:draw()
    end

    if self._frame_visible then
        self._frame:unbind_stencil()
    end

    rt.graphics.translate(0, -self._y_offset)

    if self._scroll_up_indicator_visible then
        self._scroll_up_indicator:draw()
    end

    if self._scroll_down_indicator_visible then
        self._scroll_down_indicator:draw()
    end
end

--- @override
function mn.VerboseInfoPanel:update(delta)
    self._indicator_up_duration = self._indicator_up_duration + delta
    self._indicator_down_duration = self._indicator_down_duration + delta

    local fraction = self._indicator_up_duration / rt.settings.menu.verbose_info_panel.indicator_highlight_duration
    fraction = clamp(fraction, 0, 1)
    local color = rt.color_mix(rt.Palette.SELECTION, rt.settings.menu.verbose_info_panel.indicator_base_color, fraction)

    for shape in range(self._scroll_up_indicator) do
        shape:set_color(color)
    end

    fraction = self._indicator_down_duration / rt.settings.menu.verbose_info_panel.indicator_highlight_duration
    fraction = clamp(fraction, 0, 1)
    color = rt.color_mix(rt.Palette.SELECTION, rt.settings.menu.verbose_info_panel.indicator_base_color, fraction)

    for shape in range(self._scroll_down_indicator) do
        shape:set_color(color)
    end

    for item in values(self._items) do
        if item.update ~= nil then
            item:update(delta)
        end
    end
end

--- @brief
function mn.VerboseInfoPanel:set_selection_state(state)
    meta.assert_enum_value(state, rt.SelectionState)
    self._selection_state = state
    self._frame:set_selection_state(state)
end

--- @brief
function mn.VerboseInfoPanel:_update_scroll_indicators()
    self._scroll_up_indicator_visible = self:can_scroll_up()
    self._scroll_down_indicator_visible = self:can_scroll_down()
end

--- @brief [internal]
function mn.VerboseInfoPanel:_set_current_item(i)
    self._current_item_i = i

    if self._current_item_i < 1 or self._current_item_i > self._n_items then
        self._y_offset = 0
    else
        self._y_offset = -1 * self._items[self._current_item_i].height_above
    end

    self:_update_scroll_indicators()
end

--- @brief
function mn.VerboseInfoPanel:scroll_up()
    self._indicator_up_duration = 0
    if self:can_scroll_up() then
        self._current_item_i = self._current_item_i - 1
        self:_set_current_item(self._current_item_i)
        return true
    else
        return false
    end
end

--- @brief
function mn.VerboseInfoPanel:can_scroll_up()
    local n = sizeof(self._items)
    if n < 2 then return false end

    local last_item = self._items[n]
    if last_item == nil then return false end
    return last_item._bounds.y + select(2, last_item:measure()) + self._y_offset > self._bounds.y + self._bounds.height
end

--- @brief
function mn.VerboseInfoPanel:scroll_down()
    local n = sizeof(self._items)
    if n < 2 then return false end

    self._indicator_down_duration = 0
    if self:can_scroll_down() then
        self._current_item_i = self._current_item_i + 1
        self:_set_current_item(self._current_item_i)
        return true
    else
        return false
    end
end

--- @brief
function mn.VerboseInfoPanel:can_scroll_down()
    return self._y_offset < 0
end

--- @brief
function mn.VerboseInfoPanel:advance_scroll(delta)
    if self._n_items == 0 then return end

    self._y_offset = self._y_offset + delta
    self:_update_scroll_indicators()
end

--- @brief
function mn.VerboseInfoPanel:set_frame_visible(b)
    self._frame_visible = b
end

--- @brief
function mn.VerboseInfoPanel:measure()
    return self._bounds.width, self._total_height
end