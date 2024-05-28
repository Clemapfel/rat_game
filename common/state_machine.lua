--- @class rt.StateMachine
rt.StateMachine = meta.new_type("StateMachine", function()
    return meta.new(rt.StateMachine, {
        _states = {},            -- Table<ID, rt.StateMachine.State>
        _current_state = nil,    -- rt.StateMachine.State
    })
end)

rt.StateMachine.State = meta.new_type("StateMachineState", function(id)
    return meta.new(rt.StateMachine.State, {
        _id = id
    })
end)

function rt.StateMachine:get_id()
    return self._id
end

function rt.StateMachine.State.update(delta) end
function rt.StateMachine.State.enter() end
function rt.StateMachine.State.exit() end

--- @brief
function rt.StateMachine:transition(next)
    meta.assert_isa(next, rt.StateMachine.State)

    local current = self._current_state
    if current ~= nil and current.exit ~= nil then
        current.exit()
    end

    self._current_state = next
    if next ~= nil and next.enter ~= nil then
        next.enter()
    end
end

--- @brief
function rt.StateMachine:update(delta)
    local current = self._current_state
    if current ~= nil and current.update ~= nil then
        current.update(delta)
    end
end

--- @brief
function rt.StateMachine:add_state(state)
    meta.assert_isa(state, rt.StateMachine.State)
    self._states[state:get_id()] = state
end

--- @brief
function rt.StateMachine:get_current_state()
    return self._current_state
end

--- @brief move state without invoking callbacks
function rt.StateMachine:override_current_state(id)
    local next = self._states[id]
    if next == nil then
        rt.error("In rt.StateMachine.transition: requesting transition to state `" .. id .. "`, which does not exist")
    end

    self._current_state = next
end