return {
    name = "Debug Move",
    description = "Used for debugging, no effect but prints a message for every battle event",
    flavor_text = "if a move does nothing, is it even a move?",

    sprite_id = "orbs",
    sprite_index = 1,

    animation_id = "",

    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = true,

    priority = 0,
    max_n_uses = POSITIVE_INFINITY,

    effect = function(self, user, targets)
        meta.assert_move_interface(self)
        meta.assert_entity_interface(user)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end

        println("[DBG] In " .. self:get_id() .. ".effect: " .. user:get_id() .. " used " .. self:get_id() .. " on " .. tostring(#targets) .. " targets")
    end
}