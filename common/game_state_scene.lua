
--- @brief
function rt.GameState:set_current_scene(scene_type)
    table.insert(self._active_coroutines, rt.Coroutine(function()
        if self._current_scene ~= nil then
            self._current_scene:make_inactive()
        end

        rt.savepoint_maybe()

        local scene = self._scenes[scene_type]
        if scene == nil then
            scene = scene_type(self)
            self._scenes[scene_type] = scene
        end

        self._current_scene = scene
        self._current_scene:realize()
        rt.savepoint_maybe()
        self._current_scene:fit_into(0, 0, self._state.resolution_x, self._state.resolution_y)
        rt.savepoint_maybe()
        self._current_scene:make_active()
    end))
end