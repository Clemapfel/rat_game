rt.settings.battle.scene = {
    enemy_alignment_y = 0.5,
    horizontal_margin = 100,
}

--- @class bt.EnemySpriteAlignmentMode
bt.EnemySpriteAlignmentMode = meta.new_enum({
    EQUIDISTANT = 1,
    BOSS_CENTERED = 2
})

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Widget, function()
    local out = meta.new(bt.BattleScene, {
        _debug_draw_enabled = true,
        _entities = {}, -- Table<bt.Entity>

        _enemy_sprites = {},              -- Table<bt.EnemySprite>
        _enemy_sprite_render_order = {},  -- Queue<Number>
        _enemy_sprite_alignment_mode = bt.EnemySpriteAlignmentMode.BOSS_CENTERED,

        _log = {}, -- bt.BattleLog

        _enemy_alignment_line = {}, -- rt.Line
        _margin_left_line = {},
        _margin_center_line = {},
        _margin_right_line = {}
    })
    return out
end)

--- @brief
function bt.BattleScene:get_sprite(entity)
    for _, sprite in pairs(self._enemy_sprites) do
        if sprite._entity:get_id() == entity:get_id() then
            return sprite
        end
    end
end

--- @brief
function bt.BattleScene:realize()
    self._is_realized = true

    self._log = bt.BattleLog()
    self._log:realize()

    for _, sprite in pairs(self._enemy_sprites) do
        sprite:realize()
        sprite:set_is_visible(false)
        sprite:add_animation(bt.Animation.ENEMY_APPEARED(self, sprite))
    end
    self:reformat()
end

--- @brief
function bt.BattleScene:size_allocate(x, y, width, height)
    self:_reformat_enemy_sprites()

    local enemy_y = rt.graphics.get_height() * rt.settings.battle.scene.enemy_alignment_y
    self._enemy_alignment_line = rt.Line(0, enemy_y, rt.graphics.get_width(), enemy_y)
    local mx = rt.settings.battle.scene.horizontal_margin
    self._margin_left_line = rt.Line(mx, 0, mx, rt.graphics.get_height())
    self._margin_center_line = rt.Line(mx + 0.5 * (rt.graphics.get_width() - 2 * mx), 0, mx + 0.5 * (rt.graphics.get_width() - 2 * mx), rt.graphics.get_height())
    self._margin_right_line = rt.Line(rt.graphics.get_width() - mx, 0, rt.graphics.get_width() - mx, rt.graphics.get_height())

    local my = rt.settings.margin_unit
    self._log:fit_into(mx, my, rt.graphics.get_width() - 2 * mx, 5 * my)
end

--- @brief
function bt.BattleScene:add_stage(name, prefix)
    prefix = which(prefix, "assets/stages")
    local stage = bt.Stage(rt.current_scene._world, name, prefix)
    table.insert(self._stages, stage)
end

--- @brief
function bt.BattleScene:draw()
    for _, i in pairs(self._enemy_sprite_render_order) do
        self._enemy_sprites[i]:draw()
    end

    if self._debug_draw_enabled then
        self._enemy_alignment_line:draw()
        self._margin_left_line:draw()
        self._margin_center_line:draw()
        self._margin_right_line:draw()
    end

    self._log:draw()
end

--- @brief
function bt.BattleScene:update(delta)
    for _, sprite in ipairs(self._enemy_sprites) do
        sprite:update(delta)
    end

    self._log:update(delta)
end

--- @brief
function bt.BattleScene:get_debug_draw_enabled()
    return self._debug_draw_enabled
end

--- @brief
function bt.BattleScene:set_debug_draw_enabled(b)
    self._debug_draw_enabled = b
end

--- @brief
function bt.BattleScene:play_animation(entity, animation)
    local sprite = self:get_sprite(entity)
    sprite:add_animation(animation)
end

--- @brief
function bt.BattleScene:send_message(message)
    self._log:push_back(message)
end

