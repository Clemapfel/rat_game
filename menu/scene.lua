rt.settings.menu.scene = {
    tab_bar_sprite_id = "menu_icons",
    equips_sprite_index = "equips",
    moves_sprite_index = "moves",
    consumables_sprite_index = "consumables"
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

        _control_indicator = rt.ControlIndicator(),
        _inventory_header_label = {}, -- rt.Label
        _inventory_header_frame = rt.Frame(),

        _shared_list_frame = rt.Frame(),
        _shared_move_tab_sprite = {}, -- rt.Sprite
        _shared_equip_tab_sprite = {}, -- rt.Sprite
        _shared_consumable_tab_sprite = {}, -- rt.Sprite

        _shared_tab_bar = mn.TabBar(),
        _shared_list_sort_mode = mn.ScrollableListSortMode.BY_ID,

        _current_shader_list_index = 1,
        _shared_move_list = mn.ScrollableList(),
        _shared_equip_list = mn.ScrollableList(),
        _shared_consumable_list = mn.ScrollableList(),
        _shared_template_list = mn.ScrollableList(),

        _entity_tab_bar = mn.TabBar(),
        _entity_pages = {}, -- Table<Number, {info, equips_and_consumables, moves}>
        _current_entity_i = 1,

        _selection_nodes = {}, -- Table<mn.SelectionGraphNode>
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

    self._inventory_header_label = rt.Label("<o>Inventory</o>")
    self._inventory_header_label:realize()
    self._inventory_header_label:set_justify_mode(rt.JustifyMode.CENTER)
    self._inventory_header_frame:realize()

    self._control_indicator:realize()
    self:_update_control_indicator()

    local temp_label_font =  rt.Font(80,
        "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )
    
    local settings = rt.settings.menu.scene
    local tab_sprites = {
        [self._shared_move_tab_index] = rt.Sprite(settings.tab_bar_sprite_id, settings.moves_sprite_index),
        [self._shared_consumable_tab_index] = rt.Sprite(settings.tab_bar_sprite_id, settings.consumables_sprite_index),
        [self._shared_equip_tab_index] = rt.Sprite(settings.tab_bar_sprite_id, settings.equips_sprite_index),
    }

    for sprite in values(tab_sprites) do
        local sprite_w, sprite_h = sprite:get_resolution()
        sprite_w = sprite_w * 2
        sprite_h = sprite_h * 2
        sprite:set_minimum_size(sprite_w, sprite_h)
        self._shared_tab_bar:push(sprite)
    end

    local template_label = rt.Label("<o>T</o>", temp_label_font)
    self._shared_tab_bar:push(template_label)

    self._shared_tab_bar:set_orientation(rt.Orientation.HORIZONTAL)
    self._shared_tab_bar:set_n_post_aligned_items(1)
    self._shared_tab_bar:realize()

    for list in range(
        self._shared_move_list,
        self._shared_equip_list,
        self._shared_consumable_list,
        self._shared_template_list
    ) do
        list:realize()
    end

    self._entity_pages = {}
    local entities = self._state.entities
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
            local to_push = {}
            while n >= 1 do
                table.insert(to_push, mn.SlotType.MOVE)
                if #to_push >= 5 then
                    table.insert(move_layout, to_push)
                    to_push = {}
                end
                n = n - 1
            end
            if #to_push ~= 0 then
                table.insert(move_layout, to_push)
            end
        end

        local page = {
            info = mn.EntityInfo(entity),
            equips_and_consumables = mn.Slots({equip_consumable_layout}),
            moves = mn.Slots(move_layout)
        }

        page.info:realize()
        page.equips_and_consumables:realize()
        page.moves:realize()

        -- TODO: fill pages

        self._entity_pages[entity_i] = page
    end

    local settings_label = rt.Label("<o>\u{2699}</o>", temp_label_font)
    self._entity_tab_bar:push(settings_label)
    self._entity_tab_bar:set_n_post_aligned_items(1)
    self._entity_tab_bar:set_orientation(rt.Orientation.VERTICAL)
    self._entity_tab_bar:realize()

    self:_create_from_state(self._state)
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
    self._inventory_header_frame:size_allocate(current_x, current_y, header_w, control_h)
    self._inventory_header_label:size_allocate(current_x, current_y + 0.5 * control_h - 0.5 * header_h, header_w, control_h)

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

    self._entity_tab_bar:fit_into(current_x, current_y, tile_size, height - outer_margin - (current_y - y))
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

    local shared_page_w = control_w
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
    self:_regenerate_selection_nodes()
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

    local list_i = self._current_shader_list_index
    if list_i == self._shared_move_tab_index then
        self._shared_move_list:draw()
    elseif list_i == self._shared_consumable_tab_index then
        self._shared_consumable_list:draw()
    elseif list_i == self._shared_equip_tab_index then
        self._shared_equip_list:draw()
    elseif list_i == self._shared_template_tab_index then
        self._shared_template_list:draw()
    end

    for node in values(self._selection_nodes) do
        node:draw()
    end
end

--- @brief
function mn.Scene:_update_control_indicator()
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
end

function mn.Scene:_regenerate_selection_nodes()
    self._selection_nodes = {}

    local page = self._entity_pages[self._current_entity_i]

    local entity_tab_nodes = {}
    for node in values(self._entity_tab_bar:get_selection_nodes()) do
        table.insert(entity_tab_nodes, node)
    end

    table.sort(entity_tab_nodes, function(a, b)
        return a:get_aabb().y < b:get_aabb().y
    end)

    local info_node = mn.SelectionGraphNode()
    info_node:set_aabb(page.info:get_bounds())

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

    table.sort(slot_nodes, function(a, b)
        return a:get_aabb().x < b:get_aabb().x
    end)

    local shared_tab_nodes = {}
    for node in values(self._shared_tab_bar:get_selection_nodes()) do
        table.insert(shared_tab_nodes, node)
    end

    table.sort(slot_nodes, function(a, b)
        return a:get_aabb().x < b:get_aabb().x
    end)

    local shared_move_node = mn.SelectionGraphNode()
    shared_move_node:set_aabb(self._shared_move_list:get_bounds())
    local shared_consumable_node = mn.SelectionGraphNode()
    shared_consumable_node:set_aabb(self._shared_consumable_list:get_bounds())
    local shared_equip_node = mn.SelectionGraphNode()
    shared_equip_node:set_aabb(self._shared_equip_list:get_bounds())
    local shared_template_node = mn.SelectionGraphNode()
    shared_template_node:set_aabb(self._shared_template_list:get_bounds())

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
            error("unreachable")
        end
    end

    local slot_node = slot_nodes[1]
    slot_node:set_left(find_nearest_node(slot_node, entity_tab_nodes, "y"))
    info_node:set_left(entity_tab_nodes[1])

    for node in values(left_move_nodes) do
        node:set_left(find_nearest_node(node, entity_tab_nodes, "y"))
    end

    for node in values(slot_nodes) do
        node:set_up(find_nearest_node(node, bottom_move_nodes, "x"))
    end

    for node in values(bottom_move_nodes) do
        node:set_down(find_nearest_node(node, slot_nodes, "x"))
    end

    for node in values(top_move_nodes) do
        node:set_up(info_node)
    end

    local move_right_connect_node = shared_tab_nodes[1]
    for node in values(right_move_nodes) do
        node:set_right(move_right_connect_node)
    end

    shared_tab_nodes[1]:set_left(info_node)

    shared_move_node:set_up(shared_tab_nodes[self._shared_move_tab_index])
    shared_move_node:set_left(right_move_nodes[1])

    shared_equip_node:set_up(shared_tab_nodes[self._shared_equip_tab_index])
    shared_equip_node:set_left(table.last(slot_nodes))

    shared_consumable_node:set_up(shared_tab_nodes[self._shared_consumable_tab_index])
    shared_consumable_node:set_left(table.last(slot_nodes))

    shared_template_node:set_up(shared_tab_nodes[self._shared_template_tab_index])
    shared_template_node:set_left(info_node)

    for nodes in range(
        entity_tab_nodes,
        {info_node},
        move_nodes,
        slot_nodes,
        shared_tab_nodes,
        {shared_move_node, shared_equip_node, shared_consumable_node, shared_template_node}
    ) do
        for node in values(nodes) do
            table.insert(self._selection_nodes, node)
        end
    end

    --self._selection_nodes = self._shared_move_list:get_selection_nodes()
end