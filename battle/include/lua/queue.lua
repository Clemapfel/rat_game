--- @class Queue
Queue = meta.new_type("Queue", {})

--- @constructor Queue
Queue.__meta.__call = function()

    local out = meta.new(Queue)
    out.__meta.first_element = 0
    out.__meta.last_element = 0
    out.__meta.n_elements = 0

    out.push_front = Queue.push_front
    out.push_back = Queue.push_back
    out.pop_front = Queue.pop_front
    out.front = Queue.front
    out.pop_back = Queue.pop_back
    out.back = Queue.back
    out.size = Queue.size
    out.is_empty = Queue.is_empty

    out.__meta.__index = function(this, i)
        if not meta.is_number(i) then
            return rawget(this, i)
        end
        return rawget(this, getmetatable(this).first_element + 1 + i)
    end

    out.__meta.__newindex = function(this, i, new)
        if not meta.is_number(i) then
            rawset(this, i, new)
        else
            rawset(this, getmetatable(this).first_element + 1 + i, new)
        end
    end

    return out
end

--- @brief add element to start of queue
--- @param queue Queue
--- @param x any
function push_front(queue, x)

    meta.assert_type(Queue, queue, "Queue.push_front", 1)

    local q_meta = rawget(queue, "__meta")
    local current = q_meta.first_element - 1
    rawset(queue, current, x)

    q_meta.first_element = current
    q_meta.n_elements = q_meta.n_elements + 1
end

--- @brief add element to end of queue
--- @param queue Queue
--- @param x any
function Queue.push_back(queue, x)

    meta.assert_type(Queue, queue, "Queue.push_back", 1)

    local q_meta = getmetatable(queue)
    local current = q_meta.last_element
    rawset(queue, current, x)

    q_meta.last_element = current + 1
    q_meta.n_elements = q_meta.n_elements + 1
end

--- @brief remove element at start of queue
--- @param queue Queue
--- @return any nil if queue is empty
function Queue.pop_front(queue)
    meta.assert_type(Queue, queue, "Queue.pop_front", 1)

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
--- @param queue Queue
--- @return any nil if queue is empty
function Queue.pop_back(queue)
    meta.assert_type(Queue, queue, "Queue.pop_front", 1)

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
--- @param queue Queue
--- @return any nil if queue is empty
function Queue.front(queue)
    meta.assert_type(Queue, queue, "Queue.front", 1)
    return rawget(queue, getmetatable(queue).first_element + 1)
end

--- @brief get element at end of queue
--- @param queue Queue
--- @return any nil if queue is empty
function Queue.back(queue)
    meta.assert_type(Queue, queue, "Queue.back", 1)
    return rawget(queue, getmetatable(queue).last_element - 1)
end

--- @brief get number of elements in queue
--- @return number
function Queue.size(queue)
    meta.assert_type(Queue, queue, "Queue.front", 1)
    return rawget(queue, "__meta").n_elements
end

--- @brief check whether queue is empty
--- @return boolean
function Queue.is_empty(queue)
    meta.assert_type(Queue, queue, "Queue.pop_front", 1)
    return Queue.size(queue) == 0
end
