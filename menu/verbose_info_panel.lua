rt.settings.menu.verbose_info_panel = {
    indicator_highlight_duration = 0.25,
    indicator_base_color = rt.Palette.FOREGROUND
}

--- @class mn.VerboseInfoPanel
mn.VerboseInfoPanel = meta.new_type("MenuVerboseInfoPanel", rt.Widget, function()
    return meta.new(mn.VerboseInfoPanel, {
        _items = {},
        _current_item_i = 0,
        _n_items = 0,
        _y_offset = 0,
        _frame = rt.Frame(),
        _scroll_up_indicator = {}, -- rt.Polygon
        _scroll_up_indicator_outline = {}, -- rt.Polygon
        _scroll_up_indicator_visible = true,
        _scroll_down_indicator = {}, -- rt.Polygon
        _scroll_down_indicator_outline = {}, -- rt.Polygon
        _scroll_down_indicator_visible = true,
        _indicator_up_duration = POSITIVE_INFINITY,
        _indicator_down_duration = POSITIVE_INFINITY,
        _selection_state = rt.SelectionState.INACTIVE
    })
end)

--- @brief
function mn.VerboseInfoPanel:show(object)
    local to_insert = mn.VerboseInfoPanel.Item()
    to_insert:create_from_equip(bt.Equip("DEBUG_EQUIP"))
    to_insert:realize()
    to_insert:fit_into(0, 0, 100, 100)
    self._items = {to_insert}
    self._n_items = 1
    self:_set_current_item(1)
    self:reformat()
end

--- @override
function mn.VerboseInfoPanel:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._frame:realize()
end

--- @override
function mn.VerboseInfoPanel:size_allocate(x, y, width, height)
    self._frame:fit_into(x, y, width, height)

    local m = rt.settings.margin_unit
    local angle = 120
    local arrow_width = 6 * m
    local thickness = m
    self._scroll_up_indicator = rt.Polygon(rt.generate_hat_arrow(x + 0.5 * width, y, arrow_width, thickness, angle))
    self._scroll_up_indicator_outline = rt.LineStrip(rt.generate_hat_arrow_outline(x + 0.5 * width, y, arrow_width, thickness, angle))

    self._scroll_down_indicator = rt.Polygon(rt.generate_hat_arrow(x + 0.5 * width, y + height, arrow_width, thickness, 360 - angle))
    self._scroll_down_indicator_outline = rt.LineStrip(rt.generate_hat_arrow_outline(x + 0.5 * width, y + height, arrow_width, thickness, 360 - angle))

    for body in range(self._scroll_up_indicator, self._scroll_down_indicator) do
        body:set_color(rt.settings.menu.verbose_info_panel.indicator_base_color)
    end

    for line in range(self._scroll_down_indicator_outline, self._scroll_up_indicator_outline) do
        line:set_line_width(1)
        line:set_color(rt.Palette.BASE_OUTLINE)
    end

    local current_x, current_y = x, y
    local total_height = 0
    local n_items = sizeof(self._items)
    for i = 1, n_items do
        local item = self._items[i]
        item:fit_into(current_x, current_y, width, POSITIVE_INFINITY)
        local h = select(2, item:measure())

        item.height_above = total_height
        total_height = total_height + h
        current_y = current_y + h
    end

    local reverse_height = 0
    for i = n_items, 1, -1 do
        local item = self._items[i]
        reverse_height = reverse_height + item.aabb.height
        item.height_below = reverse_height
    end

    self._scroll_up_indicator_visible = self:can_scroll_up()
    self._scroll_down_indicator_visible = self:can_scroll_down()
end

--- @override
function mn.VerboseInfoPanel:draw()
    self._frame:draw()
    self._frame:_bind_stencil()
    rt.graphics.translate(0, self._y_offset)
    for item in values(self._items) do
        item:draw()
    end
    self._frame:_unbind_stencil()
    rt.graphics.translate(0, -self._y_offset)

    if self._scroll_up_indicator_visible and self._selection_state == rt.SelectionState.SELECTED then
        self._scroll_up_indicator:draw()
        self._scroll_up_indicator_outline:draw()
    end

    if self._scroll_down_indicator_visible and self._selection_state == rt.SelectionState.SELECTED then
        self._scroll_down_indicator:draw()
        self._scroll_down_indicator_outline:draw()
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
end

--- @brief
function mn.VerboseInfoPanel:set_selection_state(state)
    meta.assert_enum(state, rt.SelectionState)
    self._selection_state = state
    self._frame:set_selection_state(state)
end

--- @brief [internal]
function mn.VerboseInfoPanel:_set_current_item(i)
    self._current_item_i = i
    self._y_offset = -1 * self._items[self._current_item_i].height_above
    self._scroll_up_indicator_visible = self:can_scroll_up()
    self._scroll_down_indicator_visible = self:can_scroll_down()
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
    return self._current_item_i > 1
end

--- @brief
function mn.VerboseInfoPanel:scroll_down()
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
    local current = self._items[self._current_item_i]
    if current == nil then return false end
    return self._current_item_i < self._n_items and current.height_below > self._bounds.height
end

--[[
Move (\u{25A0}) -- rectangle
    Some moves can only be used a limited number of times per battle.

    priority:
        >0: Always goes first
        <0: Always goes last

    is_intrinsic:
        this move is automatically made available at the start of each battle

Equip (\u{2B23} -- hexagon
    May raise certains stats, and / or apply a unique effect at the start of each battle

Consumable (\u{x25CF}) -- circle
    Item that will activate on its own when certain conditions are met.

    max_n_uses:
        Only activates up to *N* times per battle
        \u{221E} Activates an unlimited number of times

Templates
    (this feature is not yet implemented)
--

Health (HP)
    When a characters HP reaches 0, they are knocked out. If damaged while knocked out, they die

Attack (ATK)
    For most moves, user's ATK increases damage dealt to the target

Defense (DEF)
    For most moves, target's DEF decreases damage dealt to target

Speed (SPD)
    Along with Move Priority, influences in what order participants act each turn

]]--