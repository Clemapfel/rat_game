--- @class bt.Scene
bt.Scene = meta.new_type("BattleScene", rt.Scene, function()
    return meta.new(bt.Scene, {
        _current_state = nil,
        _state_manager = {}, -- bt.SceneStateManager
        _input_controller = rt.InputController(),

        _log = {}, -- rt.TextBox
        _priority_queue = {}, -- bt.PriorityQueue
        _global_status_bar = {}, -- bt.GlobalStatusBar
        _background = nil,  -- bt.Background

        _enemy_sprites = {},              -- Table<bt.EnemySprite>
        _enemy_sprite_render_order = {},  -- Queue<Number>
        _party_sprites = {}, -- Table<bt.PartySprite>
        _gradient_right = {}, -- rt.LogGradient
        _gradient_left = {},  -- rt.LogGradient
        _fast_forward_indicator = {}, -- rt.FastForwardIndicator
    })
end)

--- @brief
function bt.Scene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._state_manager = bt.SceneStateManager(self)
    self._input_controller:signal_connect("pressed", function(_, button)
        if self._current_state ~= nil then
            self._current_state:handle_button_pressed(button)
        end

        if self._state_manager ~= nil then
            self._state_manager:handle_button_pressed(button)
        end
    end)

    self._input_controller:signal_connect("released", function(_, button)
        if self._current_state ~= nil then
            self._current_state:handle_button_released(button)
        end

        if self._state_manager ~= nil then
            self._state_manager:handle_button_released(button)
        end
    end)

    self._animation_queue = rt.AnimationQueue()

    self._log = rt.TextBox()
    self._log:realize()

    self._priority_queue = bt.PriorityQueue()
    self._priority_queue:realize()

    self._global_status_bar = bt.GlobalStatusBar()
    self._global_status_bar:realize()

    if self._background ~= nil then
        self._background:realize()
    end

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

    self._fast_forward_indicator = rt.FastForwardIndicator()
    self._fast_forward_indicator:realize()
end

--- @brief
function bt.Scene:size_allocate(x, y, width, height)
    if self._background ~= nil then
        self._background:fit_into(x, y, width, height)
    end

    local m = rt.settings.margin_unit
    self._log:set_n_visible_lines(rt.settings.battle.battle_ui.log_n_lines_default)

    local m = rt.settings.margin_unit * 2
    local mx = rt.settings.battle.priority_queue.outer_margin + rt.settings.battle.priority_queue.element_size * rt.settings.battle.priority_queue.first_element_scale_factor + m
    local log_horizontal_margin = mx
    local log_vertical_margin = m
    local log_aabb = rt.AABB(x + log_horizontal_margin,
        y + log_vertical_margin,
        width - 2 * log_horizontal_margin,
        height * 1 / 4 - log_vertical_margin)
    self._log:fit_into(log_aabb)

    self:_reformat_enemy_sprites(self._bounds.x, self._bounds.width)
    self:_reformat_party_sprites(log_aabb.x, log_aabb.width)

    local my = rt.settings.margin_unit
    local mx = my
    local priority_queue_width = rt.settings.battle.battle_ui.priority_queue_width
    local log_height = 5 * my
    self._priority_queue:fit_into(
        x + width - priority_queue_width,
        y,
        priority_queue_width,
        height
    )

    local gradient_width = 1 / 16 * width
    self._gradient_left:resize(x, y, gradient_width, height)
    self._gradient_right:resize(x + width - gradient_width, y, gradient_width, self._bounds.height)

    local party_min_x, party_min_y, party_max_x, party_max_y = POSITIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for sprite in values(self._party_sprites) do
        local bounds = sprite:get_bounds()
        party_min_x = math.min(party_min_x, bounds.x)
        party_min_y = math.min(party_min_y, bounds.y)
        party_max_x = math.max(party_max_x, bounds.x + bounds.width)
        party_max_y = math.max(party_max_y, bounds.y + bounds.height)
    end

    local status_h = select(2, self._global_status_bar:measure())
    self._global_status_bar:fit_into(0, party_min_y, party_min_x, party_max_y - party_min_y)

    self._fast_forward_indicator:fit_into(x + m, y + m, 5 * m, 2.5 * m)

    if self._current_state ~= nil then
        self._current_state:exit()
        self._current_state:enter()
    end
end

--- @brief
function bt.Scene:update(delta)
    if self._background ~= nil then
        self._background:update(delta)
    end

    if self._current_state ~= nil then
        self._current_state:update(delta)
    end
end

