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

    description = "Deal damage equal to 1× <color=ATTACK>ATK</color>, always hits first, unless we have to add even more text",
    bonus_description = "<color=ATTACK>A</color> B <color=DEFENSE>C</color>",

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