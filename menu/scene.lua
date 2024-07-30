rt.settings.menu.scene = {
    tab_sprite_scale_factor = 3
}

mn.Scene = meta.new_type("MenuScene", rt.Scene, function()
    return meta.new(mn.Scene, {
        _background = bt.Background.PARALLELL_LINES(),

        _state = {}, -- mn.InventoryState

        _entity_tab_bar = mn.TabBar(),
        _entity_pages = {},
        _entity_index = 1,

        _shared_list_index = mn.Scene._shared_consumable_list_index,
        _shared_list_frame = rt.Frame(),
        _shared_tab_bar = mn.TabBar(),

        _shared_move_list = mn.ScrollableList(),
        _shared_equip_list = mn.ScrollableList(),
        _shared_consumable_list = mn.ScrollableList(),
        _shared_template_list = mn.ScrollableList(),

        _verbose_info = mn.VerboseInfoPanel(),

        _control_indicator = nil, -- rt.ControlIndicator
    })
end, {
    _shared_move_list_index = 1,
    _shared_consumable_list_index = 2,
    _shared_equip_list_index = 3,
    _shared_template_list_index = 4,

    _shared_list_sort_mode_order = {
        [mn.ScrollableListSortMode.BY_TYPE] = mn.ScrollableListSortMode.BY_NAME,
        [mn.ScrollableListSortMode.BY_NAME] = mn.ScrollableListSortMode.BY_QUANTITY,
        [mn.ScrollableListSortMode.BY_QUANTITY] = mn.ScrollableListSortMode.BY_ID,
        [mn.ScrollableListSortMode.BY_ID] = mn.ScrollableListSortMode.BY_TYPE,
    },

    _entity_order = {
        ["MC"] = 1,
        ["WILDCARD"] = 1,
        ["RAT"] = 2,
        ["PROF"] = 3,
        ["GIRL"] = 4,
        ["SCOUT"] = 5
    }
})

--- @brief
function mn.Scene:_shared_tab_index_to_list(index)
    meta.assert_number(index)
    if index == self._shared_move_list_index then
        return self._shared_move_list
    elseif index == self._shared_consumable_list_index then
        return self._shared_consumable_list
    elseif index == self._shared_sequip_list_index then
        return self._shared_equip_list
    elseif index == self._shared_template_list_index then
        return self._shared_template_list
    else
        return nil
    end
end

