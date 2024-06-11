--- @class bt.SceneState.ENTITY_SELECT
bt.SceneState.ENTITY_SELECT = meta.new_type("ENTITY_SELECT", function(scene)
    local out = meta.new(bt.SceneState.ENTITY_SELECT, {
        _scene = scene,

        _nodes = {},
        _current_node = nil,
        _unselected_entities = {},

        _control_indicator = {}
    })

    return out
end)

--- @brief [internal]
function bt.SceneState.ENTITY_SELECT:_create()
    local scene = self._scene

    -- TODO
    local user = self._scene._state:list_party()[1]
    local move = bt.Move("DEBUG_MOVE")
    -- TODO

    local can_target_multiple = move:get_can_target_multiple()
    local can_target_self = move:get_can_target_self()
    local can_target_ally, can_target_enemy
    local allies, enemies = {}, {}

    can_target_enemy = move:get_can_target_enemy()
    can_target_ally = move:get_can_target_ally()

    for entity in values(self._scene._state:list_party()) do
        table.insert(allies, entity)
    end

    for entity in values(self._scene._state:list_enemies()) do
        table.insert(enemies, entity)
    end

    for which in range(allies, enemies) do
        table.sort(which, function(a, b)
            local a_sprite = self._scene:get_sprite(a)
            local b_sprite = self._scene:get_sprite(b)
            local bounds_a = a_sprite:get_bounds()
            local bounds_b = b_sprite:get_bounds()
            return bounds_a.x < bounds_b.x
        end)
    end

    self._nodes = {}

    local new_node = function(entities)
        if meta.isa(entities, bt.Entity) then entities = {entities} end
        local sprites = {}
        for entity in values(entities) do
            table.insert(sprites, self._scene:get_sprite(entity))
        end

        local min_x, min_y, max_x, max_y = POSITIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
        for sprite in values(sprites) do
            local bounds = sprite:get_bounds()
            min_x = math.min(min_x, bounds.x)
            min_y = math.min(min_y, bounds.y)
            max_x = math.max(max_x, bounds.x + bounds.width)
            max_y = math.max(max_y, bounds.y + bounds.height)
        end

        local bounds = rt.AABB(min_x, min_y, max_x - min_x, max_y - min_y)

        local out = {
            entities = entities,
            sprites = sprites,
            bounds = bounds,
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

    local enemy_nodes, ally_nodes = {}, {}

    if can_target_enemy == false and can_target_self == false and can_target_ally == false then
        -- field
        self._nodes = {new_node({})}
        self._unselected_entities = scene._state:list_entities()
    elseif can_target_multiple == false then
        -- single target
        self._unselected_entities = {}

        for enemy in values(enemies) do
            if can_target_enemy == true then
                table.insert(enemy_nodes, new_node(enemy))
            else
                table.insert(self._unselected_entities, enemy)
            end
        end

        for entity in values(allies) do
            if entity ~= user then
                if can_target_ally then
                    table.insert(ally_nodes, new_node(entity))
                else
                    table.insert(self._unselected_entities, entity)
                end
            else
                if can_target_self then
                    table.insert(ally_nodes, new_node(entity))
                else
                    table.insert(self._unselected_entities, entity)
                end
            end
        end

        local n_enemies, n_allies = sizeof(enemy_nodes), sizeof(ally_nodes)

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

        if n_allies > 0 then
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
        end

        if n_enemies > 0 then
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
        end

        for nodes in range(enemy_nodes, ally_nodes) do
            for node in values(nodes) do
                table.insert(self._nodes, node)
            end
        end
    else
        -- multiple targets
        local separate_enemies_and_allies = false -- whether multiple selection means there is always exactly one node

        if separate_enemies_and_allies == false then
            local entities = {}
            for enemy in values(enemies) do
                if can_target_enemy == true then
                    table.insert(entities, new_node(enemy))
                else
                    table.insert(self._unselected_entities, enemy)
                end
            end

            for entity in values(allies) do
                if entity ~= user then
                    if can_target_ally then
                        table.insert(entities, new_node(entity))
                    else
                        table.insert(self._unselected_entities, entity)
                    end
                else
                    if can_target_self then
                        table.insert(entities, new_node(entity))
                    else
                        table.insert(self._unselected_entities, entity)
                    end
                end
            end

            self._nodes = {new_node(entities)}
        else
            local enemy_node_entities = {}
            for entity in values(enemies) do
                if can_target_enemy then
                    table.insert(enemy_node_entities, entity)
                else
                    table.insert(self._unselected_entities, entity)
                end
            end

            local party_node_entities = {}
            for entity in values(allies) do
                if entity ~= user then
                    if can_target_ally then
                        table.insert(party_node_entities, entity)
                    else
                        table.insert(self._unselected_entities, entity)
                    end
                else
                    if can_target_self then
                        table.insert(party_node_entities, entity)
                    else
                        table.insert(self._unselected_entities, entity)
                    end
                end
            end

            local enemy_node = nil
            if can_target_enemy then
                enemy_node = new_node(enemy_node_entities)
            end

            local ally_node = nil
            if can_target_self or can_target_ally then
                ally_node = new_node(party_node_entities)
            end


            if enemy_node ~= nil then
                enemy_node.down = ally_node
            end

            if ally_node ~= nil then
                ally_node.up = enemy_node
            end

            self._nodes = {}
            for node in range(enemy_node, ally_node) do
                table.insert(self._nodes, node)
            end
        end
    end

    self._current_node = self._nodes[1]
    self:_update_selection()
end

--- @brief [internal]
function bt.SceneState.ENTITY_SELECT:_update_selection()
    local scene = self._scene
    if self._current_node == nil then
        self._scene:set_selected({}, false)
    else
        local is_unselected = {}
        for entity in values(self._unselected_entities) do
            is_unselected[entity] = true
        end

        local is_selected = {}
        for entity in values(self._current_node.entities) do
            is_selected[entity] = true
        end

        for entity in values(scene._state:list_entities()) do
            local sprite = scene:get_sprite(entity)
            if is_selected[entity] == true then
                sprite:set_selection_state(bt.SelectionState.SELECTED)
                scene._priority_queue:set_selection_state(entity, bt.SelectionState.SELECTED)
            elseif is_unselected[entity] == true then
                sprite:set_selection_state(bt.SelectionState.UNSELECTED)
                scene._priority_queue:set_selection_state(entity, bt.SelectionState.UNSELECTED)
            else
                sprite:set_selection_state(bt.SelectionState.INACTIVE)
                scene._priority_queue:set_selection_state(entity, bt.SelectionState.UNSELECTED) -- sic, highligh prio queue differently
            end
        end
    end

    local node = self._current_node
    local prefix, postfix = "<o>", "</o>"
    if node.up ~= nil or node.right ~= nil or node.down ~= nil or node.left ~= nil then
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.ALL_DIRECTIONS, prefix .. "Select Target" .. postfix},
            {rt.ControlIndicatorButton.B, prefix .. "Back" .. postfix},
            {rt.ControlIndicatorButton.A, prefix .. "Accept" .. postfix},
        })
    else
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.B, prefix .. "Back" .. postfix},
            {rt.ControlIndicatorButton.A, prefix .. "Accept" .. postfix},
        })
    end
