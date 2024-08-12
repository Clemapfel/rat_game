--- @class rt.Scene
rt.Scene = meta.new_abstract_type("Scene")

--- @override
function rt.Scene:create_from_state(state)
    rt.error("In " .. meta.typeof(self) .. ".create_from_state: abstract method called")
end

--- @override
function rt.Scene:draw()
    rt.error("In " .. meta.typeof(self) .. ".draw: abstract method called")
end

--- @override
function rt.Scene:update(delta)

end