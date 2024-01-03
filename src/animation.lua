--- @class rt.AnimationHandler
rt.AnimationHandler = meta.new_type("AnimationHandler", function()
    local out = meta.new(rt.AnimationHandler, {
        _elapsed = 0,
        _last_update = love.timer.getTime(),
        _components = {}
    })
    meta.make_weak(out._components, false, true)
    return out
end)

rt.settings.animation = {
    fps = 60,
    enabled = true
}

--- @brief [internal] update all Animations
--- @param delta Number seconds
function rt.AnimationHandler:update(delta)

    local elapsed = self._elapsed + delta
    local frame_length = 1 / rt.settings.animation.fps
    while elapsed >= frame_length do
        elapsed = elapsed - frame_length
        local now = love.timer.getTime()
        if rt.settings.animation.enabled then
            local delta = now - self._last_update
            for _, drawable in pairs(self._components) do
                drawable:update(delta)
            end
        end
        self._last_update = now
    end
    self._elapsed = elapsed
end

--- @class rt.Animation
rt.Animation = meta.new_abstract_type("Animation")
rt.Animation._is_animated = false

--- @brief abstract method, must be override
function rt.Animation:update(delta)
    rt.error("In " .. meta.typeof(self) .. ":update(): abstract method called")
end

--- @brief get whether animation is active
--- @return Boolean
function rt.Animation:get_is_animated()
    return self._is_animated
end

--- @brief set whether animation is active
--- @param b Boolean
function rt.Animation:set_is_animated(b)

    if b == self._is_animated then return end
    self._is_animated = b

    if b then
        rt.current_scene.animation_handler._components[meta.hash(self)] = self
    else
        rt.current_scene.animation_handler._components[meta.hash(self)] = nil
    end
end

--- @brief [internal] test animation
function rt.test.animation()
    error("TODO")
end
