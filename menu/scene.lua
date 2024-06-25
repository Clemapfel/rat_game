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

--- @class mn.InventoryState
mn.InventoryState = meta.new_type("MenuInventoryState", function()
    return meta.new(mn.InventoryState, {
        shared_moves = {},       -- Table<bt.Move, Number>
        shared_consumables = {}, -- Table<bt.Consumable, Number>
        shared_equips = {},      -- Table<bt.Equip, Number>
        stack = {},              -- Table<Union<bt.Move, bt.Equip, bt.Consumable>>
        equips = {},             -- Table<bt.Entity, Table<bt.Equip>>
        current_entity = nil,    -- bt.Entity
    })
end)

--- @class mn.Scene
mn.Scene = meta.new_type("MenuScene", rt.Scene, function()
    return meta.new(mn.Scene, {
        state = mn.InventoryState(),
    })
end)

--- @brief
function mn.Scene:realize()
    if self._is_realized == true then return end


end