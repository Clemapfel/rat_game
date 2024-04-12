--- @class
bt.AnimationQueue = meta.new_type("AnimationQueue", rt.Drawable, function()
    local out = meta.new(bt.AnimationQueue, {
        animations = {}, -- Fifo<bt.Animation>
    })
    bt.AnimationQueue._all_instances[meta.hash(out)] = out
    return out
end)

bt.AnimationQueue._all_instances = {}
meta.make_weak(bt.AnimationQueue._all_instances, false, true)

--- @brief
function bt.AnimationQueue:draw()
    for _, animation in pairs(self.animations) do
        if animation._is_started == true then
            animation:draw()
        end
    end
end

--- @brief
function bt.AnimationQueue:update(delta)
    local current = self.animations[1]
    if current ~= nil then
        if current._is_started ~= true then
            current._is_started = true
            if current._start_callbacks ~= nil then
                for callback in values(current._start_callbacks) do
                    callback()
                end
            end
            current:start()
        end

        local result = current:update(delta)
        if result == bt.AnimationResult.DISCONTINUE then
            current._is_finished = true
            current:finish()
            if current._finish_callbacks ~= nil then
                for callback in values(current._finish_callbacks) do
                    callback()
                end
            end

            table.remove(self.animations, 1)
        elseif result == bt.AnimationResult.CONTINUE then
            -- noop
        else
            rt.error("In bt.EnemySprite:update: animation `" .. meta.typeof(current) .. "`s update function does not return a value")
        end
    end
end

--- @brief
function bt.AnimationQueue:add_animation(animation)
    table.insert(self.animations, animation)
end

--- @brief
--- @return Boolean true if at least one animation was skipped
function bt.AnimationQueue:skip()
    local skipped = false
    for instance in values(bt.AnimationQueue._all_instances) do
        if instance ~= nil then
            local current = instance.animations[1]
            if current ~= nil then
                if current._is_started == true then
                    current:update(0)
                    current:finish()
                    if current._finish_callbacks ~= nil then
                        for callback in values(current._finish_callbacks) do
                            callback()
                        end
                    end
                    table.remove(instance.animations, 1)
                    skipped = true
                end
            end
        end
    end
    return skipped
end

--[[
--- @brief
function bt.EnemySprite:add_continuous_animation(animation, start_immediately)
    self._continuousanimations[animation] = true
    start_immediately = which(start_immediately, true)
    if start_immediately == true then
        animation:start()
        animation._is_started = true
    end
end
]]--
