--- @class rt.SelectionNode
rt.SelectionNode = meta.new_type("SelectionNode", function(self, up, right, down, left)

    for widget in range(up, right, down, left) do
        if not meta.is_nil(widget) then

        end
    end

    local out = meta.new(rt.SelectionNode, {})
    out.self = self
    out.up = ternary(meta.is_nil(up), {}, up)
    out.right = ternary(meta.is_nil(right), {}, right)
    out.down = ternary(meta.is_nil(down), {}, down)
    out.left = ternary(meta.is_nil(left), {}, left)
    return out
end)

rt.SelectionNode.self = {}
rt.SelectionNode.up = {}
rt.SelectionNode.right = {}
rt.SelectionNode.down = {}
rt.SelectionNode.left = {}

--- @class rt.SelectionHandler
--- @signal selection_changed (self, previous_widget, next_widget) -> nil
rt.SelectionHandler = meta.new_type("SelectionHandler", function(child)

    local out = meta.new(rt.SelectionHandler, {
        _nodes = {},        -- meta.hash(self) -> rt.SelectionNode(self, ...)
        _current_node = {}, -- meta.hash
        _input = {},
        _child = child
    }, rt.SignalEmitter, rt.Drawable, rt.Widget)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(_, button, self)
        if button == rt.InputButton.UP then
            self:move(rt.Direction.UP)
        elseif button == rt.InputButton.RIGHT then
            self:move(rt.Direction.RIGHT)
        elseif button == rt.InputButton.DOWN then
            self:move(rt.Direction.DOWN) 
        elseif button == rt.InputButton.LEFT then
            self:move(rt.Direction.LEFT)
        end
    end, out)

    out:signal_add("selection_changed")
    return out
end)

--- @overload rt.Drawable.draw
function rt.SelectionHandler:draw()

    if not self:get_is_visible() then return end

    self._child:draw()

    local center = function(widget)
        local pos_x, pos_y = widget:get_position()
        local width, height = widget:get_size()
        return pos_x + 0.5 * width, pos_y + 0.5 * height
    end

    for _, node in pairs(self._nodes) do
        for to in range(node.top, node.right, node.bottom, node.left) do
            if not meta.is_nil(to.self) then
                local to_x, to_y = center(to.self)
                local from_x, from_y = center(node.self)
                love.graphics.line(to_x, to_y, from_x, from_y)
            end
        end
    end

    self._current_node.self:draw_selection_indicator()
end


--- @brief [internal]
function rt.SelectionHandler:_validate_node_map()


    local n_nodes = sizeof(self._nodes)
    local error_message, error_occurred = false
    for _, node in pairs(self._nodes) do
        if meta.isa(node.top, rt.SelectionNode) then
            if node.top.bottom ~= node or node.top == node then
                error_message = "non-symmetric node map"
                goto error
            end
        end

        if meta.isa(node.right, rt.SelectionNode) then
            if node.right.left ~= node or node.right == node then
                error_message = "non-symmetric node map"
                goto error
            end
        end

        if meta.isa(node.bottom, rt.SelectionNode) then
            if node.bottom.top ~= node or node.bottom == node then
                error_message = "non-symmetric node map"
                goto error
            end
        end

        if meta.isa(node.left, rt.SelectionNode) then
            if node.left.right ~= node or node.left == node then
                error_message = "non-symmetric node map"
                goto error
            end
        end

        if n_nodes > 1 and (not meta.isa(node.top)) and (not meta.isa(node.right)) and (not meta.isa(node.bottom)) and (not meta.isa(node.left)) then
            error_message = "unreachable node"
            goto error
        end
    end

    ::error::
    if error_occurred then
        rt.error("In SelectionHandler:_validate_node_map: " .. error_message)
    end
end

--- @overload rt.Widget.size_allocate
function rt.SelectionHandler:size_allocate(x, y, width, height)
    self._child:fit_into(rt.AABB(x, y, width, height))
end

--- @overload rt.Widget.measure
function rt.SelectionHandler:measure()
    return self._child:measure()
end

--- @brief
function rt.SelectionHandler:move(direction)



    if not meta.isa(self._current_node, rt.SelectionNode) then return end

    local current = self._current_node
    local next = {}
    if direction == rt.Direction.UP then
        next = current.up
    elseif direction == rt.Direction.RIGHT then
        next = current.right
    elseif direction == rt.Direction.DOWN then
        next = current.down
    elseif direction == rt.Direction.LEFT then
        next = current.left
    end

    if meta.isa(next, rt.SelectionNode) then
        current.self:set_is_selected(false)
        next.self:set_is_selected(true)
        self._current_node = next
        self:signal_emit("selection_changed", current.self, next.self)
    end
end

--- @overload rt.Widget.realize
function rt.SelectionHandler:realize()
    self._child:realize()
    rt.Widget.realize(self)

    for _, node in pairs(self._nodes) do
        node.self:set_is_selected(false)
    end
    self._current_node.self:set_is_selected(true)
end

--- @bief
function rt.SelectionHandler:connect(direction, from, to)




    if from == to then
        rt.error("In rt.SelectionHandler:connect: trying to connect `" .. meta.typeof(from) .. "` with itself, this would create an infinite loop")
        return
    end

    local from_node = self._nodes[meta.hash(from)]
    if meta.is_nil(from_node) then
        from_node = rt.SelectionNode(from)
        self._nodes[meta.hash(from)] = from_node
    end

    local to_node = self._nodes[meta.hash(to)]
    if meta.is_nil(to_node) then
        to_node = rt.SelectionNode(to)
        self._nodes[meta.hash(to)] = to_node
    end

    if direction == rt.Direction.UP then
        from_node.up = to_node
        to_node.down = from_node
    elseif direction == rt.Direction.RIGHT then
        from_node.right = to_node
        to_node.left = from_node
    elseif direction == rt.Direction.DOWN then
        from_node.down = to_node
        to_node.up = from_node
    elseif direction == rt.Direction.LEFT then
        from_node.left = to_node
        to_node.right = from_node
    end

    if not meta.isa(self._current_node, rt.SelectionNode) then
        self._current_node = from_node
    end

    self:_validate_node_map()
end

--- @brief
--- @return rt.Widget
function rt.SelectionHandler:get_selected()

    return self._current_node.self
end

--- @brief
--- @param rt.Widget
function rt.SelectionHandler:set_selected(widget)



    local next = self._nodes[meta.hash(widget)]
    if meta.is_nil(next) then
        rt.error("In SelectionHandler:set_selected: object `" .. meta.typeof(widget) .. "` is not registered with the selection handler")
        return
    end

    self._current_node:set_is_selected(false)
    next:set_is_selected(true)
    self._current_node = next
end