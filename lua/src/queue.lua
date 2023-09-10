--- @class rt.Queue
rt.Queue = meta.new_type("Queue", function()

    local out = meta.new("Queue")
    local metatable = getmetatable(out)
    metatable.first_element = 0
    metatable.last_element = 0
    metatable.n_elements = 0

    metatable.__index = function(this, i)
        if not meta.is_number(i) then
            return getmetatable(this).properties[i]
        end

        return rawget(this, getmetatable(this).first_element + 1 + i)
    end

    metatable.__newindex = function(this, i, new)
        if not meta.is_number(i) then
            getmetatable(this).properties[i] = new
        else
            rawset(this, getmetatable(this).first_element + 1 + i, new)
        end
    end

    metatable.__len = out.size
    return out
end) -- Queue


--- @brief add element to start of queue
--- @param queue rt.Queue
--- @param x any
function rt.Queue.push_front(queue, x)
    meta.assert_isa(queue, "Queue")

    local q_meta = getmetatable(out)
    local current = q_meta.first_element - 1
    rawset(queue, current, x)

    q_meta.first_element = current
    q_meta.n_elements = q_meta.n_elements + 1
end

--- @brief add element to end of queue
--- @param queue rt.Queue
--- @param x any
function rt.Queue.push_back(queue, x)
    meta.assert_isa(queue, "Queue")

    local q_meta = getmetatable(queue)
    local current = q_meta.last_element
    rawset(queue, current, x)

    q_meta.last_element = current + 1
    q_meta.n_elements = q_meta.n_elements + 1
end

--- @brief remove element at start of queue
--- @param queue rt.Queue
--- @return any nil if queue is empty
function rt.Queue.pop_front(queue)
    meta.assert_isa(queue, "Queue")

    local q_meta = getmetatable(queue)

    if (q_meta.n_elements == 0) then
        return nil
    end

    local i = q_meta.first_element
    local out = rawget(queue, i)
    rawset(queue, i, nil)
    q_meta.first_element = i + 1
    q_meta.n_elements = q_meta.n_elements - 1

    return out
end

--- @brief remove element at end of queue
--- @param queue rt.Queue
--- @return any nil if queue is empty
function rt.Queue.pop_back(queue)
    meta.assert_isa(queue, "Queue")

    local q_meta = getmetatable(queue)

    if (q_meta.n_elements == 0) then
        return nil
    end

    local i = q_meta.last_element - 1
    local out = rawget(queue, i)
    rawset(queue, i, nil)
    q_meta.last_element = i
    q_meta.n_elements = q_meta.n_elements - 1

    return out
end

--- @brief get element at start of queue
--- @param queue rt.Queue
--- @return any nil if queue is empty
function rt.Queue.front(queue)
    meta.assert_isa(queue, "Queue")
    return rawget(queue, getmetatable(queue).first_element + 1)
end

--- @brief get element at end of queue
--- @param queue rt.Queue
--- @return any nil if queue is empty
function rt.Queue.back(queue)
    meta.assert_isa(queue, "Queue")
    return rawget(queue, getmetatable(queue).last_element - 1)
end

--- @brief get number of elements in queue
--- @return number
function rt.Queue.size(queue)
    meta.assert_isa(queue, "Queue")
    return getmetatable(queue).n_elements
end

--- @brief check whether queue is empty
--- @return boolean
function rt.Queue.is_empty(queue)
    meta.assert_isa(queue, "Queue")
    return out.size(queue) == 0
end

--- @brief [internal] test queue
function rt.test.queue()
    -- TODO
end
rt.test.queue()


