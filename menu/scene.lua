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

        _control_indicator = rt.ControlIndicator(),
        _inventory_header_label = {}, -- rt.Label
        _inventory_header_frame = rt.Frame(),

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
        _current_entity_i = 3,

        _selection_graph = mn.SelectionGraph(),
        _shared_list_node_active = false,
        _input = rt.InputController(),

        _verbose_info_frame = rt.Frame(),
        _verbose_info = bt.VerboseInfo(),

        _move_only_selection_active = false, -- prevent cursor from leaving move
        _slot_only_selection_active = false, -- prevent cursor from leaving equip / consumable
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

    local control_w, control_h = self._control_indicator:measure()
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

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

    self._inventory_header_label = rt.Label("<o>Inventory</o>")
    self._inventory_header_label:realize()
    self._inventory_header_label:set_justify_mode(rt.JustifyMode.CENTER)
    self._inventory_header_frame:realize()

    self._control_indicator:realize()
    self:_update_control_indicator()

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

            local n = entity:get_n_move_slots()

            local i = 1
            while i < n do
                table.insert(move_layout, table.rep(mn.SlotType.MOVE, ternary(n - i < 5, n - i, 5)))
                i = i + 5
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

    self._verbose_info_frame:realize()
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

    self:set_current_entity_page(1)
    
    self._shared_tab_index_to_list = {
        [self._shared_move_tab_index] = self._shared_move_list,
        [self._shared_consumable_tab_index] = self._shared_consumable_list,
        [self._shared_equip_tab_index] = self._shared_equip_list,
        [self._shared_template_tab_index] = self._shared_template_list
    }
end

--- @brief
function mn.Scene:_create_from_state()
    local entities = self._state.entities
    for entity_i = 1, #entities do
        local page = self._entity_pages[entity_i]
        local entity = entities[entity_i]

        local moves = entity:list_moves()
        page.moves:clear()
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

    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(x + width - control_w - outer_margin, y + outer_margin, control_w, control_h)

    local current_x, current_y = x + outer_margin, y + outer_margin

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

    local verbose_info_w = page_w --width - 2 * outer_margin - tab_w - 2 * m - page_w - 2 * m - shared_page_w - 2 * m
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

    -- TODO
    self._verbose_info:show({bt.Entity("GIRL")})
end

--- @override
function mn.Scene:draw()
    if self._is_realized ~= true then return end

    self._inventory_header_frame:draw()
    self._inventory_header_label:draw()
    self._control_indicator:draw()

    self._shared_tab_bar:draw()

    self._entity_tab_bar:draw()
    local current_page = self._entity_pages[self._current_entity_i]
    if current_page ~= nil then
        current_page.moves:draw()
        current_page.equips_and_consumables:draw()
        current_page.info:draw()
    end

    self._shared_list_frame:draw()
    self._shared_tab_index_to_list[self._shared_tab_index]:draw()
  
    self._verbose_info_frame:draw()
    self._verbose_info:draw()

    --self:_draw_selection_graph() -- TODO
    self._selection_graph:draw()
end

