--- @class rt.BackgroundImplementation
rt.BackgroundImplementation = meta.new_abstract_type("BackgroundImplementation")

--- @brief
function rt.BackgroundImplementation:realize()
    rt.error("In " .. meta.typeof(self) .. ".realize: abstract method called")
end

--- @brief
function rt.BackgroundImplementation:size_allocate(x, y, width, height)
    rt.error("In " .. meta.typeof(self) .. ".size_allocate: abstract method called")
end

--- @brief
--- @param delta Number
--- @param spectrum Table<Number>
function rt.BackgroundImplementation:update(delta, spectrum)
    rt.error("In " .. meta.typeof(self) .. ".updated: abstract method called")
end

--- @brief
function rt.BackgroundImplementation:draw()
    rt.error("In " .. meta.typeof(self) .. ".draw: abstract method called")
end