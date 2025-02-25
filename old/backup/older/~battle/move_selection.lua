--- @class MoveSelection
bt.MoveSelection = meta.new_type("MoveSelection", function(user, target, move)
    return meta.new(bt.MoveSelection, {
        user = user,
        target = target,
        move = move
    })
end)