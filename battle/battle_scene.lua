rt.settings.battle.battle_scene = {
    enemy_sprite_speed = 500, -- px per second
    text_box_scroll_ticks_per_second = 6,
    text_box_scroll_delay = 0.1
}

bt.BattleSceneState = meta.new_enum("BattleSceneState", {
    INSPECT = "inspect",
    MOVE_SELECTION = "move_selection"
})

--- @class bt.MoveSelection
bt.MoveSelection = function(user, move, targets, _)
    meta.assert_isa(user, bt.Entity)
    meta.assert_isa(move, bt.MoveConfig)
    meta.assert_nil(_)

    local out = {
        user = user,
        move = move,
        targets = targets
    }

    for target in values(out.targets) do
        meta.assert_isa(target, bt.Entity)
    end

    return out
end

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    local out = meta.new(bt.BattleScene, {
        _state = state,
        _scene_state = nil,
        _env = nil,
        _ai = bt.EnemyAI(state),

        _background = rt.Background(),
        _verbose_info = mn.VerboseInfoPanel(state),
        _verbose_info_width = 0,

        _text_box = rt.TextBox(),
        _text_box_scroll_mode_active = false, -- show history during inspect
        _text_box_scroll_tick_elapsed = 0,
        _text_box_scroll_delay_elapsed = 0,
        _text_box_scroll_up_active = false,
        _text_box_scroll_down_active = false,

        _priority_queue = bt.PriorityQueue(),
        _quicksave_indicator = bt.QuicksaveIndicator(),

        _global_status_bar = bt.GlobalStatusBar(),
        _entity_id_to_sprite = {},

        _party_sprites = {}, -- Table<bt.PartySprite>
        _party_sprites_motion = {}, -- Table<bt.PartySprite, bt.SmoothedMotion2D>

        _enemy_sprites = {}, -- Table<bt.EnemySprites>
        _enemy_sprites_render_order = meta.make_weak({}),
        _enemy_sprites_motion = {}, -- Table<bt.EnemySprite, bt.SmoothedMotion1D>

        _input = rt.InputController(),
        _animation_queue = rt.AnimationQueue(),

        _game_over_screen = bt.GameOverScreen(),
        _game_over_screen_active = false,

        _is_first_size_allocate = true,
        
        -- inspect
        _inspect_selection_graph = nil, -- rt.SelectionGraph
        _inspect_selection_graph_default_node = nil, -- rt.SelectionGraphNode

        _inspect_selection_arrow_up = nil,
        _inspect_selection_arrow_up_outline = nil,
        _inspect_selection_arrow_up_visible = false,

        _inspect_selection_arrow_right = nil,
        _inspect_selection_arrow_right_outline = nil,
        _inspect_selection_arrow_right_visible = false,

        _inspect_selection_arrow_down = nil,
        _inspect_selection_arrow_down_outline = nil,
        _inspect_selection_arrow_down_visible = false,

        _inspect_selection_arrow_left = nil,
        _inspect_selection_arrow_left_outline = nil,
        _inspect_selection_arrow_left_visible = false,

        _inspect_selection_frame = rt.Frame(),
        _inspect_selection_frame_visible = false,
        _inspect_control_indicator = nil,

        -- move selection
        _move_selection_order = {}, -- Table<Entities>
        _move_selection_aabb = rt.AABB(0, 0, 1, 1),
        _entity_id_to_move_selection = {}, -- Table<EntityID, MoveSelection>
        _entity_id_to_slots = {}, -- Table<EntityID, {cf. _create_move_selection_slots}>
        _move_selection_control_indicator = nil,
        
        _move_selection_jump_right_arrow_visible = false,
        _move_selection_jump_right_arrow = nil,
        _move_selection_jump_right_arrow_outline = nil,
        
        _move_selection_jump_left_arrow_visible = false,
        _move_selection_jump_left_arrow = nil,
        _move_selection_jump_left_arrow_outline = nil,
    })
    return out
end)

--- @override
function bt.BattleScene:realize()
    if self:already_realized() then return end

    for widget in range(
        self._background,
        self._text_box,
        self._priority_queue,
        self._global_status_bar,
        self._quicksave_indicator,
        self._game_over_screen,
        self._verbose_info
    ) do
        widget:realize()
    end

    self._verbose_info:set_frame_visible(false)
    self._inspect_selection_frame:realize()
    self._inspect_selection_frame:set_selection_state(rt.SelectionState.ACTIVE)
    self._inspect_selection_frame:set_base_color(rt.RGBA(0, 0, 0, 0))
    self._inspect_selection_frame:set_corner_radius(32 / 4)

    self._inspect_control_indicator = rt.ControlIndicator({
        {rt.ControlIndicatorButton.ALL_DIRECTIONS, "Select"},
        {rt.ControlIndicatorButton.B, "Return"}
    })
    self._inspect_control_indicator:realize()

    for sprite in values(self._enemy_sprites) do
        sprite:realize()
    end

    for sprite in values(self._party_sprites) do
        sprite:realize()
    end

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

    self._input:signal_connect("released", function(_, which)
        self:_handle_button_released(which)
    end)

    self._move_selection_control_indicator = rt.ControlIndicator({
        {rt.ControlIndicatorButton.ALL_DIRECTIONS, rt.Translation.battle_scene.control_indicator_select_move},
        {rt.ControlIndicatorButton.A, rt.Translation.battle_scene.control_indicator_confirm_move},
        {rt.ControlIndicatorButton.L, rt.Translation.battle_scene.control_indicator_previous_entity},
        {rt.ControlIndicatorButton.R, rt.Translation.battle_scene.control_indicator_next_entity},
        {rt.ControlIndicatorButton.Y, rt.Translation.battle_scene.control_indicator_inspect}
    })
    self._move_selection_control_indicator:realize()
    self:create_from_state(self._state)
end

--- @brief
function bt.BattleScene:get_sprite(entity)
    meta.assert_isa(entity, bt.Entity)
    local out = self._entity_id_to_sprite[entity:get_id()]

    if out == nil then
        rt.error("In bt.BattleScene.get_sprite: no sprite for entity `" .. entity:get_id() .. "`")
    end
    return out
end

--- @override
function bt.BattleScene:create_from_state()
    self._animation_queue:clear()
    self._text_box:clear()
    self._global_status_bar:clear()
    self._quicksave_indicator:clear()

    self._enemy_sprites = {}
    self._party_sprites = {}
    self._entity_id_to_sprite = {}

    local entities = self._state:list_entities()
    self:add_entity(table.unpack(entities))

    for entity in values(entities) do
        local sprite = self:get_sprite(entity)
        assert(sprite ~= nil)
        for status in values(self._state:entity_list_statuses(entity)) do
            local max = status:get_max_duration()
            local duration = self._state:entity_get_status_n_turns_elapsed(entity, status)
            sprite:add_status(status, max - duration)
        end

        for i = 1, self._state:entity_get_n_consumable_slots(entity) do
            local consumable = self._state:entity_get_consumable(entity, i)
            if consumable ~= nil then
                local max = consumable:get_max_n_uses()
                local used = self._state:entity_get_consumable_n_used(entity, i)
                sprite:add_consumable(i, consumable, max - used)
            end
        end
    end

    self._env = self:create_simulation_environment()
    self._priority_queue:reorder(self._state:list_entities_in_order())
    self._quicksave_indicator:set_screenshot(self._state:get_quicksave_screenshot())

    -- create move selection widgets
    self._entity_id_to_slots = {}
    self._entity_id_to_move_selection = {}
    for entity in values(self._state:list_party()) do
        self:_create_move_selection_slots(entity)
    end
