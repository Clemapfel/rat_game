--- @class rt.Animation
rt.Animation = meta.new_abstract_type("Animation")

--- @brief abstract method, must be override
function rt.Animation:update(delta)
    rt.error("In " .. meta.typeof(self) .. ":update(): abstract method called")
end

--[[
rt.settings.animation_handler = {
    fps = 60
}

--- @class rt.AnimationHandler
rt.AnimationHandler = meta.new_type("AnimationHandler", function()
    local out = meta.new(rt.AnimationHandler, {
        _elapsed = 0,
        _last_update = love.timer.getTime(),
        _components = {}
    })
    meta.make_weak(out._components, true, true)
    return out
end)
rt.AnimationHandler = rt.AnimationHandler() -- singleton instance

--- @brief [internal] update all Animations
--- @param delta Number seconds
function rt.AnimationHandler:update(delta)
    self._elapsed = self._elapsed + delta
    local frame_duration = 1 / rt.settings.animation_handler.fps
    while self._elapsed >= frame_duration do
        self._elapsed = self._elapsed - frame_duration
        for _, drawable in pairs(self._components) do
            if drawable._is_animated == true then
                drawable:update(frame_duration)
            end
        end
    end
end


function rt.Animation:set_is_animated(b)
    self._is_animated = b
end

function rt.Animation:set_update_automatically(b)
    if b then
        rt.AnimationHandler._components[self] = self
    else
        rt.AnimationHandler._components[self] = nil
    end
end

--- @brief [internal] test animation
function rt.test.animation()
    error("TODO")
end
]]--

