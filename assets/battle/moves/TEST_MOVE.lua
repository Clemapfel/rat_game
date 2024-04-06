return {
    name = "Test Move",
    sprite_id = "orbs",
    sprite_index = 3,

    animation_id = "",

    stance_alignment = "NEUTRAL",

    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = false,
    can_target_ally = false,

    priority = 1,

    description = "Deal damage equal to 1× <color=ATTACK>ATK</color>",
    bonus_description = "+50% damage",

    effect = function(user, targets)
        local damage = user:get_attack()
        if user:stance_matches(self.alignment) then
            damage = damage * 1.5
        end
        for target in targets do
            target:deal_damage(damage)
        end
    end
}