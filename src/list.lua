--- @class rt.List
--- @see rt.test.list for how to iterate
rt.List = meta.new_type("List", function()
    local out = meta.new(rt.List, {
        _first_node = {},
        _last_node = {},
        _nodes = {},
        _n_elements = 0
    })

    local metatable = getmetatable(out)
    metatable.__pairs = function(self)
        local function iterator(_, state)
            if meta.is_nil(state) or meta.is_nil(state.node) then return end
            local value = state.node.value
            state.node = state.node.next
            return state, value
        end
        return iterator, self, ternary(self:size() == 0, nil, { node = self._first_node })
    end

    metatable.__ipairs = function(self)
        local function iterator(self, index)
            local value = self:at(index) -- TODO: return index without using `at`
            index = index + 1
            if index > self._n_elements then return nil end
            return index, value
        end
        return iterator, self, 0
    end

    metatable.__len = out.size
    return out
end)

--- @brief add element to start of list, O(1)
--- @param element any
function rt.List:push_front(element)

    local to_insert = {
        value = element,
        previous = nil,
        next = self._first_node
    }

    if self._n_elements == 0 then
        self._last_node = to_insert
    end

    self._first_node.previous = to_insert
    self._first_node = to_insert
    self._n_elements = self._n_elements + 1
    table.insert(self._nodes, to_insert)
end

--- @brief add element to back of list, O(1)
--- @param element any
function rt.List:push_back(element)

    local to_insert = {
        value = element,
        previous = self._last_node,
        next = nil
    }

    if self._n_elements == 0 then
        self._first_node = to_insert
    end

    self._last_node.next = to_insert
    self._last_node = to_insert
    self._n_elements = self._n_elements + 1
    table.insert(self._nodes, to_insert)
end

--- @brief remove element from front of list, O(1)
--- @return any
function rt.List:pop_front()

    local out = self._first_node
    if not meta.is_nil(out.next) then
        out.next.previous = nil
    end

    self._first_node = out.next
    self._n_elements = self._n_elements - 1
    return out.value
end

--- @brief remove element from end of list, O(1)
--- @return any
function rt.List:pop_back()

    local out = self._last_node
    if not meta.is_nil(out.previous) then
        out.previous.next = nil
    end

    self._last_node = out.previous
    self._n_elements = self._n_elements - 1
    return out.value
end

--- @brief erase element in list, O(i)
--- @param index Number 1-based
--- @return any removed value
function rt.List:erase(index)

    if index > self._n_elements or index < 1 then
        rt.error("In rt.list:erase: index `" .. tostring(index) .. "` is out of bounds for list with `" .. tostring(self._n_elements) .. "` elements")
    end

    local node = self._first_node
    local i = 1
    while i < index and not meta.is_nil(node.next) do
        node = node.next
        i = i + 1
    end

    if not meta.is_nil(node.previous) then
        node.previous.next = node.next
    else
        self._first_node = node.next
    end

    if not meta.is_nil(node.next) then
        node.next.previous = node.previous
    else
        self._last_node = node.previous
    end

    self._n_elements = self._n_elements - 1
    table.remove(self._nodes, i)
    return node.value
end

--- @brief insert element after index, or 0 to insert at start, O(i)
--- @param index Number 1-based
--- @param element any
function rt.List:insert(index, element)

    if index > self._n_elements or index < 0 then
        rt.error("In rt.list:erase: index `" .. tostring(index) .. "` is out of bounds for list with `" .. tostring(self._n_elements) .. "` elements")
    end

    local to_insert = {
        value = element,
        previous = nil,
        next = nil
    }

    if index == 0 then
        to_insert.next = self._first_node
        self._first_node.previous = to_insert
        self._first_node = to_insert
    else
        local node = self._first_node
        local i = 1
        while i < index and not meta.is_nil(node.next) do
            node = node.next
            i = i + 1
        end

        to_insert.previous = node
        to_insert.next = node.next

        if not meta.is_nil(node.next) then
            node.next = to_insert
        else
            self._last_node = to_insert
        end
    end

    table.insert(self._nodes, to_insert)
    self._n_elements = self._n_elements + 1
end

--- @brief get value at given index, O(i)
--- @param index Number 1-based
--- @return any
function rt.List:at(index)

    if index > self._n_elements then
        rt.error("In rt.list:at: index `" .. tostring(index) .. "` is out of bounds for list with `" .. tostring(self._n_elements) .. "` elements")
    end

    local node = self._first_node
    local i = index
    while i > 1 and not meta.is_nil(node.next) do
        node = node.next
        i = i - 1
    end
    return node.value
end

--- @brief replace value at given index, O(i)
--- @param index Number 1-based
--- @param new_value any
function rt.List:set(index, new_value)

    if index > self._n_elements then
        rt.error("In rt.list:set: index `" .. tostring(index) .. "` is out of bounds for list with `" .. tostring(self._n_elements) .. "` elements")
    end

    local node = self._first_node
    local i = index
    while i > 1 and not meta.is_nil(node.next) do
        node = node.next
        i = i - 1
    end
    node.value = new_value
end

--- @brief remove all elements in queue
function rt.List:clear()

    self._nodes = {}
    self._first_node = nil
    self._last_node = nil
    self._n_elements = 0
end

--- @brief get number of elements, O(1)
--- @return Number
function rt.List:size()

    return self._n_elements
end

--- @brief [internal] test list
function rt.test.list()
    local list = rt.List()
    for i = 10, 20 do
        list:push_back(i)
    end

    for i = 9, 1, -1 do
        list:push_front(i)
    end

    local node = list._first_node
    local i = 1
    while not meta.is_nil(node.next) do
        assert(node.value == i)
        node = node.next
        i = i + 1
    end

    for i = 1, 20, 1 do
        assert(list:at(i) == i)
        list:set(i, i + 1)
        assert(list:at(i) == i + 1)
        list:set(i, i)
    end

    for i = 1, 10, 1 do
        list:insert(1, 1234)
    end

    for i = 1, 10, 1 do
        list:erase(2)
    end

    node = list._first_node
    i = 1
    while not meta.is_nil(node.next) do
        assert(node.value ~= 1234)
        node = node.next
        i = i + 1
    end

    for i, value in pairs(list) do
        assert(i.index == value)
    end
end

