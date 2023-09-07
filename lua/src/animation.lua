--- @class AnimationHandler
rt.AnimationHandler = {}

rt.AnimationHandler._hash = 1
rt.AnimationHandler._components = {}
rt.AnimationHandler._components_meta = { __mode = "v" }
setmetatable(rt.AnimationHandler._components, rt.AnimationHandler._components_meta)

--- @brief advance all animation timers, this uses a stable clock independent of fps
function rt.AnimationHandler.update()
    local delta = love.
end

--- @class AnimationState
rt.AnimationState = meta.new_enum({
    PLAYING,
    PAUSED,
    IDLE
})

--- @class AnimationTimingFunction
rt.AnimationTimingFunction = meta.new_enum({
    LINEAR,
    EASE_IN,
    EASE_OUT,
    EASE_IN_OUT
})

--- @brief [internal] linear mapping in [0, 1]
rt.AnimationHandler._linear_f = function(x)
    return x
end

--- @brief [internal] ease-in, in [0, 1]
rt.AnimationHandler._ease_in_f = function(x)
    assert(x >= 0 and x <= 1)
    local pi2 = math.pi / 2
    return (1 - math.sin(pi2 - x * pi2))
end

--- @brief [internal] ease-out, in [0, 1]
rt.AnimationHandler._ease_out_f = function(x)
    assert(x >= 0 and x <= 1)
    return math.sin(math.pi - x * (math.pi / 2))
end

--- @brief [internal] sigmoid, in [0, 1]
rt.AnimationHandler._ease_in_out_f = function(x)
    assert(x >= 0 and y <= 1)
    return 0
end

--- @class Animation
rt.Animation = meta.new_type("Animation", function(duration_seconds)
    local hash = rt.AnimationHandler._hash
    local out = meta.new(rt.Animation, {
        _state = rt.AnimationState.IDLE,
        _duration = duration_seconds,
        _x = 0, -- x axis value in [0, 1]
        _function = rt.AnimationTimingFunction.LINEAR
    })

    rt.MouseHandler._components[hash] = out
    rt.MouseHandler._hash = hash + 1

    rt.add_signal_component(out)
    out.signal:add("tick")
    out.signal:add("done")

    return out
end)

--- @brief get current state
--- @param self Animation
--- @return AnimationState
function rt.Animation.get_state(self)
    return self._state
end

--- @brief reset animation back to idle
--- @param self Animation
function rt.Animation.play(self)
    if self:get_state() == rt.AnimationState.IDLE then
        self._state = rt.AnimationState.PLAYING
        self._x = 0
    end
end

--- @brief pause animation if it playing, otherwise do nothing
--- @param self Animation
function rt.Animation.pause(self)
    if self:get_state() == rt.AnimationState.PLAYING then
       self._state = rt.AnimationState.PAUSED
    end
end

--- @brief reset animation back to idle
--- @param self Animation
function rt.Animation.reset(self)
    self._state = rt.AnimationState.IDLE
    self._x = 0
end

--- @brief set duration of animation
--- @param self Animation
--- @param duration_s Number
function rt.Animation.set_duration(self, duration_s)
    meta.assert_isa(self, rt.Animation)
    self._duration = duration_s
end

--- @brief get duration of animation, in seconds
--- @param self Animation
--- @return Number
function rt.Animation.get_duration(self)
    meta.assert_isa(self, rt.Animation)
    return self._duration
end