--- @class bt.Animation.ALLY_KNOCKED_OUT
bt.Animation.ALLY_KNOCKED_OUT = meta.class("ALLY_KNOCKED_OUT", rt.Animation)

--- @brief
function bt.Animation.ALLY_KNOCKED_OUT(scene, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_string(message) end

    return meta.install(self, {
        _scene = scene,
        _entity = entity,
        _target = nil,

        _message = message,
        _message_done = false,
        _message_id = nil
    })
end

--- @override
function bt.Animation.ALLY_KNOCKED_OUT:start()
    self._target = self._scene:get_sprite(self._entity)
    self._target:set_is_visible(false)

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.ALLY_KNOCKED_OUT:finish()
    self._target:set_is_visible(true)
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.ALLY_KNOCKED_OUT:update(delta)
    return rt.AnimationResult.DISCONTINUE
end

--- @override
function bt.Animation.ALLY_KNOCKED_OUT:draw()
end