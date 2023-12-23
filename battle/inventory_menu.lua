--- @class bt.InventoryMenuState
bt.InventoryMenuState = meta.new_type("InventoyMenuState", function(id)
    return meta.new(bt.InventoryMenuState, {
        entity_id = id,
        equipment = {},     -- slot (1-based) -> equipment
        inherent = {},      -- 1-based -> bt.Action
        moves = {},         -- 1-based -> bt.Action
        consumables = {},   -- 1-based -> bt.Action
        attack_ev = 0,
        defense_ev = 0,
        speed_ev = 0,
    })
end)

--- @class bt.InventoryControlDisplay
bt.InventoryControlDisplay = meta.new_type("InventoryControlDisplay", function()
    return meta.new(bt.InventoryControlDisplay, {
        --_box =
    })
end)
