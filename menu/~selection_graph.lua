--- @class rt.SelectionGraph
rt.SelectionGraph = meta.new_type("SelectionGraph", function()
    return meta.new(rt.SelectionGraph, {
        _nodes = {}, -- Set<rt.SelectionGraphNode>
        _current_node = nil,
        _n_nodes = 0
    })
end)

--- @class rt.SelectionGraphNode
rt.SelectionGraphNode = meta.new_type("SelectionGraphNode", rt.Drawable, function(aabb)
    local out = meta.new(rt.SelectionGraphNode, {
        _aabb = rt.AABB(0, 0, 1, 1),
        _centroid_x = 0,
        _centroid_y = 0,
        _on_enter = function(direction)  end,
        _on_exit = function(direction)  end,
        _on_activate = function()  end,
        _on_up = nil,     -- () -> rt.SelectionGraphNode
        _on_right = nil,  -- () -> rt.SelectionGraphNode
        _on_down = nil,   -- () -> rt.SelectionGraphNode
        _on_left = nil,   -- () -> rt.SelectionGraphNode
    })

    if aabb ~= nil then
        out._aabb = aabb
        out._centroid_x = aabb.x + 0.5 * aabb.width
        out._centroid_y = aabb.y + 0.5 * aabb.height
    end

    return out
end)

function rt.SelectionGraphNode:set_aabb(aabb_or_x, y, w, h)
    if meta.is_aabb(aabb_or_x) then
        self._aabb = aabb_or_x
    else
        self._aabb = rt.AABB(aabb_or_x, y, w, h)
    end

    self._centroid_x = self._aabb.x + 0.5 * self._aabb.width
    self._centroid_y = self._aabb.y + 0.5 * self._aabb.height
end

function rt.SelectionGraphNode:get_aabb()
    return self._aabb
end

for name_directions in range(
    {"up", rt.Direction.UP, rt.Direction.DOWN},
    {"right", rt.Direction.RIGHT, rt.Direction.LEFT},
    {"down", rt.Direction.DOWN, rt.Direction.UP},
    {"left", rt.Direction.LEFT, rt.Direction.RIGHT})
do
    local which = name_directions[1]
    local direction = name_directions[2]
    local opposite_direction = name_directions[3]

    local on_which = "_on_" .. which
    rt.SelectionGraphNode["set_" .. which] = function(self, other_or_f)
        if other_or_f == nil then
            self[on_which] = nil
        elseif meta.is_function(other_or_f) then
            self[on_which] = other_or_f
        else
            meta.assert_isa(other_or_f, rt.SelectionGraphNode)
            self[on_which] = function()
                return other_or_f
            end
        end
    end

    rt.SelectionGraphNode["get_" .. which] = function(self)
        if self[on_which] ~= nil then
            return self[on_which]()
        else
            return nil
        end
    end

    rt.SelectionGraph["move_" .. which] = function(self)
        local current = self._current_node
        if current ~= nil then
            local next = current["get_" .. which](current)
            if next ~= nil then
                meta.assert_isa(next, rt.SelectionGraphNode)

                if self._current_node._on_exit ~= nil then
                    self._current_node._on_exit(direction)
                end

                self._current_node = next

                if self._current_node._on_enter ~= nil then
                    self._current_node._on_enter(opposite_direction)
                end
                return true
            end
        end
        return false
    end
end


for which in range("on_activate", "on_enter", "on_exit") do
    rt.SelectionGraphNode["set_" .. which] = function(self, f)
        if f ~= nil then
            meta.assert_function(f)
        end
        self["_" .. which] = f
    end
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
        local next = self["get_" .. direction](self)
        if next ~= nil then
            love.graphics.setColor(rt.color_unpack(color))
            local to_x, to_y = next._centroid_x, next._centroid_y
            love.graphics.line(from_x, from_y, to_x, to_y)
        end
    end
end

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

function rt.SelectionGraph:remove(node)
    if self._nodes[node] ~= nil then
        self._nodes[node] = nil
        self._n_nodes = self._n_nodes - 1
    end
end

function rt.SelectionGraph:set_current_node(node)
    self:add(node)

    if self._current_node ~= nil and self._current_node._on_exit ~= nil then
        self._current_node._on_exit(nil)
    end

    self._current_node = node

    if self._current_node ~= nil and self._current_node._on_enter ~= nil then
        self._current_node._on_enter(nil)
    end
end

function rt.SelectionGraph:get_current_node_aabb()
    if self._current_node ~= nil then
        return self._current_node._aabb
    else
        return rt.AABB(0, 0, 1, 1)
    end
end

function rt.SelectionGraph:draw()
    for node in keys(self._nodes) do
        node:draw(rt.Palette.GRAY_4)
    end

    if self._current_node ~= nil then
        self._current_node:draw(rt.Palette.SELECTION)
    end
end

function rt.SelectionGraph:activate()
    if self._current_node ~= nil then
        if self._current_node._on_activate ~= nil then
            self._current_node._on_activate()
        end
    end
end

function rt.SelectionGraph:clear()
    for node in keys(self._nodes) do
        if node._on_exit ~= nil then
            node._on_exit(nil)
        end
    end
    self._nodes = {}
    self._current_node = nil
end