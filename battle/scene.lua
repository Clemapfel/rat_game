--- @class bt.Scene
bt.Scene = meta.new_type("BattleScene", rt.Widget, function()
    local out = meta.new(bt.Scene, {
        -- states
        _states = {},
        _current_state = nil

        -- graphics
    })

    out._states[bt.SceneState.INSPECT] = bt.SceneState.INSPECT(out)
    return out
end)

--- @brief
function bt.Scene:realize()

end

--- @brief
function bt.Scene:size_allocate(x, y, width, height)

end

--- @brief
function bt.Scene:update(delta)
    if self._current_state ~= nil then
        self._current_state:update(delta)
    end
end

--- @brief
function bt.Scene:draw()
    if self._current_state ~= nil then
        self._current_state:draw()
    end
end

--- @brief
function bt.Scene:transition(new_state)
    local current = self._current_state
    local next = self._states[new_state]

    if current ~= nil then
        current:exit()
    end

    if next == nil then
        rt.error("In bt.Scene.transition: no state `" .. new_state .. "` present")
    end

    self._current_state = next
    next:enter()
end