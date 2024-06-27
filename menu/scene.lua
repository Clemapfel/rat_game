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
        _shared_tab_bar = mn.TabBar(),
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

        _shared_move_list = mn.ScrollableList(),
        _shared_equip_list = mn.ScrollableList(),
        _shared_consumable_list = mn.ScrollableList(),

        _input_controller = rt.InputController(),
        _control_indicator = rt.ControlIndicator(),

        -- entity side
        _current_entity = nil,    -- bt.Entity

        _equip_slot_01 = {},
        _equip_slot_02 = {},
        _consumable_slot = {},
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

    local tab_sprites = {
        [self._shared_move_tab_index] = self._shared_move_tab_sprite,
        [self._shared_consumable_tab_index] = self._shared_consumable_tab_sprite,
        [self._shared_equip_tab_index] = self._shared_equip_tab_sprite,
    }

    for sprite in values(tab_sprites) do
        self._shared_tab_bar:push(sprite)
        sprite:realize()
    end

    self._shared_tab_bar:realize()

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

    self._equip_slot_01 = mn.EquipSlot(bt.EquipType.UNKNOWN)
    self._equip_slot_02 = mn.EquipSlot(bt.EquipType.UNKNOWN)
    self._consumable_slot = mn.ConsumableSlot()

    for slot in range(self._equip_slot_01, self._equip_slot_02, self._consumable_slot) do
        slot:realize()
    end
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
    local m = rt.settings.margin_unit
    local tab_x, tab_y = 200, 200
    local tab_offset = 0
    local tab_w, tab_h = self._shared_tab_bar:measure()
    self._shared_tab_bar:fit_into(tab_x + tab_offset + padding + 2, tab_y, tab_w, tab_h)
    tab_w, tab_h = self._shared_tab_bar:measure() -- update after resize

    local shared_list_w = 400
    local shared_list_h = 100
    local shared_list_frame_bounds = rt.AABB(tab_x, tab_y + tab_h, shared_list_w, shared_list_h)
    local x_margin, y_margin = m, 0.5 * m
    for list in range(
        self._shared_move_list,
        self._shared_consumable_list,
        self._shared_equip_list
    ) do
        list:fit_into(
            shared_list_frame_bounds.x + x_margin,
            shared_list_frame_bounds.y + y_margin,
            shared_list_frame_bounds.width - 2 * x_margin,
            shared_list_frame_bounds.height - 2 * y_margin
        )
    end

    self._shared_list_frame:fit_into(shared_list_frame_bounds)

    local indicator_bounds = rt.AABB(x, y, width, height)
    local m = 2 * rt.settings.margin_unit
    indicator_bounds.x = m
    indicator_bounds.y = m
    indicator_bounds.width = indicator_bounds.width - 2 * m
    indicator_bounds.height = indicator_bounds.width - 2 * m
    self._control_indicator:fit_into(indicator_bounds);

    local slot_y = y + height - 2 * m
    local slot_w = 50
    local slot_x = x + 2 * m
    self._equip_slot_01:fit_into(slot_x, slot_y, slot_w, slot_w)
    slot_x = slot_x + slot_w + m
    self._equip_slot_02:fit_into(slot_x, slot_y, slot_w, slot_w)
    slot_x = slot_x + slot_w + m
    self._consumable_slot:fit_into(slot_x, slot_y, slot_w, slot_w)
end

--- @override
function mn.Scene:draw()
    self._shared_tab_bar:draw()
    self._shared_list_frame:draw()

    if self._current_shared_tab == self._shared_move_tab_index then
        self._shared_move_list:draw()
    elseif self._current_shared_tab == self._shared_consumable_tab_index then
        self._shared_consumable_list:draw()
    elseif self._current_shared_tab == self._shared_equip_tab_index then
        self._shared_equip_list:draw()
    end

    self._equip_slot_01:draw()
    self._equip_slot_02:draw()
    self._consumable_slot:draw()

    self._control_indicator:draw()
end