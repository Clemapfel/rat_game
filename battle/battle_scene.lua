rt.settings.battle.scene = {
    enemy_alignment_y = rt.graphics.get_height() * 0.5,
    horizontal_margin = 100,
}

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", function()
    local out = meta.new(bt.BattleScene, {
        _debug_draw_enabled = true,
        _enemy_sprites = {}, -- Table<bt.EnemySprite>

        _enemy_alignment_line = {}, -- rt.Line
        _margin_left_line = {},
        _margin_center_line = {},
        _margin_right_line = {}
    })

    return out
end)

--- @brief
function bt.BattleScene:realize()
    for _, sprite in pairs(self._enemy_sprites) do
        sprite:realize()
    end
    self:_reformat_enemy_sprites()

    local enemy_y = rt.settings.battle.scene.enemy_alignment_y
    self._enemy_alignment_line = rt.Line(0, enemy_y, rt.graphics.get_width(), enemy_y)
    local mx = rt.settings.battle.scene.horizontal_margin
    self._margin_left_line = rt.Line(mx, 0, mx, rt.graphics.get_height())
    self._margin_center_line = rt.Line(mx + 0.5 * (rt.graphics.get_width() - 2 * mx), 0, mx + 0.5 * (rt.graphics.get_width() - 2 * mx), rt.graphics.get_height())
    self._margin_right_line = rt.Line(rt.graphics.get_width() - mx, 0, rt.graphics.get_width() - mx, rt.graphics.get_height())
end

--- @brief
function bt.BattleScene:add_stage(name, prefix)
    prefix = which(prefix, "assets/stages")
    local stage = bt.Stage(rt.current_scene._world, name, prefix)
    table.insert(self._stages, stage)
end

--- @brief
function bt.BattleScene:draw()
    for _, sprite in pairs(self._enemy_sprites) do
        sprite:draw()
    end

    if self._debug_draw_enabled then
        self._enemy_alignment_line:draw()
        self._margin_left_line:draw()
        self._margin_center_line:draw()
        self._margin_right_line:draw()
    end
end

--- @brief
function bt.BattleScene:update(delta)
    self._world:update(delta)
    self._camera:update(delta)
    -- entities are updated automatically through rt.Animation
end

--- @brief
function bt.BattleScene:get_debug_draw_enabled()
    return self._debug_draw_enabled
end

--- @brief
function bt.BattleScene:set_debug_draw_enabled(b)
    self._debug_draw_enabled = b
end

--- @brief [internal]
function bt.BattleScene:_reformat_enemy_sprites()
    local target_y = rt.settings.battle.scene.enemy_alignment_y
    local mx = rt.settings.battle.scene.horizontal_margin

    local total_w = rt.graphics.get_width() - 2 * mx

    local step = total_w / (#self._enemy_sprites - 1)
    for sprite_i, sprite in ipairs(self._enemy_sprites) do
        local target_x = mx + (sprite_i - 1) * step
        local w, h = sprite:measure()
        local x, y = target_x - 0.5 * w, target_y - 0.5 * h
        sprite:fit_into(x, y, w, h)
    end
end