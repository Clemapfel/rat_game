
rt.AnimationHandler = {}
rt.AnimationHandler._components = {} -- meta.hash(x) -> x
meta.make_weak(rt.AnimationTimerHandler._components, false, true)

rt.AnimationHandler._elapsed = 0
rt.AnimationHandler._last_update = love.timer.getTime()

rt.SETTINGS.animation = {}
rt.SETTINGS.animation.fps = 24
rt.SETTINGS.animation.enabled = true

--- @brief [internal] update all AnimatedDrawables
--- @param delta Number seconds
function rt.AnimationHandler:update(delta)
    meta.assert_number(delta)
    local elapsed = rt.AnimationHandler._elapsed + delta
    local frame_length = 1 / rt.SETTINGS.animation.fps
    while elapsed >= frame_length do
        elapsed = elapsed - frame_length
        if rt.SETTINGS.animation.enabled then
            local delta = love.timer.getTime() - rt.AnimationHandler._last_update
            for _, drawable in pairs(rt.AnimationHandler._components) do
                drawable:update(delta)
            end
        end
        rt.AnimationHandler._last_update = love.timer.getTime()
    end
    rt.AnimationHandler._elapsed = elapsed
end


--- @class rt.AnimatedDrawable
rt.AnimatedDrawable = meta.new_abstract_type("AnimatedDrawable")
rt.AnimatedDrawable._is_animated = false

--- @brief abstract method, must be override
function rt.AnimatedDrawable:update(delta)
    error("[rt][ERROR] In " .. meta.typeof(self) .. ":update(): abstract method called")
end

--- @brief get whether animation is active
--- @return Boolean
function rt.AnimatedDrawable:get_is_animated()
    meta.assert_isa(self, rt.Glyph)
    return self._is_animated
end

--- @brief set whether animation is active
--- @param b Boolean
function rt.AnimatedDrawable:set_is_animated(b)
    meta.assert_isa(self, rt.Glyph)
    if b == self._is_animated then return end
    self._is_animated = b

    if b then
        rt.AnimationHandler._components[meta.hash(self)] = self
    else
        rt.AnimationHandler._components[meta.hash(self)] = nil
    end
end