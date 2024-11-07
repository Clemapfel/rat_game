--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _state = state,
        _simulation_environment = nil,

        _text_box = rt.TextBox(),
        _priority_queue = bt.PriorityQueue(),
        _verbose_info = mn.VerboseInfoPanel(),
        _sprites = {},        -- Table<bt.Entity, Union<bt.PartySprite, bt.EnemySprite>>
        _party_sprites = meta.make_weak({}), -- Table<bt.PartySprite>
        _enemy_sprites = meta.make_weak({}), -- Table<bt.EnemySprite>
        _enemy_sprite_render_order = meta.make_weak({}),
        _enemy_sprite_x_offset = 0,

        _global_status_bar = bt.OrderedBox(),
        _global_status_to_sprite = {}, -- Table<bt.GlobalStatus, rt.Sprite>

        _move_selection = {}, -- Table<bt.Entity, { moves:rt.Slots, intrinsices:rt:Slots, selection_graph:rt.SelectionGraph }>
        _selecting_entity = nil,

        _party_order_priority = {
            ["MC"] = 0,
            ["WILDCARD"] = 2,
            ["RAT"] = 2,
            ["PROF"] = 3,
            ["GIRL"] = 4,
            ["SCOUT"] = 5
        },

        _animation_queue = rt.AnimationQueue(),
        _input = rt.InputController(),

        _entity_selection_graph = nil, -- rt.SelectionGraph
    })
end)

--- @override
function bt.BattleScene:realize()
    if self:already_realized() then return end

    self._text_box:realize()
    self._priority_queue:realize()

    self._verbose_info:set_frame_visible(false)
    self._verbose_info:realize()
    self._global_status_bar:realize()

    self:create_from_state()

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)
end

--- @override
function bt.BattleScene:create_from_state()
    self._sprites = {}
    self._enemy_sprites = {}
    self._party_sprites = {}
    self._move_selection = {}

    local entities = self._state:list_entities()
    self:add_entity(table.unpack(entities))

    for entity in values(entities) do
        local sprite = self._sprites[entity]
        if entity:get_is_enemy() then
            for status in values(self._state:entity_list_statuses(entity)) do
                local max = status:get_max_duration()
                local duration = self._state:entity_get_status_n_turns_elapsed(entity, status)
                sprite:add_status(status, max - duration)
            end

            for i = 1, entity:get_n_consumable_slots() do
                local consumable = self._state:entity_get_consumable(entity, i)
                if consumable ~= nil then
                    local max = consumable:get_max_n_uses()
                    local used = self._state:entity_get_consumable_n_used(entity, i)
                    sprite:add_consumable(i, consumable, max - used)
                end
            end
        end
    end

    self._simulation_environment = self:create_simulation_environment()
    self._priority_queue:reorder(self._state:list_entities_in_order())

    self:skip()
end

--- @override
function bt.BattleScene:add_entity(...)
    for entity in range(...) do
        if not entity:get_is_enemy() then
            local sprite = bt.PartySprite(entity)
            local move_layout = {
                {mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE},
                {mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE},
                {mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE},
                {mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE, mn.SlotType.MOVE}
            }

            local intrinsic_layout = {
                {mn.SlotType.INTRINSIC, mn.SlotType.INTRINSIC, mn.SlotType.INTRINSIC}
            }

            local move_slots = mn.Slots(move_layout)
            local intrinsic_slots = mn.Slots(intrinsic_layout)

            if self._is_realized then
                sprite:realize()
                move_slots:realize()
                intrinsic_slots:realize()
            end

            self._sprites[entity] = sprite
            sprite.entity = entity

            self._move_selection[entity] = {
                moves = move_slots,
                intrinsics = intrinsic_slots,
                selection_graph = rt.SelectionGraph()
            }

            table.insert(self._party_sprites, sprite)
            table.sort(self._party_sprites, function(a, b)
                local a_prio = self._party_order_priority[a.entity:get_id()]
                local b_prio = self._party_order_priority[b.entity:get_id()]

                if a_prio == nil then a_prio = POSITIVE_INFINITY end
                if b_prio == nil then b_prio = POSITIVE_INFINITY end
                return a_prio < b_prio
            end)
        else
            local sprite = bt.EnemySprite(entity)
            if self._is_realized then
                sprite:realize()
            end

            self._sprites[entity] = sprite
            table.insert(self._enemy_sprites, sprite)
        end
    end

    if self._is_realized then
        self:reformat()
    end
end