--- @brief [internal]
function bt.BattleScene:_reformat_enemy_sprites()
    if #self._enemy_sprites == 0 then
        rt.error("In bt.BattleScene:_reformat_enemy_sprites: number of enemy sprites is 0")
    end
    local target_y = rt.graphics.get_height() * rt.settings.battle.scene.enemy_alignment_y
    local mx = rt.settings.battle.scene.horizontal_margin

    local alignment_mode = self._enemy_sprite_alignment_mode
    if alignment_mode == bt.EnemySpriteAlignmentMode.EQUIDISTANT then
        local total_w = rt.graphics.get_width() - 2 * mx
        local step = total_w / (#self._enemy_sprites - 1)
        for sprite_i, sprite in ipairs(self._enemy_sprites) do
            local target_x = mx + (sprite_i - 1) * step
            local w, h = sprite:measure()
            local x, y = target_x - 0.5 * w, target_y - 0.5 * h
            sprite:fit_into(x, y, w, h)
        end
    elseif alignment_mode == bt.EnemySpriteAlignmentMode.BOSS_CENTERED then
        local max_h = 0
        local total_w = 0
        for i = 1, #self._enemy_sprites do
            local w, h = self._enemy_sprites[i]:measure()
            max_h = math.max(max_h, h)
            total_w = total_w + w
        end

        -- y-alignment of sprite based on sprite height
        function h_to_y(h)
            return target_y - h -- + 0.25 * max_h
        end

        local center_x = 0.5 * rt.graphics.get_width()
        local w, h = self._enemy_sprites[1]:measure()
        self._enemy_sprites[1]:fit_into(center_x - 0.5 * w, h_to_y(h) )
        local left_offset, right_offset = w * 0.5, w * 0.5

        local m = math.min( -- if enemy don't fit on screen, stagger without violating outer margins
            rt.settings.margin_unit * 2,
                (rt.graphics.get_width() - 2 * rt.settings.battle.scene.horizontal_margin - total_w) / #self._enemy_sprites
        )
        for i = 2, #self._enemy_sprites do
            local sprite = self._enemy_sprites[i]
            w, h = sprite:measure()
            if i % 2 == 0 then
                left_offset = left_offset + w + m
                sprite:fit_into(center_x - left_offset, h_to_y(h))
            else
                sprite:fit_into(center_x + right_offset + m, h_to_y(h))
                right_offset = right_offset + w + m
            end
        end
    end

    -- render order: largest to smallest by width, minimizes occlusion on overlap
    self._enemy_sprite_render_order = {}
    for i = 1, #self._enemy_sprites do
        table.insert(self._enemy_sprite_render_order, i)
    end
    table.sort(self._enemy_sprite_render_order, function(a, b)
        local left_w = select(1, self._enemy_sprites[a]:measure())
        local right_w = select(1, self._enemy_sprites[b]:measure())
        return left_w > right_w
    end)
end

--- @brief [internal]
function bt.BattleScene:_update_id_offsets()
    local boxes = {}
    for _, entity in pairs(self._entities) do
        local type = entity._config_id
        if boxes[type] == nil then boxes[type] = {} end
        table.insert(boxes[type], entity)
    end

    for _, box in pairs(boxes) do
        if #box > 1 then
            for i, entity in ipairs(box) do
                entity:set_id_offset(i)
            end
        else
            box[1]:set_id_offset(0)
        end
    end
end

--- @brief
function bt.BattleScene:format_name(entity)
    local name
    if meta.isa(entity, bt.BattleEntity) then
        name = entity:get_name()
        if entity.is_enemy == true then
            name = "<color=ENEMY><b><o>" .. name .. "</o></b></color> "
        end
    else
        rt.error("In bt.BattleScene:get_formatted_name: unhandled entity type `" .. meta.typeof(entity) .. "`")
    end
    return name
end

--- @brief
function bt.BattleScene:format_hp(value)
    -- same as rt.settings.battle.health_bar.hp_color_100
    return "<color=LIGHT_GREEN_2><mono><b>" .. tostring(value) .. "</b></mono></color> HP"
end

--- @brief
function bt.BattleScene:format_damage(value)
    -- same as rt.settings.battle.health_bar.hp_color_10
    return "<color=RED><mono><b>" .. tostring(value) .. "</b></mono></color> HP"
end