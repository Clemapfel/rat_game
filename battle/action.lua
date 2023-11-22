--- @class bt.TargetingMode
bt.TargetingMode = meta.new_enum({
    SINGLE = 1,
    MULTIPLE = 2,
    STAGE = 3
})

bt.Action = meta.new_abstract_type("BattleAction")

bt.Action.targeting_mode = bt.TargetingMode.SINGLE
bt.Action.can_target_ally = true
bt.Action.can_target_enemy = true
bt.Action.can_target_self = true

bt.Action.name = "ERROR"
bt.Action.thumbnail_id = "default"
bt.Action.animation_id = "default"
bt.Action.effect_text = "No effect."
bt.Action.flavor_text = "This move is unitialized"

--- @class bt.Move
bt.Move = meta.new_type("Move", function(id)
    meta.assert_string(id)
    return meta.new(bt.Move, {
    }, bt.Action)
end)

bt.Move.n_uses = POSITIVE_INFINITY

--- @class bt.Consumable
bt.Consumable = meta.new_type("Consumable", function(id)
    meta.assert_string(id)
    return meta.new(bt.Consumable, {
    }, bt.Action)
end)