--- @brief
function bt.BattleScene:size_allocate(x, y, width, height)
    local tile_size = rt.settings.menu.inventory_scene.tile_size
    for entry in values(self._move_selection) do
        tile_size = math.max(tile_size, select(2, entry.intrinsics:measure()))
        break
    end

    local m = rt.settings.margin_unit
    local outer_margin = rt.settings.menu.inventory_scene.outer_margin

    local current_x = x + outer_margin
    local current_y = y + outer_margin

    self._global_status_bar:fit_into(
        x + width - outer_margin - tile_size, current_y,
        tile_size, height - 2 * outer_margin
    )

    local party_sprites_w = (width - 2 * outer_margin - 2 * tile_size - 2 * m)
    local log_w = party_sprites_w - 2 * tile_size
    self._text_box:fit_into(x + 0.5 * width - 0.5 * log_w, current_y, log_w, tile_size)

    current_x = current_x + tile_size + m

    local max_slot_w = NEGATIVE_INFINITY
    for entity, entry in pairs(self._move_selection) do
        local move_w, move_h = entry.moves:measure()
        local intrinsic_w, intrinsic_h = entry.intrinsics:measure()
        entry.intrinsics:fit_into(current_x, current_y, move_w, intrinsic_h)
        entry.moves:fit_into(current_x, current_y + intrinsic_h + m / 2, move_w, move_h)
        self:_update_slots(entity)

        max_slot_w = math.max(max_slot_w, move_w, intrinsic_w)
    end

    current_x = current_x + max_slot_w + m
    self._verbose_info:fit_into(current_x, current_y, max_slot_w, y + height - current_y - outer_margin)

    local sprite_w = 4 / 3 * height -- sprite is 4:3, like snes, but screen is 16:9

    local queue_w = (width - sprite_w) / 2 - 2 * outer_margin
    self._priority_queue:fit_into(x + outer_margin, current_y, queue_w, height - 2 * outer_margin)

    self:_reformat_party_sprites(
        x + 0.5 * width - 0.5 * sprite_w + outer_margin,
        y + height - outer_margin,
        sprite_w - 2 * outer_margin,
        tile_size
    )

    local max_enemy_sprite_h = NEGATIVE_INFINITY
    for sprite in values(self._enemy_sprites) do
        max_enemy_sprite_h = math.max(max_enemy_sprite_h, select(2, sprite:measure()))
    end

    self:_reformat_enemy_sprites(
        x + 0.5 * width - 0.5 * sprite_w,
        y + outer_margin + tile_size + m,
        sprite_w,
        0.5 * love.graphics.getHeight() + max_enemy_sprite_h
    )
end

--- @brief
function bt.BattleScene:_reformat_enemy_sprites(x, y, width, height)
    local n_enemies = sizeof(self._enemy_sprites)
    if n_enemies < 1 then return end

    local total_w, max_h, max_sprite_only_h = 0, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local average_h = 0
    for sprite in values(self._enemy_sprites) do
        local sprite_w, sprite_h = sprite:measure()
        total_w = total_w + sprite_w
        max_h = math.max(max_h, sprite_h)
        max_sprite_only_h = math.max(max_sprite_only_h, select(2, sprite._sprite:measure()))
        average_h = average_h + sprite_h
    end

    average_h = average_h / n_enemies

    local m = rt.settings.margin_unit
    m = math.min(m, (width - total_w) / (n_enemies - 1))
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height

    self._enemy_sprite_render_order = {}
    local sprite_i_to_aabb = {}
    local left_x, right_x
    do
        local center_sprite = self._enemy_sprites[1]
        local sprite_w, sprite_h = center_sprite:measure()
        sprite_i_to_aabb[1] = rt.AABB(
            center_x - 0.5 * sprite_w,
            center_y - sprite_h,
            sprite_w, sprite_h
        )

        left_x = center_x - 0.5 * sprite_w - m
        right_x = center_x + 0.5 * sprite_w + m
        table.insert(self._enemy_sprite_render_order, center_sprite)
    end

    local min_x, max_x = POSITIVE_INFINITY, NEGATIVE_INFINITY

    do -- delay fit_into to measure enemy_sprite_x_offset
        local sprite_i = 2
        while sprite_i <= n_enemies do
            local sprite = self._enemy_sprites[sprite_i]
            local sprite_w, sprite_h = sprite:measure()
            if sprite_i % 2 == 0 then
                sprite_i_to_aabb[sprite_i] = rt.AABB(right_x, center_y - sprite_h, sprite_w, sprite_h)
                max_x = right_x + sprite_w
                right_x = right_x + sprite_w + m
            else
                sprite_i_to_aabb[sprite_i] = rt.AABB(left_x - sprite_w, center_y - sprite_h, sprite_w, sprite_h)
                min_x = left_x - sprite_w
                left_x = left_x - sprite_w - m
            end

            table.insert(self._enemy_sprite_render_order, sprite)
            sprite_i = sprite_i + 1
        end
    end

    local enemy_sprite_x_offset = ((x - min_x) + (x + width - max_x)) / 2
    for sprite_i = 1, n_enemies do
        local aabb = sprite_i_to_aabb[sprite_i]
        local sprite = self._enemy_sprites[sprite_i]
        local old = sprite:get_bounds()
        local new = rt.AABB(
            (aabb.x + enemy_sprite_x_offset), aabb.y,
            aabb.width, aabb.height
        )
        if sprite._battle_scene_motion == nil then
            sprite._battle_scene_motion = rt.SmoothedMotion1D(0, 5)
            sprite._battle_scene_motion:set_target_value(0)
        else
            sprite._battle_scene_motion:set_value(old.x - new.x) -- warp so it stays at old position
        end
        sprite:fit_into(new)
    end
