--[[
Entities:

    portraits tab bar
    HP
    tab bar
    name label
    moves / consumables / equips label

    list of items:
    Header: Name, AP, Type
        list of moves
            Icon, Name, Max Uses
        list of consumables
            Icon, Name
        list of equips
            Icon, Name, Type

    Verbose info

    Equip Slot
    Consumable Slot
]]--

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

--- @class mn.Scene
mn.Scene = meta.new_type("MenuScene", rt.Scene, function()
    return meta.new(mn.Scene, {
        _state = mn.InventoryState(),

        -- shared side
        _shared_list_frame = rt.Frame(),
        _shared_move_tab_sprite = {}, -- rt.Sprite
        _shared_equip_tab_sprite = {}, -- rt.Sprite
        _shared_consumable_tab_sprite = {}, -- rt.Sprite
        _shared_move_tab_index = 1,
        _shared_consumable_tab_index = 2,
        _shared_equip_tab_index = 3,

        _shared_list_mode_order = {
            [mn.ScrollableListSortMode.BY_TYPE] = mn.ScrollableListSortMode.BY_NAME,
            [mn.ScrollableListSortMode.BY_NAME] = mn.ScrollableListSortMode.BY_QUANTITY,
            [mn.ScrollableListSortMode.BY_QUANTITY] = mn.ScrollableListSortMode.BY_ID,
            [mn.ScrollableListSortMode.BY_ID] = mn.ScrollableListSortMode.BY_TYPE,
        },
        _shared_list_mode = mn.ScrollableListSortMode.BY_ID,
        _current_shared_tab = 3,

        _shared_tabs = mn.TabBar(),
        _shared_tabs_x_offset = 0,
        _shared_move_list = mn.ScrollableList(),
        _shared_equip_list = mn.ScrollableList(),
        _shared_consumable_list = mn.ScrollableList(),

        _input_controller = rt.InputController(),
        _control_indicator = rt.ControlIndicator(),

        -- entity side
        _entity_tabs = mn.TabBar(),
        _current_entity = nil,    -- bt.Entity

        _entity_pages = {}, -- cf. realize
        _entity_page_x_offset = 0,

        -- selection
        _selection_items = {}
    })
end)

--- @brief [internal]
function mn.Scene:_handle_button_pressed(which)
    local current_list
    if self._current_shared_tab == self._shared_move_tab_index then
        current_list = self._shared_move_list
    elseif self._current_shared_tab == self._shared_consumable_tab_index then
        current_list = self._shared_consumable_list
    elseif self._current_shared_tab == self._shared_equip_tab_index then
        current_list = self._shared_equip_list
    end

    if which == rt.InputButton.UP then
        current_list:move_up()
    elseif which == rt.InputButton.DOWN then
        current_list:move_down()
    elseif which == rt.InputButton.A then
        current_list:take(current_list:get_selected())
    elseif which == rt.InputButton.B then
        current_list:add(bt.Equip("DEBUG_EQUIP"))
    elseif which == rt.InputButton.X then
        self._shared_list_mode = self._shared_list_mode_order[self._shared_list_mode]
        self._shared_move_list:set_sort_mode(self._shared_list_mode)
        self._shared_equip_list:set_sort_mode(self._shared_list_mode)
        self._shared_consumable_list:set_sort_mode(self._shared_list_mode)
        self:_update_control_indicator()
    elseif which == rt.InputButton.RIGHT then
        if self._current_shared_tab == self._shared_move_tab_index then
            self._current_shared_tab = self._shared_consumable_tab_index
        elseif self._current_shared_tab == self._shared_consumable_tab_index then
            self._current_shared_tab = self._shared_equip_tab_index
        elseif self._current_shared_tab == self._shared_equip_tab_index then
            self._current_shared_tab = self._shared_move_tab_index
        end
    end
end

