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

        _entity_to_sprite = {},

        _party_sprites = {}, -- Table<bt.PartySprite>
        _party_sprites_motion = {}, -- Table<bt.PartySprite, bt.SmoothedMotion2D>

        _enemy_sprites = {}, -- Table<bt.EnemySprites>
        _enemy_sprites_render_order = meta.make_weak({}),
        _enemy_sprites_motion = {}, -- Table<bt.EnemySprite, bt.SmoothedMotion1D>

        _input = rt.InputController(),
        _animation_queue = rt.AnimationQueue(),

        _is_first_size_allocate = true
    })

    out._background:set_implementation(rt.Background.EYE) -- TODO
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
    return self._entity_to_sprite[entity]
end

--- @override
function bt.BattleScene:create_from_state()
    self._enemy_sprites = {}
    self._party_sprites = {}
    self._entity_to_sprite = {}

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
        local sprite
        if entity:get_is_enemy() == true then
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
        self._entity_to_sprite[entity] = sprite
        assert(self._entity_to_sprite[entity] == sprite)
    end

    if reformat_allies then self:reformat_party_sprites() end
    if reformat_enemies then self:reformat_enemy_sprites() end
end

--- @brief
function bt.BattleScene:remove_entity(...)
    local reformat_enemies, reformat_allies = false, false

    for entity in range(...) do
        local sprite = self:get_sprite(entity)
        if sprite ~= nil then
            if entity:get_is_enemy() then
                for i, other in ipairs(self._enemy_sprites) do
                    if other == sprite then
                        table.remove(self._enemy_sprites, i)
                        break
                    end
                end
            else
                for i, other in ipairs(self._party_sprites) do
                    if other == sprite then
                        table.remove(self._party_sprites, i)
                        break
                    end
                end
            end
        end
        self._entity_to_sprite[entity] = nil
    end

    if reformat_allies then self:reformat_party_sprites() end
    if reformat_enemies then self:reformat_enemy_sprites() end
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

    local text_box_w = (4 / 3 * self._bounds.height) - 2 * outer_margin - 2 * tile_size
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

    local sprite_order = {1}
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
    self._background:draw()

    --[[
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
    ]]--
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
function bt.BattleScene:push_animation(...)
    self._animation_queue:push(...)
end

--- @brief
function bt.BattleScene:append_animation(...)
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

    for motion in values(self._party_sprites_motion) do
        motion:skip()
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
function bt.BattleScene:_handle_button_pressed(which)
    if which == rt.InputButton.A then
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
    elseif which == rt.InputButton.B then
        self:skip()
    elseif which == rt.InputButton.DEBUG then
        self._background:set_implementation(rt.Background.SQUIGGLY_DANCE)
    end
end