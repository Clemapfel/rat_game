rt.settings.menu.scene = {
    tab_bar_sprite_id = "menu_icons",
    equips_sprite_index = "equips",
    moves_sprite_index = "moves",
    consumables_sprite_index = "consumables",
    template_sprite_index = "templates"
}

--- @class mn.InventoryState
mn.InventoryState = meta.new_type("MenuInventoryState", function()
    return meta.new(mn.InventoryState, {
        shared_moves = {},       -- Table<bt.Move, Number>
        shared_consumables = {}, -- Table<bt.Consumable, Number>
        shared_equips = {},      -- Table<bt.Equip, Number>
        stack = {},              -- Stack<Union<bt.Move, bt.Equip, bt.Consumable>>
        entities = {},           -- Queue<bt.Entity>
    })
end)

mn.Scene = meta.new_type("MenuScene", rt.Scene, function()
    return meta.new(mn.Scene, {
        _state = mn.InventoryState(),
        _n_entities = 0,

        _current_control_indicator = nil,
        _control_indicators = {}, -- Table<rt.ControlIndicator>

        _inventory_header_label = {}, -- rt.Label
        _inventory_header_frame = rt.Frame(),

        _grabbed_object = nil,
        _grabbed_object_sprite = nil,
        _grabbed_object_x = 0,
        _grabbed_object_y = 0,

        _shared_list_frame = rt.Frame(),
        _shared_move_tab_sprite = {}, -- rt.Sprite
        _shared_equip_tab_sprite = {}, -- rt.Sprite
        _shared_consumable_tab_sprite = {}, -- rt.Sprite

        _shared_tab_bar = mn.TabBar(),
        _shared_list_sort_mode = mn.ScrollableListSortMode.BY_ID,

        _shared_tab_index = 2,
        _shared_move_list = mn.ScrollableList(),
        _shared_equip_list = mn.ScrollableList(),
        _shared_consumable_list = mn.ScrollableList(),
        _shared_template_list = mn.ScrollableList(),
        _shared_tab_index_to_list = meta.make_weak({}, true, true), -- Table<TabIndex, mn.ScrollableList>

        _entity_tab_bar = mn.TabBar(),
        _entity_pages = {}, -- Table<Number, {info, equips_and_consumables, moves}>
        _entity_index = 3,

        _selection_graph = rt.SelectionGraph(),
        _shared_list_node_active = false,
        _input = rt.InputController(),

        _verbose_info = mn.VerboseInfoPanel(),
        _verbose_info_node_active = false,

        _move_only_selection_active = false, -- prevent cursor from leaving move
        _slot_only_selection_active = false, -- prevent cursor from leaving equip / consumable

        _animation_queue = rt.AnimationQueue(),

        _undo_grab = function() end,

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

function mn.Scene:_update_inventory_header_label()
    local before_w = select(1, self._inventory_header_label:measure())

    local prefix, postfix = "<o>", "</o>"
    if self._shared_tab_index == self._shared_move_tab_index then
        self._inventory_header_label:set_text(prefix .. "Moves" .. postfix)
    elseif self._shared_tab_index == self._shared_consumable_tab_index then
        self._inventory_header_label:set_text(prefix .. "Consumables" .. postfix)
    elseif self._shared_tab_index == self._shared_equip_tab_index then
        self._inventory_header_label:set_text(prefix .. "Equippables" .. postfix)
    elseif self._shared_tab_index == self._shared_template_tab_index then
        self._inventory_header_label:set_text(prefix .. "Templates" .. postfix)
    else
        self._inventory_header_label:set_text(prefix .. "Inventory" .. postfix)
    end

    local control_w, control_h = self._current_control_indicator:measure()
    local current_x, current_y = self._inventory_header_frame:get_position()

    local header_w, header_h = self._inventory_header_label:measure()
    header_w = header_w + 4 * rt.settings.margin_unit
    self._inventory_header_frame:fit_into(current_x, current_y, header_w, control_h)
    self._inventory_header_label:fit_into(current_x, current_y + 0.5 * control_h - 0.5 * header_h, header_w, control_h)
end

--- @override
function mn.Scene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    if self._background ~= nil then
        self._background:realize()
    end

    self._input:signal_connect("pressed", function(_, button)
        self:_handle_button_pressed(button)
    end)

    -- placeholder control until selection graph indicators are created
    self._current_control_indicator = rt.ControlIndicator({
        {rt.ControlIndicatorButton.B, "Back"}
    })
    self._current_control_indicator:realize()

    self._inventory_header_label = rt.Label("<o>Inventory</o>")
    self._inventory_header_label:realize()
    self._inventory_header_label:set_justify_mode(rt.JustifyMode.CENTER)
    self._inventory_header_frame:realize()

    local settings = rt.settings.menu.scene
    local tab_sprites = {
        [self._shared_move_tab_index] = rt.Sprite(settings.tab_bar_sprite_id, settings.moves_sprite_index),
        [self._shared_consumable_tab_index] = rt.Sprite(settings.tab_bar_sprite_id, settings.consumables_sprite_index),
        [self._shared_equip_tab_index] = rt.Sprite(settings.tab_bar_sprite_id, settings.equips_sprite_index),
        [self._shared_template_tab_index] = rt.Sprite(settings.tab_bar_sprite_id, settings.template_sprite_index)
    }

    for i, sprite in ipairs(tab_sprites) do
        local sprite_w, sprite_h = sprite:get_resolution()
        sprite_w = sprite_w * 2
        sprite_h = sprite_h * 2
        sprite:set_minimum_size(sprite_w, sprite_h)
        self._shared_tab_bar:push(sprite)
    end

    self._shared_tab_bar:set_orientation(rt.Orientation.HORIZONTAL)
    self._shared_tab_bar:set_n_post_aligned_items(1)
    self._shared_tab_bar:realize()

    self._entity_pages = {}
    local entities = self._state.entities
    self._n_entities = 0
    for entity_i = 1, #entities do
        local entity = entities[entity_i]
        local tab_sprite = rt.Sprite(entity:get_sprite_id())
        local sprite_w, sprite_h = tab_sprite:get_resolution()
        sprite_w = sprite_w * 3
        sprite_h = sprite_h * 3
        tab_sprite:set_minimum_size(sprite_w, sprite_h)
        self._entity_tab_bar:push(tab_sprite)

        local equip_consumable_layout = {}
        local move_layout = {}
        do
            local n_equips = entity:get_n_equip_slots()
            for i = 1, n_equips do
                table.insert(equip_consumable_layout, mn.SlotType.EQUIP)
            end

            for i = 1, entity:get_n_consumable_slots() do
                table.insert(equip_consumable_layout, mn.SlotType.CONSUMABLE)
            end

            local n_move_slots = entity:get_n_move_slots()
            table.insert(move_layout, {})
            for i = 1, n_move_slots do
                table.insert(move_layout[#move_layout], mn.SlotType.MOVE)
                if i % 4 == 0 and i ~= n_move_slots then
                    table.insert(move_layout, {})
                end
            end

            self._n_entities = self._n_entities + 1
        end

        local page = {
            info = mn.EntityInfo(entity),
            equips_and_consumables = mn.Slots({equip_consumable_layout}),
            moves = mn.Slots(move_layout)
        }

        page.info:realize()
        page.equips_and_consumables:realize()
        page.moves:realize()

        self._entity_pages[entity_i] = page
    end

    local sprite = rt.Sprite("opal", 19)
    sprite:realize()
    local sprite_w, sprite_h = sprite:get_resolution()
    sprite:set_minimum_size(sprite_w * 3, sprite_h * 3)

    self._entity_tab_bar:push(sprite)
    self._entity_tab_bar:set_n_post_aligned_items(1)
    self._entity_tab_bar:set_orientation(rt.Orientation.VERTICAL)
    self._entity_tab_bar:realize()

    self:_create_from_state(self._state)
    self._verbose_info:realize()

    self._shared_list_frame:realize()
    for list in range(
        self._shared_move_list,
        self._shared_equip_list,
        self._shared_consumable_list,
        self._shared_template_list
    ) do
        list:realize()
    end

    self:set_current_shared_list_page(1)
    self:set_current_entity_page(1)
    
    self._shared_tab_index_to_list = {
        [self._shared_move_tab_index] = self._shared_move_list,
        [self._shared_consumable_tab_index] = self._shared_consumable_list,
        [self._shared_equip_tab_index] = self._shared_equip_list,
        [self._shared_template_tab_index] = self._shared_template_list
    }

    -- TODO
    self._verbose_info:show(nil)
    -- TODO
end

--- @brief
function mn.Scene:_create_from_state()
    local entities = self._state.entities
    for entity_i = 1, #entities do
        local page = self._entity_pages[entity_i]
        local entity = entities[entity_i]

        page.moves:clear()
        page.equips_and_consumables:clear()

        local moves = entity:list_moves()
        for move_i = 1, #moves do
            page.moves:set_object(move_i,  moves[move_i])
        end

        local equips = entity:list_equips()
        local n_equips = entity:get_n_equip_slots()
        for i = 1, n_equips do
            local equip = equips[i]
            page.equips_and_consumables:set_object(i, equip)
        end

        local consumables = entity:list_consumables()
        local n_consumables = entity:get_n_consumable_slots()
        for i = 1, n_consumables do
            local consumable = consumables[i]
            page.equips_and_consumables:set_object(i + n_equips, consumable)
        end
    end

    self._shared_move_list:clear()
    for move, quantity in pairs(self._state.shared_moves) do
        self._shared_move_list:push({move, quantity})
    end

    self._shared_consumable_list:clear()
    for consumable, quantity in pairs(self._state.shared_consumables) do
        self._shared_consumable_list:push({consumable, quantity})
    end

    self._shared_equip_list:clear()
    for equip, quantity in pairs(self._state.shared_equips) do
        self._shared_equip_list:push({equip, quantity})
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

    local current_x, current_y = x + outer_margin, y + outer_margin
    local control_w, control_h = self._current_control_indicator:measure()
    self._current_control_indicator:fit_into(x + width - control_w - outer_margin, y + outer_margin, control_w, control_h)

    local header_w, header_h = self._inventory_header_label:measure()
    header_w = header_w + 4 * m
    self._inventory_header_frame:fit_into(current_x, current_y, header_w, control_h)
    self._inventory_header_label:fit_into(current_x, current_y + 0.5 * control_h - 0.5 * header_h, header_w, control_h)

    current_y = current_y + control_h + m

    -- left side, base tile size on slots
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

    --[[
    local verbose_info_w = page_w
    local verbose_info_h = (y + height - 2 * m) - current_y
    current_x = current_x + m + page_w + m
    self._verbose_info:fit_into(
        current_x,
        current_y,
        verbose_info_w,
        verbose_info_h
    )

    current_x = current_x + page_w

    local shared_page_w = (x + width - m) - current_x - 3 * m
    local shared_tile_size = tile_size * 0.75
    local shared_page_x = x + width - 2 * m - shared_page_w
    self._shared_tab_bar:fit_into(shared_page_x, current_y, shared_page_w, shared_tile_size)

    current_y = current_y + shared_tile_size + m
    local shared_list_aabb = rt.AABB(shared_page_x, current_y, shared_page_w, y + height - outer_margin - current_y)
    for list in range(
        self._shared_move_list,
        self._shared_equip_list,
        self._shared_consumable_list,
        self._shared_template_list
    ) do
        list:fit_into(shared_list_aabb)
    end
    ]]--
    self:_regenerate_selection_nodes()
end

--- @override
function mn.Scene:draw()
    if self._is_realized ~= true then return end

    if self._background ~= nil then
        self._background:draw()
    end

    self._inventory_header_frame:draw()
    self._inventory_header_label:draw()

    if self._current_control_indicator ~= nil then
        self._current_control_indicator:draw()
    end

    self._shared_tab_bar:draw()

    self._entity_tab_bar:draw()
    local current_page = self._entity_pages[self._entity_index]
    if current_page ~= nil then
        current_page.moves:draw()
        current_page.equips_and_consumables:draw()
        current_page.info:draw()
    end

    self._shared_list_frame:draw()
    self._shared_tab_index_to_list[self._shared_tab_index]:draw()

    self._verbose_info:draw()

    self._animation_queue:draw()

    if self._grabbed_object ~= nil then
        rt.graphics.translate(self._grabbed_object_x, self._grabbed_object_y)
        self._grabbed_object_sprite:draw()
        rt.graphics.translate(-self._grabbed_object_x, -self._grabbed_object_y)
    end
end

function mn.Scene:_regenerate_selection_nodes()
    local scene = self

    -- shared list tab nodes
    local shared_tab_nodes = {}
    for node in values(self._shared_tab_bar:get_selection_nodes()) do
        table.insert(shared_tab_nodes, node)
    end

    table.sort(shared_tab_nodes, function(a, b)
        return a:get_bounds().x < b:get_bounds().x
    end)

    -- shared list nodes
    local shared_list_nodes = {}
    for index in range(
        self._shared_move_tab_index,
        self._shared_consumable_tab_index,
        self._shared_equip_tab_index,
        self._shared_template_tab_index
    ) do
        shared_list_nodes[index] = rt.SelectionGraphNode(self._shared_tab_index_to_list[index]:get_bounds())
    end

    -- entity tab nodes
    local entity_tab_nodes = {}
    for node in values(self._entity_tab_bar:get_selection_nodes()) do
        table.insert(entity_tab_nodes, node)
    end
    table.sort(entity_tab_nodes, function(a, b) return a:get_bounds().y < b:get_bounds().y end)

    -- per-entity page nodes
    local entity_page_nodes = {}
    for entity_i = 1, self._n_entities do
        local page = self._entity_pages[entity_i]
        local info_node = rt.SelectionGraphNode(page.info:get_bounds())
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
        table.sort(slot_nodes, function(a, b) return a:get_bounds().x < b:get_aabb().x end)

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
    local verbose_info_node = rt.SelectionGraphNode(self._verbose_info:get_bounds())

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
            local nearest = find_nearest_node(node, page.slot_nodes, "x")
            node:set_down(function()
                if scene._move_only_selection_active ~= true then
                    return nearest
                else
                    return nil
                end
            end)
        end

        -- up to info, unless locked
        for node in values(page.top_move_nodes) do
            node:set_up(function()
                if scene._move_only_selection_active ~= true then
                    return page.info_node
                else
                    return nil
                end
            end)
        end

        -- left to nearest entity, unless locked
        for node in values(page.left_move_nodes) do
            local nearest = find_nearest_node(node, entity_tab_nodes, "y")
            node:set_left(function()
                if scene._move_only_selection_active ~= true then
                    return nearest
                else
                    return nil
                end
            end)
        end

        -- right to shared, unless locked
        for node in values(page.right_move_nodes) do
            node:set_right(function()
                if scene._move_only_selection_active ~= true then
                    return shared_list_nodes[scene._shared_tab_index]
                else
                    return nil
                end
            end)
        end

        -- slots up or down, unless locked
        for node in values(page.slot_nodes) do
            local nearest_up = find_nearest_node(node, page.bottom_move_nodes, "x")
            node:set_up(function()
                if scene._slot_only_selection_active ~= true then
                    return nearest_up
                else
                    return nil
                end
            end)

            node:set_down(nil)
        end

        -- slots left, unless locked
        page.slot_nodes[1]:set_left(function()
            if scene._slot_only_selection_active ~= true then
                return entity_tab_nodes[#entity_tab_nodes]
            else
                return nil
            end
        end)

        -- slots right, unless locked
        page.slot_nodes[#(page.slot_nodes)]:set_right(function()
            if scene._slot_only_selection_active ~= true then
                return shared_list_nodes[scene._shared_tab_index]
            else
                return nil
            end
        end)
    end
    for entity_tab_node in values(entity_tab_nodes) do
        -- precompute nearest node for all entity pages
        local nearest = {}
        for entity_i = 1, scene._n_entities do
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

    shared_tab_nodes[#shared_tab_nodes]:set_right(function()
        return verbose_info_node
    end)

    local shared_list_left = function()
        return entity_page_nodes[scene._entity_index].right_move_nodes[1]
    end

    local shared_list_right = function()
        return verbose_info_node
    end

    local shared_list_up = function()
        return shared_tab_nodes[scene._shared_tab_index]
    end

    for node in values(shared_list_nodes) do
        node:set_left(shared_list_left)
        node:set_right(shared_list_right)
        node:set_up(shared_list_up)
    end

    local shared_tab_down = function()
        return shared_list_nodes[scene._shared_tab_index]
    end

    for node in values(shared_tab_nodes) do
        node:set_down(shared_tab_down)
    end

    verbose_info_node:set_left(function()
        return shared_list_nodes[scene._shared_tab_index]
    end)

    -- enter / exit
    local prefix = ""
    local postfix = ""
    local shared_control_layout = {
        {rt.ControlIndicatorButton.B, "Back"},
        {rt.ControlIndicatorButton.L, "Previous"},
        {rt.ControlIndicatorButton.R, "Next"}
    }

    local entity_tab_control = rt.ControlIndicator({
        {rt.ControlIndicatorButton.A, prefix .. "Select" .. postfix},
        table.unpack(shared_control_layout)
    })

    local shared_tab_control = rt.ControlIndicator({
        {rt.ControlIndicatorButton.A, prefix .. "Select" .. postfix},
        table.unpack(shared_control_layout)
    })

    local entity_info_control = rt.ControlIndicator({
        table.unpack(shared_control_layout)
    })

    local entity_page_control = rt.ControlIndicator({
        {rt.ControlIndicatorButton.A, prefix .. "TODO" .. postfix},
        {rt.ControlIndicatorButton.X, prefix .. "Unequip Automatically" .. postfix},
        {rt.ControlIndicatorButton.Y, prefix .. "Sort" .. postfix},
        table.unpack(shared_control_layout)
    })

    local shared_list_control = rt.ControlIndicator({
        {rt.ControlIndicatorButton.A, prefix .. "TODO" .. postfix},
        {rt.ControlIndicatorButton.X, prefix .. "Equip Automatically" .. postfix},
        {rt.ControlIndicatorButton.Y, prefix .. "Sort By" .. postfix},
        table.unpack(shared_control_layout)
    })

    local verbose_info_control = rt.ControlIndicator({
        {rt.ControlIndicatorButton.A, prefix .. "TODO" .. postfix},
        {rt.ControlIndicatorButton.UP_DOWN, prefix .. "Scroll" .. postfix},
        table.unpack(shared_control_layout)
    })

    self._control_indicators = {
        entity_tab_control,
        shared_tab_control,
        entity_page_control,
        entity_info_control,
        shared_list_control,
        verbose_info_control
    }

    local x, y = self._bounds.x, self._bounds.y
    local width = self._bounds.width
    local outer_margin = 2 * rt.settings.margin_unit
    for indicator in values(self._control_indicators) do
        indicator:realize()
        local control_w, control_h = indicator:measure()
        indicator:fit_into(x + width - control_w - outer_margin, y + outer_margin, control_w, control_h)
    end

    for node_i, node in ipairs(shared_list_nodes) do
        node:set_on_enter(function()
            scene._shared_list_node_active = true
            scene._shared_list_frame:set_selection_state(rt.SelectionState.ACTIVE)
            scene._current_control_indicator = shared_list_control

            if scene._grabbed_object ~= nil then
                if meta.isa(scene._grabbed_object, bt.Move) then
                    scene:set_current_shared_list_page(self._shared_move_tab_index)
                elseif meta.isa(scene._grabbed_object, bt.Equip) then
                    scene:set_current_shared_list_page(self._shared_equip_tab_index)
                elseif meta.isa(scene._grabbed_object, bt.Consumable) then
                    scene:set_current_shared_list_page(self._shared_consumable_tab_index)
                end

                scene:_set_grabbed_object_allowed(true)
            end

            local current_shared_list = scene._shared_tab_index_to_list[scene._shared_tab_index]
            scene:_set_verbose_info_object(current_shared_list:get_selected()) -- also updated in handle_button_pressed
        end)

        node:set_on_exit(function()
            scene._shared_list_node_active = false
            scene._shared_list_frame:set_selection_state(rt.SelectionState.INACTIVE)
        end)
    end

    for entity_i, node in ipairs(entity_tab_nodes) do
        node:set_on_enter(function()
            scene._entity_tab_bar:set_tab_selected(entity_i, true)
            scene._current_control_indicator = entity_tab_control
            scene:_set_grabbed_object_allowed(false)

            scene:_set_verbose_info_object(nil) -- TODO
            if entity_i == self._n_entities + 1 then
                scene:_set_verbose_info_object("options")
            end
        end)

        node:set_on_exit(function()
            scene._entity_tab_bar:set_tab_selected(entity_i, false)
        end)
    end

    for tab_i, node in ipairs(shared_tab_nodes) do
        node:set_on_enter(function()
            scene._shared_tab_bar:set_tab_selected(tab_i, true)
            scene._current_control_indicator = shared_tab_control
            scene:_set_grabbed_object_allowed(false)

            if tab_i == self._shared_move_tab_index then
                scene:_set_verbose_info_object("move")
            elseif tab_i == self._shared_consumable_tab_index then
                scene:_set_verbose_info_object("consumable")
            elseif tab_i == self._shared_equip_tab_index then
                scene:_set_verbose_info_object("equip")
            elseif tab_i == self._shared_template_tab_index then
                scene:_set_verbose_info_object(nil) -- TODO
            end
        end)

        node:set_on_exit(function()
            scene._shared_tab_bar:set_tab_selected(tab_i, false)
        end)
    end

    for page_i, page in ipairs(entity_page_nodes) do
        page.info_node:set_on_enter(function()
            scene._entity_pages[page_i].info:set_selection_state(rt.SelectionState.ACTIVE)
            scene._current_control_indicator = entity_info_control
            scene:_set_grabbed_object_allowed(false)

            scene:_set_verbose_info_object("hp", "attack", "defense", "speed")
        end)

        page.info_node:set_on_exit(function()
            scene._entity_pages[page_i].info:set_selection_state(rt.SelectionState.INACTIVE)
        end)

        for node_i, node in ipairs(page.move_nodes) do
            node:set_on_enter(function()
                local slots = scene._entity_pages[page_i].moves
                slots:set_selection_state(rt.SelectionState.ACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.ACTIVE)
                scene._current_control_indicator = entity_page_control

                scene:_set_grabbed_object_allowed(meta.isa(scene._grabbed_object, bt.Move) and not scene._state.entities[self._entity_index]:has_move(scene._grabbed_object))

                local object = slots:get_object(node_i)
                if object == nil then
                    scene:_set_verbose_info_object("move")
                else
                    scene:_set_verbose_info_object(slots:get_object(node_i))
                end
            end)

            node:set_on_exit(function()
                local slots = scene._entity_pages[page_i].moves
                slots:set_selection_state(rt.SelectionState.INACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.INACTIVE)
            end)
        end

        for node_i, node in ipairs(page.slot_nodes) do
            node:set_on_enter(function()
                local slots = scene._entity_pages[page_i].equips_and_consumables
                slots:set_selection_state(rt.SelectionState.ACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.ACTIVE)
                scene._current_control_indicator = entity_page_control

                local n_equip_slots = scene._state.entities[page_i]:get_n_equip_slots()
                if node_i <= n_equip_slots then
                    scene:_set_grabbed_object_allowed(meta.isa(scene._grabbed_object, bt.Equip))
                else
                    scene:_set_grabbed_object_allowed(meta.isa(scene._grabbed_object, bt.Consumable))
                end

                local object = slots:get_object(node_i)
                if object == nil then
                    scene:_set_verbose_info_object(ternary(node_i <= n_equip_slots, "equip", "consumable"))
                else
                    scene:_set_verbose_info_object(slots:get_object(node_i))
                end

                -- update stat preview
                if node_i <= n_equip_slots then
                    local info = scene._entity_pages[scene._entity_index].info
                    local entity = scene._state.entities[scene._entity_index]

                    local new_hp, new_attack, new_defense, new_speed = entity:preview_equip(node_i, scene._grabbed_object)
                    local current_hp, current_attack, current_defense, current_speed = entity:get_hp_base(), entity:get_attack_base(), entity:get_defense_base(), entity:get_speed_base()
                    info:set_preview_values(
                        ternary(new_hp ~= current_hp, new_hp, nil),
                        ternary(new_attack ~= current_attack, new_hp, nil),
                        ternary(new_defense ~= current_defense, new_hp, nil),
                        ternary(new_speed ~= current_speed, new_hp, nil)
                    )
                end


            end)

            node:set_on_exit(function()
                local slots = scene._entity_pages[page_i].equips_and_consumables
                slots:set_selection_state(rt.SelectionState.INACTIVE)
                slots:set_slot_selection_state(node_i, rt.SelectionState.INACTIVE)

                local info = scene._entity_pages[scene._entity_index].info
                info:set_preview_values(nil, nil, nil, nil)
            end)
        end
    end

    verbose_info_node:set_on_enter(function()
        self._verbose_info_node_active = true
        scene._verbose_info:set_selection_state(rt.SelectionState.ACTIVE)
        scene._current_control_indicator = verbose_info_control
        scene:_set_grabbed_object_allowed(false)

        -- do not update _set_verbose_info_object
    end)

    verbose_info_node:set_on_exit(function()
        self._verbose_info_node_active = false
        scene._verbose_info:set_selection_state(rt.SelectionState.INACTIVE)
    end)

    -- activation
    for node_i, node in ipairs(entity_tab_nodes) do
        node:set_on_a(function()
            scene:set_current_entity_page(node_i)
        end)
    end

    entity_tab_nodes[#entity_tab_nodes]:set_on_a(function()
        scene:_open_options()
    end)

    for node_i, node in ipairs(shared_tab_nodes) do
        node:set_on_a(function()
            scene:set_current_shared_list_page(node_i)
        end)
    end

    local shared_list_aabb = scene._shared_list_frame:get_bounds()
    for entity_i, page in ipairs(entity_page_nodes) do
        for node_i, node in ipairs(page.move_nodes) do
            node:set_on_x(function(self)
                local current_page = scene._entity_pages[scene._entity_index]
                local object = current_page.moves:get_object(node_i)
                if object == nil then return end
                scene:set_current_shared_list_page(scene._shared_move_tab_index)
                scene:_play_move_object_animation(object, self:get_aabb(), shared_list_aabb)

                local page = scene._entity_pages[scene._entity_index]
                if page == nil then return end
                local move = page.moves:get_object(node_i)
                if move ~= nil then
                    page.moves:set_object(node_i, nil)
                    scene._shared_move_list:add(move, 1)
                end

                scene._state.entities[scene._entity_index]:remove_move(move)
            end)

            node:set_on_a(function(self)
                local page = scene._entity_pages[scene._entity_index]
                local down = page.moves:get_object(node_i)
                local up = scene._grabbed_object
                local entity = scene._state.entities[scene._entity_index]

                if up ~= nil then
                    if not meta.isa(up, bt.Move) then
                        return
                    end

                    if entity:has_move(up) then return end
                end

                scene._undo_grab = function() end

                if down == nil and up == nil then
                    -- noop
                elseif down == nil and up ~= nil then -- put down
                    scene:_set_grabbed_object(nil, node_i)
                    page.moves:set_object(node_i, up)

                    entity:add_move(up)
                elseif down ~= nil and up == nil then -- pick up
                    scene:_set_grabbed_object(down, node_i)
                    page.moves:set_object(node_i, nil)
                    entity:remove_move(down)

                    local current_page_i = scene._entity_index
                    scene._undo_grab = function()
                        scene:set_current_entity_page(current_page_i)
                        scene:_play_move_object_animation(
                            down,
                            scene._grabbed_object_bounds,
                            page.moves:get_slot_aabb(node_i),
                            function()
                                page.moves:set_object(node_i, down)
                                entity:add_move(down)
                                page.moves:set_slot_object_visible(node_i, false)
                            end,
                            function()
                                page.moves:set_slot_object_visible(node_i, true)
                            end
                        )
                    end

                elseif down ~= nil and up ~= nil then -- swap
                    scene:_set_grabbed_object(down, node_i)
                    page.moves:set_object(node_i, up)
                    entity:remove_move(down)
                    entity:add_move(up)

                    local current_page_i = scene._entity_index
                    scene._undo_grab = function()
                        scene:set_current_entity_page(current_page_i)

                        local insert_slot_i = page.moves:get_first_unoccupied_slot_i(mn.SlotType.MOVE)
                        -- if entity slots are full, return to shared inventory
                        if insert_slot_i == nil then
                            scene:_play_move_object_animation(
                                down,
                                scene._grabbed_object_bounds,
                                scene._shared_move_list:get_bounds(),
                                function()
                                    scene._shared_move_list:add(down)
                                end
                            )
                        else
                            scene:_play_move_object_animation(
                                down,
                                scene._grabbed_object_bounds,
                                page.moves:get_slot_aabb(insert_slot_i),
                                function()
                                    page.moves:set_object(insert_slot_i, down)
                                    entity:add_move(down)
                                    page.moves:set_slot_object_visible(insert_slot_i, false)
                                end,
                                function()
                                    page.moves:set_slot_object_visible(insert_slot_i, true)
                                end
                            )
                        end
                    end
                end

            end)

            node:set_on_y(function(self)
                scene._entity_pages[scene._entity_index].moves:sort()
            end)
        end

        local entity = self._state.entities[entity_i]
        local n_equips, n_consumables = entity:get_n_equip_slots(), entity:get_n_consumable_slots()
        for equip_i = 1, n_equips do
            local node_i = equip_i
            local node = page.slot_nodes[node_i]
            node:set_on_x(function(self)
                local current_page = scene._entity_pages[scene._entity_index]
                local object = current_page.equips_and_consumables:get_object(node_i)
                if object == nil then return end
                scene:set_current_shared_list_page(scene._shared_equip_tab_index)
                scene:_play_move_object_animation(object, self:get_aabb(), shared_list_aabb)

                local page = scene._entity_pages[scene._entity_index]
                if page == nil then return end
                local equip = page.equips_and_consumables:get_object(node_i)
                if equip ~= nil then
                    page.equips_and_consumables:set_object(node_i, nil)
                    scene._shared_equip_list:add(equip, 1)
                end

                scene._state.entities[scene._entity_index]:remove_equip(equip)
            end)

            node:set_on_a(function(self)
                local page = scene._entity_pages[scene._entity_index]
                local down = page.equips_and_consumables:get_object(node_i)
                local up = scene._grabbed_object

                if up ~= nil and not meta.isa(up, bt.Equip) then
                    return
                end

                if down == nil and up == nil then
                    -- noop
                elseif down == nil and up ~= nil then -- put down
                    scene:_set_grabbed_object(nil, node_i)
                    page.equips_and_consumables:set_object(node_i, up)
                    entity:add_equip(up, node_i)
                elseif down ~= nil and up == nil then -- pick up
                    scene:_set_grabbed_object(down, node_i)
                    page.equips_and_consumables:set_object(node_i, nil)
                    entity:remove_equip(down)

                    local current_page_i = scene._entity_index
                    scene._undo_grab = function()
                        scene:set_current_entity_page(current_page_i)
                        scene:_play_move_object_animation(
                            down,
                            scene._grabbed_object_bounds,
                            page.equips_and_consumables:get_slot_aabb(node_i),
                            function()
                                page.equips_and_consumables:set_object(node_i, down)
                                entity:add_equip(down, node_i)
                                page.equips_and_consumables:set_slot_object_visible(node_i, false)
                            end,
                            function()
                                page.equips_and_consumables:set_slot_object_visible(node_i, true)
                            end
                        )
                    end

                elseif down ~= nil and up ~= nil then -- swap
                    scene:_set_grabbed_object(down, node_i)
                    page.equips_and_consumables:set_object(node_i, up)
                    entity:remove_equip(down)
                    entity:add_equip(up, node_i)

                    local current_page_i = scene._entity_index
                    scene._undo_grab = function()
                        scene:set_current_entity_page(current_page_i)

                        local insert_slot_i = page.equips_and_consumables:get_first_unoccupied_slot_i(mn.SlotType.EQUIP)
                        if insert_slot_i == nil then
                            scene:_play_move_object_animation(
                                down,
                                scene._grabbed_object_bounds,
                                scene._shared_equip_list:get_bounds(),
                                function()
                                    scene._shared_equip_list:add(down)
                                end
                            )
                        else
                            scene:_play_move_object_animation(
                                down,
                                scene._grabbed_object_bounds,
                                page.equips_and_consumables:get_slot_aabb(insert_slot_i),
                                function()
                                    page.equips_and_consumables:set_object(insert_slot_i, down)
                                    entity:add_equip(down, insert_slot_i)
                                    page.equips_and_consumables:set_slot_object_visible(insert_slot_i, false)
                                end,
                                function()
                                    page.equips_and_consumables:set_slot_object_visible(insert_slot_i, true)
                                end
                            )
                        end
                    end
                end

                scene:_update_entity_info(scene._entity_index)
                local info = scene._entity_pages[scene._entity_index].info
                local entity = scene._state.entities[scene._entity_index]

                local new_hp, new_attack, new_defense, new_speed = entity:preview_equip(node_i, scene._grabbed_object)
                local current_hp, current_attack, current_defense, current_speed = entity:get_hp_base(), entity:get_attack_base(), entity:get_defense_base(), entity:get_speed_base()
                info:set_values_and_preview_values(
                    entity:get_hp_base(),
                    entity:get_attack_base(),
                    entity:get_defense_base(),
                    entity:get_speed_base(),
                    ternary(new_hp ~= current_hp, new_hp, nil),
                    ternary(new_attack ~= current_attack, new_hp, nil),
                    ternary(new_defense ~= current_defense, new_hp, nil),
                    ternary(new_speed ~= current_speed, new_hp, nil)
                )
            end)

            node:set_on_y(function(self)
                scene._entity_pages[scene._entity_index].equips_and_consumables:sort()
            end)
        end

        for consumable_i = 1, n_consumables do
            local node_i = consumable_i + n_equips
            local node = page.slot_nodes[node_i]
            node:set_on_x(function(self)
                local current_page = scene._entity_pages[scene._entity_index]
                local object = current_page.equips_and_consumables:get_object(node_i)
                if object == nil then return end
                scene:set_current_shared_list_page(scene._shared_consumable_tab_index)
                scene:_play_move_object_animation(object, self:get_aabb(), shared_list_aabb)

                local page = scene._entity_pages[scene._entity_index]
                if page == nil then return end
                local consumable = page.equips_and_consumables:get_object(node_i)
                if consumable ~= nil then
                    page.equips_and_consumables:set_object(node_i, nil)
                    scene._shared_consumable_list:add(consumable, 1)
                end

                scene._state.entities[scene._entity_index]:remove_consumable(consumable)
            end)

            node:set_on_a(function(self)
                local page = scene._entity_pages[scene._entity_index]
                local down = page.equips_and_consumables:get_object(node_i)
                local up = scene._grabbed_object

                if up ~= nil and not meta.isa(up, bt.Consumable) then
                    return
                end

                if down == nil and up == nil then
                    -- noop
                elseif down == nil and up ~= nil then -- put down
                    scene:_set_grabbed_object(nil, consumable_i)
                    page.equips_and_consumables:set_object(node_i, up)
                    entity:add_consumable(up, node_i)
                elseif down ~= nil and up == nil then -- pick up
                    scene:_set_grabbed_object(down, consumable_i)
                    page.equips_and_consumables:set_object(node_i, nil)
                    entity:remove_consumable(down)

                    local current_page_i = scene._entity_index
                    scene._undo_grab = function()
                        scene:set_current_entity_page(current_page_i)
                        scene:_play_move_object_animation(
                            down,
                            scene._grabbed_object_bounds,
                            page.equips_and_consumables:get_slot_aabb(node_i),
                            function()
                                page.equips_and_consumables:set_object(node_i, down)
                                entity:add_consumable(down, consumable_i)
                                page.equips_and_consumables:set_slot_object_visible(node_i, false)
                            end,
                            function()
                                page.equips_and_consumables:set_slot_object_visible(node_i, true)
                            end
                        )
                    end

                elseif down ~= nil and up ~= nil then -- swap
                    scene:_set_grabbed_object(down, node_i)
                    page.equips_and_consumables:set_object(node_i, up)
                    entity:remove_consumable(down)
                    entity:add_consumable(up, consumable_i)

                    local current_page_i = scene._entity_index
                    scene._undo_grab = function()
                        scene:set_current_entity_page(current_page_i)

                        local insert_slot_i = page.equips_and_consumables:get_first_unoccupied_slot_i(mn.SlotType.CONSUMABLE)
                        if insert_slot_i == nil then
                            scene:_play_move_object_animation(
                                down,
                                scene._grabbed_object_bounds,
                                scene._shared_equip_list:get_bounds(),
                                function()
                                    scene._shared_equip_list:add(down)
                                end
                            )
                        else
                            scene:_play_move_object_animation(
                                down,
                                scene._grabbed_object_bounds,
                                page.equips_and_consumables:get_slot_aabb(insert_slot_i),
                                function()
                                    page.equips_and_consumables:set_object(insert_slot_i, down)
                                    entity:add_consumable(down, insert_slot_i)
                                    page.equips_and_consumables:set_slot_object_visible(insert_slot_i, false)
                                end,
                                function()
                                    page.equips_and_consumables:set_slot_object_visible(insert_slot_i, true)
                                end
                            )
                        end
                    end
                end
            end)

            node:set_on_y(function(self)
                scene._entity_pages[scene._entity_index].equips_and_consumables:sort()
            end)
        end
    end

    local shared_move_list_node = shared_list_nodes[self._shared_move_tab_index]
    shared_move_list_node:set_on_x(function()
        local page = scene._entity_pages[scene._entity_index]
        local unoccupied_slot_i = page.moves:get_first_unoccupied_slot_i(mn.SlotType.MOVE)
        if unoccupied_slot_i ~= nil then
            local to_insert = self._shared_move_list:get_selected()
            local current_entity = self._state.entities[self._entity_index]
            for move in values(current_entity:list_moves()) do
                if move == to_insert then return end
            end

            if to_insert == nil then return end
            scene._shared_move_list:take(to_insert)
            scene:_play_move_object_animation(
                to_insert,
                scene._shared_list_frame:get_bounds(),
                page.moves:get_slot_aabb(unoccupied_slot_i),
                nil,
                function()
                    page.moves:set_object(unoccupied_slot_i, to_insert)
                end
            )

            current_entity:add_move(to_insert)
        end
    end)

    shared_move_list_node:set_on_y(function()
        scene._shared_move_list:set_sort_mode(scene._shared_list_sort_mode_order[scene._shared_move_list:get_sort_mode()])
    end)

    shared_move_list_node:set_on_a(function()
        if scene._shared_move_list:get_n_items() == 0 then return end
        local up = scene._grabbed_object
        local down = scene._shared_move_list:get_selected()

        if up == nil then
            scene:_set_grabbed_object(down)
            scene._shared_move_list:take(down)
            scene._undo_grab = function()
                scene:_play_move_object_animation(
                    down,
                    scene._grabbed_object_bounds,
                    scene._shared_move_list:get_bounds(),
                    function() scene._shared_move_list:add(down) end,
                    nil
                )
            end
        else
            scene:_set_grabbed_object(nil)
            scene._shared_move_list:add(up, 1)
        end
    end)

    local shared_equip_list_node = shared_list_nodes[self._shared_equip_tab_index]
    shared_equip_list_node:set_on_x(function()
        local page = scene._entity_pages[scene._entity_index]
        local unoccupied_slot_i = page.equips_and_consumables:get_first_unoccupied_slot_i(mn.SlotType.EQUIP)
        if unoccupied_slot_i ~= nil then
            local to_insert = self._shared_equip_list:get_selected()
            local current_entity = self._state.entities[self._entity_index]
            if to_insert == nil then return end
            scene._shared_equip_list:take(to_insert)
            local to = page.equips_and_consumables:get_slot_aabb(unoccupied_slot_i)
            scene:_play_move_object_animation(
                to_insert,
                self._shared_list_frame:get_bounds(),
                to,
                nil,
                function()
                    page.equips_and_consumables:set_object(unoccupied_slot_i, to_insert)
                end
            )

            current_entity:add_equip(to_insert)
        end
    end)

    shared_equip_list_node:set_on_a(function()
        if scene._shared_equip_list:get_n_items() == 0 then return end
        local up = scene._grabbed_object
        local down = scene._shared_equip_list:get_selected()

        if up == nil then
            scene:_set_grabbed_object(down)
            scene._shared_equip_list:take(down)
            scene._undo_grab = function()
                scene:_play_move_object_animation(
                    down,
                    scene._grabbed_object_bounds,
                    scene._shared_equip_list:get_bounds(),
                    function() scene._shared_equip_list:add(down) end,
                    nil
                )
            end
        else
            scene:_set_grabbed_object(nil)
            scene._shared_equip_list:add(up, 1)
        end
    end)

    shared_equip_list_node:set_on_y(function()
        scene._shared_equip_list:set_sort_mode(scene._shared_list_sort_mode_order[scene._shared_equip_list:get_sort_mode()])
    end)

    local shared_consumable_list_node = shared_list_nodes[self._shared_consumable_tab_index]
    shared_consumable_list_node:set_on_x(function()
        local page = scene._entity_pages[scene._entity_index]
        local unoccupied_slot_i = page.equips_and_consumables:get_first_unoccupied_slot_i(mn.SlotType.CONSUMABLE)
        if unoccupied_slot_i ~= nil then
            local to_insert = self._shared_consumable_list:get_selected()
            local current_entity = self._state.entities[self._entity_index]
            if to_insert == nil then return end
            scene._shared_consumable_list:take(to_insert)
            local to = page.equips_and_consumables:get_slot_aabb(unoccupied_slot_i)
            scene:_play_move_object_animation(
                to_insert,
                self._shared_list_frame:get_bounds(),
                to,
                nil,
                function()
                    page.equips_and_consumables:set_object(unoccupied_slot_i, to_insert)
                end
            )

            current_entity:add_consumable(to_insert)
        end
    end)

    shared_consumable_list_node:set_on_a(function()
        if scene._shared_consumable_list:get_n_items() == 0 then return end
        local up = scene._grabbed_object
        local down = scene._shared_consumable_list:get_selected()

        if up == nil then
            scene:_set_grabbed_object(down)
            scene._shared_consumable_list:take(down)
            scene._undo_grab = function()
                scene:_play_move_object_animation(
                    down,
                    scene._grabbed_object_bounds,
                    scene._shared_consumable_list:get_bounds(),
                    function() scene._shared_consumable_list:add(down) end,
                    nil
                )
            end
        else
            scene:_set_grabbed_object(nil)
            scene._shared_consumable_list:add(up, 1)

        end
    end)

    shared_consumable_list_node:set_on_y(function()
        scene._shared_consumable_list:set_sort_mode(scene._shared_list_sort_mode_order[scene._shared_consumable_list:get_sort_mode()])
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
function mn.Scene:_handle_button_pressed(which)
    if which == rt.InputButton.L then
        local next = self._entity_index
        if next == 1 then
            next = self._n_entities
        else
            next = next - 1
        end
        self:set_current_entity_page(next)
        self._selection_graph:set_current_node(self._entity_tab_bar:get_selection_nodes()[next])
        self:_update_grabbed_object_position()
        return
    elseif which == rt.InputButton.R then
        local next = self._entity_index
        if next >= self._n_entities then
            next = 1
        else
            next = next + 1
        end
        self:set_current_entity_page(next)
        self._selection_graph:set_current_node(self._entity_tab_bar:get_selection_nodes()[next])
        self:_update_grabbed_object_position()
        return
    elseif which == rt.InputButton.B then
        -- undo grab
        local grabbed = self._grabbed_object
        if grabbed ~= nil then
            self._grabbed_object = nil
            self._grabbed_object_sprite = nil
            self:_undo_grab()
            for page in values(self._entity_pages) do
                page.info:set_preview_values(nil, nil, nil, nil)
            end
        end
    end

    local current_shared_list = self._shared_tab_index_to_list[self._shared_tab_index]
    local update_verbose_info = false
    if self._shared_list_node_active and which == rt.InputButton.UP then
        if current_shared_list:move_up() == false then
            self._shared_list_node_active = false
        else
            update_verbose_info = true
            goto skip_others
        end
    elseif self._shared_list_node_active and which == rt.InputButton.DOWN then
        current_shared_list:move_down()
        update_verbose_info = true
        goto skip_others
    elseif self._shared_list_node_active and which == rt.InputButton.LEFT then
        self._shared_list_node_active = false
    elseif self._shared_list_node_active and which == rt.InputButton.RIGHT then
        self._shared_list_node_active = false
    end

    if self._verbose_info_node_active and which == rt.InputButton.UP then
        self._verbose_info:scroll_up()
        goto skip_others
    elseif self._verbose_info_node_active and which == rt.InputButton.DOWN then
        self._verbose_info:scroll_down()
        goto skip_others
    elseif self._verbose_info_node_active and which == rt.InputButton.LEFT then
        self._verbose_info_node_active = false
    elseif self._verbose_info_node_active and which == rt.InputButton.RIGHT then
        --self._verbose_info_node_active = false
    end

    self._selection_graph:handle_button(which)
    self:_update_grabbed_object_position()
    ::skip_others::

    if update_verbose_info then
        self:_set_verbose_info_object(current_shared_list:get_selected())
    end
end

--- @brief
function mn.Scene:set_current_entity_page(i)
    if i < 1 or i > self._n_entities then return end
    self._entity_index = i
    for entity_i = 1, self._n_entities do
        self._entity_tab_bar:set_tab_active(entity_i, entity_i == i)
    end
end

--- @brief
function mn.Scene:set_current_shared_list_page(i)
    if i < 1 or i > 4 then return end
    self._shared_tab_index = i
    for tab_i = 1, 4 do
        self._shared_tab_bar:set_tab_active(tab_i, tab_i == i)
    end
    self:_update_inventory_header_label()
end

--- @brief
function mn.Scene:_open_options()
    rt.warning("In mn.Scene.open_options: TODO")
end

--- @brief
function mn.Scene:_play_move_object_animation(object, from_aabb, to_aabb, before, after)
    self._animation_queue:push(mn.Animation.OBJECT_MOVED(object, from_aabb, to_aabb), before, after)
end

--- @override
function mn.Scene:update(delta)
    self._background:update(delta)
    self._animation_queue:update(delta)
    self._verbose_info:update(delta)
end

--- @brief
function mn.Scene:_update_grabbed_object_position()
    if self._grabbed_object == nil then return end
    local current = self._selection_graph:get_current_node_aabb()
    local sprite_w, sprite_h = self._grabbed_object_sprite:get_minimum_size()
    self._grabbed_object_x = current.x + 0.5 * current.width - 0.5 * sprite_w
    self._grabbed_object_y = current.y + 0.5 * current.height - 0.5 * sprite_h
    self._grabbed_object_bounds = rt.AABB(current.x, current.y, sprite_w, sprite_h)
end

--- @brief
function mn.Scene:_set_grabbed_object(object, origin_slot_i)
    self._grabbed_object = object
    self._grabbed_object_origin_slot_i = origin_slot_i
    if object ~= nil then
        self._grabbed_object_sprite = rt.LabeledSprite(object:get_sprite_id())
        self._grabbed_object_sprite:set_label("<color=LIGHT_RED_3><o>\u{00D7}</o></color>")
        self._grabbed_object_sprite:realize()
        local sprite_w, sprite_h = self._grabbed_object_sprite:get_resolution()
        sprite_w = sprite_w * 2
        sprite_h = sprite_h * 2
        self._grabbed_object_sprite:set_minimum_size(sprite_w, sprite_h)
        self._grabbed_object_sprite:set_opacity(0.5)
        self:_set_grabbed_object_allowed(true)
    else
        self._grabbed_object_sprite = nil
        self._undo_grab = function() end
        for entity_i, page in ipairs(self._entity_pages) do
            page.info:set_preview_values(nil, nil, nil, nil)
            self:_update_entity_info(entity_i)
        end
    end
end

--- @brief
function mn.Scene:_set_grabbed_object_allowed(b)
    if self._grabbed_object == nil then return end
    self._grabbed_object_sprite:set_label_is_visible(not b)
end

--- @brief
function mn.Scene:_set_verbose_info_object(...)
    self._verbose_info:show(self._grabbed_object, ...)
end

--- @brief
function mn.Scene:_update_entity_info(entity_i)
    local entity = self._state.entities[entity_i]
    local page = self._entity_pages[entity_i]
    page.info:set_values(entity:get_hp_base(), entity:get_attack_base(), entity:get_defense_base(), entity:get_speed_base())
end

--- @brief
function mn.Scene:_load_template(template)
    meta.assert_isa(template, mn.Template)

    for entity in values(self._state.entities) do
        if template:has_entity(entity) then
            for move in values(entity:list_moves()) do
                entity:remove_move(move)

                local current_n = state.shared_moves[move]
                if current_n == nil then
                    state.shared_moves[move] = 1
                else
                    state.shared_moves[move] = current_n + 1
                end
            end

            for move in values(template:list_moves(entity)) do
                local current_n = state.shared_moves[move]
                if current_n >= 1 then
                    state.shared_moves[move] = current_n - 1
                    entity:add_move(move)
                else
                    --rt.error("out of moves `" .. move:get_id() .. "`")
                end
            end

            for equip in values(entity:list_equips()) do
                entity:remove_equip(equip)

                local current_n = state.shared_equips[equip]
                if current_n == nil then
                    state.shared_equips[equip] = 1
                else
                    state.shared_equips[equip] = current_n + 1
                end
            end

            for equip in values(template:list_equips(entity)) do
                local current_n = state.shared_equips[equip]
                if current_n >= 1 then
                    state.shared_equips[equip] = current_n - 1
                    entity:add_equip(equip)
                else
                    --rt.error("out of equips `" .. equip:get_id() .. "`")
                end
            end

            for consumable in values(entity:list_consumables()) do
                entity:remove_consumable(consumable)

                local current_n = state.shared_consumables[consumable]
                if current_n == nil then
                    state.shared_consumables[consumable] = 1
                else
                    state.shared_consumables[consumable] = current_n + 1
                end
            end

            for consumable in values(template:list_consumables(entity)) do
                local current_n = state.shared_consumables[consumable]
                if current_n >= 1 then
                    state.shared_consumables[consumable] = current_n - 1
                    entity:add_consumable(consumable)
                else
                    --rt.error("out of consumables `" .. consumable:get_id() .. "`")
                end
            end
        end
    end

    self:_create_from_state(self._state)
end