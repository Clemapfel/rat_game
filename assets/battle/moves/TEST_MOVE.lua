return {
    name = "Test Move",
    sprite_id = "orbs",
    sprite_index = 3,

    animation_id = "",

    stance_alignment = "NEUTRAL",

    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = true,
    can_target_ally = false,

    priority = 1,

    description = "Deal damage equal to 1× <color=ATTACK>ATK</color>",
    bonus_description = "50% more damage, priorty",

    effect = function(user, targets)
        user:reduce_hp(150)
    end
}