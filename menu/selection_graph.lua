--- @class mn.SelectionGraph
mn.SelectionGraph = meta.new_type("SelectionGraph", function()
    return meta.new(mn.SelectionGraph, {
        _items = {}, -- Table<Number, Item>
        _current_id = 1
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
        _up = nil,
        _right = nil,
        _down = nil,
        _left = nil
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

function mn.SelectionGraphNode:link_up(other)
    if other ~= nil then
        meta.assert_isa(other, mn.SelectionGraphNode)
        other._down = self
    end
    self._up = other
end

function mn.SelectionGraphNode:set_up(other)
    self._up = other
end

function mn.SelectionGraphNode:get_up()
    return self._up
end

function mn.SelectionGraphNode:link_right(other)
    if other ~= nil then
        meta.assert_isa(other, mn.SelectionGraphNode)
        other._left = self
    end
    self._right = other
end

function mn.SelectionGraphNode:set_right(other)
    self._right = other
end

function mn.SelectionGraphNode:get_right()
    return self._right
end

function mn.SelectionGraphNode:link_down(other)
    if other ~= nil then
        meta.assert_isa(other, mn.SelectionGraphNode)
        other._up = self
    end
    self._down = other
end

function mn.SelectionGraphNode:set_down(other)
    self._down = other
end

function mn.SelectionGraphNode:get_down()
    return self._down
end

function mn.SelectionGraphNode:link_left(other)
    if other ~= nil then
        meta.assert_isa(other, mn.SelectionGraphNode)
        other._right = self
    end
    self._left = other
end

function mn.SelectionGraphNode:set_left(other)
    self._left = other
end

function mn.SelectionGraphNode:get_left()
    return self._left
end

function mn.SelectionGraphNode:draw()
    love.graphics.setLineWidth(3)
    love.graphics.setColor(rt.color_unpack(rt.Palette.SELECTION))
    love.graphics.rectangle("line", self._aabb.x, self._aabb.y, self._aabb.width, self._aabb.height)

    local from_x, from_y = self._centroid_x, self._centroid_y
    love.graphics.setColor(rt.color_unpack(rt.Palette.BLACK))
    love.graphics.circle("fill", from_x, from_y, 7)
    love.graphics.setColor(rt.color_unpack(rt.Palette.SELECTION))
    love.graphics.circle("fill", from_x, from_y, 6)

    for direction in range(
        "_up", "_right", "_down", "_left"
    ) do
        if self[direction] ~= nil then
            love.graphics.setColor(rt.color_unpack(rt.Palette.SELECTION))
            local to_x, to_y = self[direction]._centroid_x, self[direction]._centroid_y
            love.graphics.line(from_x, from_y, to_x, to_y)
        end
    end
end
