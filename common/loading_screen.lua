rt.settings.loading_screen = {
    fade_in_duration = 0.25,  -- seconds
    fade_out_duration = 0.1, -- seconds
    frame_duration = 1 / 2,  -- seconds
}

--- @class rt.LoadingScreen
--- @brief use show / hide to reveal, if hidden during show, interpolates and smoothly transitions
--- @signal shown (self) -> nil
--- @signal hidden (self) -> nil
rt.LoadingScreen = meta.new_abstract_type("LoadingScreen", rt.Widget, rt.Animation, rt.SignalEmitter)

--- @override
function rt.LoadingScreen:realize()
    error("In " .. meta.typeof(self) .. ".realize: abstract method called")
end

--- @override
function rt.LoadingScreen:size_allocate(x, y, width, height)
    error("In " .. meta.typeof(self) .. ".size_allocate: abstract method called")
end

--- @override
function rt.LoadingScreen:update(delta)
    error("In " .. meta.typeof(self) .. ".update: abstract method called")
end

--- @override
function rt.LoadingScreen:draw()
    error("In " .. meta.typeof(self) .. ".draw: abstract method called")
end

--- @brief
function rt.LoadingScreen:show()
    error("In " .. meta.typeof(self) .. ".show: abstract method called")
end

--- @brief
function rt.LoadingScreen:hide()
    error("In " .. meta.typeof(self) .. ".hide: abstract method called")
end