--- @override
function mn.Scene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._input_controller:signal_connect("pressed", function(_, button)
        if self._current_state ~= nil then
            self._current_state:handle_button_pressed(button)
        end

        self:_handle_button_pressed(button)
    end)

    self._input_controller:signal_connect("released",  function(_, button)
        if self._current_state ~= nil then
            self._current_state:handle_button_released(button)
        end
    end)

    -- tab
    local settings = rt.settings.menu.scene
    self._shared_move_tab_sprite = rt.Sprite(settings.tab_bar_sprite_id, settings.moves_sprite_index)
    self._shared_consumable_tab_sprite = rt.Sprite(settings.tab_bar_sprite_id, settings.consumables_sprite_index)
    self._shared_equip_tab_sprite = rt.Sprite(settings.tab_bar_sprite_id, settings.equips_sprite_index)

    local temp_label_font =  rt.Font(80,
        "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )

    local tab_sprites = {
        [self._shared_move_tab_index] = self._shared_move_tab_sprite,
        [self._shared_consumable_tab_index] = self._shared_consumable_tab_sprite,
        [self._shared_equip_tab_index] = self._shared_equip_tab_sprite,
    }

    for sprite in values(tab_sprites) do
        local sprite_w, sprite_h = sprite:get_resolution()
        sprite_w = sprite_w * 2
        sprite_h = sprite_h * 2
        sprite:set_minimum_size(sprite_w, sprite_h)
        self._shared_tabs:push(sprite)
    end

    local template_label = rt.Label("<o>T</o>")
    self._shared_tabs:push(template_label)

    self._shared_tabs:set_orientation(rt.Orientation.HORIZONTAL)
    self._shared_tabs:set_n_post_aligned_items(1)
    self._shared_tabs:realize()

    -- shared lists
    local moves = {}
    for move, n in pairs(self._state.shared_moves) do
        table.insert(moves, {move, n})
    end
    self._shared_move_list:push(table.unpack(moves))
    self._shared_move_list:realize()

    local consumables = {}
    for consumable, n in pairs(self._state.shared_consumables) do
        table.insert(consumables, {consumable, n})
    end
    self._shared_consumable_list:push(table.unpack(consumables))
    self._shared_consumable_list:realize()

    local equips = {}
    for equip, n in pairs(self._state.shared_equips) do
        table.insert(equips, {equip, n})
    end
    self._shared_equip_list:push(table.unpack(equips))
    self._shared_equip_list:realize()

    self._control_indicator:realize()
    self:_update_control_indicator()

    self._shared_list_frame:realize()

    -- pages
    for entity in values(self._state.entities) do
        local tab_sprite = rt.Sprite(entity:get_sprite_id())
        local sprite_w, sprite_h = tab_sprite:get_resolution()
        sprite_w = sprite_w * 3
        sprite_h = sprite_h * 3
        tab_sprite:set_minimum_size(sprite_w, sprite_h)
        self._entity_tabs:push(tab_sprite)

        local equip_consumable_layout = {}
        local n_equips = entity:get_n_equip_slots()
        for i = 1, n_equips do
            table.insert(equip_consumable_layout, mn.SlotType.EQUIP)
        end

        for i = 1, entity:get_n_consumable_slots() do
            table.insert(equip_consumable_layout, mn.SlotType.CONSUMABLE)
        end

        local move_layout = {}
        do
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

        local movelist = entity:list_moves()
        for i = 1, #movelist do
            page.moves:set_object(i, movelist[i])
        end

        local equip_list = entity:list_equips()
        for i = 1, #equip_list do
            page.equips_and_consumables:set_object(i, equip_list[i])
        end

        local consumable_list = entity:list_consumables()
        for i = 1, #consumable_list do
            page.equips_and_consumables:set_object(i + n_equips, consumable_list[i])
        end

        self._entity_pages[entity] = page
        if self._current_entity == nil then self._current_entity = entity end
    end

    local settings_label = rt.Label("<o>\u{2699}</o>", temp_label_font)
    self._entity_tabs:push(settings_label)
    self._entity_tabs:set_n_post_aligned_items(1)
    self._entity_tabs:set_orientation(rt.Orientation.VERTICAL)
    self._entity_tabs:realize()
end

--- @brief
function mn.Scene:_update_control_indicator()
    local sort_label = "Sort"
    local next_mode = self._shared_list_mode_order[self._shared_list_mode]
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

--- @override
function mn.Scene:size_allocate(x, y, width, height)
    local padding = rt.settings.frame.thickness
    local m = 2 * rt.settings.margin_unit

    local portrait_w = 6 * m
    local portrait_x, portrait_y = x + m, y + m

    local page_w, page_h = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local page_x, page_y = m, m
    local slots_h, slots_w = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for page in values(self._entity_pages) do
        local current_x, current_y = page_x, portrait_y
        local info_w, info_h = page.info:measure()

        local move_w, move_h = page.moves:measure()

        move_w = move_w + 4 * m
        move_h = move_h + 4 * m
        local move_size = math.max(move_w, move_h)

        local slot_h = 300
        local _, equip_h = page.equips_and_consumables:measure()
        equip_h = equip_h + 2 * m

        current_y = y + m

        local move_y = current_y
        page.moves:fit_into(current_x, current_y, move_w, move_h)
        local equip_y = move_y + move_h + 2 * padding
        page.equips_and_consumables:fit_into(current_x, equip_y, move_w, equip_h)
        local info_y = equip_y + equip_h + 2 * padding
        local info_h = y + height - m - info_y
        page.info:fit_into(current_x, info_y, move_w, info_h)

        page_w = math.max(page_w, info_w + move_w + 2 * padding)
        page_h = math.max(page_h, info_h + move_h + 2 * padding)
        slots_h = math.max(slots_h, equip_h)
        slots_w = math.max(slots_w, move_w)
    end

    self._entity_page_x_offset = slots_h + m
    self._entity_tabs:fit_into(x + m, y + m, slots_h, height - 2 * m)

    local control_w, control_h = self._control_indicator:measure()
    self._control_indicator:fit_into(x + width - control_w - m, y + height - control_h - m, control_w, control_h)

    local shared_w = slots_w * 1.5
    local shared_x = x + width - m - shared_w
    local shared_y = m

    local shared_tabs_h = 32 * 2.5
    self._shared_tabs:fit_into(shared_x, shared_y, x + width - shared_x - m, shared_tabs_h)
    self._shared_tabs_x_offset = 0 -- width - select(1, self._shared_tabs:measure())

    shared_y = shared_y + shared_tabs_h + m / 2
    local shared_h = height - 2 * m - (shared_y - m) - control_h - m / 2
    local shared_m = rt.settings.margin_unit
    for list in range(
        self._shared_move_list,
        self._shared_consumable_list,
        self._shared_equip_list
    ) do
        list:fit_into(shared_x + shared_m, shared_y + shared_m, shared_w - 2 * shared_m, shared_h - 2 * shared_m)
    end

    self._shared_list_frame:fit_into(shared_x, shared_y, shared_w, shared_h)
end

--- @override
function mn.Scene:draw()
    if self._is_realized ~= true then return end

    self._entity_tabs:draw()
    self._shared_list_frame:draw()

    if self._current_shared_tab == self._shared_move_tab_index then
        self._shared_move_list:draw()
    elseif self._current_shared_tab == self._shared_consumable_tab_index then
        self._shared_consumable_list:draw()
    elseif self._current_shared_tab == self._shared_equip_tab_index then
        self._shared_equip_list:draw()
    end

    rt.graphics.translate(self._shared_tabs_x_offset, 0)
    self._shared_tabs:draw()
    rt.graphics.translate(-self._shared_tabs_x_offset, 0)

    self._control_indicator:draw()

    rt.graphics.translate(self._entity_page_x_offset, 0)
    local page = self._entity_pages[self._current_entity]
    if page ~= nil then
        page.info:draw()
        page.equips_and_consumables:draw()
        page.moves:draw()
    end
    rt.graphics.translate(-self._entity_page_x_offset, 0)
end

--- @brief [internal]
function mn.Scene:_regenerate_selection_items()

end