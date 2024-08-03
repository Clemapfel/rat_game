--- @class rt.SelectionGraph
rt.SelectionGraph = meta.new_type("SelectionGraph", function()
    return meta.new(rt.SelectionGraph, {
        _nodes = {}, -- Set<rt.SelectionGraphNode>
        _current_node = nil,
        _n_nodes = 0
    })
end)

--- @brief
function rt.SelectionGraph:handle_button(button)
    local node = self._current_node
    if node == nil then return end

    if button == rt.InputButton.A and node._on_a ~= nil then
        node:_on_a()
    elseif button == rt.InputButton.B and node._on_b ~= nil then
        node:_on_b()
    elseif button == rt.InputButton.X and node._on_x ~= nil then
        node:_on_x()
    elseif button == rt.InputButton.Y and node._on_y ~= nil then
        node:_on_y()
    else
        local next
        if button == rt.InputButton.UP and node._on_up ~= nil then
            next = node:_on_up()
        elseif button == rt.InputButton.RIGHT and node._on_right ~= nil then
            next = node:_on_right()
        elseif button == rt.InputButton.DOWN and node._on_down ~=  nil then
            next = node:_on_down()
        elseif button == rt.InputButton.LEFT and node._on_left ~= nil then
            next = node:_on_left()
        end

        if next ~= nil then
            meta.assert_isa(next, rt.SelectionGraphNode)
            if self._current_node._on_exit ~= nil then
                self._current_node:_on_exit()
            end

            self._current_node = next

            if self._current_node._on_exit ~= nil then
                self._current_node:_on_enter()
            end
        end
    end
end

--- @brief
function rt.SelectionGraph:add(node)
    meta.assert_isa(node, rt.SelectionGraphNode)
    if self._nodes[node] == nil then
        self._nodes[node] = true
        if self._n_nodes == 0 then
            self._current_node = node
        end
        self._n_nodes = self._n_nodes + 1
    end
end

--- @brief
function rt.SelectionGraph:remove(node)
    if self._nodes[node] ~= nil then
        self._nodes[node] = nil
        self._n_nodes = self._n_nodes - 1
    end
end

--- @brief
function rt.SelectionGraph:set_current_node(node)
    self:add(node)

    if self._current_node ~= nil and self._current_node._on_exit ~= nil then
        self._current_node:_on_exit()
    end

    self._current_node = node

    if self._current_node ~= nil and self._current_node._on_enter ~= nil then
        self._current_node:_on_enter()
    end
end


--- @brief
function rt.SelectionGraph:get_current_node_aabb()
    if self._current_node ~= nil then
        return self._current_node._aabb
    else
        return rt.AABB(0, 0, 1, 1)
    end
end

--- @brief
function rt.SelectionGraph:get_current_node()
    return self._current_node
end

--- @brief
function rt.SelectionGraph:clear()
    for node in keys(self._nodes) do
        if node._on_exit ~= nil then
            node:_on_exit()
        end
    end
    self._nodes = {}
    self._current_node = nil
end

--- @brief
function rt.SelectionGraph:draw()
    for node in keys(self._nodes) do
        node:draw()
    end
end

-- #############################

--- @class rt.SelectionGraphNode
rt.SelectionGraphNode = meta.new_type("SelectionGraphNode", rt.Drawable, rt.SignalEmitter, function(aabb)
    local out = meta.new(rt.SelectionGraphNode, {
        _aabb = rt.AABB(0, 0, 1, 1),
        _centroid_x = 0,
        _centroid_y = 0,
        _on_enter = nil,
        _on_exit = nil,
        _on_up = nil,
        _on_right = nil,
        _on_down = nil,
        _on_left = nil,
        _on_a = nil,
        _on_b = nil,
        _on_x = nil,
        _on_y = nil
    })

    if aabb ~= nil then
        out._aabb = aabb
        out._centroid_x = aabb.x + 0.5 * aabb.width
        out._centroid_y = aabb.y + 0.5 * aabb.height
    end

    return out
end)

--- @brief
function rt.SelectionGraphNode:set_aabb(aabb_or_x, y, w, h)
    if meta.is_aabb(aabb_or_x) then
        self._aabb = aabb_or_x
    else
        self._aabb = rt.AABB(aabb_or_x, y, w, h)
    end

    self._centroid_x = self._aabb.x + 0.5 * self._aabb.width
    self._centroid_y = self._aabb.y + 0.5 * self._aabb.height
end

--- @brief
function rt.SelectionGraphNode:get_aabb()
    return self._aabb
end

for which in range(
    "enter",
    "exit",
    "up",
    "right",
    "down",
    "left",
    "a",
    "b",
    "x",
    "y"
) do
    rt.SelectionGraphNode["set_on_" .. which] = function(self, f)
        self["_on_" .. which] = f
    end
end

for which in range(
    "up",
    "right",
    "down",
    "left"
) do
    rt.SelectionGraphNode["set_" .. which] = function(self, other)
        if meta.is_function(other) then
            self["set_on_" .. which](self, other)
        else
            self["set_on_" .. which](self, function(self)
                return other
            end)
        end
    end

    rt.SelectionGraphNode["get_" .. which] = function(self)
        if self["_on_" .. which] ~= nil then
            return self["_on_" .. which](self)
        else
            return nil
        end
    end
end

--- @brief
function rt.SelectionGraphNode:draw(color)
    local color = which(color, rt.Palette.SELECTION)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(rt.color_unpack(color))
    love.graphics.rectangle("line", self._aabb.x, self._aabb.y, self._aabb.width, self._aabb.height)

    local from_x, from_y = self._centroid_x, self._centroid_y
    love.graphics.setColor(rt.color_unpack(rt.Palette.BLACK))
    love.graphics.circle("fill", from_x, from_y, 7)
    love.graphics.setColor(rt.color_unpack(color))
    love.graphics.circle("fill", from_x, from_y, 6)

    for direction in range(
        "up", "right", "down", "left"
    ) do
        local next = self["get_" .. direction](self)
        if next ~= nil then
            love.graphics.setColor(rt.color_unpack(color))
            local to_x, to_y = next._centroid_x, next._centroid_y
            love.graphics.line(from_x, from_y, to_x, to_y)
        end
    end
end

