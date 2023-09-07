--- @class AnimationHandler
rt.AnimationHandler = {}

rt.AnimationHandler._hash = 1
rt.AnimationHandler._components = {}
rt.AnimationHandler._components_meta = { __mode = "v" }
setmetatable(rt.AnimationHandler._components, rt.AnimationHandler._components_meta)

--- @class AnimationState
rt.AnimationState = meta.new_enum({
    PLAYING = "ANIMATION_STATE_PLAYING",
    PAUSED = "ANIMATION_STATE_PAUSED",
    IDLE = "ANIMATION_STATE_IDLE"
})

--- @class AnimationTimingFunction
--- @see https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-easing.c#L77
rt.AnimationTimingFunction = meta.new_enum({
    LINEAR = "ANIMATION_TIMING_FUNCTION_LINEAR",
    EASE_IN = "ANIMATION_TIMING_FUNCTION_EASE_IN",
    EASE_OUT = "ANIMATION_TIMING_FUNCTION_EASE_OUT",
    EASE_IN_OUT = "ANIMATION_TIMING_FUNCTION_EASE_IN_OUT"
})

--- @brief [internal] linear mapping in [0, 1]
rt.AnimationHandler._linear_f = function(x)
    assert(x >= 0 and x <= 1)
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
    assert(x >= 0 and x <= 1)
    return -0.5 * (math.cos(math.pi * x) - 1);
end

--- @class Animation
rt.Animation = meta.new_type("Animation", function(duration_seconds)
    meta.assert_number(duration_seconds)
    if duration_seconds < 0 then
        error("[rt] In Animation._call: Duration `" .. string(duration_seconds) .. "` cannot be negative")
    end

    local hash = rt.AnimationHandler._hash
    local out = meta.new(rt.Animation, {
        _state = rt.AnimationState.IDLE,
        _duration = duration_seconds,
        _time = 0,
        _timing_function = rt.AnimationTimingFunction.LINEAR
    })

    rt.AnimationHandler._components[hash] = out
    rt.AnimationHandler._hash = hash + 1

    rt.add_signal_component(out)
    out.signal:add("tick")
    out.signal:add("done")

    return out
end)

--- @brief advance all animation timers, this uses a stable clock independent of fps
--- @param delta Number duration of last frame, in seconds
function rt.AnimationHandler.update(delta)
    for _, component in pairs(rt.AnimationHandler._components) do
        if component:get_state() ~= rt.AnimationState.PLAYING then
            goto continue
        end

        component._time = component._time + delta

        if component._time >= component._duration then
            component._state = rt.AnimationState.IDLE
            component.signal:emit("tick", 1)
            component.signal:emit("done")
            goto continue
        end

        local value = 0
        local x = component._time / component._duration
        if component._timing_function == rt.AnimationTimingFunction.LINEAR then
            value = rt.AnimationHandler._linear_f(x)
        elseif component._timing_function == rt.AnimationTimingFunction.EASE_IN then
            value = rt.AnimationHandler._ease_in_f(x)
        elseif component._timing_function == rt.AnimationTimingFunction.EASE_OUT then
            value = rt.AnimationHandler._ease_out(x)
        elseif component._timing_function == rt.AnimationTimingFunction.EASE_IN_OUT then
            value = rt.AnimationHandler._ease_in_out_f(x)
        end

        component.signal:emit("tick", value)
        ::continue::
    end
end

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
        self._time = 0
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
    self._time = 0
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

--- @brief set timing function
--- @param self Animation
--- @param f AnimationTimingFunction
function rt.Animation.set_timing_function(self, f)
    meta.assert_isa(self, rt.Animation)
    meta.assert_enum(f, rt.AnimationTimingFunction)
    self._timing_function = f
end

--- @brief get timing function
--- @param self Animation
--- @return AnimationTimingFunction
function rt.Animation.get_timing_function(self, f)
    meta.assert_isa(self, rt.Animation)
    return self._timing_function
end

--- @brief [internal] test animation
function rt.test.test_animation()

    for _, f in ipairs({
        rt.AnimationHandler._linear_f,
        rt.AnimationHandler._ease_in_f,
        rt.AnimationHandler._ease_out_f,
        rt.AnimationHandler._ease_in_out_f
    }) do
        assert(rt.AnimationHandler._linear_f(0) == 0)
        assert(rt.AnimationHandler._linear_f(1) == 1)
    end

    local animation = rt.Animation(0)

    local tick_called = false
    animation.signal:connect("tick", function()
        tick_called = true
    end)

    local done_called = false
    animation.signal:connect("done", function()
        done_called = true
    end)

    assert(animation:get_duration() == 0)
    animation:set_duration(1)
    assert(animation:get_duration() == 1)

    animation:set_timing_function(rt.AnimationTimingFunction.EASE_IN_OUT)
    assert(animation:get_timing_function(rt.AnimationTimingFunction.EASE_IN_OUT))

    assert(animation:get_state() == rt.AnimationState.IDLE)
    animation:play()
    assert(animation:get_state() == rt.AnimationState.PLAYING)
    animation:pause()
    assert(animation:get_state() == rt.AnimationState.PAUSED)
    animation:reset()
    animation:play()

    rt.AnimationHandler.update(2)
end
rt.test.test_animation()