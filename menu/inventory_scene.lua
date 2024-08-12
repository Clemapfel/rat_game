rt.settings.menu.inventory_scene = {
    verbose_info_scroll_speed = 150,
    
    template_confirm_load_heading = "Overwrite current Equipment?",
    template_confirm_load_body = "This will return all currently equipped items back to the shared inventory",
    
    template_confirm_delete_heading = "Delete Template permanently?",
    template_confirm_delete_body = "This action cannot be undone"
}

--- @class mn.InventoryScene
mn.InventoryScene = meta.new_type("InventoryScene", rt.Scene, function(state)
    meta.assert_isa(state, rt.GameState)
    return meta.new(mn.InventoryScene, {
        _state = state,

        _entity_tab_bar = mn.TabBar(),
        _entity_pages = {},
        _entity_index = 1,

        _shared_list_index = mn.InventoryScene.shared_move_list_index,
        _shared_list_frame = rt.Frame(),
        _shared_tab_bar = mn.TabBar(),

        _shared_move_list = mn.ScrollableList(),
        _shared_equip_list = mn.ScrollableList(),
        _shared_consumable_list = mn.ScrollableList(),
        _shared_template_list = mn.ScrollableList(),

        _verbose_info = mn.VerboseInfoPanel(),
        _selection_graph = rt.SelectionGraph(),
        _grabbed_object_sprite = nil,
        _grabbed_object_sprite_x = 0,
        _grabbed_object_sprite_y = 0,
        _grabbed_object_id = nil,
        _grabbed_object_allowed = false,

        _control_indicator = nil, -- rt.ControlIndicator

        _animation_queue = rt.AnimationQueue(),
        _input_controller = rt.InputController(),

        _dialog_shadow = rt.Rectangle(0, 0, 1, 1),
        _template_confirm_load_dialog = nil, -- rt.MessageDialog
        _template_confirm_delete_dialog = nil, -- rt.MessageDialog
        _template_rename_keyboard = nil, -- rt.Keyboard
    })
end, {
    shared_move_list_index = 1,
    shared_consumable_list_index = 2,
    shared_equip_list_index = 3,
    shared_template_list_index = 4,

    _shared_list_sort_mode_order = {
        [mn.ScrollableListSortMode.BY_NAME] = mn.ScrollableListSortMode.BY_QUANTITY,
        [mn.ScrollableListSortMode.BY_QUANTITY] = mn.ScrollableListSortMode.BY_ID,
        [mn.ScrollableListSortMode.BY_ID] = mn.ScrollableListSortMode.BY_NAME,
    },
})

