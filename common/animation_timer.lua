--- @class rt.AnimationTimerHandler
rt.AnimationTimerHandler = meta.new_type("AnimationTimerHandler", function()
    local out = meta.new(rt.AnimationTimerHandler, {
        _components = {}
    })
    meta.make_weak(out._components, false, true)
    return out
end)

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
        return -0.5 * math.cos(math.pi * x) + 0.5;
    end
    return out
end)()

--- @class rt.AnimationTimer
--- @signal tick    (self, [0, 1]) -> nil
--- @signal done    (self) -> nil
rt.AnimationTimer = meta.new_type("AnimationTimer", function(duration)
    if duration:as_seconds() < 0 then
        rt.error("In AnimationTimer(): Duration `" .. string(duration) .. "` cannot be negative")
    end

    local out = meta.new(rt.AnimationTimer, {
        _state = rt.AnimationTimerState.IDLE,
        _duration = duration:as_seconds(),
        _time = 0,
        _timing_function = rt.AnimationTimingFunction.LINEAR,
        _loop = false
    })

    rt.current_scene.animation_timer_handler._components[meta.hash(out)] = out

    out:signal_add("tick")
    out:signal_add("done")

    return out
end, rt.SignalEmitter)

--- @brief advance all animation timers, this uses a stable clock independent of fps
--- @param delta Number duration of last frame, in seconds
function rt.AnimationTimerHandler:update(delta)
    for _, component in pairs(rt.current_scene.animation_timer_handler._components) do
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

    return self._state
end

--- @brief reset animation back to idle
--- @param self rt.AnimationTimer
function rt.AnimationTimer:play()

    if self:get_state() == rt.AnimationTimerState.IDLE then
        self._state = rt.AnimationTimerState.PLAYING
        self._time = 0
    end
end

--- @brief pause animation if it playing, otherwise do nothing
--- @param self rt.AnimationTimer
function rt.AnimationTimer:pause()

    if self:get_state() == rt.AnimationTimerState.PLAYING then
       self._state = rt.AnimationTimerState.PAUSED
    end
end

--- @brief reset animation back to idle
--- @param self rt.AnimationTimer
function rt.AnimationTimer:reset()

    self._state = rt.AnimationTimerState.IDLE
    self._time = 0
end

--- @brief set duration of animation
--- @param self rt.AnimationTimer
--- @param duration_s rt.Time
function rt.AnimationTimer:set_duration(duration)
    self._duration = duration:as_seconds()
end

--- @brief get duration of animation, in seconds
--- @param self rt.AnimationTimer
--- @return rt.Time
function rt.AnimationTimer:get_duration()

    return rt.seconds(self._duration)
end

--- @brief set timing function
--- @param self rt.AnimationTimer
--- @param f rt.AnimationTimingFunction
function rt.AnimationTimer:set_timing_function(f)

    self._timing_function = f
end

--- @brief get timing function
--- @param self rt.AnimationTimer
--- @return rt.AnimationTimingFunction
function rt.AnimationTimer:get_timing_function(f)

    return self._timing_function
end

--- @bief set loop
--- @param b Boolean
function rt.AnimationTimer:set_should_loop(b)


    self._loop = b
end

--- @brief [internal] test animation
function rt.test.test_animation()
    error("TODO")
end
