return {
    name = "Debug Move",
    description = "Does nothing",
    flavor_text = "",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = false,

    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = true,
    can_target_ally = true,

    sprite_id = "moves",
    sprite_index = "DEBUG_MOVE",

    effect = function(self, user, targets)
        assert_is_move_proxy(self)
        assert_is_entity_proxy(user)
        for entity in values(targets) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " effect")
    end
}