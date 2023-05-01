--- @brief basic attack
rt.BASIC_ATTACK = rt.new_move("basic_attack", {

    apply = function (self, other)
        rt.log(self.name .. " attacks " .. other.name)
        local damage = rt.get_attack(self)
        rt.reduce_hp(other, damage)
    end,

    can_target_enemy = true,
    can_target_ally = true,
    can_target_self = false,

    name = "",
    description = "TODO"
})