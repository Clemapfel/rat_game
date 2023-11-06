
rt.AnimationHandler = {}
rt.AnimationHandler._components = {}
meta.make_weak(rt.AnimationTimerHandler._components, false, true)

rt.AnimationHandler._elapsed = 0
rt.AnimationHandler._last_update = love.timer.getTime()

rt.settings.animation = {}
rt.settings.animation.fps = 24 -- ticks per second
rt.settings.animation.enabled = true

--- @brief [internal] update all Animations
--- @param delta Number seconds
function rt.AnimationHandler:update(delta)
    meta.assert_number(delta)
    local elapsed = rt.AnimationHandler._elapsed + delta
    local frame_length = 1 / rt.settings.animation.fps
    while elapsed >= frame_length do
        elapsed = elapsed - frame_length
        local now = love.timer.getTime()
        if rt.settings.animation.enabled then
            local delta = now - rt.AnimationHandler._last_update
            for _, drawable in pairs(rt.AnimationHandler._components) do
                drawable:update(delta)
            end
        end
        rt.AnimationHandler._last_update = now
    end
    rt.AnimationHandler._elapsed = elapsed
end

--- @class rt.Animation
rt.Animation = meta.new_abstract_type("Animation")
rt.Animation._is_animated = false

--- @brief abstract method, must be override
function rt.Animation:update(delta)
    meta.assert_isa(self, rt.Animation)
    error("[rt][ERROR] In " .. meta.typeof(self) .. ":update(): abstract method called")
end

--- @brief get whether animation is active
--- @return Boolean
function rt.Animation:get_is_animated()
    meta.assert_isa(self, rt.Animation)
    return self._is_animated
end

--- @brief set whether animation is active
--- @param b Boolean
function rt.Animation:set_is_animated(b)
    meta.assert_isa(self, rt.Animation)
    if b == self._is_animated then return end
    self._is_animated = b

    if b then
        rt.AnimationHandler._components[meta.hash(self)] = self
    else
        rt.AnimationHandler._components[meta.hash(self)] = nil
    end
end

--- @brief [internal] test animation
function rt.test.animation()
    error("TODO")
end
