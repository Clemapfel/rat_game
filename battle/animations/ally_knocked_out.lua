--- @class bt.Animation.ALLY_KNOCKED_OUT
bt.Animation.ALLY_KNOCKED_OUT = meta.new_type("ALLY_KNOCKED_OUT", rt.Animation, function(scene, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_string(message) end

    return meta.new(bt.Animation.ALLY_KNOCKED_OUT, {
        _scene = scene,
        _entity = entity,
        _message = message,

        _knocked_out_animation = nil, -- rt.Sprite

    })
end)

--- @override
function bt.Animation.ALLY_KNOCKED_OUT:start()
    self._target = self._scene:get_sprite(self._entity)
    self._animation = rt.Sprite(self._entity:get_config())
end

--- @override
--function bt.Animation.