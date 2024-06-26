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
        current_entity = nil,    -- bt.Entity
    })
end)

--- @class mn.Scene
mn.Scene = meta.new_type("MenuScene", rt.Scene, function()
    return meta.new(mn.Scene, {
        _state = mn.InventoryState(),

        _shared_tab_bar = mn.TabBar(),
        _shared_move_tab_sprite = {}, -- rt.Sprite
        _shared_equip_tab_sprite = {}, -- rt.Sprite
        _shared_consumable_tab_sprite = {}, -- rt.Sprite
        _shared_move_tab_index = 1,
        _shared_consumable_tab_index = 2,
        _shared_equip_tab_index = 3,

        _current_shared_tab = 3,

        _shared_move_list = mn.ScrollableList(),
        _shared_equip_list = mn.ScrollableList(),
        _shared_consumable_list = mn.ScrollableList(),

        _input_controller = rt.InputController(),
    })
end)

--- @brief [internal]
function mn.Scene:_handle_button_pressed(which)
    if which == rt.InputButton.UP then

    elseif which == rt.InputButton.DOWN then

    elseif which == rt.InputButton.A then

    end
end

--- @override
function mn.Scene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._input_controller:signal_connect("pressed", self._handle_button_pressed)
    self._input_controller:signal_connect("released", self._handle_button_released)

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
end

--- @override
function mn.Scene:size_allocate(x, y, width, height)
    local tab_x, tab_y = 50, 50
    local tab_offset = 50
    local tab_w, tab_h = self._shared_tab_bar:measure()
    self._shared_tab_bar:fit_into(tab_x + tab_offset, tab_y, tab_w, tab_h)
    tab_w, tab_h = self._shared_tab_bar:measure() -- update after resize

    local shared_list_w = 400
    local shared_list_h = 200
    for list in range(
        self._shared_move_list,
        self._shared_consumable_list,
        self._shared_equip_list
    ) do
        list:fit_into(tab_x, tab_y + tab_h, shared_list_w, shared_list_h)
    end
end

--- @override
function mn.Scene:draw()
    self._shared_tab_bar:draw()
    if self._current_shared_tab == self._shared_move_tab_index then
        self._shared_move_list:draw()
    elseif self._current_shared_tab == self._shared_consumable_tab_index then
        self._shared_consumable_list:draw()
    elseif self._current_shared_tab == self._shared_equip_tab_index then
        self._shared_equip_list:draw()
    end
end