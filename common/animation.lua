--- @class rt.Animation
rt.Animation = meta.new_abstract_type("Animation")

--- @brief abstract method, must be override
function rt.Animation:update(delta)
    rt.error("In " .. meta.typeof(self) .. ":update(): abstract method called")
end