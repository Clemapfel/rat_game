rt.settings.battle.battle_ui = {
    enemy_alignment_y = 0.75,
    priority_queue_width = 100,
    gradient_alpha = 0.4
}

--- @class bt.EnemySpriteAlignmentMode
bt.EnemySpriteAlignmentMode = meta.new_enum({
    EQUIDISTANT = 1,
    BOSS_CENTERED = 2
})

--- @class bt.BattleUI
bt.BattleUI = meta.new_type("BattleUI", rt.Widget, rt.Animation, bt.BattleAnimationTarget, function(scene)
    return meta.new(bt.BattleUI, {
        
        _scene = scene,
        _entities = {}, -- Table<bt.Entity, Boolean>

        _enemy_sprites_are_visible = true,
        _enemy_sprites = {},              -- Table<bt.EnemySprite>
        _enemy_sprite_render_order = {},  -- Queue<Number>
        _enemy_sprite_alignment_mode = bt.EnemySpriteAlignmentMode.BOSS_CENTERED,

        _party_sprites_are_visible = true,
        _party_sprites = {},

        _priority_queue_is_visible = true,
        _priority_queue = {}, -- bt.PriorityQueue

        _log_is_visible = true,
        _log = {}, -- bt.BattleLog

        _gradient_right = {}, -- rt.LogGradient
        _gradient_left = {},  -- rt.LogGradient

        _animation_queue = bt.AnimationQueue(),

        _music_path = "",
        _music_playback = {}, --

        _spectrum = {},
        _spectrum_elapsed = 0,
    })
end)

--- @brief
function bt.BattleUI:skip()
    bt.AnimationQueue.skip()
    for sprite in values(self._enemy_sprites) do
        sprite:sync()
    end
end

--- @override
function bt.BattleUI:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._log = bt.BattleLog(self._scene)
    self._log:realize()

    self._priority_queue = bt.PriorityQueue(self._scene)
    self._priority_queue:realize()

    -- gradients
    local gradient_alpha = rt.settings.battle.battle_ui.gradient_alpha
    local to = 1 - gradient_alpha
    local to_color = rt.RGBA(to, to, to, 1)
    local from_color = rt.RGBA(1, 1, 1, 1)

    self._gradient_left = rt.LogGradient(
        rt.RGBA(from_color.r, from_color.g, from_color.b, from_color.a),
        rt.RGBA(to_color.r, to_color.g, to_color.b, to_color.a)
    )

    self._gradient_right = rt.LogGradient(
        rt.RGBA(to_color.r, to_color.g, to_color.b, to_color.a),
        rt.RGBA(from_color.r, from_color.g, from_color.b, from_color.a)
    )

    for entity, initialized in pairs(self._entities) do
        if initialized == false then
            self:add_entity(entity)
        end
        self._entities[entity] = true
    end

    if self._music_path ~= "" then
        self._music_playback = rt.MonitoredAudioPlayback(self._music_path)
    end

    if meta.is_object(self._music_playback) then
        self._music_playback:play()
    end

    if meta.is_object(self._background) then
        self._background:realize()
        self._background:fit_into(self:get_bounds())
    end

    self:set_is_animated(true)
    self:reformat()
end

--- @override
function bt.BattleUI:update(delta)
    if self._is_realized then
        if meta.is_object(self._music_playback) then
            self._music_playback:update(delta)
        end

        if meta.is_object(self._background) then
            -- only fourier transforms at 30fps
            self._spectrum_elapsed = self._spectrum_elapsed + delta
            if #self._spectrum == 0 or self._spectrum_elapsed > 1 / 30 then
                self._spectrum = self._music_playback:get_current_spectrum(rt.settings.monitored_audio_playback.default_window_size, 128)
                self._spectrum_elapsed = 0
            end

            self._background:update(delta, self._spectrum)
        end
    end
end

