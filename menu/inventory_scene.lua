rt.settings.menu.inventory_scene = {
    outer_margin = 2 * rt.settings.margin_unit,
    verbose_info_scroll_speed = 150,
    sprite_factor = 2,
    grabbed_object_sprite_offset = -0.1,
    tile_size = 100
}

--- @class mn.InventoryScene
mn.InventoryScene = meta.new_type("InventoryScene", rt.Scene, function(state)
    meta.assert_isa(state, rt.GameState)
    return meta.new(mn.InventoryScene, {
        _state = state,

        _heading_label = rt.Label(""),
        _heading_frame = rt.Frame(),

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
        _verbose_info_frame = rt.Frame(),
        _selection_graph = rt.SelectionGraph(),
        _grabbed_object_sprite = nil,
        _grabbed_object_sprite_x = 0,
        _grabbed_object_sprite_y = 0,
        _grabbed_object_id = nil,
        _grabbed_object_allowed = false,

        _current_control_indicator_layout = {{rt.ControlIndicatorButton.A, "UNINITIALIZED"}},
        _control_indicator = rt.ControlIndicator(),

        _animation_queue = rt.AnimationQueue(),
        _input_controller = rt.InputController(),

        _template_confirm_load_dialog = rt.MessageDialog(),
        _template_confirm_delete_dialog = rt.MessageDialog(),
        _template_apply_unsuccesfull_dialog = rt.MessageDialog(),
        _template_rename_keyboard = rt.Keyboard(#("New Template #1234"), "New Template"),
    })
end, {
    shared_move_list_index = 1,
    shared_equip_list_index = 2,
    shared_consumable_list_index = 3,
    shared_template_list_index = 4,

    _shared_list_sort_mode_order = {
        [mn.ScrollableListSortMode.BY_NAME] = mn.ScrollableListSortMode.BY_QUANTITY,
        [mn.ScrollableListSortMode.BY_QUANTITY] = mn.ScrollableListSortMode.BY_ID,
        [mn.ScrollableListSortMode.BY_ID] = mn.ScrollableListSortMode.BY_NAME,
    },
})

--- @override
function mn.InventoryScene:realize()
    if self:already_realized() then return end

    local tab_bar_sprite_id = "menu_icons"
    local tab_sprites = {
        [self.shared_move_list_index] = rt.Sprite(tab_bar_sprite_id, "moves"),
        [self.shared_consumable_list_index] = rt.Sprite(tab_bar_sprite_id, "consumables"),
        [self.shared_equip_list_index] = rt.Sprite(tab_bar_sprite_id, "equips"),
        [self.shared_template_list_index] = rt.Sprite(tab_bar_sprite_id, "templates")
    }

    local sprite_factor = rt.settings.menu.inventory_scene.sprite_factor
    for i, sprite in ipairs(tab_sprites) do
        local sprite_w, sprite_h = sprite:get_resolution()
        sprite:set_minimum_size(sprite_w * sprite_factor, sprite_h * sprite_factor)
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
        self._verbose_info,
        self._verbose_info_frame
    ) do
        widget:realize()
    end

    self._heading_label:realize()
    self._heading_frame:realize()

    self._control_indicator = rt.ControlIndicator(self._current_control_indicator_layout)
    self._control_indicator:realize()

    self._input_controller:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

    self._template_confirm_load_dialog = rt.MessageDialog(
        " ", " ", -- set during present()
        rt.MessageDialogOption.ACCEPT, rt.MessageDialogOption.CANCEL
    )
    self._template_confirm_load_dialog:realize()


    self._template_confirm_delete_dialog = rt.MessageDialog(
        " ", " ", -- set during present()
        rt.MessageDialogOption.ACCEPT, rt.MessageDialogOption.CANCEL
    )
    self._template_confirm_delete_dialog:realize()


    self._template_apply_unsuccesfull_dialog = rt.MessageDialog(
        " ", " ", -- set during present()
        rt.MessageDialogOption.ACCEPT
    )
    self._template_apply_unsuccesfull_dialog:realize()
    self._template_rename_keyboard:realize()

    self:create_from_state(self._state)
    self._is_realized = true
end

