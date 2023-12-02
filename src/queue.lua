--- @class rt.Queue
rt.Queue = meta.new_type("Queue", function()
    local out = meta.new(rt.Queue, {
        _elements = {},
        _first_element = 0,
        _last_element = 1,
        _n_elements = 0
    })

    local metatable = getmetatable(out)
    metatable.__pairs = function(self)
        return pairs(self._elements)
    end
    metatable.__ipairs = function(self)
        return ipairs(self._elements)
    end
    metatable.__len = out.size
    return out
end)

--- @brief add element to start of queue
--- @param x any
function rt.Queue:push_front(x)


    local current = self._first_element - 1
    self._elements[current] = x
    self._first_element = current
    self._n_elements = self._n_elements + 1
end

--- @brief add element to end of queue
--- @param x any
function rt.Queue:push_back(x)


    local current = self._last_element
    self._elements[current] = x
    self._last_element = current + 1
    self._n_elements = self._n_elements + 1
end

--- @brief remove element at start of queue
--- @return any nil if queue is empty
function rt.Queue:pop_front()


    if (self._n_elements == 0) then
        return nil
    end

    local i = self._first_element
    local out = self._elements[i]
    self._first_element = i + 1
    self._n_elements = self._n_elements - 1

    return out
end

--- @brief remove element at end of queue
--- @return any nil if queue is empty
function rt.Queue:pop_back()


    if (self._n_elements == 0) then
        return nil
    end

    local i = self._last_element - 1
    local out = self._elements[i]
    self._elements[i] = nil
    self._last_element = i
    self._n_elements = self._n_elements - 1

    return out
end

--- @brief get element at start of queue
--- @return any nil if queue is empty
function rt.Queue:front()

    return self._elements[self._first_element]
end

--- @brief get element at end of queue
--- @return any nil if queue is empty
function rt.Queue:back()

    return self._elements[self._last_element - 1]
end

--- @brief get number of elements in queue
--- @return number
function rt.Queue:size()

    return self._n_elements
end

--- @brief check whether queue is empty
--- @return boolean
function rt.Queue:is_empty()

    return self:size() == 0
end

--- @brief remove all children
function rt.Queue:clear()

    self._elements = {}
    self._first_element = 0
    self._last_element = 1
    self._n_elements = 0
end

--- @brief [internal] test queue
function rt.test.queue()
    local queue = rt.Queue()
    assert(queue:size() == 0)
    assert(queue:is_empty())
    queue:push_front("front")
    queue:push_back("back")
    assert(queue:front() == "front")
    assert(queue:back() == "back")
    assert(queue:size() == 2)

    local front = queue:pop_front()
    assert(front == "front")
    local back = queue:pop_back()
    assert(back == "back")
    assert(queue:is_empty())
end



