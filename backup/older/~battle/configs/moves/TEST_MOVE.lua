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

    effect = function(self, user, targets)
        meta.assert_move_interface(self)
        meta.assert_entity_interface(user)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end

        println("[DBG] In " .. self:get_id() .. ".effect: " .. user:get_id() .. " used " .. self:get_id() .. " on " .. tostring(#targets) .. " targets")
    end
}