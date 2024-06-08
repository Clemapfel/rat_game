rt.settings.battle.scene.inspect = {
    show_hide_button = rt.InputButton.X,
}


--- @class bt.SceneState.INSPECT
bt.SceneState.INSPECT = meta.new_type("INSPECT", function(scene)
    local out = meta.new(bt.SceneState.INSPECT, {
        _scene = scene,

        _nodes = {},
        _current_node = nil,
        _priority_order = {},

        _verbose_info = bt.VerboseInfo(),
        _verbose_info_offset_x = 0,
        _verbose_info_offset_y = 0,

        _control_indicator = {},
        _background_only = false
    })

    return out
end)

--- @brief [internal]
function bt.SceneState.INSPECT:_create()
    local scene = self._scene
    self._priority_order = scene._state:list_entities_in_order()

    while not scene._animation_queue:get_is_empty() do
        scene._animation_queue:skip()
    end

    local current_sprite
    if self._current_node ~= nil then
        current_sprite = self._current_node.sprite
    end

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
        local entity = nil
        local priority_position = nil
        if sprite.get_entity ~= nil then
            entity = sprite:get_entity()
        end

        local out = {
            is_global_status_node = entity == nil,
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

        out.update = function(self)
            local bounds = self.sprite:get_bounds()
            local triangle_h = rt.settings.margin_unit
            local triangle_w = rt.settings.margin_unit * 2
            local y_offset = rt.settings.selection_indicator.thickness + 1
            local x_offset = rt.settings.selection_indicator.thickness + 1

            for which in range("up_indicator", "up_indicator_outline") do
                self[which] = rt.Triangle(
                    bounds.x + 0.5 * bounds.width - triangle_w * 0.5, bounds.y - y_offset,
                    bounds.x + 0.5 * bounds.width + triangle_w * 0.5, bounds.y - y_offset,
                    bounds.x + 0.5 * bounds.width, bounds.y - triangle_h - y_offset
                )
            end

            for which in range("right_indicator", "right_indicator_outline") do
                self[which] = rt.Triangle(
                    bounds.x + bounds.width + x_offset, bounds.y + 0.5 * bounds.height - 0.5 * triangle_w,
                    bounds.x + bounds.width + x_offset, bounds.y + 0.5 * bounds.height + 0.5 * triangle_w,
                    bounds.x + bounds.width + triangle_h + x_offset, bounds.y + 0.5 * bounds.height
                )
            end

            for which in range("down_indicator", "down_indicator_outline") do
                self[which] = rt.Triangle(
                    bounds.x + 0.5 * bounds.width - triangle_w * 0.5, bounds.y + bounds.height + y_offset,
                    bounds.x + 0.5 * bounds.width + triangle_w * 0.5, bounds.y + bounds.height + y_offset,
                    bounds.x + 0.5 * bounds.width, bounds.y + bounds.height + triangle_h + y_offset
                )
            end

            for which in range("left_indicator", "left_indicator_outline") do
                self[which] = rt.Triangle(
                    bounds.x - x_offset, bounds.y + bounds.height * 0.5 - triangle_w * 0.5,
                    bounds.x - x_offset, bounds.y + bounds.height * 0.5 + triangle_w * 0.5,
                    bounds.x - triangle_h - x_offset, bounds.y + bounds.height * 0.5
                )
            end

            for which in range("up", "right", "down", "left") do
                local outline = self[which .. "_indicator_outline"]
                outline:set_is_outline(true)
                outline:set_line_width(2)
                outline:set_color(rt.Palette.BACKGROUND_OUTLINE)

                local fill = self[which .. "_indicator"]
                fill:set_color(rt.Palette.SELECTION)
            end
        end
        out:update()
        return out
    end

    local enemy_nodes = {}
    for i = 1, n_enemies do
        table.insert(enemy_nodes, new_node(enemy_sprites[i]))
    end

    local ally_nodes = {}
    for i = 1, n_allies do
        table.insert(ally_nodes, new_node(ally_sprites[i]))
    end

    for i = 1, n_enemies do
        local node = enemy_nodes[i]
        node.left = enemy_nodes[i - 1]
        node.right = enemy_nodes[i + 1]
    end

    for i = 1, n_allies do
        local node = ally_nodes[i]
        node.left = ally_nodes[i - 1]
        node.right = ally_nodes[i + 1]
    end

    for i = 1, n_enemies do
        local node = enemy_nodes[i]
        local other = ally_nodes[clamp(i, 1, n_allies)]

        local closest_node = other
        local min_distance = POSITIVE_INFINITY
        for ally_node in values(ally_nodes) do
            local distance = math.abs(ally_node.centroid_x - node.centroid_x)
            if distance < min_distance then
                closest_node = ally_node
                min_distance = distance
            end
        end

        node.down = closest_node
        closest_node.up = node
    end

    for i = 1, n_allies do
        local node = ally_nodes[i]
        local other = enemy_nodes[clamp(i, 1, n_enemies)]

        local closest_node = other
        local min_distance = POSITIVE_INFINITY
        for enemy_node in values(enemy_nodes) do
            local distance = math.abs(enemy_node.centroid_x - node.centroid_x)
            if distance < min_distance then
                closest_node = enemy_node
                min_distance = distance
            end
        end

        node.up = closest_node
        closest_node.down = node
    end


    local global_status_node
    if sizeof(scene._state:list_global_statuses()) > 0 then
        global_status_node = new_node(self._scene._global_status_bar)
        global_status_node.right = ally_nodes[1]
        global_status_node.up = enemy_nodes[1]
        ally_nodes[1].left = global_status_node
        enemy_nodes[1].left = global_status_node
    end

    self._nodes = {global_status_node}
    self._current_node = ally_nodes[1]
    for nodes in range(enemy_nodes, ally_nodes) do
        for node in values(nodes) do
            self._nodes[node.entity] = node
            if node.sprite == current_sprite then
                self._current_node = node
            end
        end
    end

    self._control_indicator = rt.ControlIndicator()
    self._control_indicator:realize()
    self._control_indicator:fit_into(0, 0, POSITIVE_INFINITY, POSITIVE_INFINITY)

    self._verbose_info:realize()
    local m = rt.settings.margin_unit
    local bounds = self._scene._bounds
    self._verbose_info:fit_into(0, 0, bounds.height - 2 * m, bounds.width - 2 * m)
    self:_update_selection()
    self:_update_control_indicator()
end

--- @brief [internal]
function bt.SceneState.INSPECT:_update_selection()
    if self._current_node == nil then
        self._scene:set_selected({}, false)
        self._scene._global_status_bar:set_selection_state(bt.SelectionState.INACTIVE)
        self._verbose_info:show()
    else
        if self._current_node.is_global_status_node then
            self._scene:set_selected({}, false)
            self._scene._global_status_bar:set_selection_state(bt.SelectionState.SELECTED)
            local to_show = {}
            for status in values(self._scene._state:list_global_statuses()) do
                table.insert(to_show, {status, self._scene._state:get_global_status_n_turns_left(status)})
            end
            self._verbose_info:show(table.unpack(to_show))
            self._current_node:update()
        else
            local entity = self._current_node.entity
            self._scene:set_selected({entity}, false)
            self._scene._global_status_bar:set_selection_state(bt.SelectionState.INACTIVE)

            -- find all objects to show
            local to_show = {{entity}}
            for status in values(entity:list_statuses()) do
                table.insert(to_show, {status, entity:get_status_n_turns_left(status)})
            end

            for consumable in values(entity:list_consumables()) do
                table.insert(to_show, {consumable, entity:get_consumable_n_uses_left(consumable)})
            end

            self._verbose_info:show(table.unpack(to_show))
        end

        -- calculate new verbose info position
        local sprite_bounds = self._current_node.sprite:get_bounds()
        local scene_bounds = self._scene:get_bounds()

        local m = rt.settings.margin_unit
        scene_bounds.x = scene_bounds.x + 2 * m
        scene_bounds.y = scene_bounds.y + 2 * m
        scene_bounds.height = scene_bounds.height - 4 * m
        scene_bounds.width = scene_bounds.width - 4 * m

        local w, h = self._verbose_info:measure()
        if sprite_bounds.x + sprite_bounds.width + w + m < scene_bounds.x + scene_bounds.width then
            self._verbose_info_offset_x = sprite_bounds.x + sprite_bounds.width + m
        else
            self._verbose_info_offset_x = sprite_bounds.x - w - m
        end

        self._verbose_info_offset_y = sprite_bounds.y - 0.5 * h + 0.5 * sprite_bounds.height

        local control_indicator_h = select(2, self._control_indicator:measure())
        if self._verbose_info_offset_y < control_indicator_h then
            self._verbose_info_offset_y = control_indicator_h
        end

        if self._verbose_info_offset_y + h > scene_bounds.y + scene_bounds.height then
            self._verbose_info_offset_y = scene_bounds.y + scene_bounds.height - h
        end
    end
end

--- @brief [internal]
function bt.SceneState.INSPECT:_update_control_indicator()
    local prefix, postfix = "<o>", "</o>"

    if self._background_only == true then
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.X, prefix .. "Show" .. postfix},
        })
        self._control_indicator:set_opacity(0.5)
    else
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.B, prefix .. "Back" .. postfix},
            {rt.ControlIndicatorButton.ALL_DIRECTIONS, prefix .. "Select" .. postfix},
            {rt.ControlIndicatorButton.L, prefix .. "Previous" .. postfix},
            {rt.ControlIndicatorButton.R, prefix .. "Next" .. postfix},
            {rt.ControlIndicatorButton.Y, prefix .. "View Team TODO" .. postfix},
            {rt.ControlIndicatorButton.X, prefix .. "Hide" .. postfix},
        })
        self._control_indicator:set_opacity(1)
    end