--- @brief
function bt.Scene:draw()
    if self._background ~= nil then
        self._background:draw()
    end

    --[[
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    self._gradient_left:draw()
    self._gradient_right:draw()
    rt.graphics.set_blend_mode()

    if self._current_state ~= nil then
        self._current_state:draw()
    end
    ]]--
end

--- @brief
function bt.Scene:set_background(background_id)
    if bt.Background[background_id] == nil then
        rt.error("In bt.Scene:set_background: no background with id `" .. background_id .. "`")
    end

    local background = bt.Background[background_id]()
    self._background = background

    if self._is_realized then
        background:realize()
        self._background:fit_into(self._bounds)
    end
end

--- @brief
function bt.Scene:add_entity_sprite(entity, ...)
    local to_add = {entity, ...}
    for e in values(to_add) do
        if e:get_is_enemy() then
            local sprite = bt.EnemySprite(entity)
            table.insert(self._enemy_sprites, sprite)
            sprite:realize()
        else
            local sprite = bt.PartySprite(entity)
            table.insert(self._party_sprites, sprite)
            sprite:realize()
        end
    end

    -- keep sprite order same as entity order in state
    local party_order = {}
    local enemy_order = {}
    for e in values(self._state:list_entities()) do
        if e:get_is_enemy() then
            enemy_order[e] = sizeof(enemy_order)
        else
            party_order[e] = sizeof(party_order)
        end
    end
    for sprites in range(self._enemy_sprites, self._party_sprites) do
        table.sort(sprites, function(a, b)
            if a:get_entity():get_is_enemy() and b:get_entity():get_is_enemy() then
                return enemy_order[a:get_entity()] < enemy_order[b:get_entity()]
            else
                return party_order[a:get_entity()] < party_order[b:get_entity()]
            end
        end)
    end

    self:reformat()
end

--- @brief
function bt.Scene:remove_entity_sprite(entity, ...)
    local should_remove = {}
    for e in range(entity, ...) do
        should_remove[e] = true
    end

    local to_remove = {}
    for i, sprite in ipairs(self._enemy_sprites) do
        if should_remove[sprite:get_entity()] then
            table.insert(to_remove, i)
        end
    end
    table.sort(to_remove, function(a, b) return b < a end)
    for i in values(to_remove) do
        table.remove(self._enemy_sprites, i)
    end

    to_remove = {}
    for i, sprite in ipairs(self._party_sprites) do
        if should_remove[sprite:get_entity()] then
            table.insert(to_remove, i)
        end
    end
    table.sort(to_remove, function(a, b) return b < a end)
    for i in values(to_remove) do
        table.remove(self._party_sprites, i)
    end

    self:reformat()
end

