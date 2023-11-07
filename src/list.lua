--- @class rt.List
rt.List = meta.new_type("List", function()
    local out = meta.new(rt.List, {
        _first_node = {},
        _last_node = {},
        _nodes = {},
        _n_elements = 0
    })

    local metatable = getmetatable(out)
    metatable.__pairs = function(self)

        local function iterator(self, node)
            local value
            node, value = node.next, node.value
            return node, value
        end
        return iterator, self, self._first_node
    end

    metatable.__ipairs = metatable.__pairs
    metatable.__len = out.size
    return out
end)

--- @brief
function rt.List:push_front(element)
    meta.assert_isa(self, rt.List)
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

--- @brief
function rt.List:push_back(element)
    meta.assert_isa(self, rt.List)
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

--- @brief
function rt.List:pop_front()
    meta.assert_isa(self, rt.List)
    local out = self._first_node
    if not meta.is_nil(out.next) then
        out.next.previous = nil
    end

    self._first_node = out.next
    self._n_elements = self._n_elements - 1
    return out.value
end

--- @brief
function rt.List:pop_back()
    meta.assert_isa(self, rt.List)
    local out = self._last_node
    if not meta.is_nil(out.previous) then
        out.previous.next = nil
    end

    self._last_node = out.previous
    self._n_elements = self._n_elements - 1
    return out.value
end

--- @brief
--- @return any removed value
function rt.List:erase(index)
    meta.assert_isa(self, rt.List)
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

--- @brief insert element after index, or 0 to insert at start
function rt.List:insert(index, element)
    meta.assert_isa(self, rt.List)
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

--- @brief
function rt.List:at(index)
    meta.assert_isa(self, rt.List)
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

--- @brief
function rt.List:set(index, new_value)
    meta.assert_isa(self, rt.List)
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

--- @brief
function rt.List:clear()
    meta.assert_isa(self, rt.List)
    self._nodes = {}
    self._first_node = nil
    self._last_node = nil
    self._n_elements = 0
end

--- @brief
function rt.List:size()
    meta.assert_isa(self, rt.List)
    return self._n_elements
end

--- @brief [internal] test
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
        println(i, " ", value)
        --assert(list:at(i) == value)
    end
end
rt.test.list()