end

--- @brief
function bt.BattleScene:_reformat_party_sprites(x, bottom_y, width, height)
    local m = rt.settings.margin_unit
    local n_sprites = sizeof(self._party_sprites)
    local sprite_w = math.min(
    (width - 2 * m - (n_sprites - 1) * m) / n_sprites,
        (width - 2 * m - (3 - 1) * m) / 3
    )
    local sprite_m = m
    local sprite_x = x + (width - (sprite_w * n_sprites) - (m * (n_sprites - 1))) / 2
    local sprite_y = bottom_y - height
    local sprite_h = height

    for sprite in values(self._party_sprites) do
        sprite:fit_into(sprite_x, sprite_y, sprite_w, sprite_h)
        sprite_x = sprite_x + sprite_w + m
    end
end

--- @brief
function bt.BattleScene:_update_slots(entity)
    local entry = self._move_selection[entity]
    local moves = entry.moves
    local intrinsics = entry.intrinsics

    local infinity = "\u{221E}"

    local intrinsic_moves = self._state:entity_list_intrinsic_moves(entity)
    for i, move in ipairs(intrinsic_moves) do
        intrinsics:set_object(i, move, infinity)
    end

    local n_slots, move_slots = self._state:entity_list_move_slots(entity)
    for slot_i = 1, n_slots do
        local move = move_slots[slot_i]
        if move == nil then
            moves:set_object(slot_i, nil)
        else
            local n_used = self._state:entity_get_move_n_used(entity, slot_i)
            local n_left = move:get_max_n_uses() - n_used
            local n_left_label = tostring(n_left)
            if n_left == POSITIVE_INFINITY then
                n_left_label = infinity -- infinity
            end

            moves:set_object(slot_i, move, "<o>" .. n_left_label .. "</o>")
        end
    end

    local intrinsic_nodes = intrinsics:get_selection_nodes()
    local move_nodes = moves:get_selection_nodes()
    local both = {}

    local last_move_node = nil -- cursor memory
    for node_i, node in ipairs(intrinsic_nodes) do

        local closest_x, closest_node = POSITIVE_INFINITY, nil
        for other_i = 1, 4 do
            local other_node = move_nodes[other_i]
            local distance = math.abs(other_node:get_bounds().x - node:get_bounds().x)
            if distance < closest_x then
                closest_x = distance
                closest_node = other_node
            end
        end

        node:set_down(function(_)
            if last_move_node == nil then
                return closest_node
            else
                return last_move_node
            end
        end)

        node.slots = intrinsics
        node.slot_i = node_i
        node.entity = entity
        table.insert(both, node)
    end

    for node_i, node in ipairs(move_nodes) do
        local closest_x, closest_node = POSITIVE_INFINITY, nil
        for other_i = 1, #intrinsic_nodes do
            local other_node = intrinsic_nodes[other_i]
            local distance = math.abs(other_node:get_bounds().x - node:get_bounds().x)
            if distance < closest_x then
                closest_x = distance
                closest_node = other_node
            end
        end
        node:set_up(closest_node)

        node.slots = moves
        node.slot_i = node_i
        node.entity = entity
        table.insert(both, node)
    end

    local scene = self
    for node in values(intrinsic_nodes) do
        node:signal_connect("enter", function(self)
            self.slots:set_slot_selection_state(self.slot_i, rt.SelectionState.ACTIVE)
            scene._verbose_info:show(scene._state:entity_list_intrinsic_moves(self.entity)[self.slot_i])
        end)

        node:signal_connect("exit", function(self)
            self.slots:set_slot_selection_state(self.slot_i, rt.SelectionState.INACTIVE)
            scene._verbose_info:show(nil)
            last_move_node = nil
        end)
    end

    for node in values(move_nodes) do
        node:signal_connect("enter", function(self)
            self.slots:set_slot_selection_state(self.slot_i, rt.SelectionState.ACTIVE)
            scene._verbose_info:show(scene._state:entity_get_move(self.entity, self.slot_i))
        end)

        node:signal_connect("exit", function(self)
            self.slots:set_slot_selection_state(self.slot_i, rt.SelectionState.INACTIVE)
            scene._verbose_info:show(nil)
            last_move_node = self
        end)
    end

    local first = true
    for node in values(both) do
        entry.selection_graph.add(node)
        if first then
            entry.selection_graph:set_current_node(node)
            first = false
        end
    end

    self._verbose_info:show(nil)