--- @brief
function mn.Scene:_create_from_state(state)
    meta.assert_isa(state, mn.InventoryState)

    local tab_sprite_scale_factor = rt.settings.menu.scene.tab_sprite_scale_factor

    self._entity_pages = {}
    local entities = self._state:list_entities()
    table.sort(entities, function(a, b)
        return self._entity_order[a:get_id()] < self._entity_order[b:get_id()]
    end)

    for entity_i, entity in ipairs(entities) do
        local tab_sprite = rt.Sprite(entity:get_sprite_id())
        local sprite_w, sprite_h = tab_sprite:get_resolution()
        tab_sprite:set_minimum_size(sprite_w * tab_sprite_scale_factor, sprite_h * tab_sprite_scale_factor)
        self._entity_tab_bar:push(tab_sprite)

        local equip_consumable_layout = {}
        local move_layout = {}
        do
            -- split into rows of 4
            local n_move_slots = entity:get_n_move_slots()
            table.insert(move_layout, {})
            for i = 1, n_move_slots do
                table.insert(move_layout[#move_layout], mn.SlotType.MOVE)
                if i % 4 == 0 and i ~= n_move_slots then
                    table.insert(move_layout, {})
                end
            end

            -- single row
            local n_equips = entity:get_n_equip_slots()
            for i = 1, n_equips do
                table.insert(equip_consumable_layout, mn.SlotType.EQUIP)
            end

            for i = 1, entity:get_n_consumable_slots() do
                table.insert(equip_consumable_layout, mn.SlotType.CONSUMABLE)
            end
        end

        local page = {
            info = mn.EntityInfo(entity),
            equips_and_consumables = mn.Slots({equip_consumable_layout}),
            moves = mn.Slots(move_layout)
        }

        local n_moves, moves = self._state:list_move_slots(entity)
        for i = 1, n_moves do
            page.moves:set_object(i, moves[i])
        end

        local n_equips, equips = self._state:list_equip_slots(entity)
        for i = 1, n_equips do
            page.equips_and_consumables:set_object(i, equips[i])
        end

        local n_consumables, consumables = self._state:list_consumable_slots(entity)
        for i = 1, n_consumables do
            page.equips_and_consumables:set_object(i + n_equips, consumables[i])
        end

        page.info:realize()
        page.equips_and_consumables:realize()
        page.moves:realize()
        self._entity_pages[entity_i] = page
    end

    local sprite = rt.Sprite("opal", 19)
    sprite:realize()
    local sprite_w, sprite_h = sprite:get_resolution()
    sprite:set_minimum_size(sprite_w * tab_sprite_scale_factor, sprite_h * tab_sprite_scale_factor)

    self._entity_tab_bar:push(sprite)
    self._entity_tab_bar:set_n_post_aligned_items(1)
    self._entity_tab_bar:set_orientation(rt.Orientation.VERTICAL)
    self._entity_tab_bar:realize()

    for move, quantity in pairs(self._state:list_shared_moves()) do
        self._shared_move_list:add(move, quantity)
    end

    for equip, quantity in pairs(self._state:list_shared_equips()) do
        self._shared_equip_list:add(equip, quantity)
    end

    for consumable, quantity in pairs(self._state:list_shared_consumables()) do
        self._shared_consumable_list:add(consumable, quantity)
    end

    for template in values(self._state:list_templates()) do
        self._shared_template_list:add(template)
    end
end

--- @override
function mn.Scene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    if self._background ~= nil then
        self._background:realize()
    end

    local tab_bar_sprite_id = "menu_icons"
    local tab_sprites = {
        [self._shared_move_list_index] = rt.Sprite(tab_bar_sprite_id, "moves"),
        [self._shared_consumable_list_index] = rt.Sprite(tab_bar_sprite_id, "consumables"),
        [self._shared_equip_list_index] = rt.Sprite(tab_bar_sprite_id, "equips"),
        [self._shared_template_list_index] = rt.Sprite(tab_bar_sprite_id, "templates")
    }

    for i, sprite in ipairs(tab_sprites) do
        local sprite_w, sprite_h = sprite:get_resolution()
        sprite:set_minimum_size(sprite_w * 2, sprite_h * 2)
        self._shared_tab_bar:push(sprite)
    end

    self._shared_tab_bar:set_orientation(rt.Orientation.HORIZONTAL)
    self._shared_tab_bar:set_n_post_aligned_items(1)
    self._shared_tab_bar:realize()

    self:_create_from_state(self._state)

    for widget in range(
        self._shared_move_list,
        self._shared_equip_list,
        self._shared_consumable_list,
        self._shared_template_list,
        self._shared_list_frame,
        self._verbose_info
    ) do
        widget:realize()
    end
end

--- @override
function mn.Scene:size_allocate(x, y, width, height)
    if self._background ~= nil then
        self._background:fit_into(x, y, width, height)
    end

    local padding = rt.settings.frame.thickness
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m

    if self._control_indicator == nil then
        -- dummy control indicator for size negotiation
        self._control_indicator = rt.ControlIndicator({
            {rt.ControlIndicatorButton.ALL_BUTTONS, ""}
        })
        self._control_indicator:realize()
    end

    local current_x, current_y = x + outer_margin, y + outer_margin
    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(x + width - control_w - outer_margin, y + outer_margin, control_w, control_h)

    current_y = current_y + control_h + m

    -- left side
    local tile_size, max_move_w, max_info_w = NEGATIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for page in values(self._entity_pages) do
        tile_size = math.max(tile_size, select(2, page.equips_and_consumables:measure()))
        max_move_w = math.max(max_move_w, select(1, page.moves:measure()))
        max_info_w = math.max(max_info_w, select(1, page.info:measure()))
    end

    tile_size = math.max(tile_size, 100)
    local page_w = math.ceil(math.max(max_move_w, max_info_w) / tile_size) * tile_size
    page_w = page_w + 0.5 * tile_size

    local tab_w = tile_size
    page_w = (width - 2 * outer_margin - tab_w - 3 * (2 * m)) / 3

    self._entity_tab_bar:fit_into(current_x, current_y, tab_w, height - outer_margin - (current_y - y))
    local entity_bar_selection_nodes = self._entity_tab_bar:get_selection_nodes()

    current_x = current_x + tile_size + 2 * m
    for page in values(self._entity_pages) do
        local slots_h = tile_size
        local page_y = y + height - outer_margin - slots_h
        page.equips_and_consumables:fit_into(current_x, page_y, page_w, slots_h)

        local moves_h = page_w
        page_y = page_y - m - moves_h
        page.moves:fit_into(current_x, page_y, page_w, moves_h)
        page.info:fit_into(current_x, current_y, page_w, page_y - current_y - m)
    end

    local shared_page_w = page_w
    local shared_page_h = (y + height - 2 * m) - current_y
    local shared_tile_size = tile_size * 0.75
    current_x = current_x + m + page_w + m
    local shared_tab_h = shared_tile_size
    self._shared_tab_bar:fit_into(current_x, current_y, shared_page_w, shared_tab_h)

    local verbose_info_w = page_w
    local verbose_info_h = shared_page_h
    local verbose_info_bounds = rt.AABB(
        current_x + m + shared_page_w + m,
        current_y,
        verbose_info_w,
        verbose_info_h
    )
    self._verbose_info:fit_into(verbose_info_bounds)

    current_y = current_y + shared_tab_h + m

    local shared_list_bounds = rt.AABB(current_x, current_y, shared_page_w, shared_page_h - m - shared_tab_h)
    self._shared_list_frame:fit_into(shared_list_bounds)

    local list_xm, list_ym = m, m
    for list in range(
        self._shared_move_list,
        self._shared_equip_list,
        self._shared_consumable_list,
        self._shared_template_list
    ) do
        list:fit_into(
            shared_list_bounds.x + list_xm,
            shared_list_bounds.y + list_ym,
            shared_list_bounds.width - 2 * list_xm,
            shared_list_bounds.height - 2 * list_ym
        )
    end
end

--- @override
function mn.Scene:draw()
    if self._is_realized ~= true then return end

    if self._background ~= nil then
        self._background:draw()
    end

    self._entity_tab_bar:draw()
    local current_page = self._entity_pages[self._entity_index]
    if current_page ~= nil then
        current_page.moves:draw()
        current_page.equips_and_consumables:draw()
        current_page.info:draw()
    end

    if self._control_indicator ~= nil then
        self._control_indicator:draw()
    end

    self._shared_tab_bar:draw()
    self._shared_list_frame:draw()
    self:_shared_tab_index_to_list(self._shared_list_index):draw()

    self._verbose_info:draw()
end

--- @override
function mn.Scene:update(delta)
    if self._background ~= nil then
        self._background:update(delta)
    end

end