rt.settings.battle.scene = {
    enemy_alignment_y = 0.5,
    priority_queue_width = 100,
    gradient_alpha = 0.4
}

--- @class bt.EnemySpriteAlignmentMode
bt.EnemySpriteAlignmentMode = meta.new_enum({
    EQUIDISTANT = 1,
    BOSS_CENTERED = 2
})

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Widget, function()
    local out = meta.new(bt.BattleScene, {
        _debug_draw_enabled = false,
        _entities = {}, -- Table<bt.Entity>

        _enemy_sprites = {},              -- Table<bt.EnemySprite>
        _enemy_sprite_render_order = {},  -- Queue<Number>
        _enemy_sprite_alignment_mode = bt.EnemySpriteAlignmentMode.BOSS_CENTERED,

        _priority_queue_is_visible = true,
        _priority_queue = {}, -- bt.PriorityQueue

        _log_is_visible = true,
        _log = {}, -- bt.BattleLog

        _debug_layout_lines = {}, -- Table<rt.Line>

        _gradient_right = {}, -- rt.LogGradient
        _gradient_left = {},  -- rt.LogGradient

        _animation_queue = bt.AnimationQueue(),
        _elapsed = 0,
    })
    return out
end)

--- @brief
function bt.BattleScene:realize()
    self._is_realized = true

    self:_update_id_offsets()
    self._log = bt.BattleLog()
    self._log:realize()

    self._priority_queue = bt.PriorityQueue(self)
    self._priority_queue:set_order(self._entities)
    self._priority_queue:set_preview_order(rt.random.shuffle(self._entities)) -- TODO: remove
    self._priority_queue:realize()

    local to = 1 - rt.settings.battle.scene.gradient_alpha
    local to_color = rt.RGBA(to, to, to, 1)
    local from_color = rt.RGBA(1, 1, 1, 1)

    local gradient_alpha = rt.settings.battle.scene.gradient_alpha
    self._gradient_left = rt.LogGradient(
        rt.RGBA(from_color.r, from_color.g, from_color.b, from_color.a),
        rt.RGBA(to_color.r, to_color.g, to_color.b, to_color.a)
    )

    self._gradient_right = rt.LogGradient(
        rt.RGBA(to_color.r, to_color.g, to_color.b, to_color.a),
        rt.RGBA(from_color.r, from_color.g, from_color.b, from_color.a)
    )

    for _, entity in pairs(self._entities) do
        entity:realize()
        local sprite = bt.EnemySprite(self, entity)
        table.insert(self._enemy_sprites, sprite)
        sprite:realize()
        sprite:add_animation(bt.Animation.ENEMY_APPEARED(self, sprite))
    end

    self:reformat()
end

--- @brief
function bt.BattleScene:size_allocate(x, y, width, height)
    self:_reformat_enemy_sprites()

    local enemy_y = rt.graphics.get_height() * rt.settings.battle.scene.enemy_alignment_y
    self._enemy_alignment_line = rt.Line(0, enemy_y, rt.graphics.get_width(), enemy_y)
    local mx = rt.graphics.get_width() * 1 / 16
    self._margin_left_line = rt.Line(mx, 0, mx, rt.graphics.get_height())
    self._margin_center_line = rt.Line(mx + 0.5 * (rt.graphics.get_width() - 2 * mx), 0, mx + 0.5 * (rt.graphics.get_width() - 2 * mx), rt.graphics.get_height())
    self._margin_right_line = rt.Line(rt.graphics.get_width() - mx, 0, rt.graphics.get_width() - mx, rt.graphics.get_height())

    local my = rt.settings.margin_unit
    local priority_queue_width = rt.settings.battle.scene.priority_queue_width
    self._log:fit_into(mx, my, rt.graphics.get_width() - 2 * mx, 5 * my)
    self._priority_queue:fit_into(rt.graphics.get_width() - priority_queue_width, 0, priority_queue_width, rt.graphics.get_height())

    local gradient_width = 1.5 * mx
    self._gradient_left:resize(0, 0, gradient_width, rt.graphics.get_height())
    self._gradient_right:resize(rt.graphics.get_width() - gradient_width, 0, gradient_width, rt.graphics.get_height())

    local length = width
    self._debug_layout_lines = {
        -- margin_left
        rt.Line(x + (0.5/16) * width, y, x + (0.5/16) * width, y + height),
        -- marign right
        rt.Line(x + (1 - 0.5/16) * width, y, x + (1 - 0.5/16) * width, y + height),
        -- margin top
        rt.Line(x, y + (0.5/9) * height, x + width, y + (0.5/9) * height),
        -- margin bottom
        rt.Line(x, y + (1 - 0.5/9) * height, x + width, y + (1 - 0.5/9) * height),
        -- left 4:3
        rt.Line(x + (3/16) * width, y, x + (3/16) * width, y + height),
        -- right 4:3
        rt.Line(x + (1 - 3/16) * width, y, x + (1 - 3/16) * width, y + height),
        -- horizontal center
        rt.Line(x, y + 0.5 * height, x + width, y + 0.5 * height),

        -- TODO
        rt.Line(0.25 * width, 0, 0.25 * width, height),
        rt.Line(0.75 * width, 0, 0.75 * width, height),
    }