--- @brief
function mn.Scene:_update_control_indicator()
    if self._shared_list_node_active then
        local sort_label = "Sort"
        local next_mode = self._shared_list_sort_mode_order[self._shared_list_sort_mode]
        if next_mode == mn.ScrollableListSortMode.BY_ID then
            sort_label = "Sort (by ID)"
        elseif next_mode == mn.ScrollableListSortMode.BY_NAME then
            sort_label = "Sort (by Name)"
        elseif next_mode == mn.ScrollableListSortMode.BY_QUANTITY then
            sort_label = "Sort (by Quantity)"
        elseif next_mode == mn.ScrollableListSortMode.BY_TYPE then
            sort_label = "Sort (by Type)"
        end

        local prefix, postfix = "", ""-- "<o>", "</o>"
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.A, prefix .. "Equip / Unequip" .. postfix},
            {rt.ControlIndicatorButton.B, prefix .. "Undo" .. postfix},
            {rt.ControlIndicatorButton.X, prefix .. sort_label .. postfix},
            {rt.ControlIndicatorButton.Y, prefix .. "Store" .. postfix}
        })
    else
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.A, "TODO"}
        })
    end

    --[[
    TODO:

        pick up move / equip / consumable, and move it on shared side
        or move it to right side
        quick unequip with r
        quipck equip with l, goes to first

        On shared side:
            A: add item to cursor, then jump to move / slot
            if item is equip, preview stat changes,

        On entity side:
            A: pickup item, or if item is already held, swap
            R: if item is held, send that to pocket, otherwise send what is under cursor position to pocket

        Verbose Info:
            EntityPage
                Name of Entity
                State: Base + Boost = Final
                Explanation of each stat

                HP (<b>H</b>it <b>P</b>oints): Health, if HP reach 0, a character is knocked out. If a character receives 1 or more damage while knocked out, they die permanently and your adventure ends.stat
                ATK (Attack): Used by most moves to calculate the damage dealt, though sometimes ATK influences other parts of a moves behavior
                DEF (Defense): Reduces damage dealt by most moves and increases healing
                SPD (Speed): At the start of each turn, all entities in battle will be sorted by their speed, with the highest speed acting first. May be overriden by Priority

    ]]--

end

