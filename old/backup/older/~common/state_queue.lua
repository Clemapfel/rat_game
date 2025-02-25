--- @class rt.CallbackResult
rt.CallbackResult = meta.new_enum({
    CONTINUE = true,
    DISCONTINUE = false
})

--- @class rt.StateQueueState
--- @param args Table<Function> `update` function mandatory, while `start`, `finish`, and `draw` optional
rt.StateQueueState = meta.new_type("StateQueueState", rt.Drawable, function(args)
    local start, update, finish, draw
    for key, value in pairs(args) do
        if key == "start" then
            start = value
        elseif key == "update" then
            update = value
        elseif key == "finish" then
            finish = value
        elseif key == "draw" then
            draw = value
        else
            rt.error("In rt.StateQueueState: unknown argument name `" .. tostring(key) .. "`")
        end
    end

    local out = meta.new(rt.StateQueueState)

    if not meta.is_nil(start) then out.start = start end
    if not meta.is_nil(update) then out.update = update end
    if not meta.is_nil(finish) then out.finish = finish end
    if not meta.is_nil(draw) then out.draw = draw end

    return out
end)

rt.StateQueueState._started = false
rt.StateQueueState._finished = false

--- @brief
function rt.StateQueueState:get_is_done()
    return self._started == true and self._finished == true
end

--- @brief
function rt.StateQueueState:get_is_started()
    return self._started
end

--- @brief
function rt.StateQueueState:get_is_finished()
    return self._finished
end

--- @brief abstract, needs to be overloaded
--- @return rt.CallbackResult
function rt.StateQueueState:update(delta)
    rt.error("In rt.StateQueueState:update: abstract method called")
    return rt.CallbackResult.DISCONTINUE
end

--- @brief abstract
function rt.StateQueueState:start()
    -- noop, can be overloaded
end

--- @brief abstract
function rt.StateQueueState:finish()
    -- noop, can be overloaded
end

--- @brief abstract
function rt.StateQueueState:draw()
    -- noop, can be overloaded
end

--- @class rt.StateQueue
--- @signal transition (rt.StateQueue, rt.StateQueueState previous, rt.StatQueueState next) -> nil
rt.StateQueue = meta.new_type("StateQueue", function()
    local out = meta.new(rt.StateQueue, {
        _actions = rt.List(), -- rt.List<rt.StateQueueState>
        _is_paused = false
    }, rt.Drawable, rt.Animation)
    return out
end)

--- @overload
function rt.StateQueue:draw()
    local current_action = self._actions:front()
    if not meta.is_nil(current_action) and current_action:get_is_started() and not current_action:get_is_finished() then
        current_action:draw()
    end
end

--- @overload
function rt.StateQueue:update(delta)
    local current_action = self._actions:front()
    if not meta.is_nil(current_action) then
        if current_action._started == false then
            current_action._started = true
            current_action:start()
        end

        if self._is_paused then return end
        local res = current_action:update(delta)

        if res == rt.CallbackResult.CONTINUE then
            -- noop
        elseif res == rt.CallbackResult.DISCONTINUE then
            current_action._finished = true
            current_action:finish()
            self._actions:pop_front()
        else
            rt.error("In rt.StateQueue:update: StateQueueState `" .. meta.typeof(current_action) .. "`s `update` does not return rt.StateQueueResult")
        end
    end
end

--- @brief
function rt.StateQueue:push_back(action)
    meta.assert_isa(action, rt.StateQueueState)
    self._actions:push_back(action)

    if self:get_is_animated() == false then
        self:set_is_animated(true)
    end
end

--- @brief
function rt.StateQueue:skip()
    local current_action = self._actions:front()
    if not meta.is_nil(current_action) then

        if current_action._started == false then
            current_action._started = true
            current_action:start()
        end

        current_action:update(0)
        current_action._finished = true
        current_action:finish()
        self._actions:pop_front()
    end
end

--- @brief
function rt.StateQueue:set_is_paused(b)
    self._is_paused = b
    self:set_is_animated(not b)
end

--- @brief
function rt.StateQueue:get_is_paused()
    return self._is_paused
end

--- @brief
function rt.StateQueue:get_size()
    return self._actions:size()
end

--- @brief [internal]
function rt.test.state_queue()

    queue = rt.StateQueue()
    function new_closure()
        return rt.StateQueueState({
            start = function(self)
                assert(self:get_is_started())
                self.elapsed = 0
                local size = 100

                local w = rt.graphics.get_width() / 2
                local h = rt.graphics.get_height() / 2
                local x = rt.random.number(w - 200, w + 200)
                local y = rt.random.number(h - 200, h + 200)

                self.shape = rt.Rectangle(x, y, size, size)
                self.shape:set_color(rt.HSVA(rt.random.number(0, 1), 1, 1, 1))
            end,

            update = function(self, delta)
                self.elapsed = self.elapsed + delta
                self.shape:set_rotation(rt.degrees(self.elapsed % 1 * 360))

                if self.elapsed > 1 then
                    return rt.CallbackResult.DISCONTINUE
                else
                    return rt.CallbackResult.CONTINUE
                end
            end,

            finish = function(self)
                assert(self:get_is_finished())
                queue:push_back(new_closure("TEST"))
            end,

            draw = function(self)
                self.shape:draw()
            end
        })
    end

    queue:push_back(new_closure("TEST"))

    rt.current_scene.input:signal_connect("pressed", function(_, which)
        if which == rt.InputButton.A then
            queue:skip()
        elseif which == rt.InputButton.B then
            queue:push_back(new_closure("ADDED"))
        elseif which == rt.InputButton.X then
            queue:set_is_paused(not queue:get_is_paused())
        end
    end)

    queue:push_back(new_closure("TEST"))
    queue:draw()
end 