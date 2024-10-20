--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _state = state,
        _simulation_environment = nil,

        _log = rt.TextBox(),
        _priority_queue = bt.PriorityQueue(),
        _verbose_info = mn.VerboseInfoPanel(),
        _sprites = {},        -- Table<bt.Entity, Union<bt.PartySprite, bt.EnemySprite>>
        _party_sprites = meta.make_weak({}), -- Table<bt.PartySprite>
        _enemy_sprites = meta.make_weak({}), -- Table<bt.EnemySprite>
        _enemy_sprite_render_order = meta.make_weak({}),
        _enemy_sprite_x_offset = 0,

        _global_status_bar = bt.OrderedBox(),

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
    })
end)

--- @override
function bt.BattleScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._log:realize()
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

    self:add_entity(table.unpack(self._state:list_entities()))

    self._simulation_environment = self:create_simulation_environment()
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

    self._priority_queue:fit_into(current_x, current_y, tile_size, height - 2 * outer_margin)
    self._global_status_bar:fit_into(
        x + width - outer_margin - tile_size, current_y,
        tile_size, height - 2 * outer_margin
    )

    local party_sprites_w = (width - 2 * outer_margin - 2 * tile_size - 2 * m)
    local log_w = party_sprites_w - 2 * tile_size
    self._log:fit_into(x + 0.5 * width - 0.5 * log_w, current_y, log_w, tile_size)

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

    self:_reformat_party_sprites(
        x + outer_margin + tile_size + m,
        y + height - outer_margin,
        party_sprites_w,
        tile_size
    )

    local max_party_sprite_h = NEGATIVE_INFINITY
    for sprite in values(self._party_sprites) do
        max_party_sprite_h = math.max(max_party_sprite_h, select(2, sprite:measure()))
    end

    self:_reformat_enemy_sprites(
        x + outer_margin + tile_size + m,
        y + outer_margin + tile_size + m,
        width - 2 * outer_margin - 2 * tile_size - 2 * m,
        height - 2 * outer_margin - tile_size - max_party_sprite_h - 2 * m
    )
end

--- @brief
function bt.BattleScene:_reformat_enemy_sprites(x, y, width, height)
    local n_enemies = sizeof(self._enemy_sprites)
    if n_enemies < 1 then return end

    local total_w, max_h, max_sprite_only_h = 0, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for sprite in values(self._enemy_sprites) do
        local sprite_w, sprite_h = sprite:measure()
        total_w = total_w + sprite_w
        max_h = math.max(max_h, sprite_h)
        max_sprite_only_h = math.max(max_sprite_only_h, select(2, sprite._sprite:measure()))
    end

    local m = rt.settings.margin_unit
    m = math.min(m, (width - total_w) / (n_enemies - 1))
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height + (max_h - max_sprite_only_h) + m

    self._enemy_sprite_render_order = {}
    local left_x, right_x
    do
        local center_sprite = self._enemy_sprites[1]
        local sprite_w, sprite_h = center_sprite:measure()
        center_sprite:fit_into(
            center_x - 0.5 * sprite_w,
            center_y - sprite_h,
            sprite_w, sprite_h
        )

        left_x = center_x - 0.5 * sprite_w - m
        right_x = center_x + 0.5 * sprite_w + m
        table.insert(self._enemy_sprite_render_order, center_sprite)
    end

    local min_x, max_x = POSITIVE_INFINITY, NEGATIVE_INFINITY

    local sprite_i = 2
    while sprite_i <= n_enemies do
        local sprite = self._enemy_sprites[sprite_i]
        local sprite_w, sprite_h = sprite:measure()
        if sprite_i % 2 == 0 then
            sprite:fit_into(right_x, center_y - sprite_h, sprite_w, sprite_h)
            max_x = right_x + sprite_w
            right_x = right_x + sprite_w + m
        else
            sprite:fit_into(left_x - sprite_w, center_y - sprite_h, sprite_w, sprite_h)
            min_x = left_x - sprite_w
            left_x = left_x - sprite_w - m
        end

        table.insert(self._enemy_sprite_render_order, sprite)
        sprite_i = sprite_i + 1
    end

    self._enemy_sprite_x_offset = ((x - min_x) + (x + width - max_x)) / 2
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

        node:signal_connect(rt.InputButton.DOWN, function(_)
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
        sprite:draw()
    end
    love.graphics.translate(-self._enemy_sprite_x_offset, 0)

    for x in range(
        self._log,
        self._priority_queue,
        self._verbose_info,
        self._global_status_bar
    ) do
        x:draw_bounds()
        x:draw()
    end

    if self._selecting_entity ~= nil then
        local entry = self._move_selection[self._selecting_entity]
        entry.intrinsics:draw()
        entry.moves:draw()
    end

    love.graphics.line(0.5 * love.graphics.getWidth(), 0, 0.5 * love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.line(0, 0.5 * love.graphics.getHeight(), love.graphics.getWidth(), 0.5 * love.graphics.getHeight())
end

--- @override
function bt.BattleScene:update(delta)
    self._log:update(delta)
    self._global_status_bar:update(delta)
    for sprite in values(self._sprites) do
        sprite:update(delta)
    end
    self._priority_queue:update(delta)
end

--- @override
function bt.BattleScene:make_active()
    self._input:signal_unblock_all()
end

--- @override
function bt.BattleScene:make_inactive()
    self._input:signal_block_all()
end

--- @brief [internal]
function bt.BattleScene:_handle_button_pressed(which)
    if which == rt.InputButton.A then
        self:invoke(function()
            message("test")
        end)
    end
    --[[
    if self._selecting_entity ~= nil then
        local entry = self._move_selection[self._selecting_entity]
        entry.selection_graph:handle_button(which)
    else

    end
    ]]--
end