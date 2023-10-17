--- @class rt.AnimationTimerHandler
rt.AnimationTimerHandler = {}

rt.AnimationTimerHandler._hash = 1
rt.AnimationTimerHandler._components = {}

--- @class rt.AnimationTimerState
rt.AnimationTimerState = meta.new_enum({
    PLAYING = "ANIMATION_STATE_PLAYING",
    PAUSED = "ANIMATION_STATE_PAUSED",
    IDLE = "ANIMATION_STATE_IDLE"
})

--- @class rt.AnimationTimerTimingFunction
--- @see https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-easing.c#L77
rt.AnimationTimerTimingFunction = meta.new_enum({
    LINEAR = "ANIMATION_TIMING_FUNCTION_LINEAR",
    EASE_IN = "ANIMATION_TIMING_FUNCTION_EASE_IN",
    EASE_OUT = "ANIMATION_TIMING_FUNCTION_EASE_OUT",
    EASE_IN_OUT = "ANIMATION_TIMING_FUNCTION_EASE_IN_OUT"
})

rt.AnimationTimerHandler._timing_functions = (function()

    --- @see https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-easing.c
    local out = {}
    out[rt.AnimationTimerTimingFunction.LINEAR] = function(x)
        return x
    end

    out[rt.AnimationTimerTimingFunction.EASE_IN] = function(x)
        return -1.0 * math.cos(x * (math.pi / 2)) + 1.0;
    end

    out[rt.AnimationTimerTimingFunction.EASE_OUT] = function(x)
        return math.sin(x * (math.pi / 2));
    end

    out[rt.AnimationTimerTimingFunction.EASE_IN_OUT] = function(x)
        return -0.5 * (math.cos(math.pi * x) - 1);
    end
    return out
end)()


--- @class rt.AnimationTimer
rt.AnimationTimer = meta.new_type("AnimationTimer", function(duration_seconds)
    meta.assert_number(duration_seconds)
    if duration_seconds < 0 then
        error("[rt] In AnimationTimer(): Duration `" .. string(duration_seconds) .. "` cannot be negative")
    end

    local hash = rt.AnimationTimerHandler._hash
    local out = meta.new(rt.AnimationTimer, {
        _state = rt.AnimationTimerState.IDLE,
        _duration = duration_seconds,
        _time = 0,
        _timing_function = rt.AnimationTimerTimingFunction.LINEAR
    })

    rt.AnimationTimerHandler._components[hash] = out
    rt.AnimationTimerHandler._hash = hash + 1

    rt.add_signal_component(out)
    out.signal:add("tick")
    out.signal:add("done")

    return out
end)

--- @brief advance all animation timers, this uses a stable clock independent of fps
--- @param delta Number duration of last frame, in seconds
function rt.AnimationTimerHandler.update(delta)
    for _, component in pairs(rt.AnimationTimerHandler._components) do

        if component:get_state() ~= rt.AnimationTimerState.PLAYING then
            goto continue
        end

        component._time = component._time + delta

        if component._time >= component._duration then
            component._state = rt.AnimationTimerState.IDLE
            component.signal:emit("tick", 1)
            component.signal:emit("done")
            goto continue
        end

        local value = rt.AnimationTimerHandler._timing_functions[component._timing_function](
            component._time / component._duration
        )

        component.signal:emit("tick", value)
        ::continue::
    end
end

--- @brief get current state
--- @param self rt.AnimationTimer
--- @return rt.AnimationTimerState
function rt.AnimationTimer.get_state(self)
    return self._state
end

--- @brief reset animation back to idle
--- @param self rt.AnimationTimer
function rt.AnimationTimer.play(self)
    if self:get_state() == rt.AnimationTimerState.IDLE then
        self._state = rt.AnimationTimerState.PLAYING
        self._time = 0
    end
end

--- @brief pause animation if it playing, otherwise do nothing
--- @param self rt.AnimationTimer
function rt.AnimationTimer.pause(self)
    if self:get_state() == rt.AnimationTimerState.PLAYING then
       self._state = rt.AnimationTimerState.PAUSED
    end
end

--- @brief reset animation back to idle
--- @param self rt.AnimationTimer
function rt.AnimationTimer.reset(self)
    self._state = rt.AnimationTimerState.IDLE
    self._time = 0
end

--- @brief set duration of animation
--- @param self rt.AnimationTimer
--- @param duration_s Number
function rt.AnimationTimer.set_duration(self, duration_s)
    meta.assert_isa(self, rt.AnimationTimer)
    self._duration = duration_s
end

--- @brief get duration of animation, in seconds
--- @param self rt.AnimationTimer
--- @return Number
function rt.AnimationTimer.get_duration(self)
    meta.assert_isa(self, rt.AnimationTimer)
    return self._duration
end

--- @brief set timing function
--- @param self rt.AnimationTimer
--- @param f rt.AnimationTimerTimingFunction
function rt.AnimationTimer.set_timing_function(self, f)
    meta.assert_isa(self, rt.AnimationTimer)
    meta.assert_enum(f, rt.AnimationTimerTimingFunction)
    self._timing_function = f
end

--- @brief get timing function
--- @param self rt.AnimationTimer
--- @return rt.AnimationTimerTimingFunction
function rt.AnimationTimer.get_timing_function(self, f)
    meta.assert_isa(self, rt.AnimationTimer)
    return self._timing_function
end

--- @brief [internal] test animation
function rt.test.test_animation()

    for _, f in ipairs({
        rt.AnimationTimerHandler._linear_f,
        rt.AnimationTimerHandler._ease_in_f,
        rt.AnimationTimerHandler._ease_out_f,
        rt.AnimationTimerHandler._ease_in_out_f
    }) do
        assert(rt.AnimationTimerHandler._linear_f(0) == 0)
        assert(rt.AnimationTimerHandler._linear_f(1) == 1)
    end

    local animation = rt.AnimationTimer(0)

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

    animation:set_timing_function(rt.AnimationTimerTimingFunction.EASE_IN_OUT)
    assert(animation:get_timing_function(rt.AnimationTimerTimingFunction.EASE_IN_OUT))

    assert(animation:get_state() == rt.AnimationTimerState.IDLE)
    animation:play()
    assert(animation:get_state() == rt.AnimationTimerState.PLAYING)
    animation:pause()
    assert(animation:get_state() == rt.AnimationTimerState.PAUSED)
    animation:reset()
    animation:play()

    rt.AnimationTimerHandler.update(2)
end
rt.test.test_animation()