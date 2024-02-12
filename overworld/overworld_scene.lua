--- @class CameraMode
ow.CameraMode = meta.new_enum({
    MANUAL = "MANUAL",
    FOLLOW_PLAYER = "FOLLOW_PLAYER",
    STATIONARY = "STATIONARY"
})

--- @class
ow.OverworldScene = meta.new_type("OverworldScene", function()
    local map = ow.Map("debug_map", "assets/maps/debug")
    local out = meta.new(ow.OverworldScene, {
        _player = ow.Player(map._world),
        _camera = ow.Camera(),
        _camera_mode = ow.CameraMode.FOLLOW_PLAYER,
        _map = map
    }, rt.Widget, rt.Animation)

    return out
end)

--- @brief
function ow.OverworldScene:set_camera_mode(mode)
    meta.assert_enum(mode, ow.CameraMode)
    self._camera_mode = mode
end

--- @overload
function ow.OverworldScene:draw()
    self._camera:bind()
    self._map:draw()
    self._player:draw()
    self._camera:unbind()
end

--- @overload
function ow.OverworldScene:update(delta)
    self._map:update(delta)
end

--- @overload
function ow.OverworldScene:size_allocate(x, y, width, height)

end