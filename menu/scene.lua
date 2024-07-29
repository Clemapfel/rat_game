mn.Scene = meta.new_type("MenuScene", rt.Scene, function()
    return meta.new(mn.Scene, {
        _background = bt.Background.SDF_MEATBALLS()
    })
end, {
    _shared_move_tab_index = 1,
    _shared_consumable_tab_index = 2,
    _shared_equip_tab_index = 3,
    _shared_template_tab_index = 4,

    _shared_list_sort_mode_order = {
        [mn.ScrollableListSortMode.BY_TYPE] = mn.ScrollableListSortMode.BY_NAME,
        [mn.ScrollableListSortMode.BY_NAME] = mn.ScrollableListSortMode.BY_QUANTITY,
        [mn.ScrollableListSortMode.BY_QUANTITY] = mn.ScrollableListSortMode.BY_ID,
        [mn.ScrollableListSortMode.BY_ID] = mn.ScrollableListSortMode.BY_TYPE,
    },
})

--- @override
function mn.Scene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    if self._background ~= nil then
        self._background:realize()
    end
end

--- @override
function mn.Scene:size_allocate(x, y, width, height)
    local padding = rt.settings.frame.thickness
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m

    if self._background ~= nil then
        self._background:fit_into(x, y, width, height)
    end
end

--- @override
function mn.Scene:draw()
    if self._is_realized ~= true then return end

    if self._background ~= nil then
        self._background:draw()
    end
end

--- @override
function mn.Scene:update(delta)
    if self._background ~= nil then
        self._background:update(delta)
    end
end