rt.settings.battle.scene.move_select = {
    show_hide_button = rt.InputButton.X,
}

--- @class bt.SceneState.MOVE_SELECT
bt.SceneState.MOVE_SELECT = meta.new_type("MOVE_SELECT", function(scene)
    local out = meta.new(bt.SceneState.MOVE_SELECT, {
        _scene = scene,
        _area = rt.AABB(0, 0, 1, 1),

        _user = scene._state:list_party()[1],
        _move_selection = bt.MoveSelection(),
        _control_indicator = {}, -- rt.ControlIndicator
    })

    return out
end)

--- @brief [internal]
function bt.SceneState.MOVE_SELECT:_create()
    local scene = self._scene
    local bounds = scene:get_bounds()
    local m = rt.settings.margin_unit

    local priority_queue_x, priority_queue_y = scene._priority_queue:get_position()
    local priority_queue_width, priority_queue_height = scene._priority_queue:measure()
    local indicator_bounds = self._control_indicator:get_bounds()
    local party_sprite_x, party_sprite_y = scene._party_sprites[1]:get_position()
    local x_align, y_align = indicator_bounds.x, indicator_bounds.y + select(2, self._control_indicator:measure())
    self._area = rt.AABB(
        x_align,
        y_align + m,
        priority_queue_x - x_align - m,
        party_sprite_y - y_align - m
    )

    local moveset = {}
    for move in values(self._user:list_moves()) do
        table.insert(moveset, 1, move)
    end

    self._move_selection:create_from(self._user, moveset)
    self._move_selection:realize()
    self._move_selection:fit_into(self._area)
end

--- @brief [internal]
function bt.SceneState.MOVE_SELECT:_update_selection()
    local scene = self._scene
    local move = self._move_selection:get_selected_move()
    local user = self._move_selection:get_user()

    for entity in values(scene._state:list_entities()) do
        local sprite = scene:get_sprite(entity)
        if entity == self._user then
            sprite:set_selection_state(bt.SelectionState.INACTIVE)
        else
            sprite:set_selection_state(bt.SelectionState.UNSELECTED)
        end
    end

    if move == nil then
        for entity in values(scene._state:list_entities()) do
            scene._priority_queue:set_selection_state(entity, bt.SelectionState.UNSELECTED)
        end
    else
        local targets = {}, {}
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
    end
end

--- @override
function bt.SceneState.MOVE_SELECT:handle_button_pressed(button)
    local scene = self._scene

    if button == rt.InputButton.A then
        self._scene:transition(bt.SceneState.ENTITY_SELECT)
    elseif button == rt.InputButton.Y then
        self._scene:transition(bt.SceneState.INSPECT)
    end

    local should_update = true
    if button == rt.InputButton.UP then
        self._move_selection:move_up()
    elseif button == rt.InputButton.RIGHT then
        self._move_selection:move_right()
    elseif button == rt.InputButton.DOWN then
        self._move_selection:move_down()
    elseif button == rt.InputButton.LEFT then
        self._move_selection:move_left()
    else
        should_update = false
    end

    if should_update then
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

    local prefix, postfix = "<o>", "</o>"
    if not meta.isa(self._control_indicator, rt.ControlIndicator) then
        self._control_indicator = rt.ControlIndicator()
        self._control_indicator:realize()
    end
    self._control_indicator:create_from({
        {rt.ControlIndicatorButton.ALL_DIRECTIONS, prefix .. "Select Move" .. postfix},
        {rt.ControlIndicatorButton.A, prefix .. "Accept" .. postfix},
        {rt.ControlIndicatorButton.B, prefix .. "Back" .. postfix},
        {rt.ControlIndicatorButton.Y, prefix .. "Inspect" .. postfix}
    })

    local indicator_bounds = scene:get_bounds()
    local m = 2 * rt.settings.margin_unit
    indicator_bounds.x = m
    indicator_bounds.y = m
    indicator_bounds.width = indicator_bounds.width - 2 * m
    indicator_bounds.height = indicator_bounds.width - 2 * m
    self._control_indicator:fit_into(indicator_bounds)
    self:_create()
    self:_update_selection()
end

--- @override
function bt.SceneState.MOVE_SELECT:exit()
    for entity in values(self._scene._state:list_entities()) do
        self._scene:get_sprite(entity):set_selection_state(bt.SelectionState.INACTIVE)
        self._scene._priority_queue:set_selection_state(entity, bt.SelectionState.INACTIVE)
    end
end

--- @override
function bt.SceneState.MOVE_SELECT:update(delta)
    local scene = self._scene
    for sprite in values(scene._party_sprites) do
        sprite:update(delta)
    end

    for sprite in values(scene._enemy_sprites) do
        sprite:update(delta)
    end

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
    self._move_selection:draw()
end