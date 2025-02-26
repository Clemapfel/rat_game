--- @class rt.Scene
--- @signal update (rt.Scene) -> nil
rt.Scene = meta.abstract_class("Scene", rt.Widget)

--- @brief
function rt.Scene:instantiate()
    self._is_active = false
end

meta.add_signals(rt.Scene,
    "update"
)

--- @brief
function rt.Scene:make_active()
    rt.error("In " .. meta.typeof(self) .. ".make_active: abstract method called")
end

--- @brief
function rt.Scene:make_inactive()
    rt.error("In " .. meta.typeof(self) .. ".make_active: abstract method called")
end

--- @brief
function rt.Scene:get_is_active()
    return self._is_active
end

--- @override
function rt.Scene:create_from_state(state)
    rt.error("In " .. meta.typeof(self) .. ".create_from_state: abstract method called")
end

--- @override
function rt.Scene:realize()
    rt.error("In " .. meta.typeof(self) .. ".realize: abstract method called")
end

--- @override
function rt.Scene:size_allocate()
    rt.error("In " .. meta.typeof(self) .. ".realize: abstract method called")
end

--- @override
function rt.Scene:draw()
    rt.error("In " .. meta.typeof(self) .. ".draw: abstract method called")
end

--- @override
function rt.Scene:update(delta)
    rt.error("In " .. meta.typeof(self) .. ".update: abstract method called")
end