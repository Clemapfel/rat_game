--- @class bt.TargetingMode
bt.TargetingMode = meta.new_enum({
    SINGLE = 1,
    MULTIPLE = 2,
    STAGE = 3
})

--- @class bt.Action
--- @brief immutable config for battle actions
bt.Action = meta.new_type("Action", function(id)
    meta.assert_string(id)
    local out = meta.new(bt.Action, {
        id = id
    })
    meta.set_is_mutable(out, false)
end)

-- possible targets
bt.Action.targeting_mode = bt.TargetingMode.SINGLE
bt.Action.can_target_ally = true
bt.Action.can_target_enemy = true
bt.Action.can_target_self = true

-- maximum number of uses
bt.Action.max_n_uses = POSITIVE_INFINITY

-- cleartext name
bt.Action.name = "ERROR_ACTION"

-- clear text effect
bt.Action.effect_text = "No effect."

-- flavor text for inventory, optional
bt.Action.flavor_text = ""

-- sprite for inventory thumbnail
bt.Action.thumbnail_id = "default"

-- sprite for in-battle animation
bt.Action.animation_id = "default"

--- @class bt.Move
bt.Move = meta.new_type("Move", function(id)
    meta.assert_string(id)
    local action = bt.Action(id)
    return meta.new(bt.Move, {
        action = action,
        current_n_uses = action.max_n_uses
    })
end)

--- @class bt.Consumable
bt.Consumable = meta.new_type("Consumable", function(id, n_stacks)
    meta.assert_string(id)
    meta.assert_number(n_stacks)
    local action = bt.Action(id)
    return meta.new(bt.Consumable, {
        action = action,
        n_stacks = n_stacks
    })
end)