--- @override
function mn.InventoryScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local tab_bar_sprite_id = "menu_icons"
    local tab_sprites = {
        [self.shared_move_list_index] = rt.Sprite(tab_bar_sprite_id, "moves"),
        [self.shared_consumable_list_index] = rt.Sprite(tab_bar_sprite_id, "consumables"),
        [self.shared_equip_list_index] = rt.Sprite(tab_bar_sprite_id, "equips"),
        [self.shared_template_list_index] = rt.Sprite(tab_bar_sprite_id, "templates")
    }

    for i, sprite in ipairs(tab_sprites) do
        local sprite_w, sprite_h = sprite:get_resolution()
        sprite:set_minimum_size(sprite_w * 2, sprite_h * 2)
        self._shared_tab_bar:push(sprite)
    end

    self._shared_tab_bar:set_orientation(rt.Orientation.HORIZONTAL)
    self._shared_tab_bar:set_n_post_aligned_items(1)
    self._shared_tab_bar:realize()

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

    self._control_indicator = rt.ControlIndicator({
        {rt.ControlIndicatorButton.ALL_BUTTONS, ""}
    })
    self._control_indicator:realize()

    self._input_controller:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)
    
    self._template_confirm_load_dialog = rt.MessageDialog(
        rt.settings.menu.inventory_scene.template_confirm_load_heading,
        rt.settings.menu.inventory_scene.template_confirm_load_body,
        rt.MessageDialogOption.ACCEPT, rt.MessageDialogOption.CANCEL
    )
    self._template_confirm_load_dialog:realize()

    self._template_confirm_delete_dialog = rt.MessageDialog(
        rt.settings.menu.inventory_scene.template_confirm_delete_heading,
        rt.settings.menu.inventory_scene.template_confirm_delete_body,
        rt.MessageDialogOption.ACCEPT, rt.MessageDialogOption.CANCEL
    )
    self._template_confirm_delete_dialog:realize()
    
    self._template_rename_keyboard = rt.Keyboard(#("New Template #1234"), "New Template")
    self._template_rename_keyboard:realize()

    self:create_from_state(self._state)
end

--- @override
function mn.InventoryScene:create_from_state(state)

    local tab_sprite_scale_factor = 3

    self._entity_pages = {}
    self._entity_tab_bar:clear()

    local entities = self._state:list_entities()
    table.sort(entities, function(a, b)
        return self._state:entity_get_party_index(a) < self._state:entity_get_party_index(b)
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
            entity = entity,
            info = mn.EntityInfo(entity),
            equips_and_consumables = mn.Slots({equip_consumable_layout}),
            moves = mn.Slots(move_layout)
        }

        local n_moves, moves = self._state:entity_list_move_slots(entity)
        for i = 1, n_moves do
            page.moves:set_object(i, moves[i])
        end

        local n_equips, equips = self._state:entity_list_equip_slots(entity)
        for i = 1, n_equips do
            page.equips_and_consumables:set_object(i, equips[i])
        end

        local n_consumables, consumables = self._state:entity_list_consumable_slots(entity)
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

    self._shared_move_list:clear()
    for move, quantity in pairs(self._state:list_shared_move_quantities()) do
        self._shared_move_list:add(move, quantity)
    end

    self._shared_equip_list:clear()
    for equip, quantity in pairs(self._state:list_shared_equip_quantities()) do
        self._shared_equip_list:add(equip, quantity)
    end

    self._shared_consumable_list:clear()
    for consumable, quantity in pairs(self._state:list_shared_consumable_quantities()) do
        self._shared_consumable_list:add(consumable, quantity)
    end

    self._shared_template_list:clear()
    for template in values(self._state:list_templates()) do
        self._shared_template_list:add(template)
    end
end

--- @override
function mn.InventoryScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m

    local current_x, current_y = x + outer_margin, y + outer_margin
    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(x + width - control_w - outer_margin, y + outer_margin, control_w, control_h)

    current_y = current_y + control_h + m

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

    self:_regenerate_selection_nodes()
    self:_set_shared_list_index(self._shared_list_index)
    self:_set_entity_index(self._entity_index)

    local shadow_strength = rt.settings.message_dialog.shadow_strength;
    self._dialog_shadow:set_color(rt.RGBA(shadow_strength, shadow_strength, shadow_strength, 1))
    self._dialog_shadow:resize(x, y, width, height)

    self._template_rename_keyboard:fit_into(x, y, width, height)
    self._template_confirm_load_dialog:fit_into(x,y , width, height)
end

--- @override
function mn.InventoryScene:update(delta)
    self._animation_queue:update(delta)

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

    if self._template_rename_keyboard:get_is_active() then
        self._template_rename_keyboard:update(delta)
    elseif self._template_confirm_delete_dialog:get_is_active() then
        self._template_confirm_delete_dialog:update(delta)
    elseif self._template_confirm_load_dialog:get_is_active() then
        self._template_confirm_load_dialog:update(delta)
    end
end

--- @override
function mn.InventoryScene:draw()
    if self._is_realized ~= true then return end

    self._entity_tab_bar:draw()
    local current_page = self._entity_pages[self._entity_index]
    if current_page ~= nil then
        current_page.moves:draw()
        current_page.equips_and_consumables:draw()
        current_page.info:draw()
    end

    self._control_indicator:draw()
    self._shared_tab_bar:draw()
    self._shared_list_frame:draw()
    self:_shared_list_index_to_list(self._shared_list_index):draw()

    if self._grabbed_object_sprite ~= nil then
        rt.graphics.translate(self._grabbed_object_sprite_x, self._grabbed_object_sprite_y)
        self._grabbed_object_sprite:draw()
        rt.graphics.translate(-self._grabbed_object_sprite_x, -self._grabbed_object_sprite_y)
    end

    self._verbose_info:draw()
    self._animation_queue:draw()
    
    local template_load_active = self._template_confirm_load_dialog:get_is_active()
    local template_delete_active = self._template_confirm_delete_dialog:get_is_active()
    local template_rename_active = self._template_confirm_delete_dialog:get_is_active()

    if template_load_active or template_delete_active or template_rename_active then
        rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
        self._dialog_shadow:draw()
        rt.graphics.set_blend_mode()
    end

    if template_load_active then
        self._template_confirm_load_dialog:draw()
    end

    if template_delete_active then
        self._template_confirm_delete_dialog:draw()
    end

    if template_rename_active then
        self._template_rename_keyboard:draw()
    end
end

--- @brief
function mn.InventoryScene:_shared_list_index_to_list(index)
    meta.assert_number(index)
    if index == self.shared_move_list_index then
        return self._shared_move_list
    elseif index == self.shared_consumable_list_index then
        return self._shared_consumable_list
    elseif index == self.shared_equip_list_index then
        return self._shared_equip_list
    elseif index == self.shared_template_list_index then
        return self._shared_template_list
    else
        rt.error("In mn.InventoryScene:_shared_list_index_to_index: invalid index `" .. index .. "`")
    end
end

--- @brief
function mn.InventoryScene:_handle_button_pressed(which)
    
end


--- @brief
function mn.InventoryScene:_set_shared_list_index(tab_i)
    self._shared_list_index = tab_i
    for i = 1, 4 do
        self._shared_tab_bar:set_tab_active(i, i == self._shared_list_index)
    end
end

--- @brief
function mn.InventoryScene:_set_entity_index(entity_i)
    self._entity_index = entity_i
    local n = self._state:get_n_allies()
    for i = 1, n do
        self._entity_tab_bar:set_tab_active(i, i == self._entity_index)
    end
end

--- @brief
function mn.InventoryScene:_regenerate_selection_nodes()

end