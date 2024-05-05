rt.settings.battle.battle_ui = {
    log_n_lines_default = 3
}

bt.Animation = {}

--- @class bt.BattleUI
bt.BattleUI = meta.new_type("BattleUI", rt.Widget, rt.Animation, function()
    return meta.new(bt.BattleUI, {
        _log = {}, -- rt.TextBox
        _entities = {},  -- Set<bt.Entity>
        _enemy_sprites = {},              -- Table<bt.EnemySprite>
        _enemy_sprite_render_order = {},  -- Queue<Number>

        _animation_queue = {}, -- rt.AnimationQueue
    })
end)

--- @brief
function bt.BattleUI:realize()
    if self._is_realized then return end

    self._log = rt.TextBox()
    self._log:realize()

    self._animation_queue = rt.AnimationQueue()

    for entity in keys(self._entities) do
        if entity:get_is_enemy() then
            self:_add_enemy_sprite(entity)
        end
    end

    self._is_realized = true
end

--- @brief
function bt.BattleUI:_add_enemy_sprite(entity)
    local sprite = bt.EnemySprite(entity)
    table.insert(self._enemy_sprites, sprite)
    sprite:realize()
    self:_reformat_enemy_sprites()
end

--- @brief
function bt.BattleUI:_reformat_enemy_sprites()
    if not self._is_realized or #self._enemy_sprites == 0 then return end

    local max_h = 0
    local total_w = 0
    for i = 1, #self._enemy_sprites do
        local w, h = self._enemy_sprites[i]:measure()
        max_h = math.max(max_h, h)
        total_w = total_w + w
    end

    local mx = self._bounds.width * 1 / 16
    local center_x = self._bounds.x + self._bounds.width * 0.5
    local w, h = self._enemy_sprites[1]:measure()
    local left_offset, right_offset = w * 0.5, w * 0.5
    local m = math.min( -- if enemy don't fit on screen, stagger without violating outer margins
        rt.settings.margin_unit * 2,
        (self._bounds.width - 2 * mx - total_w) / (#self._enemy_sprites - 1)
    )
    total_w = total_w + (#self._enemy_sprites - 1) * m

    local target_y = self._bounds.y + self._bounds.height * 0.5 + 0.25 * h
    local n_enemies = sizeof(self._enemy_sprites)
    self._enemy_sprite_render_order = table.seq(n_enemies, 1, -1)

    -- order enemies with 1 at the center, subsequent distributed equally on the side
    local enemy_sprite_indices = { 1 }
    for i = 2, n_enemies, 2 do
        table.insert(enemy_sprite_indices, 1, i)
        if i < n_enemies then
            table.insert(enemy_sprite_indices, i + 1)
        end
    end

    local xy_positions = {}
    local x_offset = 0
    for i in values(enemy_sprite_indices) do
        local sprite = self._enemy_sprites[i]
        w, h = sprite:measure()
        xy_positions[i] = {
            clamp(mx + x_offset, mx),
            target_y - h
        }
        x_offset = x_offset + w + m
    end

    local x_offset = clamp(((self._bounds.width - 2 * mx) - total_w) * 0.5, 0)
    for i, xy in pairs(xy_positions) do
        self._enemy_sprites[i]:fit_into(xy[1] + x_offset, xy[2])
    end
end

--- @brief
function bt.BattleUI:get_log()
    return self._log
end

--- @brief
function bt.BattleUI:get_animation_queue()
    return self._animation_queue
end

--- @brief
function bt.BattleUI:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    self._log:set_n_visible_lines(rt.settings.battle.battle_ui.log_n_lines_default)

    local log_horizontal_margin = 2 * m
    local log_vertical_margin = m
    self._log:fit_into(
        log_horizontal_margin,
        log_vertical_margin,
        self._bounds.width - 2 * log_horizontal_margin,
        self._bounds.height * 1 / 4 - log_vertical_margin
    )

    self:_reformat_enemy_sprites()
end

--- @brief
function bt.BattleUI:update(delta)
    if not self._is_realized then return end
    self._animation_queue:update(delta)
    self._log:update(delta)
end

--- @brief
function bt.BattleUI:draw()
    if not self._is_realized then return end
    self._log:draw()

    for i in values(self._enemy_sprite_render_order) do
        self._enemy_sprites[i]:draw()
    end
end
