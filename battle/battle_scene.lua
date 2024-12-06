rt.settings.battle.battle_scene = {
    enemy_sprite_speed = 500 -- px per second
}

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    local out = meta.new(bt.BattleScene, {
        _state = state,
        _env = nil,

        _background = rt.Background(),

        _text_box = rt.TextBox(),
        _priority_queue = bt.PriorityQueue(),
        _quicksave_indicator = bt.QuicksaveIndicator(),

        _global_status_bar = bt.OrderedBox(),
        _global_status_to_sprite = {}, -- Table<bt.GlobalStatus, rt.Sprite>

        _party_sprites = {}, -- Table<bt.Entity, bt.PartySprite>
        _enemy_sprites = {}, -- Table<bt.Entity, bt.EnemySprites>
        _enemy_sprites_render_order = meta.make_weak({}),
        _enemy_sprites_motion = {}, -- Table<bt.EnemySprite, bt.SmoothedMotion1D>

        _input = rt.InputController(),
        _animation_queue = rt.AnimationQueue(),

        _is_first_size_allocate = true
    })
    out._background:set_implementation(rt.Background.CONFUSION) -- TODO
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
        self._quicksave_indicator
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
    if entity:get_is_enemy() == true then
        return self._enemy_sprites[entity]
    else
        return self._party_sprites[entity]
    end
end

--- @override
function bt.BattleScene:create_from_state()
    self._enemy_sprites = {}
    self._party_sprites = {}

    local entities = self._state:list_entities()
    self:add_entity(table.unpack(entities))

    for entity in values(entities) do
        local sprite = self:get_sprite(entity)
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

    self._env = self:create_simulation_environment()
    self._priority_queue:reorder(self._state:list_entities_in_order())
    self._quicksave_indicator:set_screenshot(self._state:get_quicksave_screenshot())
end

--- @brief
function bt.BattleScene:add_entity(...)
    local reformat_enemies, reformat_allies = false, false
    for entity in range(...) do
        if entity:get_is_enemy() == true then
            reformat_enemies = true
            local sprite = bt.EnemySprite(entity)
            if self._is_realized == true then
                sprite:realize()
            end

            self._enemy_sprites[entity] = sprite
        else
            reformat_allies = true
            local sprite = bt.PartySprite(entity)
            if self._is_realized == true then
                sprite:realize()
            end

            -- TODO: setup UI
            self._party_sprites[entity] = sprite
        end
    end

    if reformat_allies then self:_reformat_party_sprites() end
    if reformat_enemies then self:_reformat_enemy_sprites() end
end

--- @brief
function bt.BattleScene:remove_entity(...)
    local reformat_enemies, reformat_allies = false, false

    for entity in range(...) do
        if entity:get_is_enemy() == true then
            reformat_enemies = true
            self._enemy_sprites[entity] = nil
        else
            reformat_allies = true
            self._party_sprites[entity] = nil
            -- TODO: remove UI
        end
    end

    if reformat_allies then self:_reformat_party_sprites() end
    if reformat_enemies then self:_reformat_enemy_sprites() end
end

