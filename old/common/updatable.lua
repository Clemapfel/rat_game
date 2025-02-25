--- @class rt.Updatable
rt.Updatable = meta.new_abstract_type("Updatable")

--- @brief abstract method, must be override
function rt.Updatable:update(delta)
    rt.error("In " .. meta.typeof(self) .. ":update(): abstract method called")
end