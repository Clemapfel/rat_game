--- @class rt.Scene
rt.Scene = meta.new_abstract_type("Scene", rt.Widget)

--- @brief
function rt.Scene:transition(state)
    meta.assert_isa(state, rt.SceneState)
    rt.error("In " .. meta.typeof(self) .. ".transtion: abstract method called")
end
