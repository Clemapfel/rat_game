--[[
Move Slots
Verbose Info
Party Sprite
Enemy Sprite
textbox


]]--

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _state = state,

        _temp = bt.OrderedBox(),
        _temp_objects = {},
        _temp_object_to_widget = {},

        _health = bt.HealthBar(0, 100),
        _speed = bt.SpeedValue(55),

        _log = rt.TextBox(),
        _priority_queue = bt.PriorityQueue(),

        _verbose_info = mn.VerboseInfoPanel(),
        _input = rt.InputController(),

        _entities = {}, -- Table<bt.Entity, cf. add_entity>
    })
end)

--- @brief
function bt.BattleScene:_add_item(object)
    local widget = rt.LabeledSprite(object:get_sprite_id())
    self._temp_object_to_widget[object] = widget
    self._temp:add(widget, not meta.isa(object, bt.Consumable))

    table.insert(self._temp_objects, object)
end

--- @override
function bt.BattleScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for object in range(
        bt.Status("DEBUG_STATUS"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.GlobalStatus("DEBUG_GLOBAL_STATUS")
    ) do
        self:_add_item(object)
    end

    self._temp:realize()
    self._health:realize()
    self._speed:realize()

    self._verbose_info:realize()
    self._verbose_info:set_frame_visible(false)

    self._log:realize()
    self._priority_queue:realize()

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

    for entity in values(self._state:list_entities()) do
        self:add_entity(entity)
    end

    for entity, entry in pairs(self._entities) do
        entry.sprite:realize()
    end
end

--- @override
function bt.BattleScene:create_from_state(state)
    self._log:clear()
end

--- @override
function bt.BattleScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local temp_w, temp_h = 0.5 * width, 50
    self._temp:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h, temp_w, temp_h)
    self._health:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h + 2 * temp_h, temp_w, temp_h)
    self._speed:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h + 3 * temp_h, temp_w, temp_h)


    local outer_margin = 2 * m
    local log_margin = 10 * outer_margin
    self._log:fit_into(log_margin, outer_margin, width - 2 * log_margin, height - 2 * outer_margin)

    local verbose_w = 0.3 * width
    self._verbose_info:fit_into(x + width - verbose_w - outer_margin, outer_margin, verbose_w, height - 2 * outer_margin)

    -- TODO
    self._verbose_info:show(bt.Status("DEBUG_STATUS"))
    -- TODO

    local xm, ym = self:_get_margin()

    local prio_w = xm
    local prio_x = x + width - prio_w
    local prio_y = y + ym
    local prio_h = height - 2 * ym
    self._priority_queue:fit_into(prio_x, prio_y, prio_w, prio_h)

    local party_sprites, enemy_sprites = {}, {}
    for entity, entry in pairs(self._entities) do
        if entity:get_is_enemy() == true then
            table.insert(enemy_sprites, entry.sprite)
        else
            table.insert(party_sprites, entry.sprite)
        end
    end

    self:_reformat_party_sprites(party_sprites)
    self:_reformat_enemy_sprites(enemy_sprites)
end

--- @brief [internal]
function bt.BattleScene:_get_margin()
    local width_4_by_3 = self._bounds.height * (4 / 3)
    local xm = (self._bounds.width - width_4_by_3) / 2
    local ym = 2 * rt.settings.margin_unit
    return xm, ym
end

--- @brief [internal]
function bt.BattleScene:_reformat_party_sprites(sprites)
    local m = rt.settings.margin_unit
    local xm, ym = self:_get_margin()
    local x = self._bounds.x + xm
    local width = self._bounds.width - 2 * xm

    local n_sprites = sizeof(sprites)
    local default_w_n_sprites = 3
    local frame_thickness = 0
    local w = math.min((width - (n_sprites - 1) * (m + 2 * frame_thickness)) / n_sprites, (width - (default_w_n_sprites - 1) * (m + 2 * frame_thickness)) / default_w_n_sprites)
    local h = self._bounds.height * (3 / 9)
    local y = self._bounds.y + self._bounds.height - h - ym
    x = x + 0.5 * width - 0.5 * (n_sprites * w + (n_sprites - 1) * m)

    for i = 1, n_sprites do
        local sprite = sprites[i]
        sprite:fit_into(x, y, w, h)
        x = x + w + m
    end
end

--- @brief [internal]
function bt.BattleScene:_reformat_enemy_sprites(sprites)

end

--- @override
function bt.BattleScene:draw()
    self._priority_queue:draw()

    for entry in values(self._entities) do
        entry.sprite:draw()
    end
end

--- @override
function bt.BattleScene:update(delta)
    self._temp:update(delta)
    self._health:update(delta)
    self._speed:update(delta)
    self._verbose_info:update(delta)
    self._log:update(delta)
    self._priority_queue:update(delta)
end

--- @override
function bt.BattleScene:make_active()
    self._is_active = true
end

--- @override
function bt.BattleScene:make_inactive()
    self._is_active = false
end

--- @brief
function bt.BattleScene:_handle_button_pressed(which)
    if which == rt.InputButton.A then
        local entities = {}
        local list = self._state:list_entities()
        for _ = 1, 5  do
            for entity in values(list) do
                table.insert(entities, entity)
            end
        end

        self._priority_queue:reorder(rt.random.shuffle(entities))
    elseif which == rt.InputButton.B then
        self._priority_queue:set_selection(rt.random.choose_multiple(self._state:list_entities(), 3), true)
    elseif which == rt.InputButton.Y then
        self._priority_queue:set_n_consumed(rt.random.integer(0, 4))
    end
end

--- @brief
function bt.BattleScene:add_entity(entity)
    if self._entities[entity] == nil then
        local entry = {
            sprite = nil, -- bt.EntitySprite
        }
        if entity:get_is_enemy() == false then
            entry.sprite = bt.PartySprite(entity)
        else
            -- TODo
        end

        if self._is_realized then
            entry.sprite:realize()
        end

        self._entities[entity] = entry
    end
end