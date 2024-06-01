--- @class bt.SceneState.INSPECT
bt.SceneState.INSPECT = meta.new_type("INSPECT", function(scene)
    local out = meta.new(bt.SceneState.INSPECT, {
        _scene = scene,

        _nodes = {},
        _current_node = nil,
        _priority_order = {}
    })

    return out
end)

--- @brief [internal]
function bt.SceneState.INSPECT:_create()
    local scene = self._scene
    self._priority_order = scene._state:list_entities_in_order()

    local enemy_sprites = {}
    local n_enemies, n_allies = 0, 0
    for sprite in values(scene._enemy_sprites) do
        table.insert(enemy_sprites, sprite)
        n_enemies = n_enemies + 1
    end

    local ally_sprites = {}
    for sprite in values(scene._party_sprites) do
        table.insert(ally_sprites, sprite)
        n_allies = n_allies + 1
    end

    for which in range(ally_sprites, enemy_sprites) do
        table.sort(which, function(a, b)
            local bounds_a = a:get_bounds()
            local bounds_b = b:get_bounds()
            return bounds_a.x < bounds_b.x
        end)
    end

    local entities_in_order = {}
    do
        local i = 1
        for entity in values(self._priority_order) do
            if entities_in_order[entity] == nil then    -- only count first occurrence
                entities_in_order[entity] = i
            end
            i = i + 1
        end
    end

    local new_node = function(sprite)
        local bounds = sprite:get_bounds()
        local entity = sprite:get_entity()
        local out = {
            sprite = sprite,
            entity = entity,
            priority_position = entities_in_order[entity],
            bounds = rt.aabb_copy(bounds),
            info_position_x = bounds.x + bounds.width,
            info_position_y = bounds.y,
            centroid_x = bounds.x + 0.5 * bounds.width,
            centroid_y = bounds.y + 0.5 * bounds.height,
            up = nil,
            right = nil,
            down = nil,
            left = nil,
            up_indicator = {},
            up_indicator_outline = {},
            right_indicator = {},
            down_indicator = {},
            left_indicator = {}
        }

        local triangle_h = rt.settings.margin_unit
        local triangle_w = rt.settings.margin_unit * 2
        local y_offset = rt.settings.selection_indicator.thickness + 1
        local x_offset = rt.settings.selection_indicator.thickness + 1

        for which in range("up_indicator", "up_indicator_outline") do
            out[which] = rt.Triangle(
                bounds.x + 0.5 * bounds.width - triangle_w * 0.5, bounds.y - y_offset,
                bounds.x + 0.5 * bounds.width + triangle_w * 0.5, bounds.y - y_offset,
                bounds.x + 0.5 * bounds.width, bounds.y - triangle_h - y_offset
            )
        end

        for which in range("right_indicator", "right_indicator_outline") do
            out[which] = rt.Triangle(
                bounds.x + bounds.width + x_offset, bounds.y + 0.5 * bounds.height - 0.5 * triangle_w,
                bounds.x + bounds.width + x_offset, bounds.y + 0.5 * bounds.height + 0.5 * triangle_w,
                bounds.x + bounds.width + triangle_h + x_offset, bounds.y + 0.5 * bounds.height
            )
        end

        for which in range("down_indicator", "down_indicator_outline") do
            out[which] = rt.Triangle(
                bounds.x + 0.5 * bounds.width - triangle_w * 0.5, bounds.y + bounds.height + y_offset,
                bounds.x + 0.5 * bounds.width + triangle_w * 0.5, bounds.y + bounds.height + y_offset,
                bounds.x + 0.5 * bounds.width, bounds.y + bounds.height + triangle_h + y_offset
            )
        end

        for which in range("left_indicator", "left_indicator_outline") do
            out[which] = rt.Triangle(
                bounds.x - x_offset, bounds.y + bounds.height * 0.5 - triangle_w * 0.5,
                bounds.x - x_offset, bounds.y + bounds.height * 0.5 + triangle_w * 0.5,
                bounds.x - triangle_h - x_offset, bounds.y + bounds.height * 0.5
            )
        end


        for which in range("up", "right", "down", "left") do
            local outline = out[which .. "_indicator_outline"]
            outline:set_is_outline(true)
            outline:set_line_width(2)
            outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
            
            local fill = out[which .. "_indicator"]
            fill:set_color(rt.Palette.SELECTION)
        end

        return out
    end

    local enemy_nodes = {}
    for i = 1, n_enemies do
        table.insert(enemy_nodes, new_node(enemy_sprites[i]))
    end

    for i = 1, n_enemies do
        local node = enemy_nodes[i]
        node.left = enemy_nodes[i - 1]
        node.right = enemy_nodes[i + 1]
    end

    local ally_nodes = {}
    for i = 1, n_allies do
        table.insert(ally_nodes, new_node(ally_sprites[i]))
    end

    for i = 1, n_allies do
        local node = ally_nodes[i]
        node.left = ally_nodes[i - 1]
        node.right = ally_nodes[i + 1]
    end

    for i = 1, n_enemies do
        local node = enemy_nodes[i]
        node.down = ally_nodes[clamp(i, 1, n_allies)]
    end

    for i = 1, n_allies do
        local node = ally_nodes[i]
        node.up = enemy_nodes[clamp(i, 1, n_enemies)]
    end

    self._nodes = {}
    for nodes in range(enemy_nodes, ally_nodes) do
        for node in values(nodes) do
            self._nodes[node.entity] = node
        end
    end
    self._current_node = ally_nodes[1]