end

--- @override
function bt.BattleScene:draw()
    for sprite in values(self._party_sprites) do
        sprite:draw()
    end

    love.graphics.translate(self._enemy_sprite_x_offset, 0)
    for sprite in values(self._enemy_sprite_render_order) do
        local offset = sprite._battle_scene_motion:get_value()
        love.graphics.translate(offset, 0)
        sprite:draw()
        love.graphics.translate(-offset, 0)
    end
    love.graphics.translate(-self._enemy_sprite_x_offset, 0)

    self._priority_queue:draw_bounds()

    if self._selecting_entity ~= nil then
        local entry = self._move_selection[self._selecting_entity]
        entry.intrinsics:draw()
        entry.moves:draw()
    end

    --love.graphics.line(0.5 * love.graphics.getWidth(), 0, 0.5 * love.graphics.getWidth(), love.graphics.getHeight())
    local w, h = love.graphics.getDimensions()
    love.graphics.line(0, 0.5 * h, w, 0.5 * h)

    local left_w = (w - (4 / 3) * h) / 2
    love.graphics.line(left_w, 0, left_w, h)
    love.graphics.line(w - left_w, 0, w - left_w, h)
    self._animation_queue:draw()

    for x in range(
        self._text_box,
        self._priority_queue,
        self._verbose_info,
        self._global_status_bar
    ) do
        x:draw()
    end
end

--- @override
function bt.BattleScene:update(delta)
    self._text_box:update(delta)
    self._global_status_bar:update(delta)

    local speed = 300
    for sprite in values(self._sprites) do
        sprite:update(delta)

        if sprite._battle_scene_motion ~= nil then
            sprite._battle_scene_motion:update(delta)
        end
    end

    self._priority_queue:update(delta)
    self._animation_queue:update(delta)
end

--- @override
function bt.BattleScene:make_active()
    self._input:signal_unblock_all()
end

--- @override
function bt.BattleScene:make_inactive()
    self._input:signal_block_all()
end

--- @brief
function bt.BattleScene:_push_animation(...)
    self._animation_queue:push(...)
end

--- @brief
function bt.BattleScene:_append_animation(...)
    self._animation_queue:append(...)
end

--- @brief
function bt.BattleScene:_set_selection(entities, state)
    for entity in values(entities) do
        local sprite = self._sprites[entity]
        sprite:set_selection_state(state)
    end

    -- todo: prio selection
end

--- @brief
function bt.BattleScene:set_priority_order(entities)
    self._priority_queue:reorder(entities)
end

