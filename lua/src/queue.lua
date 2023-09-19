--- @class rt.Queue
rt.Queue = meta.new_type("Queue", function()

    local out = meta.new(rt.Queue, {
        elements = {},
        first_element = 0,
        last_element = 1,
        n_elements = 0
    })

    local metatable = getmetatable(out)
    metatable.__pairs = function(self)
        return pairs(self.elements)
    end
    metatable.__ipairs = function(self)
        return ipairs(self.elements)
    end

    metatable.__len = out.size
    return out
end) -- Queue


--- @brief add element to start of queue
--- @param x any
function rt.Queue:push_front(x)
    meta.assert_isa(self, rt.Queue)

    local current = self.first_element - 1
    self.elements[current] = x
    self.first_element = current
    self.n_elements = self.n_elements + 1
end

--- @brief add element to end of queue
--- @param x any
function rt.Queue:push_back(x)
    meta.assert_isa(self, rt.Queue)

    local current = self.last_element
    self.elements[current] = x
    self.last_element = current + 1
    self.n_elements = self.n_elements + 1
end

--- @brief remove element at start of queue
--- @return any nil if queue is empty
function rt.Queue:pop_front()
    meta.assert_isa(self, rt.Queue)

    if (self.n_elements == 0) then
        return nil
    end

    local i = self.first_element
    local out = self.elements[i]
    self.first_element = i + 1
    self.n_elements = self.n_elements - 1

    return out
end

--- @brief remove element at end of queue
--- @return any nil if queue is empty
function rt.Queue:pop_back()
    meta.assert_isa(self, rt.Queue)

    if (self.n_elements == 0) then
        return nil
    end

    local i = self.last_element - 1
    local out = self.elements[i]
    self.elements[i] = nil
    self.last_element = i
    self.n_elements = self.n_elements - 1

    return out
end

--- @brief get element at start of queue
--- @return any nil if queue is empty
function rt.Queue:front()
    meta.assert_isa(self, rt.Queue)
    return self.elements[self.first_element]
end

--- @brief get element at end of queue
--- @return any nil if queue is empty
function rt.Queue:back()
    meta.assert_isa(self, rt.Queue)
    return self.elements[self.last_element - 1]
end

--- @brief get number of elements in queue
--- @return number
function rt.Queue:size()
    meta.assert_isa(self, rt.Queue)
    return self.n_elements
end

--- @brief check whether queue is empty
--- @return boolean
function rt.Queue:is_empty()
    meta.assert_isa(self, rt.Queue)
    return self:size() == 0
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
rt.test.queue()


