--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _state = state,

        _log = rt.TextBox(),
        _priority_queue = bt.PriorityQueue(),
        _verbose_info = mn.VerboseInfoPanel(),
        _sprites = {},        -- Table<bt.Entity, Union<bt.PartySprite, bt.EnemySprite>>
        _party_sprites = meta.make_weak({}), -- Table<bt.PartySprite>
        _enemy_sprites = meta.make_weak({}), -- Table<bt.EnemySprite>
        _move_selection = {}, -- Table<bt.Entity, cf. add_entity>
        _global_status_bar = bt.OrderedBox(),
        _input = rt.InputController(),

        _party_order_priority = {
            ["MC"] = 0,
            ["WILDCARD"] = 2,
            ["RAT"] = 2,
            ["PROF"] = 3,
            ["GIRL"] = 4,
            ["SCOUT"] = 5
        }
    })
end)

--- @override
function bt.BattleScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._log:realize()
    self._priority_queue:realize()
    self._verbose_info:realize()
    self._global_status_bar:realize()

    self:create_from_state()
end

--- @override
function bt.BattleScene:create_from_state()
    self._sprites = {}
    self._move_selection = {}

    for entity in values(self._state:list_entities()) do
        self:add_entity(entity)
    end
end

--- @override
function bt.BattleScene:add_entity(entity)
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
            intrinsics = intrinsic_slots
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
        -- todo enemy sprite
    end

    self:reformat()
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

    self:_reformat_party_sprites(
        x + outer_margin + tile_size + m,
        y + height - outer_margin,
        party_sprites_w,
        tile_size
    )
    self:_reformat_enemy_sprites()
end

--- @brief
function bt.BattleScene:_reformat_enemy_sprites(x, y, width, height)
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

--- @override
function bt.BattleScene:draw()
    for sprite in values(self._sprites) do
        sprite:draw()
    end

    for x in range(
        self._log,
        self._priority_queue,
        self._verbose_info,
        self._global_status_bar
    ) do
        x:draw()
        x:draw_bounds()
    end
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