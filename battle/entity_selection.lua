bt.EntitySelection = meta.new_type("BattleEntitySelection", function(scene)
    return meta.new(bt.EntitySelection, {
        _scene = scene,
        _nodes = {}, -- cf. create_from
        _current_node = nil,
        _is_active = true
    })
end)

--- @brief reformat selection mapping
--- @param user bt.Entity
--- @param single_target Boolean
--- @param can_target_self Boolean
--- @param can_target_ally Boolean
--- @param can_target_enemy Boolean
function bt.EntitySelection:create_from(user, can_target_multiple, can_target_self, can_target_ally, can_target_enemy)
    if can_target_self == false and can_target_ally == false and can_target_enemy == false then
        self._nodes = {{
            entities = {},
            sprites = {},
            up = nil,
            right = nil,
            down = nil,
            left = nil
        }}
    elseif can_target_multiple == false then
        local self_sprite, ally_sprites, enemy_sprites = {}, {}, {}
        for entity in values(self._scene._state:list_entities()) do
            local sprite = self._scene._ui:get_sprite(entity)
            if entity:get_is_enemy() == user:get_is_enemy() then
                table.insert(ally_sprites, sprite)
            else
                table.insert(enemy_sprites, sprite)
            end

            if entity == user then
                self_sprite = sprite
            end
        end

        -- sort sprites left to right
        for which in range(ally_sprites, enemy_sprites) do
            table.sort(which, function(a, b)
                local bounds_a = a:get_bounds()
                local bounds_b = b:get_bounds()
                return bounds_a.x < bounds_b.x
            end)
        end

        local enemies = {}
        local allies = {}

        if can_target_enemy then
            for sprite in values(enemy_sprites) do
                table.insert(enemies, {
                    entities = {sprite:get_entity()},
                    sprites = {sprite},
                    up = nil,
                    right = nil,
                    down = nil,
                    left = nil
                })
            end
        end

        if can_target_ally then
            for sprite in values(ally_sprites) do
                if sprite:get_entity() ~= user or (sprite:get_entity() == user and can_target_self) then
                    table.insert(allies, {
                        entities = {sprite:get_entity()},
                        sprites = {sprite},
                        up = nil,
                        right = nil,
                        down = nil,
                        left = nil
                    })
                end
            end
        end

        for i = 1, #enemies do
            local current = enemies[i]
            current.right = enemies[i + 1]
            current.left = enemies[i - 1]
            current.up = nil
            if #allies > 0 then
                current.down = allies[clamp(i, 1, #allies)]
            end
        end

        for i = 1, #allies do
            local current = allies[i]
            current.right = allies[i + 1]
            current.left = allies[i - 1]
            current.down = nil
            if #enemies > 0 then
                current.up = enemies[clamp(i, 1, #enemies)]
            end
        end

        self._nodes = {}
        for array in range(allies, enemies) do
            for node in values(array) do
                table.insert(self._nodes, node)
            end
        end
    else -- can_target_multiple == true
        local all_node = {
            entities = {},
            sprites = {},
            up = nil,
            right = nil,
            down = nil,
            left = nil
        }

        local enemy_node = {
            entities = {},
            sprites = {},
            up = nil,
            right = nil,
            down = nil,
            left = nil
        }

        local ally_node = {
            entities = {},
            sprites = {},
            up = nil,
            right = nil,
            down = nil,
            left = nil
        }

        for entity in values(self._scene._state:list_entities()) do
            local sprite = self._scene._ui:get_sprite(entity)
            if entity == user and can_target_self then
                table.insert(ally_node.entities, entity)
                table.insert(ally_node.sprites, sprite)

                table.insert(all_node.entities, entity)
                table.insert(all_node.sprites, sprite)
            elseif entity:get_is_enemy() == user:get_is_enemy() and can_target_ally then
                table.insert(ally_node.entities, entity)
                table.insert(ally_node.sprites, sprite)

                table.insert(all_node.entities, entity)
                table.insert(all_node.sprites, sprite)
            elseif entity:get_is_enemy() ~= user:get_is_enemy() then
                table.insert(enemy_node.entities, entity)
                table.insert(enemy_node.sprites, sprite)

                table.insert(all_node.entities, entity)
                table.insert(all_node.sprites, sprite)
            end
        end

        self._nodes = {}
        if can_target_enemy == true and can_target_ally == true then
            self._nodes = {all_node}
        elseif can_target_enemy == false and (can_target_ally == true or can_target_self == true) then
            self._nodes = {ally_node}
        elseif can_target_enemy == true and can_target_ally == false then
            self._nodes = {enemy_node}
        end
    end

    for node in values(self._nodes) do
        local min_x, min_y, max_x, max_y = POSITIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
        for sprite in values(node.sprites) do
            local bounds = sprite:get_bounds()
            min_x = math.min(min_x, bounds.x)
            min_y = math.min(min_y, bounds.y)
            max_x = math.max(max_x, bounds.x + bounds.width)
            max_y = math.max(max_y, bounds.y + bounds.height)
        end
        node.aabb = rt.AABB(min_x, min_x, max_x - min_x, max_y - min_y)
        node.centroid_x = min_x + 0.5 * (max_x - min_x)
        node.centroid_y = min_y + 0.5 * (max_y - min_y)
    end

    self._current_node = self._nodes[1]
    if self._is_active then
        self:_update_selections()
    end
end

--- @brief [internal]
function bt.EntitySelection:draw()
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

    --[[
    love.graphics.setLineWidth(1)
    for node, neighbors in pairs(self._mapping) do
        local from_x, from_y = node.centroid_x, node.centroid_y
        love.graphics.setColor(rt.color_unpack(rt.Palette.BLACK))
        love.graphics.circle("fill", from_x, from_y, 7)
        love.graphics.setColor(rt.color_unpack(rt.Palette.WHITE))
        love.graphics.circle("fill", from_x, from_y, 6)
        for direction in range(
            bt.EntitySelection.Direction.UP,
            bt.EntitySelection.Direction.RIGHT,
            bt.EntitySelection.Direction.DOWN,
            bt.EntitySelection.Direction.LEFT
        ) do
            if neighbors[direction] ~= nil then
                local to_x, to_y = neighbors[direction].centroid_x, neighbors[direction].centroid_y
                love.graphics.line(from_x, from_y, to_x, to_y)
            end
        end
    end
    ]]--
end

--- @brief
function bt.EntitySelection:_update_selections()
    if not self._is_active or self._current_node == nil then
        self._scene:set_selected({}, false)
    else
        self._scene:set_selected(self._current_node.entities, true)
    end
end

--- @brief
function bt.EntitySelection:set_is_active(b)
    if self._is_active == b then return end
    self._is_active = b
    self:_update_selections()
end

--- @brief
function bt.EntitySelection:get_is_active()
    return self._is_active
end

--- @brief
function bt.EntitySelection:get_selected()
    return self._current_node.entities
end

--- @brief defines move_*
--- @return Boolean
for which in range("up", "right", "down", "left") do
    bt.EntitySelection["move_" .. which] = function(self)
        if self._current_node == nil then return false end
        local next = self._current_node[which]
        if next == nil then return false end
        self._current_node = next
        self:_update_selections()
        return true
    end
end