end

--- @brief
function bt.BattleScene:add_entity(entity)
    table.insert(self._entities, entity)
    self:_update_id_offsets()

    if self._is_realized then
        if entity:get_is_enemy() then
            local sprite = bt.EnemySprite(self, entity)
            table.insert(self._enemy_sprites, sprite)
            sprite:realize()
            sprite:add_animation(bt.Animation.ENEMY_APPEARED(self, sprite))
        end

        self._priority_queue:reorder(self._entities)
        self._priority_queue:set_preview_order(rt.random.shuffle(self._entities))
        self:_reformat_enemy_sprites()
    end
end

--- @brief
function bt.BattleScene:draw()

    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    self._gradient_left:draw()
    self._gradient_right:draw()
    rt.graphics.set_blend_mode()

    for _, i in pairs(self._enemy_sprite_render_order) do
        self._enemy_sprites[i]:_draw()
    end

    for _, i in pairs(self._enemy_sprite_render_order) do
        self._enemy_sprites[i]:_draw_animations()
    end

    if self._debug_draw_enabled then
        for _, line in pairs(self._debug_layout_lines) do
            line:draw()
        end
    end

    if self._priority_queue_is_visible then
        self._priority_queue:draw()
    end

    if self._log_is_visible then
        self._log:draw()
    end
end

--- @brief
function bt.BattleScene:update(delta)
    self._elapsed = self._elapsed + delta
    for _, sprite in ipairs(self._enemy_sprites) do
        sprite:update(delta)
    end

    self._animation_queue:update(delta)
    self._log:update(delta)
end

--- @brief
function bt.BattleScene:get_elapsed()
    return self._elapsed
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
function bt.BattleScene:send_message(message)
    self._log:push_back(message)
end

--- @brief [internal]
function bt.BattleScene:_reformat_enemy_sprites()
    if #self._enemy_sprites == 0 then
        rt.error("In bt.BattleScene:_reformat_enemy_sprites: number of enemy sprites is 0")
    end
    local target_y = rt.graphics.get_height() * rt.settings.battle.scene.enemy_alignment_y
    local mx = rt.graphics.get_width() * 1 / 16

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
                (rt.graphics.get_width() - 2 * mx - total_w) / #self._enemy_sprites
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
function bt.BattleScene:get_entities()
    return self._entities
end

--- @brief
function bt.BattleScene:format_name(entity)
    local name
    if meta.isa(entity, bt.BattleEntity) then
        name = entity:get_name()
        if entity.is_enemy == true then
            name = "<color=ENEMY><b>" .. name .. "</b></color> "
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

--- @brief formated message insertions based on grammatical gender
function bt.BattleScene:format_pronouns(entity)
    local gender = entity.gender
    if gender == bt.Gender.NEUTRAL then
        return "it", "it", "its", "is"
    elseif gender == bt.Gender.MALE then
        return "he", "him", "his", "is"
    elseif gender == bt.Gender.FEMALE then
        return "she", "her", "hers", "is"
    elseif gender == bt.Gender.MULTIPLE or gender == bt.Gender.UNKNOWN then
        return "they", "their", "them", "are"
    else
        rt.error("In bt.BattleScene:format_prounouns: unhandled gender `" .. gender .. "` of entity `" .. entity:get_id() .. "`")
        return "error", "error", "error", "error"
    end
end

--- @brief
function bt.BattleScene:get_priority_queue()
    return self._priority_queue
end

--- @brief
function bt.BattleScene:skip()
    rt.AnimationQueue.skip()
    for sprite in values(self._enemy_sprites) do
        sprite:sync()
    end
end