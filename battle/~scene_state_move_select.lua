rt.settings.battle.scene.move_select = {
    show_hide_button = rt.InputButton.X,
}

--[[
App view
Top bar: inherent abilitis
hrule
app view below
scroll bar on the left
verbose info next to each tile
]]--

--- @class bt.SceneState.MOVE_SELECT
bt.SceneState.MOVE_SELECT = meta.new_type("MOVE_SELECT", function(scene)
    local out = meta.new(bt.SceneState.MOVE_SELECT, {
        _scene = scene,
        _control_indicator = {}, -- rt.ControlIndicator
        _area = rt.AABB(0, 0, 1, 1),

        _user = scene._state:list_party()[1],
        _items = {}, -- Table<bt.MoveSelectionItem>
        _verbose_info = bt.VerboseInfo(),
        _selected_item_i = 1,
    })

    return out
end)

--- @brief [internal]
function bt.SceneState.MOVE_SELECT:_create()
    local scene = self._scene
    local bounds = scene:get_bounds()
    local m = rt.settings.margin_unit

    self._area = rt.AABB(
        scene._priority_queue._final_position_x,
        scene._priority_queue._final_position_y,
        scene._priority_queue._final_width,
        scene._priority_queue._final_height
    )

    local priority_queue_x, priority_queue_y = scene._priority_queue:get_position()
    local priority_queue_width, priority_queue_height = scene._priority_queue:measure()
    local control_w, control_h = self._control_indicator:measure()
    local party_sprite_x, party_sprite_y = scene._party_sprites[1]:get_position()
    local x_align, y_align = 2 * m, control_h + m
    self._area = rt.AABB(
       x_align,
       y_align,
        priority_queue_x - x_align - m,
        party_sprite_y - y_align
    )

    local moveset = {}
    for move in values(self._user:list_moves()) do
        table.insert(moveset, 1, move)
    end

    local current_x, current_y = bounds.x, bounds.y
    self._items = {}
    for move in values(self._user:list_moves()) do
        local to_insert = bt.MoveSelectionItem(move, self._user:get_move_n_uses_left(move))
        to_insert:realize()
        to_insert:fit_into(current_x, current_y, 100, 100)
        table.insert(self._items, to_insert)
    end

    self._verbose_info:realize()
    self._verbose_info:fit_into(
        0, 0,
        self._area.width - self._area.x + max_w + m,
        self._area.height
    )
    self._verbose_info_offset_x = self._area.x + max_w + m + 2 * m
    self:_update_selection()
end

--- @brief [internal]
function bt.SceneState.MOVE_SELECT:_update_selection()
    for i = 1, #self._items do
        local item = self._items[i]
        if i == self._selected_item_i then
            item:set_selection_state(bt.SelectionState.SELECTED)
        else
            item:set_selection_state(bt.SelectionState.INACTIVE)
        end
    end

    local scene = self._scene
    for entity in values(scene._state:list_entities()) do
        local sprite = scene:get_sprite(entity)
        if entity == self._user then
            sprite:set_selection_state(bt.SelectionState.INACTIVE)
        else
            sprite:set_selection_state(bt.SelectionState.UNSELECTED)
        end
    end

    local targets = {}, {}
    local move = self._items[self._selected_item_i]._move
    local can_target_enemies = (self._user:get_is_enemy() == true and move:get_can_target_ally()) or (self._user:get_is_enemy() == false and move:get_can_target_enemy())
    local can_target_self = move:get_can_target_self()
    local can_target_party = (self._user:get_is_enemy() == true and move:get_can_target_enemy()) or (self._user:get_is_enemy() == false and move:get_can_target_ally())

    for entities in range(scene._state:list_enemies(), scene._state:list_party()) do
        for entity in values(entities) do
            if entity == self._user and can_target_self then
                targets[entity] = true
            elseif entity:get_is_enemy() == true and can_target_enemies then
                targets[entity] = true
            elseif entity:get_is_enemy() == false and can_target_party then
                targets[entity] = true
            else
                targets[entity] = false
            end
        end
    end

    for entity, state in pairs(targets) do
        if state == true then
            scene._priority_queue:set_selection_state(entity, bt.SelectionState.SELECTED)
        else
            scene._priority_queue:set_selection_state(entity, bt.SelectionState.UNSELECTED)
        end
    end

    self._verbose_info:show({move})
    local verbose_w, verbose_h = self._verbose_info:measure()
    self._verbose_info_offset_y = self._area.height * 0.5 - 0.5 * verbose_h
end

--- @override
function bt.SceneState.MOVE_SELECT:handle_button_pressed(button)
    local scene = self._scene

    if button == rt.InputButton.Y then
        self._scene:transition(bt.SceneState.INSPECT)
    end

    if button == rt.InputButton.UP then
        self._selected_item_i = clamp(self._selected_item_i - 1, 1, #self._items)
        self:_update_selection()
    elseif button == rt.InputButton.DOWN then
        self._selected_item_i = clamp(self._selected_item_i + 1, 1, #self._items)
        self:_update_selection()
    end
end

--- @override
function bt.SceneState.MOVE_SELECT:handle_button_released(button)
end

--- @override
function bt.SceneState.MOVE_SELECT:enter()
    local scene = self._scene

    scene._global_status_bar:synchronize(scene._state)
    while not scene._animation_queue:get_is_empty() do
        scene._animation_queue:skip()
    end

    if not meta.isa(self._control_indicator, rt.ControlIndicator) then
        self._control_indicator = rt.ControlIndicator()
        self._control_indicator:realize()
    end

    local prefix, postfix = "<o>", "</o>"
    self._control_indicator:create_from({
        {rt.ControlIndicatorButton.B, prefix .. "Back" .. postfix},
        {rt.ControlIndicatorButton.A, prefix .. "Select Move" .. postfix},
        {rt.ControlIndicatorButton.Y, prefix .. "Inspect" .. postfix}
    })
    self._control_indicator:fit_into(scene:get_bounds())
    self:_create()
end

--- @override
function bt.SceneState.MOVE_SELECT:exit()

    for entity in self._scene._state:list_entities() do
        self._scene:get_sprite(entity):set_selection_state(bt.SelectionState.INACTIVE)
        self._scene._priority_queue:set_selection_state(bt.SelectionState.INACTIVE)
    end
end

--- @override
function bt.SceneState.MOVE_SELECT:update(delta)
    local scene = self._scene

    scene._global_status_bar:update(delta)
    scene._priority_queue:update(delta)

    for item in values(self._items) do
        item:update(delta)
    end
end

--- @override
function bt.SceneState.MOVE_SELECT:draw()
    local scene = self._scene

    for sprites in range(scene._party_sprites, scene._enemy_sprites) do
        for sprite in values(sprites) do
            sprite:draw()
            bt.BattleSprite.draw(sprite)
        end
    end

    scene._global_status_bar:draw()
    scene._priority_queue:draw()

    self._control_indicator:draw()

    love.graphics.setColor(1, 0, 1, 0.6)
    love.graphics.rectangle("fill", self._area.x, self._area.y, self._area.width, self._area.height)

    rt.graphics.translate(self._verbose_info_offset_x, self._verbose_info_offset_y)
    self._verbose_info:draw()
    rt.graphics.translate(-1 * self._verbose_info_offset_x, -1 * self._verbose_info_offset_y)

    for item in values(self._items) do
       item:draw()
    end
end