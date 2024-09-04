--- @class rt.SelectionGraph
rt.SelectionGraph = meta.new_type("SelectionGraph", rt.Drawable, function()
    return meta.new(rt.SelectionGraph, {
        _nodes = {}, -- Set<rt.SelectionGraphNode>
        _current_node = nil,
        _n_nodes = 0
    })
end)

--- @class rt.SelectionGraphNode
--- @signal enter (rt.SelectionGraphNode) -> nil
--- @signal exit (rt.SelectionGraphNode) -> nil
--- @signal rt.InputButton.UP (rt.SelectionGraphNode) -> rt.SelectionGraphNode
--- @signal rt.InputButton.RIGHT (rt.SelectionGraphNode) -> rt.SelectionGraphNode
--- @signal rt.InputButton.DOWN (rt.SelectionGraphNode) -> rt.SelectionGraphNode
--- @signal rt.InputButton.LEFT (rt.SelectionGraphNode) -> rt.SelectionGraphNode
--- @signal rt.InputButton.A (rt.SelectionGraphNode) -> nil
--- @signal rt.InputButton.B (rt.SelectionGraphNode) -> nil
--- @signal rt.InputButton.X (rt.SelectionGraphNode) -> nil
--- @signal rt.InputButton.Y (rt.SelectionGraphNode) -> nil
rt.SelectionGraphNode = meta.new_type("SelectionGraphNode", rt.SignalEmitter, rt.Drawable, function(aabb)
    local out = meta.new(rt.SelectionGraphNode, {
        _aabb = rt.AABB(0, 0, 1, 1),
        _control_layout_function = function() return {} end,
        _centroid_x = 0,
        _centroid_y = 0,
    })

    if aabb ~= nil then
        out._aabb = aabb
        out._centroid_x = aabb.x + 0.5 * aabb.width
        out._centroid_y = aabb.y + 0.5 * aabb.height
    end

    for id in range(
        "enter",
        "exit",
        rt.InputButton.UP,
        rt.InputButton.RIGHT,
        rt.InputButton.DOWN,
        rt.InputButton.LEFT,
        rt.InputButton.A,
        rt.InputButton.B,
        rt.InputButton.X,
        rt.InputButton.Y
    ) do
        out:signal_add(id)
    end

    return out
end)

--- @brief
function rt.SelectionGraphNode:set_bounds(aabb_or_x, y, w, h)
    if meta.is_aabb(aabb_or_x) then
        self._aabb = aabb_or_x
    else
        self._aabb = rt.AABB(aabb_or_x, y, w, h)
    end

    self._centroid_x = self._aabb.x + 0.5 * self._aabb.width
    self._centroid_y = self._aabb.y + 0.5 * self._aabb.height
end

--- @brief
function rt.SelectionGraphNode:get_bounds()
    return self._aabb
end

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
        local next = self:signal_emit(direction)
        if next ~= nil then
            love.graphics.setColor(rt.color_unpack(color))
            local to_x, to_y = next._centroid_x, next._centroid_y
            love.graphics.line(from_x, from_y, to_x, to_y)
        end
    end
end

--- @brief
function rt.SelectionGraphNode:set_up(next)
    if next == nil then
        self:signal_disconnect(rt.InputButton.UP)
    else
        meta.assert_isa(next, rt.SelectionGraphNode)
        self:signal_connect(rt.InputButton.UP, function(self)
            return next
        end)
    end
end

--- @brief
function rt.SelectionGraphNode:get_up()
    return self:signal_emit(rt.InputButton.UP)
end

--- @brief
function rt.SelectionGraphNode:set_right(next)
    if next == nil then
        self:signal_disconnect(rt.InputButton.RIGHT)
    else
        meta.assert_isa(next, rt.SelectionGraphNode)
        self:signal_connect(rt.InputButton.RIGHT, function(self)
            return next
        end)
    end
end

--- @brief
function rt.SelectionGraphNode:get_right()
    return self:signal_emit(rt.InputButton.RIGHT)
end

--- @brief
function rt.SelectionGraphNode:set_down(next)
    if next == nil then
        self:signal_disconnect(rt.InputButton.DOWN)
    else
        meta.assert_isa(next, rt.SelectionGraphNode)
        self:signal_connect(rt.InputButton.DOWN, function(self)
            return next
        end)
    end
end

--- @brief
function rt.SelectionGraphNode:get_down()
    return self:signal_emit(rt.InputButton.DOWN)
end

--- @brief
function rt.SelectionGraphNode:set_left(next)
    if next == nil then
        self:signal_disconnect(rt.InputButton.LEFT)
    else
        meta.assert_isa(next, rt.SelectionGraphNode)
        self:signal_connect(rt.InputButton.LEFT, function(self)
            return next
        end)
    end
end

--- @brief
function rt.SelectionGraphNode:get_left()
    return self:signal_emit(rt.InputButton.LEFT)
end

--- @brief
function rt.SelectionGraphNode:set_control_layout(layout)
    if meta.is_function(layout) then
        self._control_layout_function = layout
    else
        self._control_layout_function = function()
            return layout
        end
    end
end

--- @brief
function rt.SelectionGraphNode:get_control_layout()
    return self._control_layout_function()
end

--- ###

--- @brief
function rt.SelectionGraph:handle_button(button)
    local current = self._current_node
    if current == nil then return end

    if button == rt.InputButton.A or button == rt.InputButton.B or button == rt.InputButton.X or button == rt.InputButton.Y then
        current:signal_emit(button)
    elseif button == rt.InputButton.UP or button == rt.InputButton.RIGHT or button == rt.InputButton.DOWN or button == rt.InputButton.LEFT then
        local next = current:signal_emit(button)
        if next ~= nil then
            if not meta.isa(next, rt.SelectionGraphNode) then
                rt.error("In rt.SelectionGraph:handle_button: node #" .. meta.hash(current) .. " returns object of type `" .. meta.typeof(next) .. "` on `" .. button .. "` instead of rt.SelectionGraphNode")
                return
            end
            current:signal_emit("exit")
            self._current_node = next
            next:signal_emit("enter")
        end
    end
end

--- @brief
function rt.SelectionGraph:add(...)
    for node in range(...) do
        meta.assert_isa(node, rt.SelectionGraphNode)
        if self._nodes[node] == nil then
            self._nodes[node] = true
            if self._n_nodes == 0 then
                self._current_node = node
            end
            self._n_nodes = self._n_nodes + 1
        end
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

    if self._current_node ~= nil then
        self._current_node:signal_emit("exit")
    end

    self._current_node = node

    if self._current_node ~= nil then
        self._current_node:signal_emit("enter")
    end
end

--- @brief
function rt.SelectionGraph:get_current_node()
    return self._current_node
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
function rt.SelectionGraph:draw()
    for node in keys(self._nodes) do
        node:draw(rt.Palette.GRAY_4)
    end

    if self._current_node ~= nil then
        self._current_node:draw(rt.Palette.SELECTION)
    end
end

--- @brief
function rt.SelectionGraph:clear()
    for node in keys(self._nodes) do
        node:signal_emit("exit")
    end
    self._nodes = {}
    self._current_node = nil
end