end

--- @brief [internal]
function bt.SceneState.INSPECT:_update_selection()
    if self._current_node ~= nil then
        self._scene:set_selected({self._current_node.entity}, false)
    else
        self._scene:set_selected({}, false)
    end
end

--- @override
function bt.SceneState.INSPECT:handle_button_pressed(button)
    local scene = self._scene

    if self._current_node ~= nil then
        -- move in spatial direction
        local move = function(direction)
            local next = self._current_node[direction]
            if next ~= nil then
                self._current_node = next
                self:_update_selection()
                return true
            end
            return false
        end

        -- move in priority queue order
        local jump = function(direction)
            local current_position = self._current_node.priority_position
            local next_entity

            if direction == "forward" then
                next_entity = self._priority_order[current_position + 1]
            elseif direction == "backward" then
                next_entity = self._priority_order[current_position - 1]
            else
                return false
            end

            if next_entity == nil then return false end
            local next_node = self._nodes[next_entity]
            self._current_node = next_node
            self:_update_selection()
        end

        if button == rt.InputButton.UP then
            move("up")
        elseif button == rt.InputButton.RIGHT then
            move("right")
        elseif button == rt.InputButton.DOWN then
            move("down")
        elseif button == rt.InputButton.LEFT then
            move("left")
        elseif button == rt.InputButton.L then
            jump("forward")
        elseif button == rt.InputButton.R then
            jump("backward")
        end
    end
end

--- @override
function bt.SceneState.INSPECT:handle_button_released(button)
    -- noop
end

--- @override
function bt.SceneState.INSPECT:enter()
    local scene = self._scene
    scene:set_priority_order(scene._state:list_entities_in_order())
    self:_create()
    self:_update_selection()
end

--- @override
function bt.SceneState.INSPECT:exit()
    self._current_node = nil -- unselects all
    self:_update_selection()
end

--- @override
function bt.SceneState.INSPECT:update(delta)
    local scene = self._scene
    for sprite in values(scene._party_sprites) do
        sprite:update(delta)
    end

    for sprite in values(scene._enemy_sprites) do
        sprite:update(delta)
    end

    scene._global_status_bar:update(delta)
    scene._priority_queue:update(delta)
end

--- @override
function bt.SceneState.INSPECT:draw()
    local scene = self._scene

    for i in values(scene._enemy_sprite_render_order) do
        scene._enemy_sprites[i]:draw()
    end

    for sprite in values(scene._party_sprites) do
        sprite:draw()
    end

    scene._global_status_bar:draw()
    scene._priority_queue:draw()

    for i in values(scene._enemy_sprite_render_order) do
        bt.BattleSprite.draw(scene._enemy_sprites[i])
    end

    if self._current_node ~= nil then
        local node = self._current_node
        if node.up ~= nil then
            node.up_indicator_outline:draw()
            node.up_indicator:draw()
        end

        if node.right ~= nil then
            node.right_indicator_outline:draw()
            node.right_indicator:draw()
        end

        if node.down ~= nil then
            node.down_indicator_outline:draw()
            node.down_indicator:draw()
        end

        if node.left ~= nil then
            node.left_indicator_outline:draw()
            node.left_indicator:draw()
        end
    end

    --[[ DEBUG draw selection graph
    for node in values(self._nodes) do
        local from_x, from_y = node.centroid_x, node.centroid_y
        love.graphics.setColor(rt.color_unpack(rt.Palette.BLACK))
        love.graphics.circle("fill", from_x, from_y, 7)
        if node == self._current_node then
            love.graphics.setColor(rt.color_unpack(rt.Palette.SELECTION))
        else
            love.graphics.setColor(rt.color_unpack(rt.Palette.WHITE))
        end
        love.graphics.circle("fill", from_x, from_y, 6)

        for direction in range(
            "up", "right", "down", "left"
        ) do
            if node[direction] ~= nil then
                if node == self._current_node or node[direction] == self._current_node then
                    love.graphics.setColor(rt.color_unpack(rt.Palette.SELECTION))
                else
                    love.graphics.setColor(rt.color_unpack(rt.Palette.WHITE))
                end
                local to_x, to_y = node[direction].centroid_x, node[direction].centroid_y
                love.graphics.line(from_x, from_y, to_x, to_y)
            end
        end
    end
    ]]--
end