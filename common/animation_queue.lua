--- @class rt.QueueableAnimationResult
rt.QueueableAnimationResult = {
    CONTINUE = true,
    DISCONTINUE = false
}

--- @class rt.QueueableAnimationState
rt.QueueableAnimationState = {
    IDLE = 1,       -- not yet start
    STARTED = 2,    -- running
    FINISHED = 3    -- done running
}

--- @class rt.QueueableAnimation
rt.QueueableAnimation = meta.new_abstract_type("QueueableAnimation", rt.Drawable, {
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
    -- noop
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

--- @brief
function rt.QueueableAnimation:get_is_started()
    return self._state == rt.QueueableAnimationState.STARTED
end

-- ###

--- @class
rt.AnimationQueue = meta.new_type("AnimationQueue", rt.Drawable, rt.Animation, function()
    local out = meta.new(rt.AnimationQueue, {
        _animations = {}, -- Table<cf. push>
    })
    return out
end)

--- @brief
function rt.AnimationQueue:push(animations, start_callback, finish_callback)
    if meta.isa(animations, rt.QueueableAnimation) then
        animations = { animations }
    end

    local node = {}
    node.on_start = start_callback
    node.on_finish = finish_callback
    node.is_started = false
    node.is_finished = false
    node.animations = {}
    for animation in values(animations) do
        meta.assert_isa(animation, rt.QueueableAnimation)
        table.insert(node.animations, animation)
    end

    table.insert(self._animations, {node})
end

--- @brief
function rt.AnimationQueue:append(animations, start_callback, finish_callback)
    if meta.isa(animations, rt.QueueableAnimation) then
        animations = { animations }
    end

    if sizeof(self._animations) == 0 then
        self:push(animations, start_callback, finish_callback)
    else
        local node = {}
        node.on_start = start_callback
        node.on_finish = finish_callback
        node.is_started = false
        node.is_finished = false
        node.animations = {}
        for animation in values(animations) do
            meta.assert_isa(animation, rt.QueueableAnimation)
            table.insert(node.animations, animation)
        end

        table.insert(self._animations[#self._animations], node)
    end
end

--- @brief
function rt.AnimationQueue:_start_animation(animation)
    if animation._state ~= rt.QueueableAnimationState.IDLE then return end
    animation._state = rt.QueueableAnimationState.STARTED
    animation:start()
    animation:update(0)
end

--- @brief
function rt.AnimationQueue:_finish_animation(animation)
    if animation._state == rt.QueueableAnimationState.FINISHED then return end
    animation:update(0)
    animation._state = rt.QueueableAnimationState.FINISHED
    animation:finish()
end

--- @brief
function rt.AnimationQueue:skip()
    for node in values(self._animations[1]) do
        if node == nil then return end

        if node._is_started == false then
            node._is_started = true
            if node.on_start ~= nil then
                node.on_start()
            end
        end

        for animation in values(node.animations) do
            if animation._state == rt.QueueableAnimationState.IDLE then
                self:_start_animation(animation)
            end

            animation:update(0)
            self:_finish_animation(animation)
        end

        if node.on_finish ~= nil and node.is_finished == false then
            node.on_finish()
            node.is_finished = true
        end
    end

    table.remove(self._animations, 1)
end

--- @brief
function rt.AnimationQueue:update(delta)
    ::restart::
    if sizeof(self._animations) == 0 then return end

    for node in values(self._animations[1]) do
        if node.is_started == false then
            node.is_started = true

            if node.on_start ~= nil then
                node.on_start()
            end
        end

        local depleted = true
        for animation in values(node.animations) do
            if animation._state == rt.QueueableAnimationState.IDLE then
                self:_start_animation(animation)
            end

            if animation._state ~= rt.QueueableAnimationState.FINISHED then
                local res = animation:update(delta)
                if res == rt.QueueableAnimationResult.DISCONTINUE then
                    self:_finish_animation(animation)
                elseif res == rt.QueueableAnimationResult.CONTINUE then
                    depleted = false
                else
                    rt.error("In rt.AnimationQueue: animation `" .. meta.typeof(animation) .. "`.update does not return rt.QueueableAnimationResult, instead returns `" .. serialize(res) .. "`")
                end
            end
        end

        if depleted == true then
            if node.on_finish ~= nil and node.is_finished == false then
                node.on_finish()
            end
            node.is_finished = true
        end
    end

    local done = true
    for node in values(self._animations[1]) do
        if node.is_finished ~= true then
            done = false
            break
        end
    end

    if done == true then
        table.remove(self._animations, 1)
        delta = 0
        goto restart
    end
end

--- @brief
function rt.AnimationQueue:draw()
    for node in values(self._animations[1]) do
        if node == nil or node.is_started == false then return end
        for animation in values(node.animations) do
            if animation:get_state() ~= rt.QueueableAnimationState.FINISHED then
                animation:draw()
            end
        end
    end
end

--- @brief
function rt.AnimationQueue:get_is_empty()
    return sizeof(self._animations) == 0
end