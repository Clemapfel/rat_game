rt.settings.menu.scene = {
    tab_sprite_scale_factor = 3,
    verbose_info_scroll_speed = 150
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

        _selection_graph = mn.SelectionGraph(),
        _grabbed_object = nil,
        _grabbed_object_sprite = nil,

        _control_indicator = nil, -- rt.ControlIndicator
        _input_controller = rt.InputController()
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
function mn.Scene:_shared_list_index_to_list(index)
    meta.assert_number(index)
    if index == self._shared_move_list_index then
        return self._shared_move_list
    elseif index == self._shared_consumable_list_index then
        return self._shared_consumable_list
    elseif index == self._shared_equip_list_index then
        return self._shared_equip_list
    elseif index == self._shared_template_list_index then
        return self._shared_template_list
    else
        rt.error("In mn.Scene:_shared_list_index_to_index: invalid index `" .. index .. "`")
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
            entity = entity,
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

    self._control_indicator = rt.ControlIndicator({
        {rt.ControlIndicatorButton.ALL_BUTTONS, ""}
    })

    self._input_controller:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)
end

--- @override
function mn.Scene:size_allocate(x, y, width, height)
    if self._background ~= nil then
        self._background:fit_into(x, y, width, height)
    end

    local padding = rt.settings.frame.thickness
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m

    self._control_indicator:realize()

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

    self:_regenerate_selection_nodes()
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
    self:_shared_list_index_to_list(self._shared_list_index):draw()

    self._verbose_info:draw()
end

--- @override
function mn.Scene:update(delta)
    if self._background ~= nil then
        self._background:update(delta)
    end

    local speed = rt.settings.menu.scene.verbose_info_scroll_speed
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

