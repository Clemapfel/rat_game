--- @class mn.SelectionGraph
mn.SelectionGraph = meta.new_type("SelectionGraph", function()
    return meta.new(mn.SelectionGraph, {
        _nodes = {}, -- Set<mn.SelectionGraphNode>
        _current_node = nil,
        _n_nodes = 0
    })
end)

--- @class mn.SelectionGraphNode
mn.SelectionGraphNode = meta.new_type("SelectionGraphNode", rt.Drawable, function()
    return meta.new(mn.SelectionGraphNode, {
        _aabb = rt.AABB(0, 0, 1, 1),
        _centroid_x = 0,
        _centroid_y = 0,
        _on_enter = function()  end,
        _on_exit = function()  end,
        _on_activate = function()  end,
        _on_up = nil,     -- () -> mn.SelectionGraphNode
        _on_right = nil,  -- () -> mn.SelectionGraphNode
        _on_down = nil,   -- () -> mn.SelectionGraphNode
        _on_left = nil,   -- () -> mn.SelectionGraphNode
    })
end)

function mn.SelectionGraphNode:set_aabb(aabb_or_x, y, w, h)
    if meta.is_aabb(aabb_or_x) then
        self._aabb = aabb_or_x
    else
        self._aabb = rt.AABB(aabb_or_x, y, w, h)
    end

    self._centroid_x = self._aabb.x + 0.5 * self._aabb.width
    self._centroid_y = self._aabb.y + 0.5 * self._aabb.height
end

function mn.SelectionGraphNode:get_aabb()
    return self._aabb
end

for which in range("up", "right", "down", "left") do
    local on_which = "_on_" .. which
    mn.SelectionGraphNode["set_" .. which] = function(self, other_or_f)
        if other_or_f == nil then
            self[on_which] = nil
        elseif meta.is_function(other_or_f) then
            self[on_which] = other_or_f
        else
            meta.assert_isa(other_or_f, mn.SelectionGraphNode)
            self[on_which] = function()
                return other_or_f
            end
        end
    end

    mn.SelectionGraphNode["get_" .. which] = function(self)
        if self[on_which] ~= nil then
            return self[on_which]()
        else
            return nil
        end
    end

    mn.SelectionGraph["move_" .. which] = function(self)
        local current = self._current_node
        if current ~= nil then
            local next = current["get_" .. which](current)
            if next ~= nil then
                meta.assert_isa(next, mn.SelectionGraphNode)
                self._current_node = next
                return true
            end
        end
        return false
    end
end

function mn.SelectionGraphNode:draw(color)

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

function mn.SelectionGraph:add(node)
    meta.assert_isa(node, mn.SelectionGraphNode)
    if self._nodes[node] == nil then
        self._nodes[node] = true
        if self._n_nodes == 0 then
            self._current_node = node
        end
        self._n_nodes = self._n_nodes + 1
    end
end

function mn.SelectionGraph:remove(node)
    if self._nodes[node] ~= nil then
        self._nodes[node] = nil
        self._n_nodes = self._n_nodes - 1
    end
end

function mn.SelectionGraph:set_current_node(node)
    self:add(node)
    self._current_node = node
end

function mn.SelectionGraph:draw()
    for node in keys(self._nodes) do
        node:draw(rt.Palette.GRAY_4)
    end

    if self._current_node ~= nil then
        self._current_node:draw(rt.Palette.SELECTION)
    end
end