--- @brief
function bt.BattleUI:size_allocate(x, y, width, height)
    self:_reformat_enemy_sprites()

    local enemy_y = rt.graphics.get_height() * rt.settings.battle.battle_ui.enemy_alignment_y
    self._enemy_alignment_line = rt.Line(0, enemy_y, rt.graphics.get_width(), enemy_y)
    local mx = rt.graphics.get_width() * 1 / 16
    self._margin_left_line = rt.Line(mx, 0, mx, rt.graphics.get_height())
    self._margin_center_line = rt.Line(mx + 0.5 * (rt.graphics.get_width() - 2 * mx), 0, mx + 0.5 * (rt.graphics.get_width() - 2 * mx), rt.graphics.get_height())
    self._margin_right_line = rt.Line(rt.graphics.get_width() - mx, 0, rt.graphics.get_width() - mx, rt.graphics.get_height())

    local my = rt.settings.margin_unit
    local priority_queue_width = rt.settings.battle.battle_ui.priority_queue_width
    local log_height = 5 * my
    self._log:fit_into(mx, my, rt.graphics.get_width() - 2 * mx, 5 * my)
    self._priority_queue:fit_into(rt.graphics.get_width() - priority_queue_width, 0, priority_queue_width, rt.graphics.get_height())
    local gradient_width = 1.5 * mx
    self._gradient_left:resize(0, 0, gradient_width, rt.graphics.get_height())
    self._gradient_right:resize(rt.graphics.get_width() - gradient_width, 0, gradient_width, rt.graphics.get_height())

    if meta.is_object(self._background) then
        self._background:fit_into(self:get_bounds())
    end
end

--- @override
function bt.BattleUI:measure()
    return rt.graphics.get_width(), rt.graphics.get_height()
end

--- @override
function bt.BattleUI:get_bounds()
    return rt.AABB(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
end

--- @brief
function bt.BattleUI:draw()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    if meta.is_object(self._background) then
        self._background:draw()
    end

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

    self._animation_queue:draw()

    if self._priority_queue_is_visible == true then
        self._priority_queue:draw()
    end

    if self._log_is_visible == true then
        self._log:draw()
    end
end

--- @brief
function bt.BattleUI:add_entity(entity)
    self._entities[entity] = false

    if self._is_realized == true then
        if entity:get_is_enemy() then
            local sprite = bt.EnemySprite(self._scene, entity)
            table.insert(self._enemy_sprites, sprite)
            sprite:realize()
        end

        self:_reformat_enemy_sprites()
        self._entities[entity] = true
    end
end

--- @brief
function bt.BattleUI:send_message(message)
    self._log:push_back(message)
end

--- @brief [internal]
function bt.BattleUI:_reformat_enemy_sprites()
    if not self._is_realized or #self._enemy_sprites == 0 then return end

    local target_y = rt.graphics.get_height() * rt.settings.battle.battle_ui.enemy_alignment_y
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

--- @brief
function bt.BattleUI:set_priority_order(order)
    self._priority_queue:set_order(order)
end

--- @brief
function bt.BattleUI:get_sprite(entity)
    if meta.isa(entity, bt.BattleEntity) then
        if entity:get_is_enemy() then
            for sprite in values(self._enemy_sprites) do
                if sprite:get_entity() == entity then
                    return sprite
                end
            end
            return nil
        else
            for sprite in values(self._party_sprites) do
                if sprite:get_entity() == entity then
                    return sprite
                end
            end
            return nil
        end
    elseif meta.isa(entity, bt.BattleScene) then
        return self
    else
        rt.error("In bt.BattleUI:get_sprite: unhandled entity type `" .. meta.typeof(entity) .. "`")
    end
end

--- @brief
function bt.BattleUI:set_music(music_path)
    self._music_path = music_path
    self._music_playback = rt.MonitoredAudioPlayback(self._music_path)
    if self._is_realized then
        self._music_playback:start()
    end
end

--- @brief
function bt.BattleUI:set_background(id)
    self._background = bt.BattleBackground(id)
    if self._is_realized then
        self._background:realize()
        self._background:fit_into(self:get_bounds())
    end
end

--- @brief
function bt.BattleUI:set_state(entity, state)
    self._priority_queue:set_state(entity, state)
    self:get_sprite(entity):set_state(state)
end