end

--- @brief
function bt.BattleScene:_reformat_move_selection_slots(entity)
    local element = self._entity_id_to_slots[entity:get_id()]
    if element == nil then
        rt.warning("In bt.BattleScene:_reformat_move_selection_slots: slots for entity `" .. entity:get_id() .. "` not yet initialized")
        return
    end
    local move_w, move_h = element.moves:measure()
    local intrinsic_w, intrinsic_h = element.intrinsics:measure()
    local w = math.max(move_w, intrinsic_w)
    element.moves:fit_into(
        self._move_selection_aabb.x,
        self._move_selection_aabb.y,
        w, move_h
    )
    element.intrinsics:fit_into(
        self._move_selection_aabb.x,
        self._move_selection_aabb.y + move_h + rt.settings.margin_unit,
        w, intrinsic_h
    )
end

--- @brief
function bt.BattleScene:_create_move_selection_slots(entity)
    local n_move_slots, move_slots = self._state:entity_list_move_slots(entity)
    local intrinsic_slots = self._state:entity_list_intrinsic_moves(entity)
    local n_intrinsic_slots = sizeof(intrinsic_slots)

    local move_widget, intrinsic_widget

    local move_slot_layout = {}
    table.insert(move_slot_layout, {})
    for i = 1, n_move_slots do
        table.insert(move_slot_layout[#move_slot_layout], mn.SlotType.MOVE)
        if i % 4 == 0 and i ~= n_move_slots then
            table.insert(move_slot_layout, {})
        end
    end
    move_widget = mn.Slots(move_slot_layout)

    local intrinsic_layout = {}
    for _ in values(intrinsic_slots) do
        table.insert(intrinsic_layout, mn.SlotType.INTRINSIC)
    end
    intrinsic_widget = mn.Slots({intrinsic_layout})

    for widget in range(move_widget, intrinsic_widget) do
        widget:realize()
    end

    local current = {
        moves = move_widget,
        last_n_move_slots = n_move_slots,
        intrinsics = intrinsic_widget,
        last_n_intrinsic_slots = n_intrinsic_slots,
        selection_graph = rt.SelectionGraph(),
        move_nodes = nil,
        intrinsic_nodes = nil
    }

    self._entity_id_to_slots[entity:get_id()] = current
    self:_reformat_move_selection_slots(entity)

    -- create selection graph
    local scene = self

    local move_nodes = current.moves:get_selection_nodes()
    for i = 1, sizeof(move_nodes) do
        local node = move_nodes[i]
        node.slot_i = i
        node.entity = entity
        node.slots = current.moves
        node.get_move = function(self)
            return scene._state:entity_get_move(self.entity, self.slot_i)
        end
    end

    local intrinsic_nodes = {}
    if n_intrinsic_slots > 0 then
        intrinsic_nodes = current.intrinsics:get_selection_nodes()

        for i = 1, sizeof(intrinsic_nodes) do
            local node = intrinsic_nodes[i]
            node.slot_i = i
            node.entity = entity
            node.slots = current.intrinsics
            node.get_move = function(self)
                return scene._state:entity_list_intrinsic_moves(self.entity)[self.slot_i]
            end
        end

        local bottom_nodes = {}
        do
            local max_y = NEGATIVE_INFINITY
            for node in values(move_nodes) do
                max_y = math.max(node:get_bounds().y, max_y)
            end
            for node in values(move_nodes) do
                if node:get_bounds().y == max_y then table.insert(bottom_nodes, node) end
            end
        end

        local _last_intrinsic_node = nil
        local _last_bottom_node = nil

        for self in values(bottom_nodes) do
            local self_x = self:get_bounds().x + 0.5 * self:get_bounds().width
            local min_distance, closest_node = POSITIVE_INFINITY, nil
            for other in values(intrinsic_nodes) do
                local other_bounds = other:get_bounds()
                local distance = math.abs(other_bounds.x + 0.5 * other_bounds.width - self_x)
                if distance < min_distance then
                    min_distance = distance
                    closest_node = other
                end
            end

            self:set_down(function(self)
                if _last_intrinsic_node == nil then
                    return closest_node
                else
                    return _last_intrinsic_node
                end
            end)

            self:signal_connect("leave_down", function(self)
                _last_bottom_node = self
            end)

            self:signal_connect("exit", function(self)
                _last_intrinsic_node = nil
            end)
        end

        for self in values(intrinsic_nodes) do
            local self_x = self:get_bounds().x + 0.5 * self:get_bounds().width
            local min_distance, closest_node = POSITIVE_INFINITY, nil
            for other in values(bottom_nodes) do
                local other_bounds = other:get_bounds()
                local distance = math.abs(other_bounds.x + 0.5 * other_bounds.width - self_x)
                if distance < min_distance then
                    min_distance = distance
                    closest_node = other
                end
            end

            self:set_up(function(self)
                if _last_bottom_node == nil then
                    return closest_node
                else
                    return _last_bottom_node
                end
            end)

            self:signal_connect("leave_up", function(self)
                _last_intrinsic_node = self
            end)

            self:signal_connect("exit", function(self)
                _last_bottom_node = nil
            end)
        end
    end

    local _update_priority_queue_selection = function(entity, move)
        local entities = self._state:entity_get_valid_targets_for_move(entity, move)
        local as_set = {};
        for e in values(entities) do as_set[e:get_id()] = true end

        for other in values(self._state:list_entities()) do
            self._priority_queue:set_selection_state(other, ternary(as_set[other:get_id()] == true, rt.SelectionState.ACTIVE, rt.SelectionState.UNSELECTED))
        end
    end

    for nodes in range(move_nodes, intrinsic_nodes) do
        for node in values(nodes) do
            node:signal_connect("enter", function(self)
                self.slots:set_slot_selection_state(self.slot_i, rt.SelectionState.ACTIVE)
                scene._verbose_info:show(self:get_move())
                _update_priority_queue_selection(self.entity, self:get_move())
            end)

            node:signal_connect("exit", function(self)
                self.slots:set_slot_selection_state(self.slot_i, rt.SelectionState.INACTIVE)
                scene._verbose_info:show(nil)

                for other in values(scene._state:list_entities()) do
                    scene._priority_queue:set_selection_state(other, rt.SelectionState.UNSELECTED)
                end
            end)

            node:signal_connect(rt.InputButton.A, function(self)
                scene:_set_move_choice(self.entity, self:get_move())
                scene:set_scene_state(bt.BattleSceneState.TARGET_SELECTION)
                -- TODO: start simulation
            end)

            current.selection_graph:add(node)
        end
    end

    current.move_nodes = move_nodes
    current.intrinsic_nodes = intrinsic_nodes
    return current
end

--- @brief
function bt.BattleScene:add_entity(...)
    local reformat_enemies, reformat_allies = false, false
    for entity in range(...) do
        local sprite
        if self._state:entity_get_is_enemy(entity) == true then
            reformat_enemies = true
            sprite = bt.EnemySprite(entity)
            if self._is_realized == true then
                sprite:realize()
            end

            table.insert(self._enemy_sprites, sprite)
        else
            reformat_allies = true
            sprite = bt.PartySprite(entity)
            if self._is_realized == true then
                sprite:realize()
            end

            -- TODO: setup UI
            table.insert(self._party_sprites, sprite)
        end
        self._entity_id_to_sprite[entity:get_id()] = sprite
    end

    if reformat_allies then self:reformat_party_sprites() end
    if reformat_enemies then self:reformat_enemy_sprites() end
end

--- @brief
function bt.BattleScene:remove_entity(...)
    local reformat_enemies, reformat_allies = false, false

    for entity in range(...) do
        local sprite = self:get_sprite(entity)
        local removed = false
        if sprite ~= nil then
            for i, other in ipairs(self._enemy_sprites) do
                if other == sprite then
                    table.remove(self._enemy_sprites, i)
                    removed = true
                    break
                end
            end

            if not removed then
                for i, other in ipairs(self._party_sprites) do
                    if other == sprite then
                        table.remove(self._party_sprites, i)
                        removed = true
                        break
                    end
                end
            end
        end

        self._entity_id_to_sprite[entity:get_id()] = nil
        if not removed then
            rt.error("In bt.BattleScene.remove_entity: no sprite for entity `" .. entity:get_id() .. "` present")
        end
    end

    if reformat_allies then self:reformat_party_sprites() end
    if reformat_enemies then self:reformat_enemy_sprites() end
end

--- @override
function bt.BattleScene:size_allocate(x, y, width, height)
    self._background:fit_into(x, y, width, height)
    self._game_over_screen:fit_into(x, y, width, height)

    local tile_size = rt.settings.menu.inventory_scene.tile_size
    local m = rt.settings.margin_unit
    local outer_margin = rt.settings.menu.inventory_scene.outer_margin

    local text_box_w = (4 / 3 * self._bounds.height) - 2 * outer_margin - 2 * tile_size
    local text_box_x = x + 0.5 * width - 0.5 * text_box_w
    local text_box_y = y + outer_margin
    self._text_box:fit_into(
        text_box_x,
        text_box_y,
        text_box_w, tile_size
    )

    local queue_w = (width - 4 / 3 * height) / 2 - 2 * outer_margin
    self._priority_queue:fit_into(
        x + outer_margin, y + outer_margin, queue_w,
        height - 2 * outer_margin
    )

    local inspect_control_w, inspect_control_h = self._inspect_control_indicator:measure()
    self._inspect_control_indicator:fit_into(
        x + outer_margin + queue_w + outer_margin,
        text_box_y,
        inspect_control_w, inspect_control_h
    )

    local control_w, control_h = self._move_selection_control_indicator:measure()
    self._move_selection_control_indicator:fit_into(
        x + outer_margin + queue_w + outer_margin,
        y + outer_margin,
        control_w, control_h
    )

    local status_bar_x = x + 0.5 * width + 0.5 * text_box_w
    self._global_status_bar:fit_into(
        status_bar_x, y + outer_margin,
        x + width - status_bar_x, control_h
    )

    self._quicksave_indicator:fit_into(
        x + width - outer_margin - tile_size,
        y + height - outer_margin - tile_size,
        tile_size, tile_size
    )

    local verbose_info_h = height - 2 * outer_margin
    local verbose_info_w = 1/3 * (width - 2 * outer_margin)
    self._verbose_info:fit_into(
        x + width - outer_margin - verbose_info_w, y + outer_margin,
        verbose_info_w, verbose_info_h
    )
    self._verbose_info_width = verbose_info_w

    local enemy_bounds = self:reformat_enemy_sprites()
    self:reformat_party_sprites()

    self._move_selection_aabb = rt.AABB(
        x + outer_margin + queue_w + outer_margin,
        y + outer_margin + control_h + m,
        0, 0
    )

    for entity in keys(self._entity_id_to_slots) do
        self:_reformat_move_selection_slots(entity)
    end

    if self._is_first_size_allocate then
        -- TODO
        self._env.start_battle("DEBUG_BATTLE")
        self._env.quicksave()
        self:skip_all()
        self:set_scene_state(bt.BattleSceneState.MOVE_SELECTION)
        -- TODO
        self._is_first_size_allocate = false
    end
end

--- @brief
function bt.BattleScene:reformat_enemy_sprites()
    local n_enemies = sizeof(self._enemy_sprites)
    local i_to_sprite = {}
    local total_w = 0
    local max_h = NEGATIVE_INFINITY
    do
        local i = 1
        for sprite in values(self._enemy_sprites) do -- use state instead of self._enemy_sprites because key order is not deterministic
            if sprite ~= nil then -- entity may be dead or unlisted
                i_to_sprite[i] = sprite
                local w, h = sprite:measure()
                total_w = total_w + w
                max_h = math.max(max_h, h)
                i = i + 1
            end
        end
    end

    local m = rt.settings.margin_unit
    local outer_margin = 2 * m

    local y = 0.5 * self._bounds.height + 0.5 * max_h
    local width = (4 / 3 * self._bounds.height) - 2 * outer_margin
    local sprite_m = math.min(m, (width - total_w) / (n_enemies - 1))

    local sprite_order = {}
    if n_enemies >= 1 then table.insert(sprite_order, 1) end
    for i = 2, n_enemies do
        if i % 2 == 0 then
            table.insert(sprite_order, i)
        else
            table.insert(sprite_order, 1, i)
        end
    end

    local sprite_to_motion_backup = {}
    for sprite, motion in pairs(self._enemy_sprites_motion) do
        sprite_to_motion_backup[sprite] = motion
    end
    self._enemy_sprites_motion = {}

    local min_x, min_y = POSITIVE_INFINITY, POSITIVE_INFINITY
    local max_x, max_y = NEGATIVE_INFINITY, NEGATIVE_INFINITY

    self._enemy_sprites_render_order = {}
    local speed = rt.settings.battle.battle_scene.enemy_sprite_speed
    local current_x = self._bounds.x + 0.5 * self._bounds.width - 0.5 * (total_w + (n_enemies + 1) * sprite_m)
    for i in values(sprite_order) do
        local sprite = i_to_sprite[i]
        local sprite_w, sprite_h = sprite:measure()

        local new_x, new_y = current_x, y - sprite_h
        local motion = sprite_to_motion_backup[sprite]
        if motion == nil then
            motion = rt.SmoothedMotion2D(0, 0, speed)
        else
            local sprite_bounds = sprite:get_bounds()
            motion:set_position(sprite_bounds.x - new_x, sprite_bounds.y - new_y)
        end
        sprite:fit_into(new_x, new_y, sprite_w, sprite_h)

        min_x = math.min(min_x, new_x)
        min_y = math.min(min_y, new_y)
        max_x = math.max(max_x, new_x + sprite_w)
        max_y = math.max(max_y, new_y + sprite_h)

        self._enemy_sprites_motion[sprite] = motion
        table.insert(self._enemy_sprites_render_order, sprite)

        current_x = current_x + sprite_w + sprite_m
    end

    return rt.AABB(min_x, min_y, max_x - min_x, max_y - min_y)
end

--- @brief
function bt.BattleScene:reformat_party_sprites()
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local width = (4 / 3) * self._bounds.height - 2 * outer_margin
    local n_sprites = sizeof(self._party_sprites)

    local sprite_w = math.min(
        (width - 2 * m - (n_sprites - 1) * m) / n_sprites,
        (width - 2 * m - (3 - 1) * m) / 3
    )
    local sprite_h = rt.settings.menu.inventory_scene.tile_size
    local sprite_y = self._bounds.y + self._bounds.height - outer_margin - sprite_h
    local sprite_x = self._bounds.x + 0.5 * self._bounds.width - 0.5 * sprite_w * n_sprites

    local sprite_to_motion_backup = {}
    for sprite, motion in pairs(self._party_sprites_motion) do
        sprite_to_motion_backup[sprite] = motion
    end
    self._party_sprites_motion = {}

    local min_x, min_y = POSITIVE_INFINITY, POSITIVE_INFINITY
    local max_x, max_y = NEGATIVE_INFINITY, NEGATIVE_INFINITY

    local speed = rt.settings.battle.battle_scene.enemy_sprite_speed
    for sprite in values(self._party_sprites) do
        if sprite ~= nil then
            local motion = sprite_to_motion_backup[sprite]
            if motion == nil then
                motion = rt.SmoothedMotion2D(0, 0, speed)
            else
                local sprite_bounds = sprite:get_bounds()
                motion:set_position(sprite_bounds.x - sprite_x, sprite_bounds.y - sprite_y)
            end
            sprite:fit_into(sprite_x, sprite_y, sprite_w, sprite_h)
            self._party_sprites_motion[sprite] = motion

            min_x = math.min(min_x, sprite_x)
            min_y = math.min(min_y, sprite_y)
            max_x = math.max(max_x, sprite_x + sprite_w)
            max_y = math.max(max_y, sprite_y + sprite_h)

            sprite_x = sprite_x + sprite_w + m
        end
    end

    return rt.AABB(min_x, min_y, max_x - min_x, max_y - min_y)
end

--- @override
function bt.BattleScene:draw()
    if self._game_over_screen_active then
        self._game_over_screen:draw()
        return
    end

    self._background:draw()

    for sprite in values(self._party_sprites) do
        local motion = self._party_sprites_motion[sprite]
        love.graphics.push()
        love.graphics.translate(motion:get_position())
        sprite:draw()
        love.graphics.pop()
    end

    for sprite in values(self._enemy_sprites_render_order) do
        local motion = self._enemy_sprites_motion[sprite]
        love.graphics.push()
        love.graphics.translate(motion:get_position())
        sprite:draw()
        love.graphics.pop()
    end

    for widget in range(
        self._priority_queue,
        self._global_status_bar,
        self._quicksave_indicator
    ) do
        widget:draw()
    end

    self._animation_queue:draw()
    self._text_box:draw()

    if self._scene_state == bt.BattleSceneState.INSPECT and self._text_box:get_reveal_indicator_visible() then
        self._inspect_control_indicator:draw()
    end

    if self._scene_state == bt.BattleSceneState.MOVE_SELECTION then
        self._move_selection_control_indicator:draw()
        local current = self._move_selection_order[self._move_selection_i]
        local element = self._entity_id_to_slots[current:get_id()]
        if element.last_n_move_slots > 0 then
            element.moves:draw()
        end

        if element.last_n_intrinsic_slots > 0 then
            element.intrinsics:draw()
        end
    end

    self._verbose_info:draw()

    if self._inspect_selection_arrow_up_visible then
        self._inspect_selection_arrow_up:draw()
        self._inspect_selection_arrow_up_outline:draw()
    end

    if self._inspect_selection_arrow_right_visible then
        self._inspect_selection_arrow_right:draw()
        self._inspect_selection_arrow_right_outline:draw()
    end

    if self._inspect_selection_arrow_down_visible then
        self._inspect_selection_arrow_down:draw()
        self._inspect_selection_arrow_down_outline:draw()
    end

    if self._inspect_selection_arrow_left_visible then
        self._inspect_selection_arrow_left:draw()
        self._inspect_selection_arrow_left_outline:draw()
    end

    if self._inspect_selection_frame_visible then
        self._inspect_selection_frame:draw()
    end

    if self._move_selection_jump_left_arrow_visible then
        self._move_selection_jump_left_arrow:draw()
        self._move_selection_jump_left_arrow_outline:draw()
    end

    if self._move_selection_jump_right_arrow_visible then
        self._move_selection_jump_right_arrow:draw()
        self._move_selection_jump_right_arrow_outline:draw()
    end
end

--- @brief
function bt.BattleScene:create_quicksave_screenshot(texture)
    meta.assert_isa(texture, rt.RenderTexture)
    texture:bind()

    self._background:draw()

    for sprite in values(self._party_sprites) do
        local motion = self._party_sprites_motion[sprite]
        love.graphics.push()
        love.graphics.translate(motion:get_position())
        sprite:draw()
        love.graphics.pop()
    end

    for sprite in values(self._enemy_sprites_render_order) do
        local motion = self._enemy_sprites_motion[sprite]
        love.graphics.push()
        love.graphics.translate(motion:get_position())
        sprite:draw()
        love.graphics.pop()
    end

    texture:unbind()
end

--- @override
function bt.BattleScene:update(delta)
    do -- auto scroll while button is held
        local up_active = self._input:get_is_down(rt.InputButton.UP)
        local down_active = self._input:get_is_down(rt.InputButton.DOWN)
        if self._text_box_scroll_mode_active and (up_active or down_active) then
            self._text_box_scroll_delay_elapsed = self._text_box_scroll_delay_elapsed + delta
            if self._text_box_scroll_delay_elapsed > rt.settings.battle.battle_scene.text_box_scroll_delay then
                self._text_box_scroll_tick_elapsed = self._text_box_scroll_tick_elapsed + delta
                local tick_duration = 1 / rt.settings.battle.battle_scene.text_box_scroll_ticks_per_second
                while self._text_box_scroll_tick_elapsed > tick_duration do
                    self._text_box_scroll_tick_elapsed = self._text_box_scroll_tick_elapsed - tick_duration
                    if up_active then
                        self._text_box:scroll_up()
                    elseif down_active then
                        self._text_box:scroll_down()
                    end
                end
            end
        end
    end

    if self._game_over_screen_active then
        self._game_over_screen:update(delta)
        return
    end

    for updatable in range(
        self._background,
        self._text_box,
        self._global_status_bar,
        self._priority_queue,
        self._quicksave_indicator,
        self._animation_queue
    ) do
        updatable:update(delta)
    end

    for sprite in values(self._party_sprites) do
        sprite:update(delta)
    end

    for sprite in values(self._enemy_sprites) do
        sprite:update(delta)
    end

    for motion in values(self._enemy_sprites_motion) do
        motion:update(delta)
    end

    for motion in values(self._party_sprites_motion) do
        motion:update(delta)
    end
end

--- @override
function bt.BattleScene:make_active()
    self._input:signal_unblock_all()
    self._state:set_is_battle_active(true)
end

--- @override
function bt.BattleScene:make_inactive()
    self._input:signal_block_all()
end

--- @brief
function bt.BattleScene:set_priority_order(entities)
    self._priority_queue:reorder(entities)
end

--- @brief
function bt.BattleScene:get_text_box()
    return self._text_box
end

--- @brief
function bt.BattleScene:add_global_status(status, n_turns_left)
    self._global_status_bar:add_global_status(status, n_turns_left)
end

--- @brief
function bt.BattleScene:remove_global_status(status)
   self._global_status_bar:remove_global_status(status)
end

--- @brief
function bt.BattleScene:set_global_status_n_turns_left(status, n_turns_left)
    self._global_status_bar:set_global_status_n_turns_left(status, n_turns_left)
end

--- @brief
function bt.BattleScene:activate_global_status(status, on_done_notify)
    self._global_status_bar:activate_global_status(status, on_done_notify)
end

--- @brief
function bt.BattleScene:skip()
    for sprite in values(self._enemy_sprites) do
        sprite:skip()
    end

    for motion in values(self._enemy_sprites_motion) do
        motion:skip()
    end

    for sprite in values(self._party_sprites) do
        sprite:skip()
    end

    for motion in values(self._party_sprites_motion) do
        motion:skip()
    end

    for to_skip in range(
        self._priority_queue,
        self._global_status_bar,
        self._animation_queue,
        self._game_over_screen,
        self._text_box
    ) do
        to_skip:skip()
    end
end

--- @brief
function bt.BattleScene:skip_all()
    self._animation_queue:clear()
    self:skip()
end

--- @brief
function bt.BattleScene:get_are_sprites_done_repositioning()
    for list in range(self._enemy_sprites_motion, self._party_sprites_motion) do
        for motion in values(list) do
            local cx, cy = motion:get_position()
            local tx, ty = motion:get_target_position()
            if rt.distance(cx, cy, tx, ty) > 1 then return false end
        end
    end

    return true
end

--- @brief
function bt.BattleScene:send_message(text, on_done_notify)
    return self._text_box:append(text, on_done_notify)
end

--- @brief
function bt.BattleScene:skip_message(id)
    if id ~= nil then
        self._text_box:skip_message(id)
    end
end

--- @brief
function bt.BattleScene:set_background(background)
    self._background:set_implementation(background)
end

--- @brief
function bt.BattleScene:_verbose_info_show_next_to(object, node_bounds)
    meta.assert_aabb(node_bounds)
    self._verbose_info:show(object)
    local scene_bounds = self._bounds
    local w = self._verbose_info_width
    local h = select(2, self._verbose_info:measure())
    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local left_w = math.abs(node_bounds.x - scene_bounds.x) - m
    local right_w = math.abs((node_bounds.x + node_bounds.width) - (scene_bounds.x + scene_bounds.width)) - m
    local top_h = math.abs(node_bounds.y - scene_bounds.y) - m
    local bottom_h = math.abs((node_bounds.y + node_bounds.height) - (scene_bounds.y + scene_bounds.height)) - m

    local final_x, final_y
    local horizontally_placed = true
    if  w < right_w then
        final_x = node_bounds.x - m - w
    elseif w < left_w then
        final_x = node_bounds.x + node_bounds.width + m
    else
        final_x = node_bounds.x
        horizontally_placed = false
    end

    if horizontally_placed then
        final_y = node_bounds.y
        local free_space = math.abs((scene_bounds.y + scene_bounds.height) - node_bounds.y) - outer_margin
        if h > free_space then final_y = final_y - math.abs(h - free_space) end
        final_x = math.min(math.max(final_x, scene_bounds.x + outer_margin), scene_bounds.x + scene_bounds.width - outer_margin)
    else
        if h < bottom_h then
            final_y = node_bounds.y + node_bounds.height + m
        else
            final_y = node_bounds.y - m - h
        end
    end
    self._verbose_info:fit_into(final_x, final_y, w)
end

--- @brief
function bt.BattleScene:_verbose_info_show_next_to(object, node_bounds)
    self._verbose_info:show(object)
    local scene_bounds = self._bounds
    local info_w = self._verbose_info_width
    local info_h = select(2, self._verbose_info:measure())

    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local distance = function(a, b)
        return math.abs(a - b)
    end

    local left_w = distance(node_bounds.x - m, scene_bounds.x + outer_margin)
    local right_w = distance(node_bounds.x + node_bounds.width + m, scene_bounds.x + scene_bounds.width - outer_margin)
    local top_h = distance(node_bounds.y - m, scene_bounds.y + outer_margin)
    local bottom_h = distance(node_bounds.y + node_bounds.height + m, scene_bounds.y + scene_bounds.height - outer_margin)

    local final_x, final_y = scene_bounds.x + outer_margin, scene_bounds.y + outer_margin
    if info_w <= right_w then
        final_x = node_bounds.x + node_bounds.width + m
        final_y = node_bounds.y
    elseif info_w <= left_w then
        final_x = node_bounds.x - m - info_w
        final_y = node_bounds.y
    else
        final_x = node_bounds.x + 0.5 * node_bounds.width - 0.5 * info_w
        if info_h <= bottom_h then
            final_y = node_bounds.y + node_bounds.height + m
        elseif info_h <= top_h then
            final_y = node_bounds.y - m - info_h
        end
    end

    if final_y + info_h > scene_bounds.y + scene_bounds.height - outer_margin then
        final_y = final_y - distance(final_y + info_h, scene_bounds.y + scene_bounds.height - outer_margin)
    end

    if final_y < scene_bounds.y + m then
        final_y = final_y + distance(final_y, scene_bounds.y + m)
    end

    final_x = math.min(math.max(final_x, scene_bounds.x + outer_margin), scene_bounds.x + scene_bounds.width - outer_margin)
    final_y = math.min(math.max(final_y, scene_bounds.y + outer_margin), scene_bounds.y + scene_bounds.height - outer_margin)

    self._verbose_info:fit_into(final_x, final_y, info_w)
end

--- @brief
function bt.BattleScene:_create_inspect_selection_graph()
    local graph = rt.SelectionGraph()

    local priority_queue_nodes = self._priority_queue:get_selection_nodes()
    local global_status_bar_nodes = self._global_status_bar:get_selection_nodes()

    local textbox_nodes = { rt.SelectionGraphNode(self._text_box:get_bounds()) }
    local textbox_node = textbox_nodes[1]
    textbox_node.object = rt.VerboseInfoObject.BATTLE_LOG

    local quicksave_nodes = self._quicksave_indicator:get_selection_nodes()
    local quicksave_node = quicksave_nodes[1]
    quicksave_node.object = rt.VerboseInfoObject.QUICKSAVE

    local enemy_sprite_nodes = {}
    local enemy_status_consumable_nodes = {}
    local party_sprite_nodes = {}
    local party_status_consumable_nodes = {}

    for which in range(
        { self._enemy_sprites, enemy_sprite_nodes, enemy_status_consumable_nodes, true },
        { self._party_sprites, party_sprite_nodes, party_status_consumable_nodes, false }
    ) do
        local sprites, sprite_nodes, status_consumable_nodes, direction = table.unpack(which)
        for sprite in values(sprites) do
            local sprite_node = sprite:get_sprite_selection_node()
            local bar_nodes = sprite:get_status_consumable_selection_nodes()

            local closest_node = nil
            local min_distance = POSITIVE_INFINITY
            local sprite_center_x
            do
                local bounds = sprite_node:get_bounds()
                sprite_center_x = bounds.x + 0.5 * bounds.width
            end

            for i = 1, sizeof(bar_nodes) do
                local node = bar_nodes[i]
                local bounds = node:get_bounds()
                local center_x = bounds.x + 0.5 * bounds.width
                local distance = math.abs(sprite_center_x - center_x)
                if distance < min_distance then
                    min_distance = distance
                    closest_node = node
                end

                table.insert(status_consumable_nodes, node)
            end

            table.insert(sprite_nodes, sprite_node)
        end
    end

    -- linking
    local n_party_status_nodes = sizeof(party_status_consumable_nodes)
    local n_enemy_status_nodes = sizeof(enemy_status_consumable_nodes)
    local n_enemy_sprite_nodes = sizeof(enemy_sprite_nodes)
    local n_party_sprite_nodes = sizeof(party_sprite_nodes)
    local n_global_status_nodes = sizeof(global_status_bar_nodes)
    local n_priority_queue_nodes = sizeof(priority_queue_nodes)

    for nodes_n in range(
        {party_status_consumable_nodes, n_party_status_nodes},
        {enemy_status_consumable_nodes, n_enemy_status_nodes},
        {party_sprite_nodes, n_party_sprite_nodes},
        {enemy_sprite_nodes, n_enemy_sprite_nodes},
        {global_status_bar_nodes, n_global_status_nodes}
    ) do

        local nodes, n = table.unpack(nodes_n)
        table.sort(nodes, function(a, b)
            return a:get_bounds().x < b:get_bounds().x
        end)
        for i = 1, n do
            local node = nodes[i]
            node:set_left(nodes[i - 1])
            node:set_right(nodes[i + 1])
        end
    end

    local _last_textbox_down_node = nil
    local highest_y = POSITIVE_INFINITY
    for node in values(enemy_sprite_nodes) do
        node:set_up(textbox_node)
        node:signal_connect("enter", function(self)
            _last_textbox_down_node = self
        end)

        -- initialize as node closest to top
        if node:get_bounds().y < highest_y then
            _last_textbox_down_node = node
        end
    end

    textbox_node:set_down(function()
        return _last_textbox_down_node
    end)

    textbox_node:set_right(global_status_bar_nodes[1])
    global_status_bar_nodes[1]:set_left(textbox_node)

    local _last_quicksave_up_node = global_status_bar_nodes[1]
    for node in values(global_status_bar_nodes) do
        node:set_down(quicksave_node)
        node:signal_connect("enter", function(self)
            _last_quicksave_up_node = self
        end)
    end

    quicksave_node:set_up(function()
        return _last_quicksave_up_node
    end)

    local _last_quicksave_left_node = party_sprite_nodes[n_party_sprite_nodes]
    quicksave_node:set_left(function()
        return _last_quicksave_left_node
    end)

    party_sprite_nodes[n_party_sprite_nodes]:signal_connect("exit", function(self)
        _last_quicksave_left_node = self
    end)
    party_sprite_nodes[n_party_sprite_nodes]:set_right(quicksave_node)

    party_status_consumable_nodes[n_party_status_nodes]:signal_connect("exit", function(self)
        _last_quicksave_left_node = self
    end)
    party_status_consumable_nodes[n_party_status_nodes]:set_right(quicksave_node)

    local _sprite_to_last_status_node = {}
    for status_nodes_sprite_nodes_down_or_up in range(
        {enemy_status_consumable_nodes, enemy_sprite_nodes, true},
        {party_status_consumable_nodes, party_sprite_nodes, false}
    ) do
        local status_nodes, sprite_nodes, down_or_up = table.unpack(status_nodes_sprite_nodes_down_or_up)
        for node in values(status_nodes) do
            local self_bounds = node:get_bounds()
            local self_x = self_bounds.x + 0.5 * self_bounds.width
            local min_distance = POSITIVE_INFINITY
            local closest_node = nil
            for other in values(sprite_nodes) do
                local other_bounds = other:get_bounds()
                local distance = math.abs(self_x - (other_bounds.x + 0.5 * other_bounds.width))
                if distance < min_distance then
                    min_distance = distance
                    closest_node = other
                end
            end

            if down_or_up then
                node:set_up(closest_node)
            else
                node:set_down(closest_node)
            end

            _sprite_to_last_status_node[closest_node] = node
            node:signal_connect("enter", function(self)
                _sprite_to_last_status_node[closest_node] = self
            end)
        end

        for node in values(sprite_nodes) do
            if down_or_up then
                node:set_down(function(self)
                    return _sprite_to_last_status_node[self]
                end)
            else
                node:set_up(function(self)
                    return _sprite_to_last_status_node[self]
                end)
            end
        end
    end

    table.sort(priority_queue_nodes, function(a, b)
        return a:get_bounds().y < b:get_bounds().y
    end)

    local left_candidates = {
        textbox_node,
        enemy_sprite_nodes[1],
        enemy_status_consumable_nodes[1],
        party_sprite_nodes[1],
        party_status_consumable_nodes[1]
    }

    local _last_priority_queue_node_left = priority_queue_nodes[1]
    local _last_priority_queue_node_right
    for i = 1, n_priority_queue_nodes do
        local node = priority_queue_nodes[i]
        node:set_up(priority_queue_nodes[i - 1])
        node:set_down(priority_queue_nodes[i + 1])
        node:signal_connect("enter", function(self)
            _last_priority_queue_node_left = self
        end)

        local self_bounds = node:get_bounds()
        local self_y = self_bounds.y + 0.5 * self_bounds.height
        local min_distance = POSITIVE_INFINITY
        local closest_node = nil
        for other in values(left_candidates) do
            local other_bounds = other:get_bounds()
            local distance = math.abs(self_y - (other_bounds.y + 0.5 * other_bounds.height))
            if distance < min_distance then
                min_distance = distance
                closest_node = other
            end
        end
    end

    local _last_party_status_node = nil
    local _last_enemy_status_node = nil
    for selfs_others in range(
        {party_status_consumable_nodes, enemy_status_consumable_nodes, true},
        {enemy_status_consumable_nodes, party_status_consumable_nodes, false}
    ) do
        local selfs, others, down_or_up = table.unpack(selfs_others)
        for node in values(selfs) do
            local self_bounds = node:get_bounds()
            local self_x = self_bounds.x + 0.5 * self_bounds.width
            local min_distance = POSITIVE_INFINITY
            local closest_node = nil
            for other in values(others) do
                local other_bounds = other:get_bounds()
                local distance = math.abs(self_x - (other_bounds.x + 0.5 * other_bounds.width))
                if distance < min_distance then
                    min_distance = distance
                    closest_node = other
                end
            end

            if down_or_up then
                -- party nodes
                node:set_up(function(self)
                    local out = which(_last_enemy_status_node, closest_node)
                    _last_party_status_node = self
                    return out
                end)

                node:signal_connect("leave_left", function()
                    _last_enemy_status_node = nil
                end)

                node:signal_connect("leave_right", function()
                    _last_enemy_status_node = nil
                end)

                node:signal_connect("leave_down", function()
                    _last_enemy_status_node = nil
                end)
            else
                -- enemy nodes
                node:set_down(function(self)
                    local out = which(_last_party_status_node, closest_node)
                    _last_enemy_status_node = self
                    return out
                end)

                node:signal_connect("leave_left", function()
                    _last_party_status_node = nil
                end)

                node:signal_connect("leave_right", function()
                    _last_party_status_node = nil
                end)

                node:signal_connect("leave_up", function()
                    _last_party_status_node = nil
                end)
            end
        end
    end

    -- behavior
    local scene = self

    local textbox_node = textbox_nodes[1]
    textbox_node:signal_connect("enter", function(self)
        scene:_set_textbox_scroll_mode_active(true)
        self.is_active = true
    end)

    textbox_node:signal_connect("exit", function(self)
        scene:_set_textbox_scroll_mode_active(false)
        self.is_active = false
    end)

    textbox_node.get_bounds = function(self) -- override to account for resizing textbox
        return scene._text_box:get_bounds()
    end

    local quicksave_node = quicksave_nodes[1]
    quicksave_node:signal_connect("enter", function(self)
        scene._quicksave_indicator:set_selection_state(rt.SelectionState.ACTIVE)
    end)

    quicksave_node:signal_connect("exit", function(self)
        scene._quicksave_indicator:set_selection_state(rt.SelectionState.INACTIVE)
    end)

    scene:signal_connect("update", function()
        if textbox_node.is_active then
            textbox_node:signal_emit("enter") -- reformat verbose info
        end
    end)

    do
        local on_entity_node_enter = function(self)
            scene:_set_entity_selection_state(self.object, rt.SelectionState.ACTIVE)
        end

        local on_entity_node_exit = function(self)
            scene:_set_entity_selection_state(self.object, rt.SelectionState.INACTIVE)
        end

        for nodes in range(
            enemy_sprite_nodes,
            party_sprite_nodes,
            priority_queue_nodes
        ) do
            for entity_node in values(nodes) do
                entity_node:signal_connect("enter", on_entity_node_enter)
                entity_node:signal_connect("exit", on_entity_node_exit)
            end
        end
    end

    local on_small_node_enter = function()
        scene._inspect_selection_frame_visible = true
    end

    local on_small_node_exit = function()
        scene._inspect_selection_frame_visible = false
    end

    for nodes in range(
        global_status_bar_nodes,
        enemy_status_consumable_nodes,
        party_status_consumable_nodes
    ) do
        for node in values(nodes) do
            node:signal_connect("enter", on_small_node_enter)
            node:signal_connect("exit", on_small_node_exit)
        end
    end

    do
        local on_enter_show_verbose_info = function(self)
            scene:_verbose_info_show_next_to(self.object, self:get_bounds())
            scene:_update_inspect_selection_arrows(self)
        end

        for nodes in range(
            enemy_sprite_nodes,
            enemy_status_consumable_nodes,
            party_sprite_nodes,
            party_status_consumable_nodes,
            priority_queue_nodes,
            global_status_bar_nodes,
            quicksave_nodes,
            textbox_nodes
        ) do
            for node in values(nodes) do
                assert(node.object ~= nil)
                node:signal_connect("enter", on_enter_show_verbose_info)

                graph:add(node)
            end
        end
    end

    self._inspect_selection_graph = graph
    self._inspect_selection_graph_default_node = enemy_sprite_nodes[1]
end

--- @brief
function bt.BattleScene:_generate_selection_arrow(center_x, center_y, angle)
    local r = rt.settings.margin_unit
    local a_x, a_y = rt.translate_point_by_angle(center_x, center_y, r, angle + (2 * math.pi) * (0 / 3))
    local b_x, b_y = rt.translate_point_by_angle(center_x, center_y, r, angle + (2 * math.pi) * (1 / 3))
    local c_x, c_y = rt.translate_point_by_angle(center_x, center_y, r, angle + (2 * math.pi) * (2 / 3))

    local body = rt.Polygon(a_x, a_y, b_x, b_y, c_x, c_y)
    body:set_color(rt.Palette.SELECTION)

    local outline = rt.Polygon(a_x, a_y, b_x, b_y, c_x, c_y)
    outline:set_color(rt.Palette.BLACK)
    outline:set_is_outline(true)
    outline:set_line_width(1)

    return body, outline
end

--- @brief
function bt.BattleScene:_update_inspect_selection_arrows(node)
    local bounds = node:get_bounds()
    local m = rt.settings.margin_unit

    local thickness = self._inspect_selection_frame:get_thickness() * 2
    self._inspect_selection_frame:fit_into(bounds.x, bounds.y , bounds.width, bounds.height)

    local outline_thickness = 1
    local r = m
    local offset = r * math.cos(2 * math.pi / 3 / 2) + self._inspect_selection_frame:get_thickness() + 4 * outline_thickness
    
    self._inspect_selection_arrow_up_visible = node:get_up() ~= nil
    if self._inspect_selection_arrow_up_visible then
        self._inspect_selection_arrow_up, self._inspect_selection_arrow_up_outline = self:_generate_selection_arrow(
            bounds.x + 0.5 * bounds.width,
            bounds.y - offset,
            -0.5 * math.pi
        )
    end

    self._inspect_selection_arrow_right_visible = node:get_right() ~= nil
    if self._inspect_selection_arrow_right_visible then
        self._inspect_selection_arrow_right, self._inspect_selection_arrow_right_outline = self:_generate_selection_arrow(
            bounds.x + bounds.width + offset,
            bounds.y + 0.5 * bounds.height,
            0
        )
    end

    self._inspect_selection_arrow_down_visible = node:get_down() ~= nil
    if self._inspect_selection_arrow_down_visible then
        self._inspect_selection_arrow_down, self._inspect_selection_arrow_down_outline = self:_generate_selection_arrow(
            bounds.x + 0.5 * bounds.width,
            bounds.y + bounds.height + offset,
            0.5 * math.pi
        )
    end

    self._inspect_selection_arrow_left_visible = node:get_left() ~= nil
    if self._inspect_selection_arrow_left_visible then
        self._inspect_selection_arrow_left, self._inspect_selection_arrow_left_outline = self:_generate_selection_arrow(
            bounds.x - offset,
            bounds.y + 0.5 * bounds.height,
            1 * math.pi
        )
    end
end

--- @brief
function bt.BattleScene:_set_textbox_scroll_mode_active(b)
    self._text_box_scroll_mode_active = b
    if b then
        self._text_box:set_history_mode_active(true)
        self._text_box:set_reveal_indicator_visible(false)
        self._text_box:set_selection_state(rt.SelectionState.ACTIVE)
    else
        self._text_box:set_history_mode_active(false)
        self._text_box:set_reveal_indicator_visible(true)
        self._text_box:set_selection_state(rt.SelectionState.INACTIVE)
    end
end

--- @brief
function bt.BattleScene:_set_entity_selection_state(entity, state)
    local sprite = self:get_sprite(entity)
    sprite:set_selection_state(state)
    self._priority_queue:set_selection_state(entity, state)
end

--- @brief
function bt.BattleScene:_start_move_selection()
    -- collect viable entities
    local entities = self._state:list_entities()
    local party = {}
    local enemies = {}

    self._entity_id_to_move_selection = {}
    for entity in values(entities) do
        if not (self._state:entity_get_is_stunned(entity) or self._state:entity_get_state(entity) ~= bt.EntityState.ALIVE) then
            if self._state:entity_get_is_enemy(entity) then
                table.insert(enemies, entity)
            else
                table.insert(party, entity)
            end
            self._entity_id_to_move_selection[entity:get_id()] = nil
        end
    end

    for choice in values(self._ai:make_move_selection(enemies)) do
        self._entity_id_to_move_selection[choice.user:get_id()] = choice
    end

    self._move_selection_order = party

    -- update slot base
    for entity in values(party) do
        local n_move_slots, move_slots = self._state:entity_list_move_slots(entity)
        local intrinsic_slots = self._state:entity_list_intrinsic_moves(entity)
        local n_intrinsic_slots = sizeof(intrinsic_slots)

        local current = self._entity_id_to_slots[entity:get_id()]
        local needs_update = current == nil or
            current.last_n_move_slots ~= n_move_slots or
            current.last_n_intrinsic_slots ~= n_intrinsic_slots

        if needs_update then
            -- only re-init widgets if necessary
            current = self:_create_move_selection_slots(entity)
        end

        local label_prefix = "<b><o><mono>"
        local label_postfix = "</o></mono></b>"
        local font = rt.settings.font.default_regular
        local font_mono = rt.settings.font.default_mono

        -- always update move icons
        for slot_i = 1, n_move_slots do
            local move = move_slots[slot_i]
            if move ~= nil then
                local n_left = move:get_max_n_uses() - self._state:entity_get_move_n_used(entity, slot_i)
                current.moves:set_object(slot_i, move, rt.Label(
                    label_prefix .. ternary(n_left == POSITIVE_INFINITY, rt.Translation.infinity, n_left) .. label_postfix,
                    font,
                    font_mono
                ))
            else
                current.moves:set_object(slot_i, nil)
            end
        end

        if current.intrinsics ~= nil then
            local slot_i = 1
            for intrinsic in values(intrinsic_slots) do
                current.intrinsics:set_object(slot_i, intrinsic, rt.Label(
                    label_prefix .. rt.Translation.infinity .. label_postfix,
                    font,
                    font_mono
                ))
                slot_i = slot_i + 1
            end
        end
    end

    self:_set_move_selection_i(1)
end

--- @brief
function bt.BattleScene:_set_move_selection_i(i)
    self._move_selection_i = i
    local current_entity =self._move_selection_order[self._move_selection_i]
    local current = self._entity_id_to_slots[current_entity:get_id()]
    if current == nil then
        current = self:_create_move_selection_slots(current_entity)
    end

    local move_bounds = current.moves:get_bounds()
    local intrinsic_bounds = current.intrinsics:get_bounds()
    self._verbose_info:fit_into(
        move_bounds.x + math.max(move_bounds.width, intrinsic_bounds.width) + rt.settings.margin_unit,
        move_bounds.y ,
        math.max(move_bounds.width, intrinsic_bounds.width),
        move_bounds.height + rt.settings.margin_unit + intrinsic_bounds.height
    )

    local left_prefix, left_postfix = "", ""
    local right_prefix, right_postfix = "", ""
    local selection_bounds = self:get_sprite(current_entity)._frame:get_bounds()
    local r = rt.settings.margin_unit
    local offset = r * math.cos(2 * math.pi / 3 / 2) + self:get_sprite(current_entity)._frame:get_thickness() + 4 * 1

    if self._move_selection_i <= 1 then
        left_prefix = "<s><color=GRAY>"
        left_postfix = "</color></s>"

        self._move_selection_jump_left_arrow_visible = false
    else
        self._move_selection_jump_left_arrow_visible = true
        self._move_selection_jump_left_arrow, self._move_selection_jump_left_arrow_outline = self:_generate_selection_arrow(
            selection_bounds.x - offset,
            selection_bounds.y + 0.5 * selection_bounds.height,
            -math.pi
        )
    end

    if self._move_selection_i >= sizeof(self._move_selection_order) then
        right_prefix = "<s><color=GRAY>"
        right_postfix = "</s></color>"
        self._move_selection_jump_right_arrow_visible = false
    else
        self._move_selection_jump_right_arrow_visible = true
        self._move_selection_jump_right_arrow, self._move_selection_jump_right_arrow_outline = self:_generate_selection_arrow(
            selection_bounds.x + selection_bounds.width + offset,
            selection_bounds.y + 0.5 * selection_bounds.height,
            0
        )
    end

    self._move_selection_control_indicator:create_from({
        {rt.ControlIndicatorButton.ALL_DIRECTIONS, rt.Translation.battle_scene.control_indicator_select_move},
        {rt.ControlIndicatorButton.A, rt.Translation.battle_scene.control_indicator_confirm_move},
        {rt.ControlIndicatorButton.L, left_prefix .. rt.Translation.battle_scene.control_indicator_previous_entity .. left_postfix},
        {rt.ControlIndicatorButton.R, right_prefix .. rt.Translation.battle_scene.control_indicator_next_entity .. right_postfix},
        {rt.ControlIndicatorButton.Y, rt.Translation.battle_scene.control_indicator_inspect}
    })

    for sprite in values(self._enemy_sprites) do
        sprite:set_selection_state(rt.SelectionState.UNSELECTED)
    end

    for entity in values(self._state:list_party()) do
        local sprite = self:get_sprite(entity)
        if sprite ~= nil then
            sprite:set_selection_state(ternary(entity == current_entity, rt.SelectionState.ACTIVE, rt.SelectionState.UNSELECTED))
        end
    end

    if current.selection_graph:get_current_node() == nil then -- cursor memory
        current.selection_graph:set_current_node(current.move_nodes[1])
    end
end

--- @brief
function bt.BattleScene:_set_move_choice(entity, move, targets)
    local sprite = self:get_sprite(entity)
    if sprite == nil then
        rt.error("In bt.BattleScene:_set_move_choice: no sprite for entity `" .. entity:get_id() .. "`")
        return
    end

    sprite:set_move_choice(move)
end

--- @brief
function bt.BattleScene:set_scene_state(state)
    if self._scene_state == state then return end

    -- reset UI elements
    for entity in values(self._state:list_entities()) do
        self._priority_queue:set_selection_state(entity, rt.SelectionState.INACTIVE)
        local sprite = self:get_sprite(entity)
        if sprite ~= nil then
            sprite:set_selection_state(rt.SelectionState.INACTIVE)
        end
    end

    self._verbose_info:show(nil)

    self._text_box:set_reveal_indicator_visible(false)
    self._inspect_selection_arrow_up_visible = false
    self._inspect_selection_arrow_right_visible = false
    self._inspect_selection_arrow_down_visible = false
    self._inspect_selection_arrow_left_visible = false
    self._move_selection_jump_right_arrow_visible = false
    self._move_selection_jump_left_arrow_visible = false

    if state == bt.BattleSceneState.INSPECT then
        self:_create_inspect_selection_graph()
        self._text_box:set_reveal_indicator_visible(true)
        self._inspect_selection_graph:set_current_node(self._inspect_selection_graph_default_node) -- no cursor memory
    elseif state == bt.BattleSceneState.MOVE_SELECTION then
        self:_start_move_selection()
    else
        rt.error("In bt.BattleScene:_set_mode: unhandled state `" .. tostring(state) .. "`")
    end

    self._scene_state = state
end

--- @brief
function bt.BattleScene:_handle_button_released(which)
    self._text_box_scroll_delay_elapsed = 0
    self._text_box_scroll_tick_elapsed = 0
end

--- @brief
function bt.BattleScene:_handle_button_pressed(which)
    if self._scene_state == bt.BattleSceneState.INSPECT then
        if which == rt.InputButton.B then
            self:set_scene_state(bt.BattleSceneState.MOVE_SELECTION)
            self:_set_textbox_scroll_mode_active(false)
            return
        elseif self._text_box_scroll_mode_active then
            local should_exit = false
            if which == rt.InputButton.UP then
                self._text_box:scroll_up()
            elseif which == rt.InputButton.DOWN then
                local can_scroll = self._text_box:scroll_down()
                if not can_scroll then
                    should_exit = true
                end
            elseif which == rt.InputButton.LEFT or which == rt.InputButton.RIGHT then
                should_exit = true
            end

            if should_exit then
                self:_set_textbox_scroll_mode_active(false)
            else
                return -- do not invoke other elements
            end
        end

        self._inspect_selection_graph:handle_button(which)

    elseif self._scene_state == bt.BattleSceneState.MOVE_SELECTION then
        if which == rt.InputButton.Y then
            self:set_scene_state(bt.BattleSceneState.INSPECT)
        elseif which == rt.InputButton.L then
            local i = self._move_selection_i
            if i > 1 then
                self:_set_move_selection_i(i - 1)
            end
        elseif which  == rt.InputButton.R then
            local i = self._move_selection_i
            if i < sizeof(self._move_selection_order) then
                self:_set_move_selection_i(i + 1)
            end
        else
            local current = self._move_selection_order[self._move_selection_i]
            local element = self._entity_id_to_slots[current:get_id()]
            if element ~= nil and element.selection_graph ~= nil then
                element.selection_graph:handle_button(which)
            end
        end
    end
end