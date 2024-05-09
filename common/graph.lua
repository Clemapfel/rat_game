--- @class rt.Quaternarytree
rt.QuaternaryTree = meta.new_type("QuaternaryTree", function()
    return meta.new(rt.QuaternaryTree, {
        _nodes = {}
    })
end)

--- @brief
function rt.QuaternaryTree:add(value)
    meta.assert_isa(value, rt.Widget)
    local to_insert = {
        value = value,
        up = nil,
        right = nil,
        bottom = nil,
        left = nil
    }

    self._nodes[value] = to_insert
    if #self._nodes == 1 then
        self._current_node = to_insert
    end
    return to_insert
end

-- generate move_*, get_*, link_*
for which in range("left", "up", "right", "down") do
    --- @brief
    --- @return true if position changed, false otherwise
    rt.QuaternaryTree["move_" .. which] = function(self)
        if self._current_node == nil then return false end
        if self._current_node[which] ~= nil then
            self._current_node = self._current_node[which]
            return true
        else
            return false
        end
    end

    --- @brief
    rt.QuaternaryTree["can_move_" .. which] = function(self)
        return self._current_node[which] ~= nil
    end

    --- @brief
    rt.QuaternaryTree["get_"] = function(self)
        if self._current_node == nil then return false end
        return self._current_node[which].value
    end
end

function rt.QuaternaryTree:link_horizontally(left, right)
    if self._nodes[left] == nil then self:add(left) end
    if self._nodes[right] == nil then self:add(right) end

    local left_node = self._nodes[left]
    local right_node = self._nodes[right]
    left_node.right = right_node
    right_node.left = left_node
end

function rt.QuaternaryTree:link_vertically(up, bottom)
    if self._nodes[up] == nil then self:add(up) end
    if self._nodes[bottom] == nil then self:add(bottom) end

    local up_node = self._nodes[up]
    local bottom_node = self._nodes[bottom]
    up_node.bottom = bottom_node
    bottom_node.up = up_node
end

--- @brief
function rt.QuaternaryTree:get_current()
    if self._current_node == nil then return nil end
    return self._current_node.value
end

--- @brief
function rt.QuaternaryTree:set_current(value)
    if self._nodes[value] == nil then self:add(value) end
    self._current_node = self._nodes[value]
end

