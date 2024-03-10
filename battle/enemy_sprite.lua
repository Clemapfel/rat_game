--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", rt.Widget, rt.Animation, function(entity)
    return meta.new(bt.EnemySprite, {
        _entity = entity,
        _is_realized = false,


    })
end)

--- @brief
function bt.EnemySprite:realize()
    if self._is_realized then return end

end