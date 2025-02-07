--- @class ow.OverworldScene
ow.OverworldScene = meta.new_type("OverworldScene", rt.Scene, {
    _is_active = false
})

--- @brief
function ow.OverworldScene:make_active()
end

--- @brief
function ow.OverworldScene:make_inactive()
end

--- @brief
function ow.OverworldScene:get_is_active()
    return self._is_active
end

--- @override
function ow.OverworldScene:create_from_state(state)
end

--- @override
function ow.OverworldScene:realize()
end

--- @override
function ow.OverworldScene:size_allocate()
end

--- @override
function ow.OverworldScene:draw()
end

--- @override
function ow.OverworldScene:update(delta)
end