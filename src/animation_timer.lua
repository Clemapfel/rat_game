--- @class rt.AnimationTimerHandler
rt.AnimationTimerHandler = {}

rt.AnimationTimerHandler._hash = 1
rt.AnimationTimerHandler._components = {}
meta.make_weak(rt.AnimationTimerHandler._components, false, true)

--- @class rt.AnimationTimerState
rt.AnimationTimerState = meta.new_enum({
    PLAYING = "ANIMATION_STATE_PLAYING",
    PAUSED = "ANIMATION_STATE_PAUSED",
    IDLE = "ANIMATION_STATE_IDLE"
})

--- @class rt.AnimationTimingFunction
--- @see https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-easing.c#L77
rt.AnimationTimingFunction = meta.new_enum({
    LINEAR = "ANIMATION_TIMING_FUNCTION_LINEAR",
    EASE_IN = "ANIMATION_TIMING_FUNCTION_EASE_IN",
    EASE_OUT = "ANIMATION_TIMING_FUNCTION_EASE_OUT",
    EASE_IN_OUT = "ANIMATION_TIMING_FUNCTION_EASE_IN_OUT"
})

rt.AnimationTimerHandler._timing_functions = (function()

    --- @see https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-easing.c
    local out = {}
    out[rt.AnimationTimingFunction.LINEAR] = function(x)
        return x
    end

    out[rt.AnimationTimingFunction.EASE_IN] = function(x)
        return -1.0 * math.cos(x * (math.pi / 2)) + 1.0;
    end

    out[rt.AnimationTimingFunction.EASE_OUT] = function(x)
        return math.sin(x * (math.pi / 2));
    end

    out[rt.AnimationTimingFunction.EASE_IN_OUT] = function(x)
        return -0.5 * (math.cos(math.pi * x) - 1);
    end
    return out
end)()


--- @class rt.AnimationTimer
rt.AnimationTimer = meta.new_type("AnimationTimer", function(duration_seconds)
    meta.assert_number(duration_seconds)
    if duration_seconds < 0 then
        error("[rt][ERROR] In AnimationTimer(): Duration `" .. string(duration_seconds) .. "` cannot be negative")
    end

    local hash = rt.AnimationTimerHandler._hash
    local out = meta.new(rt.AnimationTimer, {
        _state = rt.AnimationTimerState.IDLE,
        _duration = duration_seconds,
        _time = 0,
        _timing_function = rt.AnimationTimingFunction.LINEAR,
        _loop = false,
        _hash = hash
    }, rt.SignalEmitter)

    rt.AnimationTimerHandler._components[hash] = out
    rt.AnimationTimerHandler._hash = hash + 1

    out:signal_add("tick")
    out:signal_add("done")

    return out
end, function(self)
    println("freed: ", self._hash)
    rt.AnimationTimerHandler._components[self._hash] = nil
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
            if component._loop then
                while component._time > component._duration do
                    component:signal_emit("tick", 1)
                    component._time = component._time - component._duration
                end
            else
                component._state = rt.AnimationTimerState.IDLE
                component:signal_emit("tick", 1)
                component:signal_emit("done")
                goto continue
            end
        end

        local value = rt.AnimationTimerHandler._timing_functions[component._timing_function](
            component._time / component._duration
        )

        component:signal_emit("tick", value)
        ::continue::
    end
end

--- @brief get current state
--- @param self rt.AnimationTimer
--- @return rt.AnimationTimerState
function rt.AnimationTimer:get_state()
    meta.assert_isa(self, rt.AnimationTimer)
    return self._state
end

--- @brief reset animation back to idle
--- @param self rt.AnimationTimer
function rt.AnimationTimer:play()
    meta.assert_isa(self, rt.AnimationTimer)
    if self:get_state() == rt.AnimationTimerState.IDLE then
        self._state = rt.AnimationTimerState.PLAYING
        self._time = 0
    end
end

--- @brief pause animation if it playing, otherwise do nothing
--- @param self rt.AnimationTimer
function rt.AnimationTimer:pause()
    meta.assert_isa(self, rt.AnimationTimer)
    if self:get_state() == rt.AnimationTimerState.PLAYING then
       self._state = rt.AnimationTimerState.PAUSED
    end
end

--- @brief reset animation back to idle
--- @param self rt.AnimationTimer
function rt.AnimationTimer:reset()
    meta.assert_isa(self, rt.AnimationTimer)
    self._state = rt.AnimationTimerState.IDLE
    self._time = 0
end

--- @brief set duration of animation
--- @param self rt.AnimationTimer
--- @param duration_s Number
function rt.AnimationTimer:set_duration(duration_s)
    meta.assert_isa(self, rt.AnimationTimer)
    self._duration = duration_s
end

--- @brief get duration of animation, in seconds
--- @param self rt.AnimationTimer
--- @return Number
function rt.AnimationTimer:get_duration()
    meta.assert_isa(self, rt.AnimationTimer)
    return self._duration
end

--- @brief set timing function
--- @param self rt.AnimationTimer
--- @param f rt.AnimationTimingFunction
function rt.AnimationTimer:set_timing_function(f)
    meta.assert_isa(self, rt.AnimationTimer)
    meta.assert_enum(f, rt.AnimationTimingFunction)
    self._timing_function = f
end

--- @brief get timing function
--- @param self rt.AnimationTimer
--- @return rt.AnimationTimingFunction
function rt.AnimationTimer:get_timing_function(f)
    meta.assert_isa(self, rt.AnimationTimer)
    return self._timing_function
end

--- @bief set loop
--- @param b Boolean
function rt.AnimationTimer:set_should_loop(b)
    meta.assert_isa(self, rt.AnimationTimer)
    meta.assert_boolean(b)
    self._loop = b
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
    animation:signal_connect("tick", function()
        tick_called = true
    end)

    local done_called = false
    animation:signal_connect("done", function()
        done_called = true
    end)

    assert(animation:get_duration() == 0)
    animation:set_duration(1)
    assert(animation:get_duration() == 1)

    animation:set_timing_function(rt.AnimationTimingFunction.EASE_IN_OUT)
    assert(animation:get_timing_function(rt.AnimationTimingFunction.EASE_IN_OUT))

    assert(animation:get_state() == rt.AnimationTimerState.IDLE)
    animation:play()
    assert(animation:get_state() == rt.AnimationTimerState.PLAYING)
    animation:pause()
    assert(animation:get_state() == rt.AnimationTimerState.PAUSED)
    animation:reset()
    animation:play()

    rt.AnimationTimerHandler.update(2)
end
--rt.test.test_animation()