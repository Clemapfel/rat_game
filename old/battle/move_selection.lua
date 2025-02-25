--- @class bt.MoveSelection
bt.MoveSelection = function(user, move, targets)
    meta.assert_isa(user, bt.Entity)
    if move ~= nil then
        meta.assert_isa(move, bt.MoveConfig)
    end
    meta.assert_table(targets)

    for target in values(targets) do
        meta.assert_isa(target, bt.Entity)
    end

    return {
        user = user,
        move = move,
        targets = targets
    }
end