end

--- @override
function bt.SceneState.INSPECT:handle_button_pressed(button)
    local scene = self._scene
    if button == rt.settings.battle.scene.inspect.show_hide_button then
        self._background_only = true
        self:_update_control_indicator()
        return
    elseif button == rt.InputButton.Y then
        self._scene:transition(bt.SceneState.SIMULATION)
    end

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
            if self._current_node.is_global_status_node then return end
            local next_entity
            local current_position = self._current_node.priority_position
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
    if button == rt.settings.battle.scene.inspect.show_hide_button then
        self._background_only = false
        self:_update_control_indicator()
        return
    end
end

--- @override
function bt.SceneState.INSPECT:enter()
    local scene = self._scene

    scene._global_status_bar:synchronize(scene._state)
    scene._global_status_bar:update(100)

    scene:set_priority_order(scene._state:list_entities_in_order())
    self:_create()
    self:_update_selection()
    self._verbose_info:realize()

    local m = rt.settings.margin_unit
    local bounds = self._scene:get_bounds()
end

--- @override
function bt.SceneState.INSPECT:exit()
    self._scene:set_selected({}, false)
    self._scene._global_status_bar:set_selection_state(bt.SelectionState.INACTIVE)
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
    if self._background_only then
        self._control_indicator:draw()
        return
    end

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

    rt.graphics.translate(self._verbose_info_offset_x, self._verbose_info_offset_y)
    self._verbose_info:draw()
    rt.graphics.translate(-self._verbose_info_offset_x, -self._verbose_info_offset_y)

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

    self._control_indicator:draw()

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