--- @override
function mn.InventoryScene:create_from_state(state)
    local tab_sprite_scale_factor = 1
    self._state = state
    self._entity_pages = {}

    self._entity_tab_bar:clear()

    local entities = self._state:active_template_list_party()
    table.sort(entities, function(a, b)
        return self._state:active_template_get_entity_index(a) < self._state:active_template_get_entity_index(b)
    end)

    for entity_i, entity in ipairs(entities) do
        local tab_sprite = rt.Sprite(entity:get_config():get_portrait_sprite_id())
        local sprite_w, sprite_h = tab_sprite:get_resolution()
        tab_sprite:set_minimum_size(sprite_w * tab_sprite_scale_factor, sprite_h * tab_sprite_scale_factor)
        self._entity_tab_bar:push(tab_sprite)

        local equip_consumable_layout = {}
        local move_layout = {}
        do
            -- split into rows of 4
            local n_move_slots = self._state:active_template_get_n_move_slots(entity)
            table.insert(move_layout, {})
            for i = 1, n_move_slots do
                table.insert(move_layout[#move_layout], mn.SlotType.MOVE)
                if i % 4 == 0 and i ~= n_move_slots then
                    table.insert(move_layout, {})
                end
            end

            -- single row
            local n_equips = self._state:active_template_get_n_equip_slots(entity)
            for i = 1, n_equips do
                table.insert(equip_consumable_layout, mn.SlotType.EQUIP)
            end

            for i = 1, self._state:active_template_get_n_consumable_slots(entity) do
                table.insert(equip_consumable_layout, mn.SlotType.CONSUMABLE)
            end
        end

        local page = {
            entity = entity,
            info = mn.EntityInfo(
                self._state:active_template_get_hp(entity),
                self._state:active_template_get_attack(entity),
                self._state:active_template_get_defense(entity),
                self._state:active_template_get_speed(entity)
            ),
            equips_and_consumables = mn.Slots({equip_consumable_layout}),
            moves = mn.Slots(move_layout)
        }

        local n_moves, moves = self._state:active_template_list_move_slots(entity)
        for i = 1, n_moves do
            page.moves:set_object(i, moves[i])
        end
        
        local n_equips, equips = self._state:active_template_list_equip_slots(entity)
        for i = 1, n_equips do
            page.equips_and_consumables:set_object(i, equips[i])
        end
        
        local n_consumables, consumables = self._state:active_template_list_consumable_slots(entity)
        for i = 1, n_consumables do
            page.equips_and_consumables:set_object(i + n_equips, consumables[i])
        end

        page.info:realize()

        page.equips_and_consumables:realize()

        page.moves:realize()

        self._entity_pages[entity_i] = page
    end

    local sprite = rt.Sprite("menu_icons", "options")
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
    local outer_margin = rt.settings.menu.inventory_scene.outer_margin

    local current_x, current_y = x + outer_margin, y + outer_margin
    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(x + width - control_w - outer_margin, y + outer_margin, control_w, control_h)

    self:_update_heading_label()

    current_y = current_y + control_h + m

    local tile_size, max_move_w, max_info_w = NEGATIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for page in values(self._entity_pages) do
        tile_size = math.max(tile_size, select(2, page.equips_and_consumables:measure()))
        max_move_w = math.max(max_move_w, select(1, page.moves:measure()))
        max_info_w = math.max(max_info_w, select(1, page.info:measure()))
    end

    tile_size = math.max(tile_size, rt.settings.menu.inventory_scene.tile_size)
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
    self._verbose_info_frame:fit_into(verbose_info_bounds)

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

    self._template_rename_keyboard:fit_into(x, y, width, height)
    self._template_confirm_load_dialog:fit_into(x, y, width, height)
    self._template_confirm_delete_dialog:fit_into(x, y, width, height)
    self._template_apply_unsuccesfull_dialog:fit_into(x, y, width, height)
end

--- @override
function mn.InventoryScene:update(delta)
    if self._is_active ~= true then return end

    self._animation_queue:update(delta)
    self._verbose_info:update(delta)

    self._entity_tab_bar:update(delta)

    if self._template_rename_keyboard:get_is_active() then
        self._template_rename_keyboard:update(delta)
    elseif self._template_confirm_delete_dialog:get_is_active() then
        self._template_confirm_delete_dialog:update(delta)
    elseif self._template_confirm_load_dialog:get_is_active() then
        self._template_confirm_load_dialog:update(delta)
    elseif self._template_apply_unsuccesfull_dialog:get_is_active() then
        self._template_apply_unsuccesfull_dialog:update(delta)
    else
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
    end
end

--- @override
function mn.InventoryScene:draw()
    if not self:get_is_allocated() then return end

    self._entity_tab_bar:draw()
    local current_page = self._entity_pages[self._entity_index]
    if current_page ~= nil then
        current_page.moves:draw()
        current_page.equips_and_consumables:draw()
        current_page.info:draw()
    end

    self._heading_frame:draw()
    self._heading_label:draw()

    self._control_indicator:draw()
    self._shared_tab_bar:draw()
    self._shared_list_frame:draw()
    self:_shared_list_index_to_list(self._shared_list_index):draw()

    if self._grabbed_object_sprite ~= nil then
        rt.graphics.translate(self._grabbed_object_sprite_x, self._grabbed_object_sprite_y)
        self._grabbed_object_sprite:draw()
        rt.graphics.translate(-self._grabbed_object_sprite_x, -self._grabbed_object_sprite_y)
    end

    self._verbose_info_frame:draw()
    self._verbose_info:draw()
    self._animation_queue:draw()

    local template_load_active = self._template_confirm_load_dialog:get_is_active()
    local template_delete_active = self._template_confirm_delete_dialog:get_is_active()
    local template_rename_active = self._template_rename_keyboard:get_is_active()
    local template_load_unsuccesfull_active = self._template_apply_unsuccesfull_dialog:get_is_active()

    if template_load_active then
        self._template_confirm_load_dialog:draw()
    end

    if template_delete_active then
        self._template_confirm_delete_dialog:draw()
    end

    if template_rename_active then
        self._template_rename_keyboard:draw()
    end

    if template_load_unsuccesfull_active then
        self._template_apply_unsuccesfull_dialog:draw()
    end
end

--- @brief
function mn.InventoryScene:_set_control_indicator_layout(layout)
    local shared_layout = {}

    local final_layout = {}
    for x in values(layout) do
        table.insert(final_layout, x)
    end

    if self._verbose_info:can_scroll_up() or self._verbose_info:can_scroll_down() then
        --table.insert(final_layout, {rt.ControlIndicatorButton.L_R, "Scroll"})
    end

    for x in values(shared_layout) do
        table.insert(final_layout, x)
    end

    -- prevent unnecesssary reformats
    local no_change = true
    local n = sizeof(final_layout)
    if n == sizeof(self._current_control_indicator_layout) then
        for i = 1, n do
            local pair_a = final_layout[i]
            local pair_b = self._current_control_indicator_layout[i]

            if pair_a[1] ~= pair_b[1] or pair_a[2] ~= pair_b[2] then
                no_change = false
                break
            end
        end
    else
        no_change = false
    end
    if no_change == true then return end

    self._current_control_indicator_layout = final_layout
    self._control_indicator:create_from(final_layout)

    local outer_margin = rt.settings.margin_unit * 2
    local control_w, control_h = self._control_indicator:measure()

    self._control_indicator:fit_into(
        self._bounds.x + self._bounds.width - control_w - outer_margin,
        self._bounds.y + outer_margin, control_w, control_h
    )
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
    if self._is_active ~= true then return end

    local dialog_active = self._template_rename_keyboard:get_is_active() or
        self._template_confirm_load_dialog:get_is_active() or
        self._template_confirm_delete_dialog:get_is_active() or
        self._template_apply_unsuccesfull_dialog:get_is_active()

    if dialog_active then
        -- noop
    else
        local current_node = self._selection_graph:get_current_node()
        if current_node == nil then return end

        local is_grabbing = self._state:has_grabbed_object()
        local current_shared_list = self:_shared_list_index_to_list(self._shared_list_index)

        if current_node.is_shared_list_node and not is_grabbing and which == rt.InputButton.UP then
            if current_shared_list:move_up() then
                self:_set_verbose_info_object(current_shared_list:get_selected_object())
            else
                self._selection_graph:handle_button(rt.InputButton.UP)  -- escape from list scroll
            end
        elseif current_node.is_shared_list_node and not is_grabbing and which == rt.InputButton.DOWN then
            if current_shared_list:move_down() then
                self:_set_verbose_info_object(current_shared_list:get_selected_object())
            end
        else
            local before = self._selection_graph:get_current_node()
            self._selection_graph:handle_button(which)
            local after = self._selection_graph:get_current_node()
            if before ~= after then
                self._previous_selection_node = before
            end
        end

        self:_set_control_indicator_layout(self._selection_graph:get_current_node():get_control_layout())
    end
end

--- @brief
function mn.InventoryScene:_set_shared_list_index(tab_i)
    self._shared_list_index = tab_i
    for i = 1, 4 do
        self._shared_tab_bar:set_tab_active(i, i == self._shared_list_index)
    end
end

--- @brief
function mn.InventoryScene:_update_heading_label()
    local name = self._entity_pages[self._entity_index].entity:get_name()
    local prefix = rt.Translation.inventory_scene.heading
    self._heading_label:set_text("<b>" .. prefix .. " > " .. name .. "</b>")
    local heading_w, heading_h = self._heading_label:measure()

    local outer_margin = 2 * rt.settings.margin_unit
    local _, control_h = self._control_indicator:measure()
    local x, y = self._bounds.x, self._bounds.y
    self._heading_frame:fit_into(x + outer_margin, y + outer_margin, heading_w + 2 * outer_margin, control_h)
    self._heading_label:fit_into(x + outer_margin + outer_margin, y + outer_margin + 0.5 * control_h - 0.5 * heading_h, POSITIVE_INFINITY)
end

--- @brief
function mn.InventoryScene:_set_entity_index(entity_i)
    self._entity_index = entity_i
    local n = self._state:active_template_get_party_size()
    for i = 1, n do
        self._entity_tab_bar:set_tab_active(i, i == self._entity_index)
    end
    self:_update_heading_label()
end

--- @brief
function mn.InventoryScene:_get_current_entity()
    local page = self._entity_pages[self._entity_index]
    if page == nil then return nil end
    return page.entity
end

--- @brief
function mn.InventoryScene:_regenerate_selection_nodes()

    local scene = self

    -- nodes

    local shared_tab_nodes = {}
    for node in values(self._shared_tab_bar:get_selection_nodes()) do
        table.insert(shared_tab_nodes, node)
    end

    table.sort(shared_tab_nodes, function(a, b)
        return a:get_bounds().x < b:get_bounds().x
    end)

    local shared_list_nodes = {}
    for index in range(
        self.shared_move_list_index,
        self.shared_consumable_list_index,
        self.shared_equip_list_index,
        self.shared_template_list_index
    ) do
        local node = rt.SelectionGraphNode(self:_shared_list_index_to_list(index):get_bounds())
        node.is_shared_list_node = true
        shared_list_nodes[index] = node
    end

    local shared_move_node = shared_list_nodes[self.shared_move_list_index]
    local shared_consumable_node = shared_list_nodes[self.shared_consumable_list_index]
    local shared_equip_node = shared_list_nodes[self.shared_equip_list_index]
    local shared_template_node = shared_list_nodes[self.shared_template_list_index]

    local entity_tab_nodes = {}
    for node_i, node in ipairs(self._entity_tab_bar:get_selection_nodes()) do
        table.insert(entity_tab_nodes, node)
    end
    table.sort(entity_tab_nodes, function(a, b) return a:get_bounds().y < b:get_bounds().y end)

    local entity_page_nodes = {}
    local n_entities = self._state:active_template_get_party_size()
    for entity_i = 1, n_entities do
        local page = self._entity_pages[entity_i]
        local info_node = rt.SelectionGraphNode(page.info:get_bounds())
        local move_nodes = {}
        local left_move_nodes, bottom_move_nodes, top_move_nodes, right_move_nodes = {}, {}, {}, {}
        for node_i, node in ipairs(page.moves:get_selection_nodes()) do
            if node:get_left() == nil then table.insert(left_move_nodes, node) end
            if node:get_up() == nil then table.insert(top_move_nodes, node) end
            if node:get_right() == nil then table.insert(right_move_nodes, node) end
            if node:get_down() == nil then table.insert(bottom_move_nodes, node) end
            table.insert(move_nodes, node)
            node.slot_i = node_i
        end

        local slot_nodes = {}
        for node_i, node in ipairs(page.equips_and_consumables:get_selection_nodes()) do
            table.insert(slot_nodes, node)
            node.slot_i = node_i
        end
        table.sort(slot_nodes, function(a, b) return a:get_bounds().x < b:get_bounds().x end)

        entity_page_nodes[entity_i] = {
            info_node = info_node,
            move_nodes = move_nodes,
            left_move_nodes = left_move_nodes,
            bottom_move_nodes = bottom_move_nodes,
            top_move_nodes = top_move_nodes,
            right_move_nodes = right_move_nodes,
            slot_nodes = slot_nodes
        }
    end

    local verbose_info_node = rt.SelectionGraphNode(self._verbose_info:get_bounds())

    -- action conditions

    local shared_list_allow_take = function()
        return not scene._state:has_grabbed_object()
    end

    local shared_list_allow_deposit = function()
        local grabbed = scene._state:peek_grabbed_object()
        if grabbed == nil then return end
        if scene._shared_list_index == scene.shared_move_list_index then
            return meta.isa(grabbed, bt.MoveConfig)
        elseif scene._shared_list_index == scene.shared_equip_list_index then
            return meta.isa(grabbed, bt.EquipConfig)
        elseif scene._shared_list_index == scene.shared_consumable_list_index then
            return meta.isa(grabbed, bt.ConsumableConfig)
        else
            return false
        end
    end

    local shared_list_allow_equip = function()
        if scene._state:has_grabbed_object() then
            return false
        end

        local current_entity = scene:_get_current_entity()
        if scene._shared_list_index == scene.shared_move_list_index then
            -- inventory full
            if scene._state:active_template_get_first_free_move_slot(current_entity) == nil then
                return false
            end

            -- or more already present
            local selected_move = scene._shared_move_list:get_selected_object()
            return not scene._state:active_template_has_move(current_entity, selected_move)
        elseif scene._shared_list_index == scene.shared_equip_list_index then
            -- inventory full
            return scene._state:active_template_get_first_free_equip_slot(current_entity) ~= nil
        elseif scene._shared_list_index == scene.shared_consumable_list_index then
            -- inventory full
            return scene._state:active_template_get_first_free_consumable_slot(current_entity) ~= nil
        else
            return false
        end
    end

    local shared_list_allow_sort = function()
        return not scene._state:has_grabbed_object()
    end

    local template_list_allow_load = function()
        return not scene._state:has_grabbed_object()
    end

    local template_list_allow_rename = function()
        return not scene._state:has_grabbed_object()
    end

    local template_list_allow_delete = function()
        return not scene._state:has_grabbed_object()
    end

    local move_slot_allow_take = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_move(entity, slot_i)

        return up == nil and down ~= nil
    end

    local equip_slot_allow_take = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_equip(entity, slot_i)

        return up == nil and down ~= nil
    end

    local consumable_slot_allow_take = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i - self._state:active_template_get_n_equip_slots(entity)
        local down = scene._state:active_template_get_consumable(entity, slot_i)

        return up == nil and down ~= nil
    end

    local move_slot_allow_deposit = function()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        if slot_i == nil then return false end

        local grabbed = scene._state:peek_grabbed_object()
        if grabbed == nil or not meta.isa(grabbed, bt.MoveConfig) then return false end

        local slot_is_free = scene._state:active_template_get_move(entity, slot_i) == nil
        local entity_has_move = scene._state:active_template_has_move(entity, grabbed)
        return slot_is_free and not entity_has_move
    end

    local equip_slot_allow_deposit = function()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        if slot_i == nil then return false end

        local grabbed = scene._state:peek_grabbed_object()
        if grabbed == nil or not meta.isa(grabbed, bt.EquipConfig) then return false end

        return scene._state:active_template_get_equip(entity, slot_i) == nil
    end

    local consumable_slot_allow_deposit = function()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i - self._state:active_template_get_n_consumable_slots(entity)
        if slot_i == nil then return false end

        local grabbed = scene._state:peek_grabbed_object()
        if grabbed == nil or not meta.isa(grabbed, bt.ConsumableConfig) then return false end

        return scene._state:active_template_get_consumable(entity, slot_i) == nil
    end

    local move_slot_allow_swap = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_move(entity, slot_i)

        return meta.isa(up, bt.MoveConfig) and down ~= nil and (not scene._state:active_template_has_move(entity, down))
    end

    local equip_slot_allow_swap = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_equip(entity, slot_i)

        return meta.isa(up, bt.EquipConfig) and down ~= nil
    end

    local consumable_slot_allow_swap = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i - self._state:active_template_get_n_equip_slots(entity)
        local down = scene._state:active_template_get_consumable(entity, slot_i)

        return meta.isa(up, bt.ConsumableConfig) and down ~= nil
    end

    local move_slot_allow_unequip = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_move(entity, slot_i)
        return up ~= nil or down ~= nil
    end

    local equip_slot_allow_unequip = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_equip(entity, slot_i)

        return up ~= nil or down ~= nil
    end

    local consumable_slot_allow_unequip = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i - self._state:active_template_get_n_equip_slots(entity)
        local down = scene._state:active_template_get_consumable(entity, slot_i)

        return up ~= nil or down ~= nil
    end

    local slots_allow_sort = function()
        return not scene._state:has_grabbed_object()
    end

    -- control indicator layouts

    local consumable_name = rt.settings.battle.consumable.name
    local equip_name = rt.settings.battle.equip.name
    local move_name = rt.settings.battle.move.name

    local disable = function(label)
        return "<s><color=GRAY>" .. label .. "</s></color>"
    end


    local function sort_mode_to_label(mode)
        local next = self._shared_list_sort_mode_order[mode]
        local translation = rt.Translation.inventory_scene
        if next == mn.ScrollableListSortMode.BY_ID then
            return translation.sort_mode_by_id
        elseif next == mn.ScrollableListSortMode.BY_QUANTITY then
            return translation.sort_mode_by_quantity
        elseif next == mn.ScrollableListSortMode.BY_NAME then
            return translation.sort_mode_by_name
        end
    end

    local control_indicator_translation = rt.Translation.inventory_scene.control_indicator
    local drop_grabbed_object_entry = function()
        if scene._state:peek_grabbed_object() ~= nil then
            return {rt.ControlIndicatorButton.B, control_indicator_translation.drop}
        else
            return nil
        end
    end

    local shared_list_up_down_label = control_indicator_translation.shared_list_up_down

    for node_list_name in range(
        {shared_move_node, scene._shared_move_list, move_name},
        {shared_equip_node, scene._shared_equip_list, equip_name},
        {shared_consumable_node, scene._shared_consumable_list, consumable_name}
    ) do
        local node = node_list_name[1]
        local list = node_list_name[2]
        local name = node_list_name[3]

        node:set_control_layout(function()
            local is_grabbing = scene._state:has_grabbed_object()

            local a_label
            if is_grabbing then
                a_label = control_indicator_translation.deposit_item_f(name)
                if not shared_list_allow_deposit() then
                    a_label = disable(a_label)
                end
            else
                a_label = control_indicator_translation.take_item_f(name)
                if not shared_list_allow_take() then
                    a_label = disable(a_label)
                end
            end

            local x_label = control_indicator_translation.equip_item_f(name)
            if not shared_list_allow_equip() then
                x_label = disable(x_label)
            end

            local y_label = sort_mode_to_label(list:get_sort_mode())

            return {
                {rt.ControlIndicatorButton.A, a_label},
                drop_grabbed_object_entry(),
                {rt.ControlIndicatorButton.X, x_label},
                {rt.ControlIndicatorButton.Y, y_label},
                {rt.ControlIndicatorButton.UP_DOWN, shared_list_up_down_label}
            }
        end)
    end

    shared_template_node:set_control_layout(function()
        local translation = rt.Translation.inventory_scene
        local a_label = translation.template_load
        if not template_list_allow_delete() then
            a_label = disable(a_label)
        end

        local x_label = translation.template_rename
        if not template_list_allow_rename() then
            x_label = disable(x_label)
        end

        local y_label = translation.template_delete
        if not template_list_allow_delete() then
            y_label = disable(y_label)
        end

        return {
            {rt.ControlIndicatorButton.A, a_label},
            drop_grabbed_object_entry(),
            {rt.ControlIndicatorButton.X, x_label},
            {rt.ControlIndicatorButton.Y, y_label},
            {rt.ControlIndicatorButton.UP_DOWN, shared_list_up_down_label}
        }
    end)

    local shared_tab_node_control_layout = function()
        return {
            {rt.ControlIndicatorButton.A, rt.Translation.inventory_scene.shared_tab_select},
            drop_grabbed_object_entry()
        }
    end

    for node in values(shared_tab_nodes) do
        node:set_control_layout(shared_tab_node_control_layout)
    end

    local entity_tab_node_control_layout = function()
        return {
            {rt.ControlIndicatorButton.A, rt.Translation.inventory_scene.entity_tab_select},
            drop_grabbed_object_entry()
        }
    end

    local option_tab_node_control_layout = function()
        return {
            {rt.ControlIndicatorButton.A, rt.Translation.inventory_scene.option_tab_select},
            drop_grabbed_object_entry()
        }
    end

    for node in values(entity_tab_nodes) do
        node:set_control_layout(entity_tab_node_control_layout)
    end
    entity_tab_nodes[#entity_tab_nodes]:set_control_layout(option_tab_node_control_layout)

    verbose_info_node:set_control_layout(function()
        return {
            drop_grabbed_object_entry()
        }
    end)

    local entity_info_node_control_layout = function()
        return {
            drop_grabbed_object_entry()
        }
    end

    local move_node_control_layout = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_move(entity, slot_i)
        local name = move_name

        local translation = rt.Translation.inventory_scene

        local a_label
        if up ~= nil and down == nil then
            a_label = translation.move_node_place_f(name)
            if not move_slot_allow_deposit() then
                a_label = disable(a_label)
            end
        elseif up ~= nil and down ~= nil then
            a_label = translation.move_node_swap_f(name)
            if not move_slot_allow_swap() then
                a_label = disable(a_label)
            end
        elseif up == nil then
            a_label = translation.move_node_take_f(name)
            if not move_slot_allow_take() then
                a_label = disable(a_label)
            end
        end

        local x_label = translation.move_node_unequip
        if not move_slot_allow_unequip() then
            x_label = disable(x_label)
        end

        local y_label = translation.move_node_sort
        if not slots_allow_sort() then
            y_label = disable(y_label)
        end

        return {
            {rt.InputButton.A, a_label},
            drop_grabbed_object_entry(),
            {rt.InputButton.X, x_label},
            {rt.InputButton.Y, y_label}
        }
    end

    local equip_node_control_layout = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_equip(entity, slot_i)
        local translation = rt.Translation.inventory_scene

        local a_label
        if up ~= nil and down == nil then
            a_label = translation.equip_node_place_f(equip_name)
            if not equip_slot_allow_deposit() then
                a_label = disable(a_label)
            end
        elseif up ~= nil and down ~= nil then
            a_label = translation.equip_node_swap_f(equip_name)
            if not equip_slot_allow_swap() then
                a_label = disable(a_label)
            end
        elseif up == nil then
            a_label = translation.equip_node_take_f(equip_name)
            if not equip_slot_allow_take() then
                a_label = disable(a_label)
            end
        end

        local x_label = translation.equip_node_unequip
        if not equip_slot_allow_unequip() then
            x_label = disable(x_label)
        end

        local y_label = translation.equip_node_sort
        if not slots_allow_sort() then
            y_label = disable(y_label)
        end

        return {
            {rt.InputButton.A, a_label},
            drop_grabbed_object_entry(),
            {rt.InputButton.X, x_label},
            {rt.InputButton.Y, y_label}
        }
    end

    local consumable_node_control_layout = function()
        local up = scene._state:peek_grabbed_object()
        local entity = scene:_get_current_entity()
        local slot_i = scene._selection_graph:get_current_node().slot_i
        local down = scene._state:active_template_get_consumable(entity, slot_i - self._state:active_template_get_n_equip_slots(entity))
        local translation = rt.Translation.inventory_scene

        local a_label
        if up ~= nil and down == nil then
            a_label = translation.consumable_node_place_f(consumable_name)
            if not consumable_slot_allow_deposit() then
                a_label = disable(a_label)
            end
        elseif up ~= nil and down ~= nil then
            a_label = translation.consumable_node_swap_f(consumable_name)
            if not consumable_slot_allow_swap() then
                a_label = disable(a_label)
            end
        elseif up == nil then
            a_label = translation.consumable_node_take_f(consumable_name)
            if not consumable_slot_allow_take() then
                a_label = disable(a_label)
            end
        end

        local x_label = translation.consumable_node_unequip
        if not consumable_slot_allow_unequip() then
            x_label = disable(x_label)
        end

        local y_label = translation.consumable_node_sort
        if not slots_allow_sort() then
            y_label = disable(y_label)
        end

        return {
            {rt.InputButton.A, a_label},
            drop_grabbed_object_entry(),
            {rt.InputButton.X, x_label},
            {rt.InputButton.Y, y_label}
        }
    end

    for page_i, node_page in ipairs(entity_page_nodes) do
        node_page.info_node:set_control_layout(entity_info_node_control_layout)

        for move_node in values(node_page.move_nodes) do
            move_node:set_control_layout(move_node_control_layout)
        end

        local entity = scene._entity_pages[page_i].entity
        local n_equip_slots = self._state:active_template_get_n_equip_slots(entity)
        for slot_i, node in ipairs(node_page.slot_nodes) do
            if slot_i <= n_equip_slots then
                node:set_control_layout(equip_node_control_layout)
            else
                node:set_control_layout(consumable_node_control_layout)
            end
        end
    end

    -- linking

    local function find_nearest_node(origin, nodes, mode)
        if mode == "y" then
            local nearest_node = nil
            local y_dist = POSITIVE_INFINITY
            local origin_y = origin:get_bounds().y + 0.5 * origin:get_bounds().height
            for node in values(nodes) do
                local current_dist = math.abs(node:get_bounds().y + 0.5 * node:get_bounds().height - origin_y)
                if current_dist < y_dist then
                    y_dist = current_dist
                    nearest_node = node
                end
            end
            return nearest_node
        elseif mode == "x" then
            local nearest_node = nil
            local x_dist = POSITIVE_INFINITY
            local origin_x = origin:get_bounds().x + 0.5 * origin:get_bounds().width
            for node in values(nodes) do
                local current_dist = math.abs(node:get_bounds().x + 0.5 * node:get_bounds().width - origin_x)
                if current_dist < x_dist then
                    x_dist = current_dist
                    nearest_node = node
                end
            end
            return nearest_node
        else
            error("invalid mode: " .. mode)
        end
    end

    for page in values(entity_page_nodes) do
        local center_node_i
        if #(page.top_move_nodes) % 2 == 0 then
            center_node_i = #(page.top_move_nodes) / 2
        else
            center_node_i = math.floor(#(page.top_move_nodes) / 2) + 1
        end

        page.info_node:set_left(entity_tab_nodes[1])
        page.info_node:set_right(shared_tab_nodes[1])
        page.info_node:set_down(function()
            for node in values(page.top_move_nodes) do
                if node == scene._previous_selection_node then
                    return scene._previous_selection_node
                end
            end
            return page.top_move_nodes[center_node_i]
        end)

        for node in values(page.bottom_move_nodes) do
            node:set_down(function()
                for node in values(page.slot_nodes) do
                    if node == scene._previous_selection_node then
                        return scene._previous_selection_node
                    end
                end
                return find_nearest_node(node, page.slot_nodes, "x")
            end)
        end

        for node in values(page.top_move_nodes) do
            node:set_up(page.info_node)
        end

        for node in values(page.left_move_nodes) do
            node:set_left(find_nearest_node(node, entity_tab_nodes, "y"))
        end

        for node in values(page.right_move_nodes) do
            node:set_right(function()
                return shared_list_nodes[scene._shared_list_index]
            end)
        end

        for node in values(page.slot_nodes) do
            node:set_up(function()
                for node in values(page.bottom_move_nodes) do
                    if node == scene._previous_selection_node then
                        return scene._previous_selection_node
                    end
                end
                return find_nearest_node(node, page.bottom_move_nodes, "x")
            end)
        end

        page.slot_nodes[1]:set_left(entity_tab_nodes[#entity_tab_nodes])
        page.slot_nodes[#(page.slot_nodes)]:set_right(function(_)
            return shared_list_nodes[scene._shared_list_index]
        end)
    end

    for entity_tab_node in values(entity_tab_nodes) do
        local nearest = {}
        for entity_i = 1, n_entities do
            local page = entity_page_nodes[entity_i]
            nearest[entity_i] = find_nearest_node(
                entity_tab_node, {
                    page.info_node, page.slot_nodes[1], table.unpack(page.left_move_nodes)
                }, "y"
            )
        end
        entity_tab_node:set_right(function()
            local page = entity_page_nodes[scene._entity_index]
            for node in range(page.info_node, page.slot_nodes[1], table.unpack(page.left_move_nodes)) do
                if node == scene._previous_selection_node then
                    return scene._previous_selection_node
                end
            end
            return nearest[scene._entity_index]
        end)
    end

    shared_tab_nodes[1]:set_left(function()
        return entity_page_nodes[scene._entity_index].info_node
    end)

    --[[
    shared_tab_nodes[#shared_tab_nodes]:set_right(function()
        return verbose_info_node
    end)
    ]]--

    local shared_list_left = function()
        local page = entity_page_nodes[scene._entity_index]
        for node in values(page.right_move_nodes) do
            if scene._previous_selection_node == node then
                return scene._previous_selection_node
            end
        end
        return entity_page_nodes[scene._entity_index].right_move_nodes[1]
    end

    --[[
    local shared_list_right = function()
        return verbose_info_node
    end
    ]]--

    local shared_list_up = function()
        local is_viable = {}
        for i = 1, 4 do
            if shared_tab_nodes[i] == scene._previous_selection_node then
                return scene._previous_selection_node
            end
        end

        return shared_tab_nodes[scene._shared_list_index]
    end

    for node in values(shared_list_nodes) do
        node:set_left(function(_)
            return shared_list_left()
        end)

        node:set_right(function(_)
            return nil --shared_list_right()
        end)

        node:set_up(function(_)
            return shared_list_up()
        end)
    end

    for node in values(shared_tab_nodes) do
        node:set_down(function(_)
            return shared_list_nodes[scene._shared_list_index]
        end)
    end

    verbose_info_node:set_left(function(_)
        return shared_tab_nodes[#shared_tab_nodes]
    end)

    -- interactivity

    local on_b_undo_grab = function(_)
        if scene._state:peek_grabbed_object() ~= nil then
            scene._undo_grab()
            scene:_update_grabbed_object()
        end
    end

    for entity_i, node in ipairs(entity_tab_nodes) do
        node:signal_connect("enter", function(_)
            scene._entity_tab_bar:set_tab_selected(entity_i, true)
            local page = scene._entity_pages[entity_i]
            if page ~= nil then
                scene:_set_verbose_info_object(page.entity)
            else
                scene:_set_verbose_info_object(rt.VerboseInfoObject.OPTIONS)
            end

            scene:_update_grabbed_object()
            scene:_set_grabbed_object_allowed(false)
        end)

        node:signal_connect("exit", function(_)
            scene._entity_tab_bar:set_tab_selected(entity_i, false)
            scene:_set_verbose_info_object(nil)
        end)

        if entity_i <= n_entities then
            node:signal_connect(rt.InputButton.A, function(_)
                scene:_set_entity_index(entity_i)
            end)
        else
            node:signal_connect(rt.InputButton.A, function(_)
                scene._state:set_current_scene(mn.OptionsScene)
            end)
        end

        node:signal_connect(rt.InputButton.B, on_b_undo_grab)
    end

    for tab_i, node in ipairs(shared_tab_nodes) do
        node:signal_connect("enter", function(_)
            scene._shared_tab_bar:set_tab_selected(tab_i, true)

            if tab_i == scene.shared_move_list_index then
                scene:_set_verbose_info_object(rt.VerboseInfoObject.MOVE)
            elseif tab_i == scene.shared_consumable_list_index then
                scene:_set_verbose_info_object(rt.VerboseInfoObject.CONSUMABLE)
            elseif tab_i == scene.shared_equip_list_index then
                scene:_set_verbose_info_object(rt.VerboseInfoObject.EQUIP)
            elseif tab_i == scene.shared_template_list_index then
                scene:_set_verbose_info_object(rt.VerboseInfoObject.TEMPLATE)
            end
            scene:_update_grabbed_object()
            scene:_set_grabbed_object_allowed(false)
        end)

        node:signal_connect("exit", function(_)
            scene._shared_tab_bar:set_tab_selected(tab_i, false)
        end)

        node:signal_connect(rt.InputButton.A, function(_)
            scene:_set_shared_list_index(tab_i)
        end)

        node:signal_connect(rt.InputButton.B, on_b_undo_grab)
    end

    local try_unequip_grabbed = function()
        local up = scene._state:peek_grabbed_object()
        if up ~= nil then
            scene._state:take_grabbed_object()

            local list, list_i
            if meta.isa(up, bt.MoveConfig) then
                scene._state:add_shared_move(up)
                list = scene._shared_move_list
                list_i = scene.shared_move_list_index
            elseif meta.isa(up, bt.EquipConfig) then
                scene._state:add_shared_equip(up)
                list = scene._shared_equip_list
                list_i = scene.shared_equip_list_index
            elseif meta.isa(up, bt.ConsumableConfig) then
                scene._state:add_shared_consumable(up)
                list = scene._shared_consumable_list
                list_i = scene.shared_consumable_list_index
            end

            scene:_play_transfer_object_animation(
                up,
                scene:_get_grabbed_object_sprite_aabb(),
                list:get_bounds(),
                function()
                    scene:_set_shared_list_index(list_i)
                    scene:_update_grabbed_object()
                end,
                function()
                    list:add(up)
                end
            )
            return true
        else
            return false
        end
    end

    for page_i, node_page in ipairs(entity_page_nodes) do
        node_page.info_node:signal_connect("enter", function(_)
            scene._entity_pages[page_i].info:set_selection_state(rt.SelectionState.ACTIVE)
            scene:_set_verbose_info_object(
                rt.VerboseInfoObject.HP,
                rt.VerboseInfoObject.ATTACK,
                rt.VerboseInfoObject.DEFENSE,
                rt.VerboseInfoObject.SPEED
            )
            scene:_update_grabbed_object()
            scene:_set_grabbed_object_allowed(false)
        end)

        node_page.info_node:signal_connect("exit", function(_)
            scene._entity_pages[page_i].info:set_selection_state(rt.SelectionState.INACTIVE)
        end)

        node_page.info_node:signal_connect(rt.InputButton.B, on_b_undo_grab)

        local slots_sort_on_y = function(_)
            if slots_allow_sort() then
                local page = scene._entity_pages[scene._entity_index]
                local moves, equips, consumables = scene._state:entity_sort_inventory(page.entity)

                page.moves:clear()
                page.equips_and_consumables:clear()

                for i, move in ipairs(moves) do
                    page.moves:set_object(i, move)
                end

                local n_equip_slots = page.self._state:entity_get_n_equip_slots(entity)
                for i, equip in ipairs(equips) do
                    page.equips_and_consumables:set_object(i, equip)
                end

                for i, consumable in ipairs(consumables) do
                    page.equips_and_consumables:set_object(i + n_equip_slots, consumable)
                end
            end
        end

        for node_i, node in ipairs(node_page.move_nodes) do
            node:signal_connect("enter", function(_)
                local page = scene._entity_pages[page_i]
                local slots = page.moves
                slots:set_selection_state(rt.SelectionState.ACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.ACTIVE)

                local object = scene._state:active_template_get_move(page.entity, node_i)
                if object == nil and not scene._state:has_grabbed_object() then
                    scene:_set_verbose_info_object(rt.VerboseInfoObject.MOVE)
                else
                    scene:_set_verbose_info_object(object)
                end

                scene:_update_grabbed_object()
                local grabbed = scene._state:peek_grabbed_object()
                scene:_set_grabbed_object_allowed(move_slot_allow_deposit() or move_slot_allow_swap())
            end)

            node:signal_connect("exit", function(_)
                local slots = scene._entity_pages[page_i].moves
                slots:set_selection_state(rt.SelectionState.INACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.INACTIVE)
            end)

            node:signal_connect(rt.InputButton.B, on_b_undo_grab)

            node:signal_connect(rt.InputButton.A, function(_)
                local page = scene._entity_pages[page_i]

                local up = scene._state:peek_grabbed_object()
                local down = scene._state:active_template_get_move(page.entity, node_i)

                if up ~= nil and down == nil and move_slot_allow_deposit() then
                    scene._state:take_grabbed_object()
                    scene._state:active_template_add_move(page.entity, node_i, up)

                    page.moves:set_object(node_i, up)
                    scene:_update_grabbed_object()
                    scene._undo_grab = function() end
                elseif up == nil and down ~= nil and move_slot_allow_take() then
                    scene._state:set_grabbed_object(down)
                    scene._state:active_template_remove_move(page.entity, node_i)

                    page.moves:set_object(node_i, nil)
                    scene:_update_grabbed_object()
                    scene:_set_grabbed_object_allowed(true)

                    scene._undo_grab = function()
                        scene:_set_entity_index(page_i)
                        scene._state:active_template_add_move(page.entity, node_i, down)
                        scene._state:take_grabbed_object()
                        scene:_play_transfer_object_animation(
                            down,
                            scene:_get_grabbed_object_sprite_aabb(),
                            page.moves:get_slot_aabb(node_i),
                            function() end,
                            function()
                                page.moves:set_object(node_i, scene._state:active_template_get_move(page.entity, node_i))
                                scene:_update_grabbed_object()
                            end
                        )
                    end
                elseif up ~= nil and down ~= nil and move_slot_allow_swap() then
                    local new_equipped = scene._state:take_grabbed_object()
                    local new_grabbed = scene._state:active_template_remove_move(page.entity, node_i)

                    scene._state:set_grabbed_object(new_grabbed)
                    scene._state:active_template_add_move(page.entity, node_i, new_equipped)

                    page.moves:set_object(node_i, new_equipped)
                    scene:_update_grabbed_object()
                    scene:_set_grabbed_object_allowed(true)

                    scene._undo_grab = function()
                        scene:_set_entity_index(page_i)
                        scene._state:active_template_add_move(page.entity, node_i, new_grabbed)
                        scene._state:set_grabbed_object(new_equipped)
                        scene:_play_transfer_object_animation(
                            down,
                            scene:_get_grabbed_object_sprite_aabb(),
                            page.moves:get_slot_aabb(node_i),
                            function()
                                page.moves:set_object(node_i, nil)
                            end,
                            function()
                                page.moves:set_object(node_i, scene._state:active_template_get_move(page.entity, node_i))
                                scene:_update_grabbed_object()
                            end
                        )
                        scene._undo_grab = function() end
                    end

                end
            end)

            node:signal_connect(rt.InputButton.X, function(_)
                if try_unequip_grabbed() then return end
                if move_slot_allow_unequip() then
                    local page = scene._entity_pages[page_i]
                    local slot_i = node_i
                    local down = scene._state:entity_get_move(page.entity, slot_i)
                    scene._state:entity_remove_move(page.entity, slot_i)
                    scene._state:add_shared_move(down)

                    scene:_play_transfer_object_animation(
                        down,
                        page.moves:get_slot_aabb(node_i),
                        scene._shared_move_list:get_bounds(),
                        function()
                            scene:_set_shared_list_index(scene.shared_move_list_index)
                            page.moves:set_object(node_i, nil)
                        end,
                        function()
                            scene._shared_move_list:add(down)
                        end
                    )
                end
            end)

            node:signal_connect(rt.InputButton.Y, slots_sort_on_y)
        end

        local entity = self._entity_pages[page_i].entity
        local n_equip_slots = self._state:entity_get_n_equip_slots(entity)
        for node_i, node in ipairs(node_page.slot_nodes) do
            node:signal_connect("enter", function(_)
                if node_i <= n_equip_slots then
                    local object = scene._state:entity_get_equip(entity, node_i)
                    if object == nil and not scene._state:has_grabbed_object() then
                        scene:_set_verbose_info_object(rt.VerboseInfoObject.EQUIP)
                    else
                        scene:_set_verbose_info_object(object)
                    end
                    scene:_set_grabbed_object_allowed(equip_slot_allow_deposit() or equip_slot_allow_swap())
                    scene:_update_entity_info_preview(node_i)
                else
                    local object = scene._state:entity_get_consumable(entity, node_i - n_equip_slots)
                    if object == nil and not scene._state:has_grabbed_object() then
                        scene:_set_verbose_info_object(rt.VerboseInfoObject.CONSUMABLE)
                    else
                        scene:_set_verbose_info_object(object)
                    end
                    scene:_set_grabbed_object_allowed(consumable_slot_allow_deposit() or consumable_slot_allow_swap())
                    scene:_reset_entity_info_preview()
                end

                local slots = scene._entity_pages[page_i].equips_and_consumables
                slots:set_selection_state(rt.SelectionState.ACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.ACTIVE)
                scene:_update_grabbed_object()
            end)

            node:signal_connect("exit", function(_)
                local slots = scene._entity_pages[page_i].equips_and_consumables
                slots:set_selection_state(rt.SelectionState.INACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.INACTIVE)
                scene:_reset_entity_info_preview()
            end)

            node:signal_connect(rt.InputButton.B, on_b_undo_grab)

            node:signal_connect(rt.InputButton.A, function(_)
                local page = scene._entity_pages[page_i]
                if node_i <= n_equip_slots then
                    local up = scene._state:peek_grabbed_object()
                    local down = scene._state:entity_get_equip(page.entity, node_i)

                    if up ~= nil and down == nil and equip_slot_allow_deposit() then
                        scene._state:take_grabbed_object()
                        scene._state:entity_add_equip(page.entity, node_i, up)

                        page.equips_and_consumables:set_object(node_i, up)
                        scene:_update_grabbed_object()
                        scene._undo_grab = function() end
                    elseif up == nil and down ~= nil and equip_slot_allow_take() then
                        scene._state:set_grabbed_object(down)
                        scene._state:entity_remove_equip(page.entity, node_i)

                        page.equips_and_consumables:set_object(node_i, nil)
                        scene:_update_grabbed_object()
                        scene:_set_grabbed_object_allowed(true)

                        scene._undo_grab = function()
                            scene:_set_entity_index(page_i)
                            scene._state:entity_add_equip(page.entity, node_i, down)
                            scene._state:take_grabbed_object()
                            scene:_play_transfer_object_animation(
                                down,
                                scene:_get_grabbed_object_sprite_aabb(),
                                page.equips_and_consumables:get_slot_aabb(node_i),
                                function()  end,
                                function()
                                    page.equips_and_consumables:set_object(node_i, scene._state:entity_get_equip(page.entity, node_i))
                                    scene:_update_grabbed_object()
                                end
                            )
                        end
                    elseif up ~= nil and down ~= nil and equip_slot_allow_swap() then
                        local new_equipped = scene._state:take_grabbed_object()
                        local new_grabbed = scene._state:entity_remove_equip(page.entity, node_i)

                        scene._state:set_grabbed_object(new_grabbed)
                        scene._state:entity_add_equip(page.entity, node_i, new_equipped)

                        page.equips_and_consumables:set_object(node_i, new_equipped)
                        scene:_update_grabbed_object()
                        scene:_set_grabbed_object_allowed(true)

                        scene._undo_grab = function()
                            scene:_set_entity_index(page_i)
                            scene._state:entity_add_equip(page.entity, node_i, new_grabbed)
                            scene._state:set_grabbed_object(new_equipped)
                            scene:_play_transfer_object_animation(
                                down,
                                scene:_get_grabbed_object_sprite_aabb(),
                                page.equips_and_consumables:get_slot_aabb(node_i),
                                function()
                                    page.equips_and_consumables:set_object(node_i, nil)
                                end,
                                function()
                                    page.equips_and_consumables:set_object(node_i, scene._state:entity_get_equip(page.entity, node_i))
                                    scene:_update_grabbed_object()
                                end
                            )
                            scene._undo_grab = function() end
                        end
                    end
                    
                    scene:_update_entity_info()
                    scene:_update_entity_info_preview(node_i)
                else
                    local up = scene._state:peek_grabbed_object()
                    local slot_i = node_i - page.self._state:entity_get_n_equip_slots(entity)
                    local down = scene._state:entity_get_consumable(page.entity, slot_i)
                    if up ~= nil and down == nil and consumable_slot_allow_deposit() then
                        scene._state:take_grabbed_object()
                        scene._state:entity_add_consumable(page.entity, slot_i, up)

                        page.equips_and_consumables:set_object(node_i, up)
                        scene:_update_grabbed_object()
                        scene._undo_grab = function() end
                    elseif up == nil and down ~= nil and consumable_slot_allow_take() then
                        scene._state:set_grabbed_object(down)
                        scene._state:entity_remove_consumable(page.entity, slot_i)

                        page.equips_and_consumables:set_object(node_i, nil)
                        scene:_update_grabbed_object()
                        scene:_set_grabbed_object_allowed(true)

                        scene._undo_grab = function()
                            scene:_set_entity_index(page_i)
                            scene._state:entity_add_consumable(page.entity, slot_i, down)
                            scene._state:take_grabbed_object()
                            scene:_play_transfer_object_animation(
                                down,
                                scene:_get_grabbed_object_sprite_aabb(),
                                page.equips_and_consumables:get_slot_aabb(node_i),
                                function()  end,
                                function()
                                    page.equips_and_consumables:set_object(node_i, scene._state:entity_get_consumable(page.entity, node_i))
                                    scene:_update_grabbed_object()
                                end
                            )
                        end
                    elseif up ~= nil and down ~= nil and consumable_slot_allow_swap() then
                        local new_equipped = scene._state:take_grabbed_object()
                        local new_grabbed = scene._state:entity_remove_consumable(page.entity, slot_i)

                        scene._state:set_grabbed_object(new_grabbed)
                        scene._state:entity_add_consumable(page.entity, slot_i, new_equipped)

                        page.equips_and_consumables:set_object(node_i, new_equipped)
                        scene:_update_grabbed_object()
                        scene:_set_grabbed_object_allowed(true)

                        scene._undo_grab = function()
                            scene:_set_entity_index(page_i)
                            scene._state:entity_add_consumable(page.entity, slot_i, new_grabbed)
                            scene._state:set_grabbed_object(new_equipped)
                            scene:_play_transfer_object_animation(
                                down,
                                scene:_get_grabbed_object_sprite_aabb(),
                                page.equips_and_consumables:get_slot_aabb(node_i),
                                function()
                                    page.equips_and_consumables:set_object(node_i, nil)
                                end,
                                function()
                                    page.equips_and_consumables:set_object(node_i, scene._state:entity_get_consumable(page.entity, node_i))
                                    scene:_update_grabbed_object()
                                end
                            )
                            scene._undo_grab = function() end
                        end
                    end
                end
            end)

            node:signal_connect(rt.InputButton.X, function(_)
                if try_unequip_grabbed() then return end

                local page = scene._entity_pages[page_i]
                local slot_i = node_i
                local n_equip_slots = page.self._state:entity_get_n_equip_slots(entity)
                if slot_i <= n_equip_slots then
                    if equip_slot_allow_unequip() then
                        local down = scene._state:entity_get_equip(page.entity, slot_i)
                        scene._state:entity_remove_equip(page.entity, slot_i)
                        scene._state:add_shared_equip(down)
                        assert(meta.isa(down, bt.EquipConfig))

                        scene:_play_transfer_object_animation(
                            down,
                            page.equips_and_consumables:get_slot_aabb(node_i),
                            scene._shared_equip_list:get_bounds(),
                            function()
                                scene:_set_shared_list_index(scene.shared_equip_list_index)
                                page.equips_and_consumables:set_object(node_i, nil)
                            end,
                            function()
                                scene._shared_equip_list:add(down)
                            end
                        )
                    end
                else
                    if consumable_slot_allow_unequip() then
                        local down = scene._state:entity_get_consumable(page.entity, slot_i - n_equip_slots)
                        scene._state:entity_remove_consumable(page.entity, slot_i - n_equip_slots)
                        scene._state:add_shared_consumable(down)
                        assert(meta.isa(down, bt.ConsumableConfig))

                        scene:_play_transfer_object_animation(
                            down,
                            page.equips_and_consumables:get_slot_aabb(node_i),
                            scene._shared_consumable_list:get_bounds(),
                            function()
                                scene:_set_shared_list_index(scene.shared_consumable_list_index)
                                page.equips_and_consumables:set_object(node_i, nil)
                            end,
                            function()
                                scene._shared_consumable_list:add(down)
                            end
                        )
                    end
                end
                scene:_update_entity_info()
                scene:_update_entity_info_preview(node_i)
            end)

            node:signal_connect(rt.InputButton.Y, slots_sort_on_y)
        end
    end

    for node_list_type in range(
        {shared_move_node, scene._shared_move_list, bt.MoveConfig},
        {shared_equip_node, scene._shared_equip_list, bt.EquipConfig},
        {shared_consumable_node, scene._shared_consumable_list, bt.ConsumableConfig}
    ) do
        local node, list, type = table.unpack(node_list_type)
        node:signal_connect("enter", function(_)
            scene._shared_list_frame:set_selection_state(rt.SelectionState.ACTIVE)
            list:set_selection_state(rt.SelectionState.ACTIVE)

            scene:_set_verbose_info_object(list:get_selected_object())
            scene:_update_grabbed_object()
            scene:_set_grabbed_object_allowed(meta.isa(scene._state:peek_grabbed_object(), type))
        end)

        node:signal_connect("exit", function(_)
            list:set_selection_state(rt.SelectionState.INACTIVE)
            scene._shared_list_frame:set_selection_state(rt.SelectionState.INACTIVE)
        end)

        node:signal_connect(rt.InputButton.Y, function(_)
            list:set_sort_mode(scene._shared_list_sort_mode_order[list:get_sort_mode()])
        end)

        node:signal_connect(rt.InputButton.B, on_b_undo_grab)

        node:signal_connect(rt.InputButton.A, function(_)
            local up = scene._state:peek_grabbed_object()
            if up ~= nil and shared_list_allow_deposit() then
                list:add(up)
                scene._state:take_grabbed_object()
                scene._state:add_shared_object(up)
                scene:_set_grabbed_object_allowed(shared_list_allow_take())
                scene._undo_grab = function() end
            elseif up == nil and shared_list_allow_take() then
                local object = list:get_selected_object()
                list:take(object)
                scene._state:set_grabbed_object(object)
                scene:_set_grabbed_object_allowed(shared_list_allow_deposit())
                scene._undo_grab = function()
                    local grabbed = scene._state:take_grabbed_object()
                    scene._state:add_shared_object(grabbed)
                    scene:_play_transfer_object_animation(grabbed,
                        scene:_get_grabbed_object_sprite_aabb(),
                        scene._shared_move_list:get_bounds(),
                        nil,
                        function()
                            scene._shared_move_list:add(grabbed)
                        end
                    )
                    scene._undo_grab = function() end
                end
            end

            scene:_update_grabbed_object()
        end)

        node:signal_connect(rt.InputButton.Y, function(_)
            list:set_sort_mode(scene._shared_list_sort_mode_order[list:get_sort_mode()])
        end)
    end

    shared_move_node:signal_connect(rt.InputButton.X, function(_)
        if shared_list_allow_equip() then
            local to_equip = scene._shared_move_list:get_selected_object()
            local page = scene._entity_pages[scene._entity_index]
            local entity = page.entity
            local slot_i = scene._state:entity_get_first_free_move_slot(entity)
            assert(slot_i ~= nil and scene._state:entity_has_move(entity, to_equip) == false)

            scene._state:remove_shared_move(to_equip)
            scene._state:entity_add_move(entity, slot_i, to_equip)
            scene:_play_transfer_object_animation(
                to_equip,
                scene._shared_move_list:get_item_aabb(scene._shared_move_list:get_selected_item_i()),
                page.moves:get_slot_aabb(slot_i),
                function()
                    scene._shared_move_list:take(to_equip)
                end,
                function()
                    page.moves:set_object(slot_i, to_equip)
                end
            )
        end
    end)

    shared_equip_node:signal_connect(rt.InputButton.X, function(_)
        if shared_list_allow_equip() then
            local to_equip = scene._shared_equip_list:get_selected_object()
            local page = scene._entity_pages[scene._entity_index]
            local entity = page.entity
            local slot_i = scene._state:entity_get_first_free_equip_slot(entity)
            assert(slot_i ~= nil)

            scene._state:remove_shared_equip(to_equip)
            scene._state:entity_add_equip(entity, slot_i, to_equip)
            scene:_update_entity_info()
            scene:_play_transfer_object_animation(
                to_equip,
                scene._shared_equip_list:get_item_aabb(scene._shared_equip_list:get_selected_item_i()),
                page.equips_and_consumables:get_slot_aabb(slot_i),
                function()
                    scene._shared_equip_list:take(to_equip)
                end,
                function()
                    page.equips_and_consumables:set_object(slot_i, to_equip)
                end
            )
        end
    end)

    shared_consumable_node:signal_connect(rt.InputButton.X, function(_)
        if shared_list_allow_equip() then
            local to_equip = scene._shared_consumable_list:get_selected_object()
            local page = scene._entity_pages[scene._entity_index]
            local entity = page.entity
            local slot_i = scene._state:entity_get_first_free_consumable_slot(entity)
            local n_equip_slots = self._state:entity_get_n_equip_slots(entity)
            assert(slot_i ~= nil)

            scene._state:remove_shared_consumable(to_equip)
            scene._state:entity_add_consumable(entity, slot_i, to_equip)
            scene:_play_transfer_object_animation(
                to_equip,
                scene._shared_consumable_list:get_item_aabb(scene._shared_consumable_list:get_selected_item_i()),
                page.equips_and_consumables:get_slot_aabb(slot_i + n_equip_slots),
                function()
                    scene._shared_consumable_list:take(to_equip)
                end,
                function()
                    page.equips_and_consumables:set_object(slot_i + n_equip_slots, to_equip)
                end
            )
        end
    end)

    shared_template_node:signal_connect("enter", function(_)
        scene._shared_template_list:set_selection_state(rt.SelectionState.ACTIVE)
        scene._shared_list_frame:set_selection_state(rt.SelectionState.ACTIVE)
        scene:_set_verbose_info_object(scene._shared_template_list:get_selected_object())
        scene:_update_grabbed_object()
        scene:_set_grabbed_object_allowed(false)
    end)

    shared_template_node:signal_connect("exit", function(_)
        scene._shared_template_list:set_selection_state(rt.SelectionState.INACTIVE)
        scene._shared_list_frame:set_selection_state(rt.SelectionState.INACTIVE)
    end)

    shared_template_node:signal_connect(rt.InputButton.B, on_b_undo_grab)

    scene._template_apply_unsuccesfull_dialog:signal_disconnect_all()
    scene._template_apply_unsuccesfull_dialog:signal_connect("selection", function(self, option_index)
        self:close()
    end)

    scene._template_confirm_load_dialog:signal_disconnect_all()
    scene._template_confirm_load_dialog:signal_connect("selection", function(self, option_index)
        if option_index == rt.MessageDialogOption.ACCEPT then
            local current = scene._shared_template_list:get_selected_object()
            if current ~= nil then
                local success = scene._state:load_template(current)
                local clock = rt.Clock()
                scene:create_from_state(scene._state)
                scene:reformat()

                if success == false then
                    scene._template_apply_unsuccesfull_dialog:set_message(
                        rt.Translation.inventory_scene.template_apply_unsuccessful_dialog_f(current:get_name())
                    )
                    scene._template_apply_unsuccesfull_dialog:present()
                end
            end
        end

        scene._template_confirm_load_dialog:close()
    end)

    shared_template_node:signal_connect(rt.InputButton.A, function(_)
        if template_list_allow_load() then
            local current = scene._shared_template_list:get_selected_object()
            if current ~= nil then
                scene._template_confirm_load_dialog:set_message(
                    rt.Translation.inventory_scene.template_confirm_dialog_f(current:get_name())
                )
                scene._template_confirm_load_dialog:present()
            end
        end
    end)

    scene._template_rename_keyboard:signal_disconnect_all()
    scene._template_rename_keyboard:signal_connect("accept", function(self, new_name)
        local template = scene._shared_template_list:get_selected_object()
        scene._shared_template_list:take(template)
        scene._state:template_rename(template:get_id(), new_name)
        scene._shared_template_list:add(template)

        self:close()
    end)
    scene._template_rename_keyboard:signal_connect("cancel", function(self)
        self:close()
    end)

    shared_template_node:signal_connect(rt.InputButton.X, function(_)
        if template_list_allow_rename() then
            scene._template_rename_keyboard:present()
        end
    end)

    scene._template_confirm_delete_dialog:signal_disconnect_all()
    scene._template_confirm_delete_dialog:signal_connect("selection", function(self, option_index)
        if option_index == rt.MessageDialogOption.ACCEPT then
            local current = scene._shared_template_list:get_selected_object()
            if current ~= nil then
                scene._state:remove_template(current)
                scene._shared_template_list:take(current)
            end
        end

        scene._template_confirm_delete_dialog:close()
    end)

    shared_template_node:signal_connect(rt.InputButton.Y, function(_)
        if template_list_allow_delete() then
            local current = scene._shared_template_list:get_selected_object()
            if current ~= nil then
                scene._template_confirm_delete_dialog:set_message(rt.Translation.inventory_scene.template_delete_dialog_f(current:get_name()))
                scene._template_confirm_delete_dialog:present()
            end
        end
    end)

    -- push

    self._selection_graph:clear()

    for nodes in range(
        entity_tab_nodes,
        shared_tab_nodes,
        shared_list_nodes,
        {verbose_info_node}
    ) do
        for node in values(nodes) do
            self._selection_graph:add(node)
        end
    end

    for page in values(entity_page_nodes) do
        for nodes in range(
            {page.info_node},
            page.move_nodes,
            page.slot_nodes
        ) do
            for node in values(nodes) do
                self._selection_graph:add(node)
            end
        end
    end

    local current_node = entity_tab_nodes[self._entity_index]
    if current_node ~= nil then
        self._selection_graph:set_current_node(current_node)
    end
    self:_set_control_indicator_layout(self._selection_graph:get_current_node():get_control_layout())
end

--- @override
function mn.InventoryScene:make_active()
    if self._is_realized == false then self:realize() end
    self._is_active = true
    self._input_controller:signal_unblock_all()
end

--- @override
function mn.InventoryScene:make_inactive()
    self._is_active = false
    self._input_controller:signal_block_all()
end

--- @brief
function mn.InventoryScene:_set_verbose_info_object(...)
    self._verbose_info:show(self._state:peek_grabbed_object(), ...)
end

--- @brief
function mn.InventoryScene:_update_grabbed_object()
    local grabbed = self._state:peek_grabbed_object()
    if grabbed == nil then
        if self._grabbed_object_id ~= nil then
            self._grabbed_object_sprite = nil
            self._grabbed_object_id = nil
        end
    else
        local sprite_w, sprite_h
        if grabbed:get_id() ~= self._grabbed_object_id then
            self._grabbed_object_id = grabbed:get_id()
            self._grabbed_object_sprite = rt.Sprite(grabbed:get_sprite_id())
            self._grabbed_object_sprite:set_bottom_right_child(rt.Label(rt.Translation.inventory_scene.grabbed_object_bottom_right_indicator))
            self._grabbed_object_sprite:realize()
            sprite_w, sprite_h = self._grabbed_object_sprite:get_resolution()
            local sprite_factor = rt.settings.menu.inventory_scene.sprite_factor
            sprite_w = sprite_w * sprite_factor
            sprite_h = sprite_h * sprite_factor

            local offset = rt.settings.menu.inventory_scene.grabbed_object_sprite_offset

            self._grabbed_object_sprite:fit_into(-0.5 * sprite_w + offset * sprite_w, -0.5 * sprite_h + offset * sprite_w, sprite_w, sprite_h)
            self._grabbed_object_sprite:set_opacity(0.5)
            self:_set_grabbed_object_allowed(self._grabbed_object_allowed)
        end

        local current = self._selection_graph:get_current_node_aabb()
        self._grabbed_object_sprite_x = current.x + 0.5 * current.width
        self._grabbed_object_sprite_y = current.y + 0.5 * current.height
    end
end

--- @brief
function mn.InventoryScene:_update_entity_info()
    local info = self._entity_pages[self._entity_index].info
    local entity = self._entity_pages[self._entity_index].entity
    info:set_values(
        self._state:entity_get_hp(entity),
        self._state:entity_get_attack(entity),
        self._state:entity_get_defense(entity),
        self._state:entity_get_speed(entity)
    )
end

--- @brief
function mn.InventoryScene:_update_entity_info_preview(equip_slot_i)
    local up = self._state:peek_grabbed_object()
    local page = self._entity_pages[self._entity_index]
    local down = self._state:entity_get_equip(page.entity, equip_slot_i)

    if up ~= nil and meta.isa(up, bt.EquipConfig) then
        page.info:set_preview_values(self._state:entity_preview_equip(page.entity, equip_slot_i, up))
    else
        page.info:set_preview_values(nil, nil, nil, nil)
    end
end

--- @brief
function mn.InventoryScene:_reset_entity_info_preview()
    local page = self._entity_pages[self._entity_index]
    page.info:set_preview_values(nil, nil, nil, nil)
end

--- @brief
function mn.InventoryScene:_set_grabbed_object_allowed(b)
    self._grabbed_object_allowed = b
    if self._grabbed_object_sprite ~= nil then
        self._grabbed_object_sprite:get_bottom_right_child():set_is_visible(not self._grabbed_object_allowed)
    end
end

--- @brief
function mn.InventoryScene:_get_grabbed_object_sprite_aabb()
    if self._grabbed_object_sprite == nil then
        return rt.AABB(0, 0, 1, 1)
    end

    local out = self._grabbed_object_sprite:get_bounds()
    out.x = out.x + self._grabbed_object_sprite_x
    out.y = out.y + self._grabbed_object_sprite_y
    return out
end

--- @brief
function mn.InventoryScene:_play_transfer_object_animation(object, from_aabb, to_aabb, before, after)
    local animation = mn.Animation.OBJECT_MOVED(object, from_aabb, to_aabb)
    animation:signal_connect("start", before)
    animation:signal_connect("finish", after)
    self._animation_queue:append(animation)
end
