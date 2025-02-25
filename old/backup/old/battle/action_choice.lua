--- @class bt.ActionChoice
bt.ActionChoice = meta.new_type("ActionChoice", function(user, move, targets)
    meta.assert_isa(user, bt.Entity)
    meta.assert_isa(move, bt.Move)
    meta.assert_table(targets)
    for e in values(targets) do
        meta.assert_isa(e, bt.Entity)
    end

    return meta.new(bt.ActionChoice, {
        user = user,
        move = move,
        targets = targets
    })
end)