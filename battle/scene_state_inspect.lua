--- @class bt.SceneState.INSPECT
bt.SceneState.INSPECT = meta.new_type("INSPECT", function(scene)
    local out = meta.new(bt.SceneState.INSPECT, {
        _scene = scene,
    })

    return out
end)

--- @brief [internal]
function bt.SceneState.INSPECT._on_pressed(button)
    if which == rt.InputButton.UP then
        self._scene._selection_handler:move_up()
    elseif which == rt.InputButton.RIGHT then
        self._scene._selection_handler:move_right()
    elseif which == rt.InputButton.DOWN then
        self._scene._selection_handler:move_down()
    elseif which == rt.InputButton.LEFT then
        self._scene._selection_handler:move_left()
    end
end

--- @override
function bt.SceneState.INSPECT:enter()
    self._controller:set_is_disabled(false)
end

--- @override
function bt.SceneState.INSPECT:exit()
    self._controller:set_is_disabled(true)
end

--- @override
function bt.SceneState.INSPECT:update(delta)
    -- noop
end

--- @override
function bt.SceneState.INSPECT:draw()

end