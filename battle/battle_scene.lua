rt.settings.battle.battle_scene = {
    enemy_sprite_speed = 500 -- px per second
}

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    local out = meta.new(bt.BattleScene, {
        _state = state,
        _env = nil,

        _background = rt.Background(),
        _verbose_info = mn.VerboseInfoPanel(),

        _text_box = rt.TextBox(),
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

        _selection_graph = nil, -- rt.SelectionGraph?
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
        self._game_over_screen
    ) do
        widget:realize()
    end

    for sprite in values(self._enemy_sprites) do
        sprite:realize()
    end

    for sprite in values(self._party_sprites) do
        sprite:realize()
    end

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

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
    self._text_box:fit_into(
        x + 0.5 * width - 0.5 * text_box_w, y + outer_margin,
        text_box_w, tile_size
    )

    local status_bar_x = x + 0.5 * width + 0.5 * text_box_w
    self._global_status_bar:fit_into(
        status_bar_x, y + outer_margin,
        x + width - status_bar_x, tile_size
    )

    local queue_w = (width - 4 / 3 * height) / 2 - 2 * outer_margin
    self._priority_queue:fit_into(
        x + outer_margin, y + outer_margin, queue_w,
        height - 2 * outer_margin
    )

    self._quicksave_indicator:fit_into(
        x + width - outer_margin - tile_size,
        y + height - outer_margin - tile_size,
        tile_size, tile_size
    )

    local verbose_info_w = 0.5 * width
    self._verbose_info:fit_into(
        x + width - outer_margin - verbose_info_w, y + outer_margin, queue_w,
        height - 2 * outer_margin
    )

    self:reformat_enemy_sprites()
    self:reformat_party_sprites()

    if self._is_first_size_allocate then
        self:skip()
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

        self._enemy_sprites_motion[sprite] = motion
        table.insert(self._enemy_sprites_render_order, sprite)

        current_x = current_x + sprite_w + sprite_m
    end
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

            sprite_x = sprite_x + sprite_w + m
        end
    end
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

    self._verbose_info:draw()

    if self._selection_graph ~= nil then
        self._selection_graph:draw()
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
function bt.BattleScene:_create_inspect_selection_graph()
    local graph = rt.SelectionGraph()

    local priority_queue_nodes = self._priority_queue:get_selection_nodes()
    local global_status_bar_nodes = self._global_status_bar:get_selection_nodes()

    local textbox_nodes = { rt.SelectionGraphNode(self._text_box:get_bounds()) }
    textbox_nodes[1].object = rt.VerboseInfoObject.BATTLE_LOG

    local quicksave_nodes = self._quicksave_indicator:get_selection_nodes()
    quicksave_nodes[1].object = rt.VerboseInfoObject.QUICKSAVE

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
                node:set_left(bar_nodes[i - 1])
                node:set_right(bar_nodes[i + 1])

                if direction == true then
                    node:set_up(sprite_node)
                else
                    node:set_down(sprite_node)
                end

                do
                    local bounds = node:get_bounds()
                    local center_x = bounds.x + 0.5 * bounds.width
                    local distance = math.abs(sprite_center_x - center_x)
                    if distance < min_distance then
                        min_distance = distance
                        closest_node = node
                    end
                end
                table.insert(status_consumable_nodes, node)
            end

            if direction then
                sprite_node:set_down(closest_node)
            else
                sprite_node:set_up(closest_node)
            end

            table.insert(sprite_nodes, sprite_node)
        end
    end

    for sprite_nodes in range(
        enemy_sprite_nodes,
        enemy_status_consumable_nodes,
        party_sprite_nodes,
        party_status_consumable_nodes
    ) do
        table.sort(sprite_nodes, function(a, b)
            return a:get_bounds().x < b:get_bounds().x
        end)

        for i = 1, sizeof(sprite_nodes) do
            local node = sprite_nodes[i]
            node:set_left(sprite_nodes[i - 1])
            node:set_right(sprite_nodes[i + 1])
        end
    end

    do
        local nodes = priority_queue_nodes
        local right_candidates = {
            textbox_nodes[1],
            enemy_sprite_nodes[1],
            party_sprite_nodes[1],
            enemy_status_consumable_nodes[1],
            party_status_consumable_nodes[1]
        }

        for i = 1, sizeof(nodes) do
            local node = nodes[i]
            node:set_up(nodes[i - 1])
            node:set_down(nodes[i + 1])

            local closest_node = nil
            local min_distance = POSITIVE_INFINITY
            for other in values(right_candidates) do
                local self_bounds = node:get_bounds()
                local self_y = self_bounds.y + 0.5 * self_bounds.height

                local other_bounds = other:get_bounds()
                local other_y = other_bounds.y -- sic, not center

                local distance = math.abs(self_y - other_y)
                if distance < min_distance then
                    min_distance = distance
                    closest_node = other
                end
            end

            node:set_right(closest_node)
            closest_node:set_left(node)
        end
    end

    do
        local node = textbox_nodes[1]
        local self_bounds = node:get_bounds()
        local self_x = self_bounds.x + 0.5 * self_bounds.width

        local min_distance = POSITIVE_INFINITY
        local closest_node = nil
        for other in values(enemy_sprite_nodes) do
            other:set_up(textbox_nodes[1])

            local other_bounds = other:get_bounds()
            local other_x = other_bounds.x + 0.5 * other_bounds.width

            local distance = math.abs(other_x - self_x)
            if distance < min_distance then
                min_distance = distance
                closest_node = other
            end
        end

        node:set_down(closest_node)
    end

    for i = 1, sizeof(global_status_bar_nodes) do
        local node = global_status_bar_nodes[i]
        node:set_left(global_status_bar_nodes[i - 1])
        node:set_right(global_status_bar_nodes[i + 1])
        node:set_down(quicksave_nodes[1])
    end
    quicksave_nodes[1]:set_up(global_status_bar_nodes[1])

    do
        local right_nodes = {
            enemy_sprite_nodes[sizeof(enemy_sprite_nodes)],
            enemy_status_consumable_nodes[sizeof(enemy_status_consumable_nodes)],
            party_sprite_nodes[sizeof(party_sprite_nodes)],
            party_status_consumable_nodes[sizeof(party_status_consumable_nodes)],
            textbox_nodes[sizeof(textbox_nodes)]
        }

        local candidates = {
            global_status_bar_nodes[1],
            quicksave_nodes[1]
        }

        for node in values(right_nodes) do
            local min_distance = POSITIVE_INFINITY
            local closest_node = nil

            local self_bounds = node:get_bounds()
            local self_y = self_bounds.y + 0.5 * self_bounds.height

            for other in values(candidates) do
                local other_bounds = other:get_bounds()
                local other_y = other_bounds.y + 0.5 * other_bounds.height

                local distance = math.abs(other_y - self_y)
                if distance < min_distance then
                    min_distance = distance
                    closest_node = other
                end
            end

            node:set_right(closest_node)
            closest_node:set_left(node)
        end
    end

    for node in values(party_status_consumable_nodes) do
        local min_distance = POSITIVE_INFINITY
        local closest_node = nil

        local self_bounds = node:get_bounds()
        local self_x = self_bounds.x + 0.5 * self_bounds.width

        for other in values(enemy_status_consumable_nodes) do
            local other_bounds = other:get_bounds()
            local other_x = other_bounds.x + 0.5 * other_bounds.width

            local distance = math.abs(other_x - self_x)
            if distance < min_distance then
                min_distance = distance
                closest_node = other
            end
        end

        node:set_up(closest_node)
        closest_node:set_down(node)
    end

    local scene = self
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
            node:signal_connect("enter", function(self)
                scene._verbose_info:show(self.object)
            end)

            graph:add(node)
        end
    end

    self._selection_graph = graph
end

--- @brief
function bt.BattleScene:_handle_button_pressed(which)
    if which == rt.InputButton.A then
        self._env.start_battle("DEBUG_BATTLE")
        self._env.quicksave()
        self:skip_all()

        self:_create_inspect_selection_graph()
        --self._text_box:set_show_history_mode_active(true)

        --[[
        local target = self._state:list_enemies()[1]
        local proxy = bt.create_entity_proxy(self, target)
        --self._env.knock_out(proxy)
        --self._env.kill(proxy)
        --self._env.revive(proxy)
        --self:remove_entity(self._state:list_enemies()[1])

        --self:push_animation(bt.Animation.TURN_START(self))
        --self._env.start_turn()
        --self._env.end_turn()
        --self._env.quicksave()
        --self._env.kill(bt.create_entity_proxy(self, self._state:list_enemies()[1]))
        --self._env.quickload()

        --[[
        local enemies = self._state:list_enemies()
        self._env.swap(
            bt.create_entity_proxy(self, enemies[1]),
            bt.create_entity_proxy(self, enemies[2])
        )
        --self:push_animation(bt.Animation.SWAP(self, self:get_sprite(enemies[1]), self:get_sprite(enemies[2])))
        ]]--

        --self._game_over_screen:set_is_expanded(not self._game_over_screen:get_is_expanded())
    elseif which == rt.InputButton.B then
        self:skip()
    elseif which == rt.InputButton.X then
        self._text_box:set_history_mode_active(not self._text_box:get_history_mode_active())
    elseif which == rt.InputButton.DEBUG then
        self._game_over_screen._vignette_shader:recompile()
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.DOWN then
    elseif which == rt.InputButton.LEFT then
    end

    if self._selection_graph ~= nil then
        self._selection_graph:handle_button(which)
    end
end