--- @brief
function bt.Scene:_reformat_enemy_sprites(x, width)
    if not self._is_realized or #self._enemy_sprites == 0 then
        self._enemy_sprite_render_order = {}
        return
    end

    local max_h = 0
    local total_w = 0
    for i = 1, #self._enemy_sprites do
        local w, h = self._enemy_sprites[i]:measure()
        max_h = math.max(max_h, h)
        total_w = total_w + w
    end

    local mx = rt.settings.battle.priority_queue.outer_margin + rt.settings.battle.priority_queue.element_size
    local center_x = x + width * 0.5
    local w, h = self._enemy_sprites[1]:measure()
    local left_offset, right_offset = w * 0.5, w * 0.5
    local m = math.min( -- if enemy don't fit on screen, stagger without violating outer margins
        rt.settings.margin_unit * 2,
        (width - 2 * mx - total_w) / (#self._enemy_sprites - 1)
    )
    total_w = total_w + (#self._enemy_sprites - 1) * m

    local target_y = self._bounds.y + self._bounds.height * 0.5 + 0.25 * max_h
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
            clamp(x + mx + x_offset, mx),
            target_y - h
        }
        x_offset = x_offset + w + m
    end

    local x_offset = clamp(((width - 2 * mx) - total_w) * 0.5, 0)
    for i, xy in pairs(xy_positions) do
        self._enemy_sprites[i]:fit_into(xy[1] + x_offset, xy[2])
    end
end

--- @brief
function bt.Scene:_reformat_party_sprites(x, width)
    local n_sprites = sizeof(self._party_sprites)
    local thickness = rt.settings.battle.priority_queue_element.frame_thickness
    local m = rt.settings.margin_unit + thickness
    local mx = rt.settings.battle.priority_queue.outer_margin + rt.settings.battle.priority_queue.element_size + m

    local default_w_n_sprites = 3
    local w = math.min((width - (n_sprites - 1) * (m + 2 * thickness)) / n_sprites, (width - (default_w_n_sprites - 1) * (m + 2 * thickness)) / default_w_n_sprites)
    local h = self._bounds.height * (3 / 9)
    local y = self._bounds.y + self._bounds.height - h
    x = x + 0.5 * width - 0.5 * (n_sprites * w + (n_sprites - 1) * m)

    for i = 1, n_sprites do
        local sprite = self._party_sprites[i]
        sprite:fit_into(x, y, w, h)
        x = x + w + m
    end
end

--- @brief
function bt.Scene:get_sprite(entity)
    for sprite in values(self._enemy_sprites) do
        if sprite:get_entity():get_id() == entity:get_id() then
            return sprite
        end
    end

    for sprite in values(self._party_sprites) do
        if sprite:get_entity():get_id() == entity:get_id() then
            return sprite
        end
    end
end


--- @brief
function bt.Scene:set_selected(entities, unselect_others)
    unselect_others = which(unselect_others, true)
    self._priority_queue:set_selected(entities, unselect_others)

    local is_selected = {}
    for entity in values(entities) do
        is_selected[entity] = true
    end

    for entity in values(self._state:list_entities()) do
        local sprite = self:get_sprite(entity)
        if is_selected[entity] == true then
            sprite:set_selection_state(bt.SelectionState.SELECTED)
        else
            if unselect_others == true then
                sprite:set_selection_state(bt.SelectionState.UNSELECTED)
            else
                sprite:set_selection_state(bt.SelectionState.INACTIVE)
            end
        end
    end
end

--- @brief
function bt.Scene:set_unselected(entities)
    for entity in values(entities) do
        local sprite = self:get_sprite(entity)
        sprite:set_selection_state(bt.SelectionState.UNSELECTED)
    end
end

--- @brief
function bt.Scene:clear()
    self._enemy_sprites = {}
    self._enemy_sprite_render_order = {}
    self._party_sprites = {}
    self._entities = {}

    self._log:clear()
    self._priority_queue:reorder({})
    self._animation_queue._animations = {}
end

--- @brief
function bt.Scene:skip()
    self._animation_queue:skip()
    self._priority_queue:skip()
    self._global_status_bar:skip()

    for sprite in values(self._enemy_sprites) do
        sprite:skip()
    end

    for sprite in values(self._party_sprites) do
        sprite:skip()
    end
end

--- @brief
function bt.Scene:format_name(entity)
    local name
    if meta.isa(entity, bt.Entity) then
        name = entity:get_name()
        if entity.is_enemy == true then
            name = "<color=ENEMY><b>" .. name .. "</b></color> "
        end
    elseif meta.isa(entity, bt.Status) then
        name = "<b><i>" .. entity:get_name() .. "</b></i>"
    elseif meta.isa(entity, bt.GlobalStatus) then
        name = "<b><i>" .. entity:get_name() .. "</b></i>"
    elseif meta.isa(entity, bt.Equip) then
        name = "<b>" .. entity:get_name() .. "</b>"
    elseif meta.isa(entity, bt.Consumable) then
        name = "<b>" .. entity:get_name() .. "</b>"
    elseif meta.isa(entity, bt.Move) then
        name = "<b><u>" .. entity:get_name() .. "</u></b>"
    else
        rt.error("In bt.Scene:get_formatted_name: unhandled entity type `" .. meta.typeof(entity) .. "`")
    end
    return name
end

--- @brief
function bt.Scene:play_animations(...)
    self._animation_queue:push(...)
end

--- @brief
function bt.Scene:append_animations(...)
    self._animation_queue:append(...)
end

--- @brief
function bt.Scene:show_log()
    self._log:set_is_closed(false)
end

--- @brief
function bt.Scene:hide_log()
    self._log:set_is_closed(true)
end

--- @brief
function bt.Scene:send_message(text, jump_to_newest)
    self._log:append(text, which(jump_to_newest, true))
end

--- @brief
function bt.Scene:get_are_messages_done()
    return self._log:get_is_scrolling_done()
end

--- @brief
function bt.Scene:set_priority_order(order)
    self._priority_queue:reorder(order)
end

--- @brief
function bt.Scene:get_is_priority_reorder_done()
    return self._priority_queue:get_is_reorder_done()
end

--- @brief
function bt.Scene:set_state(entity, state)
    self._priority_queue:set_state(entity, state)
    self:get_sprite(entity):set_state(state)
end