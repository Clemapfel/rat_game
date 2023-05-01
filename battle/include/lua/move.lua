--- @class Move
rt.Move = meta.new_type("Move", {
    id = "",
    name = "",
    description = "TODO",

    --- @brief (Entity self, Entit target) -> nil
    apply = rt.IgnitionEffect(),

    n_stacks = POSITIVE_INFINITY,
    ap_cost = 0,

    can_target_self = false,
    can_target_ally = false,
    can_target_enemy = false
})

rt.Move.__meta.__eq = function(self, other)
    return self.id == other.id
end

meta.set_constructor(rt.Move, function(self, args)

    local out = meta.new(rt.Move, args)

    if not (out.can_target_self or out.can_target_ally or out.can_target_enemy) then
        error("[ERROR] In rt.Move(): Move `" .. "` cannot target any entity. Set at least one of `can_target_self`, `can_target_ally` or `can_target_enemy` to true")
    end

    out.apply = rt.IgnitionEffect(args.apply)

    return out
end)

--- @brief add move
--- @param id String
--- @param arguments Table
--- @return Move
function rt.new_move(id, args)
    args.id = id
    if args.name == nil then
        args.name = id
    end
    return rt.Move(args)
end