function mn.Scene:_regenerate_selection_nodes()

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
        self._shared_move_tab_index,
        self._shared_consumable_tab_index,
        self._shared_equip_tab_index,
        self._shared_template_tab_index
    ) do
        shared_list_nodes[index] = mn.SelectionGraphNode(self._shared_tab_index_to_list[index]:get_bounds())
    end

    -- entity tab nodes
    local entity_tab_nodes = {}
    for node in values(self._entity_tab_bar:get_selection_nodes()) do
        table.insert(entity_tab_nodes, node)
    end
    table.sort(entity_tab_nodes, function(a, b) return a:get_aabb().y < b:get_aabb().y end)

    -- per-entity page nodes
    local entity_page_nodes = {}
    for entity_i = 1, self._n_entities do
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

    -- debug draw
    self._draw_selection_graph = function(self)
        for node in values(entity_tab_nodes) do
            node:draw()
        end

        local page = entity_page_nodes[self._current_entity_i]
        page.info_node:draw()

        for node in values(page.move_nodes) do
            node:draw()
        end

        for node in values(page.slot_nodes) do
            node:draw()
        end

        for node in values(shared_tab_nodes) do
            node:draw()
        end

        shared_list_nodes[self._shared_tab_index]:draw()
    end

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
                if self._move_only_selection_active ~= true then
                    return nearest
                else
                    return nil
                end
            end)
        end

        -- up to info, unless locked
        for node in values(page.top_move_nodes) do
            node:set_up(function()
                if self._move_only_selection_active ~= true then
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
                if self._move_only_selection_active ~= true then
                    return nearest
                else
                    return nil
                end
            end)
        end

        -- right to shared, unless locked
        for node in values(page.right_move_nodes) do
            node:set_right(function()
                if self._move_only_selection_active ~= true then
                    return shared_list_nodes[self._shared_tab_index]
                else
                    return nil
                end
            end)
        end

        -- slots up or down, unless locked
        for node in values(page.slot_nodes) do
            local nearest_up = find_nearest_node(node, page.bottom_move_nodes, "x")
            node:set_up(function()
                if self._slot_only_selection_active ~= true then
                    return nearest_up
                else
                    return nil
                end
            end)

            node:set_down(nil)
        end

        --slots left, unless locked
        page.slot_nodes[1]:set_left(function()
            if self._slot_only_selection_active ~= true then
                return entity_tab_nodes[#entity_tab_nodes]
            else
                return nil
            end
        end)

        -- slots right, unless locked
        page.slot_nodes[#(page.slot_nodes)]:set_right(function()
            if self._slot_only_selection_active ~= true then
                return shared_list_nodes[self._shared_tab_index]
            else
                return nil
            end
        end)
    end
    for entity_tab_node in values(entity_tab_nodes) do
        -- precompute nearest node for all entity pages
        local nearest = {}
        for entity_i = 1, self._n_entities do
            local page = entity_page_nodes[entity_i]
            nearest[entity_i] = find_nearest_node(
                entity_tab_node, {
                    page.info_node, page.slot_nodes[1], table.unpack(page.left_move_nodes)
                }, "y"
            )
        end
        entity_tab_node:set_right(function()
            return nearest[self._current_entity_i]
        end)
    end

    shared_tab_nodes[1]:set_left(function()
        return entity_page_nodes[self._current_entity_i].info_node
    end)

    local shared_list_left = function()
        return entity_page_nodes[self._current_entity_i].right_move_nodes[1]
    end
    for node in values(shared_list_nodes) do
        node:set_left(shared_list_left)
    end

    local shared_tab_down = function()
        return shared_list_nodes[self._shared_tab_index]
    end

    for node in values(shared_tab_nodes) do
        node:set_down(shared_tab_down)
    end

    local shared_list_up = function()
        return shared_tab_nodes[self._shared_tab_index]
    end

    for node in values(shared_list_nodes) do
        node:set_up(shared_list_up)
    end

    -- activation
    for node in values(shared_list_nodes) do
        node:set_on_enter(function()
            self._shared_list_node_active = true
        end)

        node:set_on_exit(function()
            self._shared_list_node_active = false
        end)
    end

    for entity_i, node in ipairs(entity_tab_nodes) do
        node:set_on_activate(function()
            self:set_current_entity_page(entity_i)
        end)
    end

    for tab_i, node in ipairs(shared_tab_nodes) do
        node:set_on_activate(function()
            self:set_current_shared_list_page(tab_i)
        end)
    end

    -- push
    self._selection_graph:clear()

    for nodes in range(
        entity_tab_nodes,
        shared_tab_nodes,
        shared_list_nodes
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

    self._selection_graph:set_current_node(entity_tab_nodes[self._current_entity_i])
end

--- @brief
function mn.Scene:_handle_button_pressed(which)
    ::restart::
    if self._shared_list_node_active == true then
        local current_shared_list = self._shared_tab_index_to_list[self._shared_tab_index]
        
        if which == rt.InputButton.UP then
            -- escape from tab list when going up
            local exit = current_shared_list:move_up()
            if exit == false then
                self._shared_list_node_active = false
                goto restart
            else
                self._verbose_info:show({current_shared_list:get_selected(), POSITIVE_INFINITY})
            end
        elseif which == rt.InputButton.DOWN then
            current_shared_list:move_down()
            self._verbose_info:show({current_shared_list:get_selected(), POSITIVE_INFINITY})
        elseif which == rt.InputButton.RIGHT then
            self._selection_graph:move_right()
        elseif which == rt.InputButton.LEFT then
            self._selection_graph:move_left()
        elseif which == rt.InputButton.A then
            -- TODO
        end
    else
        if which == rt.InputButton.UP then
            self._selection_graph:move_up()
        elseif which == rt.InputButton.RIGHT then
            self._selection_graph:move_right()
        elseif which == rt.InputButton.DOWN then
            self._selection_graph:move_down()
        elseif which == rt.InputButton.LEFT then
            self._selection_graph:move_left()
        elseif which == rt.InputButton.A then
            self._selection_graph:activate()
        end
    end
end

--- @brief
function mn.Scene:set_current_entity_page(i)
    if i < 1 or i > self._n_entities then return end
    self._current_entity_i = i
    self._entity_tab_bar:set_selected(self._current_entity_i)
end

--- @brief
function mn.Scene:set_current_shared_list_page(i)
    if i < 1 or i > 4 then return end
    self._shared_tab_index = i
    self:_update_inventory_header_label()
end

--- @brief
function mn.Scene:open_options()
    rt.warning("In mn.Scene.open_options: TODO")
end