end

--- @override
function bt.SceneState.ENTITY_SELECT:handle_button_pressed(button)
    local scene = self._scene
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

    if button == rt.InputButton.UP then
        move("up")
    elseif button == rt.InputButton.RIGHT then
        move("right")
    elseif button == rt.InputButton.DOWN then
        move("down")
    elseif button == rt.InputButton.LEFT then
        move("left")
    elseif button == rt.InputButton.A then
        -- TODO: move on to next selection
    elseif button == rt.InputButton.B then
        scene:transition(bt.SceneState.MOVE_SELECT)
    end
end

--- @override
function bt.SceneState.ENTITY_SELECT:handle_button_released(button)
end

--- @override
function bt.SceneState.ENTITY_SELECT:enter()
    local scene = self._scene

    if not meta.isa(self._control_indicator, rt.ControlIndicator) then
        self._control_indicator = rt.ControlIndicator()
        self._control_indicator:realize()
    end

    scene:set_priority_order(scene._state:list_entities_in_order())
    self:_create()

    local bounds = scene:get_bounds()
    local m = rt.settings.margin_unit
    bounds.x = 2 * m
    bounds.y = 2 * m
    self._control_indicator:fit_into(bounds)
end

--- @override
function bt.SceneState.ENTITY_SELECT:exit()
    self._scene:set_selected({}, false)
end

--- @override
function bt.SceneState.ENTITY_SELECT:update(delta)
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
function bt.SceneState.ENTITY_SELECT:draw()
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

    self._control_indicator:draw()

    -- DEBUG draw selection graph
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
end