--- @class rt.Scene
rt.Scene = meta.new_abstract_type("Scene", rt.Widget, {
    _current_state = nil
})

--- @brief
function rt.Scene:transition(new_state)
    meta.assert_isa(new_state, bt.SceneState)

    if self._is_realized == false then
        self:realize()
    end

    local last_state = self._current_state
    local next_state = new_state

    self._current_state = next_state

    if last_state ~= nil then
        last_state:exit()
    end

    if next_state ~= nil then
        next_state:enter()
    end
end