do
    local _find_closest_node = function(self, others, n_others, scene_center_x)
        local closest_distance, closest_node = POSITIVE_INFINITY, nil
        local my_x, _ = self:get_centroid()

        local lower_i, upper_i, step = 1, n_others, 1
        if my_x >= scene_center_x then
            -- if sprite is right of center screen, search from right to left
            lower_i = n_others
            upper_i = 1
            step = -1
        end

        local last_distance = POSITIVE_INFINITY
        for i = lower_i, upper_i, step do
            local other = others[i]
            local other_x, _ = other:get_centroid()
            local distance = math.abs(my_x - other_x)
            if distance < closest_distance then
                closest_distance = distance
                closest_node = other
            end

            if distance > last_distance then
                -- if distance starts increasing, further nodes will
                -- never be closer since they are sorted by x coords
                break
            end
            last_distance = distance
        end

        return closest_node
    end

    --- @brief [internal]
    function bt.BattleScene:_generate_entity_selection_graph_from_move(user, move)
        meta.assert_isa(user, bt.Entity)

        local can_target_self = move:get_can_target_self()
        local can_target_multiple = move:get_can_target_multiple()
        local can_target_enemy = move:get_can_target_enemy()
        local can_target_ally = move:get_can_target_ally()

        local get_sprite_bounds = function(entity)
            local bounds = self._sprites[entity]:get_bounds()
            if entity:get_is_enemy() == true then
                bounds.x = bounds.x + self._enemy_sprite_x_offset
            end
            return bounds
        end

        local _scene = self

        local graph = rt.SelectionGraph()
        if can_target_multiple == false then
            local party_nodes, enemy_nodes = {}, {}
            local n_allies, n_enemies = 0, 0
            for entity in values(self._state:list_entities()) do
                if (entity == user and can_target_self) or
                    (user:get_is_enemy() == entity:get_is_enemy() and can_target_ally) or
                    (user:get_is_enemy() ~= entity:get_is_enemy() and can_target_enemy)
                then
                    local node = rt.SelectionGraphNode(get_sprite_bounds(entity))
                    node.entities = {entity}
                    graph:add(node)

                    if entity:get_is_enemy() then
                        table.insert(enemy_nodes, node)
                        n_enemies = n_enemies + 1
                    else
                        table.insert(party_nodes, node)
                        n_allies = n_allies + 1
                    end
                end
            end

            -- linking
            local _single_target_sort_f = function(node_a, node_b)
                local entity_a = node_a.entities[1]
                local entity_b = node_b.entities[1]
                return get_sprite_bounds(entity_a).x < get_sprite_bounds(entity_b).x
            end

            local scene_center_x = self._bounds.x + self._bounds.width * 0.5

            table.sort(party_nodes, _single_target_sort_f)
            table.sort(enemy_nodes, _single_target_sort_f)

            local n_diff = math.round(math.abs(n_enemies - n_allies) / 2)

            local _last_enemy, _last_ally = nil, nil -- cursor memory
            for node_i, node in ipairs(party_nodes) do
                node:set_left(function(self)
                    _last_enemy = nil
                    return party_nodes[node_i - 1]
                end)

                node:set_right(function(self)
                    _last_enemy = nil
                    return party_nodes[node_i + 1]
                end)

                local _closest = _find_closest_node(node, enemy_nodes, n_enemies, scene_center_x)
                node:set_up(function(self)
                    _last_ally = node
                    if _last_enemy ~= nil then
                        return _last_enemy
                    else
                        return _closest
                    end
                end)

                node:signal_connect("exit", function(self)
                    _scene:_set_selection(self.entities, rt.SelectionState.INACTIVE)
                end)

                node:signal_connect("enter", function(self)
                    _scene:_set_selection(self.entities, rt.SelectionState.ACTIVE)
                end)
            end

            for node_i, node in ipairs(enemy_nodes) do
                node:set_left(function(self)
                    _last_ally = nil
                    return enemy_nodes[node_i - 1]
                end)

                node:set_right(function(self)
                    _last_ally = nil
                    return enemy_nodes[node_i + 1]
                end)

                local _closest = _find_closest_node(node, party_nodes, n_allies, scene_center_x)
                node:set_down(function(self)
                    _last_enemy = node
                    if _last_ally ~= nil then
                        return _last_ally
                    else
                        return _closest
                    end
                end)

                node:signal_connect("exit", function(self)
                    _scene:_set_selection(self.entities, rt.SelectionState.INACTIVE)
                end)

                node:signal_connect("enter", function(self)
                    _scene:_set_selection(self.entities, rt.SelectionState.ACTIVE)
                end)
            end
        else
            local entities = {}
            local min_x, min_y, max_x, max_y = POSITIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
            for entity in values(self._state:list_entities()) do
                if (entity == user and can_target_self) or
                    (user:get_is_enemy() == entity:get_is_enemy() and can_target_ally) or
                    (user:get_is_enemy() ~= entity:get_is_enemy() and can_target_enemy)
                then
                    table.insert(entities, entity)
                    local bounds = get_sprite_bounds(entity)
                    min_x = math.min(min_x, bounds.x)
                    min_y = math.min(min_y, bounds.y)
                    max_x = math.max(max_x, bounds.x + bounds.width)
                    max_y = math.max(max_x, bounds.y + bounds.height)
                end
            end
            local node = rt.SelectionGraphNode()
            node.entities = entities
            node:set_bounds(min_x, min_y, max_x - min_x, max_y - min_y)
            graph:add(node)

            node:signal_connect("enter", function(self)
                _scene:_set_selection(self.entities, rt.SelectionState.ACTIVE)
            end)

            node:signal_connect("exit", function(self)
                _scene:_set_selection(self.entities, rt.SelectionState.INACTIVE)
            end)
        end

        return graph
    end

    --- @brief [internal]
    function bt.BattleScene:_generate_inspection_graph()

    end