--- @override
function bt.BattleScene:size_allocate(x, y, width, height)
    self._background:fit_into(x, y, width, height)

    local tile_size = rt.settings.menu.inventory_scene.tile_size
    local m = rt.settings.margin_unit
    local outer_margin = rt.settings.menu.inventory_scene.outer_margin

    self._global_status_bar:fit_into(
        x + width - outer_margin - tile_size, y + outer_margin,
        tile_size, height - 2 * outer_margin
    )

    local text_box_w = width - 2 * outer_margin - 2 * tile_size - 2 * m
    self._text_box:fit_into(
        x + 0.5 * width - 0.5 * text_box_w, y + outer_margin,
        text_box_w, tile_size
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

    self:_reformat_enemy_sprites()
    self:_reformat_party_sprites()

    if self._is_first_size_allocate then
        self:skip()
        self._is_first_size_allocate = false
    end
end

--- @brief
function bt.BattleScene:_reformat_enemy_sprites()
    local total_w, max_h = 0, NEGATIVE_INFINITY
    for sprite in values(self._enemy_sprites) do
        local w, h = sprite:measure()
        total_w = total_w + w
        max_h = math.max(max_h, h)
    end

    local m = rt.settings.margin_unit
    local outer_margin = 2 * m
    local width = 4 / 3 * self._bounds.height
    local tile_size = rt.settings.menu.inventory_scene.tile_size

    local x = self._bounds.x + 0.5 * self._bounds.width - 0.5 * width
    local y = self._bounds.y + outer_margin + tile_size + m
    local height = 0.5 * self._bounds.height + max_h
    local n_enemies = sizeof(self._enemy_sprites)

    local sprite_m = math.min(m, (width - total_w) / (n_enemies - 1))
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height

    self._enemy_sprites_render_order = {}
    local i_to_enemy_sprite = {}
    do
        local i = 1
        for sprite in values(self._enemy_sprites) do
            i_to_enemy_sprite[i] = sprite
            i = i + 1
        end
    end

    -- precompute aabbs
    local sprite_i_to_aabb = {}
    local left_x, right_x
    do
        local center_sprite = i_to_enemy_sprite[1]
        local sprite_w, sprite_h = center_sprite:measure()
        sprite_i_to_aabb[1] = rt.AABB(
            center_x - 0.5 * sprite_w,
            center_y - sprite_h,
            sprite_w, sprite_h
        )

        left_x = center_x - 0.5 * sprite_w - m
        right_x = center_x + 0.5 * sprite_w + m
        table.insert(self._enemy_sprites_render_order, center_sprite)
    end

    local min_x, max_x = POSITIVE_INFINITY, NEGATIVE_INFINITY
    do
        local sprite_i = 2
        while sprite_i <= n_enemies do
            local sprite = i_to_enemy_sprite[sprite_i]
            local sprite_w, sprite_h = sprite:measure()
            if sprite_i % 2 == 0 then
                sprite_i_to_aabb[sprite_i] = rt.AABB(right_x, center_y - sprite_h, sprite_w, sprite_h)
                right_x = right_x + sprite_w + m
            else
                sprite_i_to_aabb[sprite_i] = rt.AABB(left_x - sprite_w, center_y - sprite_h, sprite_w, sprite_h)
                left_x = left_x - sprite_w - m
            end

            min_x = left_x - sprite_w
            max_x = right_x + sprite_w

            table.insert(self._enemy_sprites_render_order, sprite)
            sprite_i = sprite_i + 1
        end
    end

    local sprite_to_motion_backup = {}
    for sprite, motion in pairs(self._enemy_sprites_motion) do
        sprite_to_motion_backup[sprite] = motion
    end
    self._enemy_sprites_motion = {}

    local motion_speed = rt.settings.battle.battle_scene.enemy_sprite_speed
    local enemy_sprite_x_offset = ((x - min_x) + (x + width - max_x)) / 2
    assert(enemy_sprite_x_offset ~= NEGATIVE_INFINITY)
    local sprite_i = 1
    for sprite in values(self._enemy_sprites) do
        local old = sprite:get_bounds()
        local aabb = sprite_i_to_aabb[sprite_i]
        local new = rt.AABB(
            (aabb.x + enemy_sprite_x_offset), aabb.y,
            aabb.width, aabb.height
        )

        local motion = sprite_to_motion_backup[sprite]
        if motion == nil then
            motion = rt.SmoothedMotion1D(0, motion_speed)
            motion:set_target_value(0)
        else
            motion:set_value(old.x - new.x)
        end
        self._enemy_sprites_motion[sprite] = motion

        sprite:fit_into(new)
        sprite_i = sprite_i + 1
    end
end

--- @brief
function bt.BattleScene:_reformat_party_sprites()
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

    for sprite in values(self._party_sprites) do
        sprite:fit_into(sprite_x, sprite_y, sprite_w, sprite_h)
        sprite_x = sprite_x + sprite_w + m
    end
end

--- @override
function bt.BattleScene:draw()
    self._background:draw()

    for sprite in values(self._party_sprites) do
        sprite:draw()
    end

    for sprite in values(self._enemy_sprites_render_order) do
        local motion = self._enemy_sprites_motion[sprite]
        love.graphics.push()
        love.graphics.translate(motion:get_value(), 0)
        sprite:draw()
        love.graphics.pop()
    end

    for widget in range(
        self._text_box,
        self._priority_queue,
        self._global_status_bar,
        self._quicksave_indicator
    ) do
        widget:draw()
    end

    self._animation_queue:draw()
end

--- @override
function bt.BattleScene:update(delta)
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
function bt.BattleScene:set_priority_order(entities)
    self._priority_queue:reorder(entities)
end

--- @brief
function bt.BattleScene:get_text_box()
    return self._text_box
end

--- @brief
function bt.BattleScene:get_sprite(entity)
    meta.assert_isa(entity, bt.Entity)
    if entity:get_is_enemy() then
        return self._enemy_sprites[entity]
    else
        return self._party_sprites[entity]
    end
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
        sprite:skip()
    end

    for motion in values(self._enemy_sprites_motion) do
        motion:skip()
    end

    for sprite in values(self._party_sprites) do
        sprite:skip()
    end

    for to_skip in range(
        self._priority_queue,
        self._global_status_bar,
        self._animation_queue
    ) do
        to_skip:skip()
    end
end

--- @brief
function bt.BattleScene:_handle_button_pressed(which)
    if which == rt.InputButton.A then
        local target = self._state:list_enemies()[1]
        self._env.kill(bt.create_entity_proxy(self, target))
        --self:remove_entity(self._state:list_enemies()[1])
    elseif which == rt.InputButton.B then
        self:skip()
    end
end