--- @brief
function mn.Scene:_regenerate_selection_nodes()

    local entity_tab_control = {
        {rt.ControlIndicatorButton.A, "Select Character"}
    }

    local entity_info_control = {
    }

    local shared_tab_control = {
        {rt.ControlIndicatorButton.A, "Select Tab"}
    }
    
    local shared_list_x_label = "Equip"
    local shared_list_y_label = "Change Sorting"
    local shared_list_up_down_label = "Select"

    local shared_move_control = {
        {rt.ControlIndicatorButton.A, "Take Move"},
        {rt.ControlIndicatorButton.X, shared_list_x_label},
        {rt.ControlIndicatorButton.Y, shared_list_y_label},
        {rt.ControlIndicatorButton.UP_DOWN, shared_list_up_down_label}
    }

    local shared_consumable_control = {
        {rt.ControlIndicatorButton.A, "Take Item"},
        {rt.ControlIndicatorButton.X, shared_list_x_label},
        {rt.ControlIndicatorButton.Y, shared_list_y_label},
        {rt.ControlIndicatorButton.UP_DOWN, shared_list_up_down_label}
    }

    local shared_equip_control = {
        {rt.ControlIndicatorButton.A, "Take Gear"},
        {rt.ControlIndicatorButton.X, shared_list_x_label},
        {rt.ControlIndicatorButton.Y, shared_list_y_label},
        {rt.ControlIndicatorButton.UP_DOWN, shared_list_up_down_label}
    }

    local shared_template_control = {
        {rt.ControlIndicatorButton.A, "Load Template"},
        {rt.ControlIndicatorButton.UP_DOWN, shared_list_up_down_label}
    }

    local verbose_info_control = {
    }
    
    local move_node_control = {
        {rt.ControlIndicatorButton.A, "Take Move"},
        {rt.ControlIndicatorButton.X, "Unequip"},
        {rt.ControlIndicatorButton.Y, "Sort"}
    }
    
    local equip_node_control = {
        {rt.ControlIndicatorButton.A, "Take Gear"},
        {rt.ControlIndicatorButton.X, "Unequip"},
        {rt.ControlIndicatorButton.Y, "Sort"}
    }
    
    local consumable_node_control = {
        {rt.ControlIndicatorButton.A, "Take Item"},
        {rt.ControlIndicatorButton.X, "Unequip"},
        {rt.ControlIndicatorButton.Y, "Sort"}
    }

    local scene = self

    -- shared list tab nodes
    local shared_tab_nodes = {}
    for node in values(self._shared_tab_bar:get_selection_nodes()) do
        table.insert(shared_tab_nodes, node)
    end

    table.sort(shared_tab_nodes, function(a, b)
        return a:get_aabb().x < b:get_aabb().x
    end)

    -- shared list nodes
    local shared_list_nodes = {}
    for index in range(
        self._shared_move_list_index,
        self._shared_consumable_list_index,
        self._shared_equip_list_index,
        self._shared_template_list_index
    ) do
        local node = mn.SelectionGraphNode(self:_shared_list_index_to_list(index):get_bounds())
        node.is_shared_list_node = true
        shared_list_nodes[index] = node
    end
    
    local shared_move_node = shared_list_nodes[self._shared_move_list_index]
    local shared_consumable_node = shared_list_nodes[self._shared_consumable_list_index]
    local shared_equip_node = shared_list_nodes[self._shared_equip_list_index]
    local shared_template_node = shared_list_nodes[self._shared_template_list_index]

    -- entity tab nodes
    local entity_tab_nodes = {}
    for node in values(self._entity_tab_bar:get_selection_nodes()) do
        table.insert(entity_tab_nodes, node)
    end
    table.sort(entity_tab_nodes, function(a, b) return a:get_aabb().y < b:get_aabb().y end)

    -- per-entity page nodes
    local entity_page_nodes = {}
    local n_entities = self._state:get_n_entities()
    for entity_i = 1, n_entities do
        local page = self._entity_pages[entity_i]
        local info_node = mn.SelectionGraphNode(page.info:get_bounds())
        local move_nodes = {}
        local left_move_nodes, bottom_move_nodes, top_move_nodes, right_move_nodes = {}, {}, {}, {}
        for node in values(page.moves:get_selection_nodes()) do
            if node:get_left() == nil then table.insert(left_move_nodes, node) end
            if node:get_up() == nil then table.insert(top_move_nodes, node) end
            if node:get_right() == nil then table.insert(right_move_nodes, node) end
            if node:get_down() == nil then table.insert(bottom_move_nodes, node) end
            table.insert(move_nodes, node)
        end

        local slot_nodes = {}
        for node in values(page.equips_and_consumables:get_selection_nodes()) do
            table.insert(slot_nodes, node)
        end
        table.sort(slot_nodes, function(a, b) return a:get_aabb().x < b:get_aabb().x end)

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

    -- verbose info scroll node
    local verbose_info_node = mn.SelectionGraphNode(self._verbose_info:get_bounds())

    -- linking
    local function find_nearest_node(origin, nodes, mode)
        if mode == "y" then
            local nearest_node = nil
            local y_dist = POSITIVE_INFINITY
            local origin_y = origin:get_aabb().y + 0.5 * origin:get_aabb().height
            for node in values(nodes) do
                local current_dist = math.abs(node:get_aabb().y + 0.5 * node:get_aabb().height - origin_y)
                if current_dist < y_dist then
                    y_dist = current_dist
                    nearest_node = node
                end
            end
            return nearest_node
        elseif mode == "x" then
            local nearest_node = nil
            local x_dist = POSITIVE_INFINITY
            local origin_x = origin:get_aabb().x + 0.5 * origin:get_aabb().width
            for node in values(nodes) do
                local current_dist = math.abs(node:get_aabb().x + 0.5 * node:get_aabb().width - origin_x)
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
        page.info_node:set_down(page.top_move_nodes[center_node_i])

        -- down to slots, unless locked
        for node in values(page.bottom_move_nodes) do
            node:set_down(find_nearest_node(node, page.slot_nodes, "x"))
        end

        -- up to info, unless locked
        for node in values(page.top_move_nodes) do
            node:set_up(page.info_node)
        end

        -- left to nearest entity, unless locked
        for node in values(page.left_move_nodes) do
            node:set_left(find_nearest_node(node, entity_tab_nodes, "y"))
        end

        -- right to shared, unless locked
        for node in values(page.right_move_nodes) do
            node:set_right(shared_list_nodes[scene._shared_list_index])
        end

        -- slots up or down, unless locked
        for node in values(page.slot_nodes) do
            node:set_up(find_nearest_node(node, page.bottom_move_nodes, "x"))
        end

        -- slots left, unless locked
        page.slot_nodes[1]:set_left(entity_tab_nodes[#entity_tab_nodes])

        -- slots right, unless locked
        page.slot_nodes[#(page.slot_nodes)]:set_right(shared_list_nodes[scene._shared_list_index])
    end

    for entity_tab_node in values(entity_tab_nodes) do
        -- precompute nearest node for all entity pages
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
        return entity_page_nodes[scene._entity_index].right_move_nodes[1]
    end

    --[[
    local shared_list_right = function()
        return verbose_info_node
    end
    ]]--

    local shared_list_up = function()
        return shared_tab_nodes[scene._shared_list_index]
    end

    for node in values(shared_list_nodes) do
        node:set_left(shared_list_left)
        node:set_right(shared_list_right)
        node:set_up(shared_list_up)
    end

    local shared_tab_down = function()
        return shared_list_nodes[scene._shared_list_index]
    end

    for node in values(shared_tab_nodes) do
        node:set_down(shared_tab_down)
    end

    --[[
    verbose_info_node:set_left(function()
        return shared_tab_nodes[#shared_tab_nodes]
    end)
    ]]--

    -- interactivity

    for entity_i, node in ipairs(entity_tab_nodes) do
        node:set_on_enter(function()
            scene._entity_tab_bar:set_tab_selected(entity_i, true)
            scene:_set_verbose_info_object(nil) -- TODO: character info
            scene:_set_control_indicator_layout(entity_tab_control)
        end)

        node:set_on_exit(function()
            scene._entity_tab_bar:set_tab_selected(entity_i, false)
        end)

        node:set_on_a(function()
            scene._entity_index = entity_i
        end)
    end

    for page_i, page in ipairs(entity_page_nodes) do
        page.info_node:set_on_enter(function()
            scene._entity_pages[page_i].info:set_selection_state(rt.SelectionState.ACTIVE)
            scene:_set_verbose_info_object("hp", "attack", "defense", "speed")
            scene:_set_control_indicator_layout(entity_info_control)
        end)

        page.info_node:set_on_exit(function()
            scene._entity_pages[page_i].info:set_selection_state(rt.SelectionState.INACTIVE)
        end)

        for node_i, node in ipairs(page.move_nodes) do
            node:set_on_enter(function()
                local page = scene._entity_pages[page_i]
                local slots = page.moves
                slots:set_selection_state(rt.SelectionState.ACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.ACTIVE)

                local object = scene._state:get_move_at(page.entity, node_i)
                if object == nil then
                    scene:_set_verbose_info_object("move")
                else
                    scene:_set_verbose_info_object(object)
                end

                scene:_set_control_indicator_layout(move_node_control)
            end)

            node:set_on_exit(function()
                local slots = scene._entity_pages[page_i].moves
                slots:set_selection_state(rt.SelectionState.INACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.INACTIVE)
            end)

            node:set_on_a(function()
                local page = scene._entity_pages[page_i]

                local down = page.moves:get_object(node_i)
                local up = scene._grabbed_object

                -- TODO
                if down == nil and up == nil then
                    -- noop
                elseif down == nil and up ~= nil then -- put down

                elseif down ~= nil and up == nil then -- pick up

                elseif down ~= nil and up ~= nil then -- swap

                end
            end)

            node:set_on_x(function()
                -- TODO
            end)

            node:set_on_y(function()
                -- TODO
            end)
        end

        local n_equips = scene._entity_pages[page_i].entity:get_n_equip_slots()
        for node_i, node in ipairs(page.slot_nodes) do
            node:set_on_enter(function()
                local page = scene._entity_pages[page_i]
                if node_i <= n_equips then
                    local object = scene._state:get_equip_at(page.entity, node_i)
                    if object == nil then
                        scene:_set_verbose_info_object("equip")
                    else
                        scene:_set_verbose_info_object(object)
                    end
                    scene:_set_control_indicator_layout(equip_node_control)
                else
                    local object = scene._state:get_consumable_at(page.entity, node_i - n_equips)
                    if object == nil then
                        scene:_set_verbose_info_object("consumable")
                    else
                        scene:_set_verbose_info_object(object)
                    end
                    scene:_set_control_indicator_layout(consumable_node_control)
                end

                local slots = page.equips_and_consumables
                slots:set_selection_state(rt.SelectionState.ACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.ACTIVE)
            end)

            node:set_on_exit(function()
                local slots = scene._entity_pages[page_i].equips_and_consumables
                slots:set_selection_state(rt.SelectionState.INACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.INACTIVE)
            end)

            node:set_on_a(function()
                local page = scene._entity_pages[page_i]

                local down = page.moves:get_object(node_i)
                local up = scene._grabbed_object

                -- TODO
                if down == nil and up == nil then
                    -- noop
                elseif down == nil and up ~= nil then -- put down

                elseif down ~= nil and up == nil then -- pick up

                elseif down ~= nil and up ~= nil then -- swap

                end
            end)

            node:set_on_x(function()
                -- TODO
            end)

            node:set_on_y(function()
                -- TODO
            end)
        end
    end

    shared_move_node:set_on_enter(function()
        scene._shared_list_frame:set_selection_state(rt.SelectionState.ACTIVE)
        scene:_set_verbose_info_object(scene._shared_move_list:get_selected_object())
        scene:_set_control_indicator_layout(shared_move_control)
    end)

    shared_consumable_node:set_on_enter(function()
        scene._shared_list_frame:set_selection_state(rt.SelectionState.ACTIVE)
        scene:_set_verbose_info_object(scene._shared_consumable_list:get_selected_object())
        scene:_set_control_indicator_layout(shared_consumable_control)
    end)

    shared_equip_node:set_on_enter(function()
        scene._shared_list_frame:set_selection_state(rt.SelectionState.ACTIVE)
        scene:_set_verbose_info_object(scene._shared_equip_list:get_selected_object())
        scene:_set_control_indicator_layout(shared_equip_control)
    end)

    shared_template_node:set_on_enter(function()
        scene._shared_list_frame:set_selection_state(rt.SelectionState.ACTIVE)
        scene:_set_verbose_info_object(scene._shared_template_list:get_selected_object())
        scene:_set_control_indicator_layout(shared_template_control)
    end)

    for node in values(shared_list_nodes) do
        node:set_on_exit(function()
            scene._shared_list_frame:set_selection_state(rt.SelectionState.INACTIVE)
        end)

        node:set_on_a(function()
            -- TODO: take / deposit
        end)

        node:set_on_x(function()
            -- TODO: quick-equpi
        end)

        node:set_on_y(function()
            -- TODO change sorting
        end)
    end

    for tab_i, node in ipairs(shared_tab_nodes) do
        node:set_on_enter(function()
            scene._shared_tab_bar:set_tab_selected(tab_i, true)

            if tab_i == scene._shared_move_list_index then
                scene:_set_verbose_info_object("move")
            elseif tab_i == scene._shared_consumable_list_index then
                scene:_set_verbose_info_object("consumable")
            elseif tab_i == scene._shared_equip_list_index then
                scene:_set_verbose_info_object("equip")
            elseif tab_i == scene._shared_template_list_index then
                scene:_set_verbose_info_object("template")
            end
            scene:_set_control_indicator_layout(shared_tab_control)
        end)

        node:set_on_exit(function()
            scene._shared_tab_bar:set_tab_selected(tab_i, false)
        end)

        node:set_on_a(function()
            scene._shared_list_index = tab_i
        end)
    end

    verbose_info_node:set_on_enter(function()
        scene._verbose_info:set_selection_state(rt.SelectionState.ACTIVE)
    end)

    verbose_info_node:set_on_exit(function()
        scene._verbose_info:set_selection_state(rt.SelectionState.INACTIVE)
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
end

--- @brief
function mn.Scene:_set_control_indicator_layout(layout)
    local shared_layout = {
        {rt.ControlIndicatorButton.ALL_DIRECTIONS, "Move"}
    }

    local final_layout = {}
    if self._grabbed_object ~= nil then
        table.insert(final_layout, {rt.ControlIndicatorButton.B, "Drop"})
    end

    for x in values(layout) do
        table.insert(final_layout, x)
    end

    if self._verbose_info:can_scroll_up() or self._verbose_info:can_scroll_down() then
        table.insert(final_layout, {rt.ControlIndicatorButton.L_R, "Scroll"})
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

    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(
        self._bounds.x + self._bounds.width - control_w - outer_margin,
        self._bounds.y + outer_margin, control_w, control_h
    )
end

--- @brief
function mn.Scene:_handle_button_pressed(which)
    local current_node = self._selection_graph:get_current_node()
    if current_node == nil then return end
    local current_shared_list = self:_shared_list_index_to_list(self._shared_list_index)
    if current_node.is_shared_list_node == true and which == rt.InputButton.UP then
        local success = current_shared_list:move_up()
        if not success then -- escape from list scroll
            self._selection_graph:handle_button(rt.InputButton.UP)
        else
            self:_set_verbose_info_object(current_shared_list:get_selected_object())
        end
    elseif current_node.is_shared_list_node == true and which == rt.InputButton.DOWN then
        if current_shared_list:move_down() then
            self:_set_verbose_info_object(current_shared_list:get_selected_object())
        end
    else
        self._selection_graph:handle_button(which)
    end
end

--- @brief
function mn.Scene:_set_verbose_info_object(...)
    self._verbose_info:show(self._grabbed_object, ...)
end

--TODO: A, X, Y, visualize templates, smooth info scroll