end

--- @brief
function bt.BattleScene:get_text_box()
    return self._text_box
end

--- @brief
function bt.BattleScene:get_sprite(entity)
    return self._sprites[entity]
end

--- @brief
function bt.BattleScene:add_global_status(status, n_turns_left)
    meta.assert_isa(status, bt.GlobalStatus)
    meta.assert_number(n_turns_left)

    if self._global_status_to_sprite[status] ~= nil then
        self:set_global_status_n_turns_left(status, n_turns_left)
        return
    end

    local sprite = rt.Sprite(status:get_sprite_id())
    if n_turns_left ~= POSITIVE_INFINITY then
        sprite:set_bottom_right_child("<o>" .. n_turns_left .. "</o>")
    end
    sprite:set_minimum_size(sprite:get_resolution())

    self._global_status_to_sprite[status] = sprite
    self._global_status_bar:add(sprite, true)
end

--- @brief
function bt.BattleScene:remove_global_status(status)
    meta.assert_isa(status, bt.GlobalStatus)

    local sprite = self._global_status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt.BattleScene:remove_global_status: global status `" .. status:get_id() .. "` is not present")
        return
    end

    self._global_status_to_sprite[status] = nil
    self._global_status_bar:remove(sprite)
end

--- @brief
function bt.BattleScene:set_global_status_n_turns_left(status, n_turns_left)
    meta.assert_isa(status, bt.GlobalStatus)
    meta.assert_number(n_turns_left)

    local sprite = self._global_status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt.BattleScene:set_global_status_n_turns_left: global status `" .. status:get_id() .. "` is not present")
        return
    end

    if n_turns_left == POSITIVE_INFINITY then
        sprite:set_bottom_right_child("")
    else
        sprite:set_bottom_right_child("<o>" .. n_turns_left .. "</o>")
    end
end

--- @brief
function bt.BattleScene:activate_global_status(status, on_done_notify)
    meta.assert_isa(status, bt.Status)

    local sprite = self._global_status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt.BattleScene:activate_global_status: status `" .. status:get_id() .. "` is not present")
        return
    end

    self._global_status_bar:activate(sprite, on_done_notify)
end

--- @brief
function bt.BattleScene:skip()
    for sprite in values(self._enemy_sprites) do
        if sprite._battle_scene_motion ~= nil then
            sprite._battle_scene_motion:skip()
        end
    end

    for sprite in values(self._sprites) do
        sprite:skip()
    end

    self._priority_queue:skip()
    self._animation_queue:skip()
end

--- @brief [internal]
function bt.BattleScene:_handle_button_pressed(which)
    if which == rt.InputButton.A then
        self._simulation_environment.spawn(self._simulation_environment.ENTITY_BOULDER)
        --[[
        --self:_test_simulation()
        for sprite in values(self._enemy_sprites) do
            self:_append_animation(bt.Animation.ENEMY_APPEARED(self, sprite))
        end

        for sprite in values(self._party_sprites) do
            self:_append_animation(bt.Animation.ALLY_APPEARED(self, sprite))
        end
        --self:_push_animation(bt.Animation.STATUS_LOST(self, bt.Status("DEBUG_STATUS"), self._enemy_sprites[1]))
        --self:_push_animation(bt.Animation.GLOBAL_STATUS_GAINED(self, bt.GlobalStatus("DEBUG_GLOBAL_STATUS")))
        --self:_push_animation(bt.Animation.GLOBAL_STATUS_LOST(self, bt.GlobalStatus("DEBUG_GLOBAL_STATUS")))
        ]]--
    elseif which == rt.InputButton.B then
        self:skip()
    end
    --[[
    if which == rt.InputButton.A then
        self._entity_selection_graph = self:_generate_entity_selection_graph_from_move(self._state:list_allies()[1], bt.Move("DEBUG_MOVE"))
    end

    if self._entity_selection_graph ~= nil then
        self._entity_selection_graph:handle_button(which)
    end
    ]]
end