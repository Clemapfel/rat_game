--- @class rt.QueueableAnimationResult
rt.QueueableAnimationResult = {
    CONTINUE = true,
    DISCONTINUE = false
}

--- @class rt.QueueableAnimationState
rt.QueueableAnimationState = {
    IDLE = 1,       -- not yet start
    START = 2,      -- running
    FINISHED = 3    -- done running
}

--- @class rt.QueueableAnimation
rt.QueueableAnimation = meta.new_abstract_type("BattleAnimation", rt.Drawable, rt.SignalEmitter, {
    _state = rt.QueueableAnimationState.IDLE
})

--- @brief
function rt.QueueableAnimation:start()
    -- noop
end

--- @brief
function rt.QueueableAnimation:finish()
    -- noop
end

--- @brief
function rt.QueueableAnimation:update(delta)
    rt.error("In rt.QueueableAnimation.update: abstract method called")
    return rt.QueueableAnimationResult.DISCONTINUE
end

--- @overload
function rt.QueueableAnimation:draw()
    -- noop
end

--- @brief
function rt.QueueableAnimation:get_state()
    return self._state
end

--- #############

--- @class
rt.AnimationQueue = meta.new_type("AnimationQueue", rt.Drawable, rt.Animation, function()
    local out = meta.new(rt.AnimationQueue, {
        _animations = {}, -- Table<rt.Animation>
    })
    out:set_is_animated(true)
    return out
end)

--- @brief add new node in queue
function rt.AnimationQueue:push(animation, ...)
    local node = {}
    for animation in values({animation, ...}) do
        meta.assert_isa(animation, rt.QueueableAnimation)
        table.insert(node, animation)
    end
    table.insert(self._animations, node)
end

--- @brief add animations to last node, without creating a new one
function rt.AnimationQueue:append(animation, ...)
    local node = self._animations[#self._animations]
    for animation in values({animation, ...}) do
        meta.assert_isa(animation, rt.QueueableAnimation)
        table.insert(node, animation)
    end
end

--- @brief
function rt.AnimationQueue:register_finish_callback(callback)
    meta.assert_function(callback)
    if self._finish_callbacks == nil then
        self._finish_callbacks = {}
    end
    table.insert(self._finish_callbacks, callback)
end

--- @brief
function rt.AnimationQueue:register_start_callback(callback)
    meta.assert_function(callback)
    if self._start_callbacks == nil then
        self._start_callbacks = {}
    end
    table.insert(self._start_callbacks, callback)
end

--- @brief
function rt.AnimationQueue:_start_animation(animation)
    if animation._state ~= rt.QueueableAnimationState.IDLE then return end
    animation._state = rt.QueueableAnimationState.STARTED

    if animation._start_callbacks ~= nil then
        for callback in values(animation._start_callbacks) do
            callback()
        end
    end
    animation:update(0)
end

--- @brief
function rt.AnimationQueue:_finish_animation(animation)
    if animation._state == rt.QueueableAnimationState.FINISHED then return end
    animation:update(0)
    animation._state = rt.QueueableAnimationState.FINISHED

    if animation._finish_callbacks ~= nil then
        for callback in values(animation._finish_callbacks) do
            callback()
        end
    end
end

--- @brief
function rt.AnimationQueue:skip()
    println(#self._animations)
    local node = self._animations[1]
    if node == nil then return end
    for animation in values(node) do
        if animation._state == rt.QueueableAnimationState.IDLE then
            self:_start_animation(animation)
        elseif animation._state == rt.QueueableAnimationState.STARTED then
            self:_finish_animation(animation)
        else
            -- noop
        end
    end
    table.remove(self._animations, 1)
    self:update(0) -- start next node if possible
end

--- @brief
function rt.AnimationQueue:draw()
    local node = self._animations[1]
    if node == nil then return end
    for animation in values(node) do
        if animation._state ~= rt.QueueableAnimationState.FINISHED then
            animation:draw()
        end
    end
end

--- @brief
function rt.AnimationQueue:update(delta)
    ::restart::
    local node = self._animations[1]
    if node == nil then return end

    local depleted = true
    for animation in values(node) do
        if animation._state == rt.QueueableAnimationResult.IDLE then
            self:_start_animation(animation)
        end

        if animation._state ~= rt.QueueableAnimationState.FINISHED then
            local res = animation:update(delta)
            if res == rt.QueueableAnimationResult.DISCONTINUE then
                self:_finish_animation(animation)
            else
                depleted = false
            end
        end
    end

    if depleted == true then
        table.remove(self._animations, 1)
        delta = 0
        goto restart
    end
end

--- @brief [internal]
function rt.test.animation_queue()
    rt.TestQueueableAnimation = meta.new_type("TestQueueableAnimation", rt.QueueableAnimation, function(x, y)
        local out = meta.new(rt.TestQueueableAnimation, {
            _color = rt.HSVA(rt.random.number(0, 1), 1, 1, 1),
            _shape = rt.Circle(x, y, 50, 50),
            _duration = 1,
            _elapsed = 0
        })
        out._shape:set_color(out._color)
        return out
    end)

    function rt.TestQueueableAnimation:update(delta)
        self._elapsed = self._elapsed + delta
        local fraction = self._elapsed / self._duration
        return fraction < 1
    end

    function rt.TestQueueableAnimation:draw()
        rt.graphics.push()
        --rt.graphics.rotate(self._elapsed / self._duration * 2 * math.pi)
        self._shape:draw()
        rt.graphics.pop()
    end

    queue = rt.AnimationQueue()
    input_controller = rt.InputController()
    input_controller:signal_connect("pressed", function(self, which)
        if which == rt.InputButton.A then
            local n = rt.random.number(1, 3)
            local to_push = {}
            for i = 1, n do
                local x = rt.random.number(0.25, 0.75) * rt.graphics.get_width()
                local y = rt.random.number(0.25, 0.75) * rt.graphics.get_height()
                table.insert(to_push, rt.TestQueueableAnimation(x, y))
            end
            queue:push(splat(to_push))
        elseif which == rt.InputButton.X then
            local n = rt.random.number(1, 3)
            local to_push = {}
            for i = 1, n do
                local x = rt.random.number(0.25, 0.75) * rt.graphics.get_width()
                local y = rt.random.number(0.25, 0.75) * rt.graphics.get_height()
                table.insert(to_push, rt.TestQueueableAnimation(x, y))
            end
            queue:append(splat(to_push))
        elseif which == rt.InputButton.B then
            queue:skip()
        end
    end)
end
