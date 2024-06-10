rt.settings.battle.scene.move_select = {
    show_hide_button = rt.InputButton.X,
}

bt.MoveSelectionItem = meta.new_type("MoveSelectionItem", rt.Widget, rt.Animation, function(move, n_uses)
    return meta.new(bt.MoveSelectionItem, {
        _sprite = {},
        _name_label = {},
        _description_label = {},
        _selection_state = bt.SelectionState.INACTIVE,
        _move = move,
        _n_uses = n_uses,
        _final_width = 0,
        _final_height = 0,
        _verbose_info = bt.VerboseInfo(),
        _verbose_info_offset_x = 0,
        _verbose_info_offset_y = 0
    })
end)

function bt.MoveSelectionItem:_update_label_text()
    local always_prefix = "<o>"
    local always_postfix = "</o>"

    if self._selection_state == bt.SelectionState.INACTIVE then
        self._name_label:set_text(always_prefix .. self._move:get_name() .. always_postfix)
        self._name_label:set_opacity(1)
    elseif self._selection_state == bt.SelectionState.SELECTED then
        self._name_label:set_text("<color=SELECTION><b>" .. always_prefix .. self._move:get_name() .. always_postfix .. "</b></color>")
        self._name_label:set_opacity(1)
    elseif self._selection_state == bt.SelectionState.UNSELECTED then
        self._name_label:set_text(always_prefix .. self._move:get_name() .. always_postfix)
        self._name_label:set_opacity(0.5)
    end
end

function bt.MoveSelectionItem:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._sprite = rt.LabeledSprite(self._move:get_sprite_id())
    self._sprite:set_sprite_scale(3)

    self._name_label = rt.Label()
    self:_update_label_text()

    for widget in range(self._sprite, self._name_label) do
        widget:realize()
    end

    self._name_label:set_justify_mode(rt.JustifyMode.LEFT)
end

function bt.MoveSelectionItem:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    self._sprite:set_sprite_scale(2)

    local current_x, current_y = x, y
    local sprite_w, sprite_h = self._sprite:measure()
    self._sprite:fit_into(current_x, current_y, sprite_w, sprite_h)

    current_x = current_x + sprite_w + 2 * m
    local name_label_w, name_label_h = self._name_label:measure()
    self._name_label:fit_into(current_x, current_y + 0.5 * sprite_h - 0.5 * name_label_h, width, height)

    self._final_width = sprite_w + m + name_label_w
    self._final_height = math.max(sprite_h, name_label_h)
end

function bt.MoveSelectionItem:draw()
    if self._is_realized ~= true then return end
    self._sprite:draw()
    self._name_label:draw()
end

function bt.MoveSelectionItem:measure()
    return self._final_width, self._final_height
end

function bt.MoveSelectionItem:set_selection_state(state)
    self._selection_state = state
    self:_update_label_text()
end

function bt.MoveSelectionItem:update(delta)
    self._name_label:update(delta)
end

--- @class bt.SceneState.MOVE_SELECT
bt.SceneState.MOVE_SELECT = meta.new_type("MOVE_SELECT", function(scene)
    local out = meta.new(bt.SceneState.MOVE_SELECT, {
        _scene = scene,
        _control_indicator = {}, -- rt.ControlIndicator
        _area = rt.AABB(0, 0, 1, 1),

        _user = scene._state:list_party()[1],
        _items = {}, -- Table<bt.MoveSelectionItem>
        _verbose_info = bt.VerboseInfo(),
        _selected_item_i = 1
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

    local moveset = self._user:list_moves()

    self._items = {}
    local max_w = NEGATIVE_INFINITY
    local current_x, current_y = self._area.x, self._area.y
    for move in values(moveset) do
        local to_insert = bt.MoveSelectionItem(move, self._user:get_move_n_uses_left(move))
        to_insert:realize()
        to_insert:fit_into(current_x, current_y, self._area.width, self._area.height)
        local item_w, item_h = to_insert:measure()
        current_y = current_y + item_h
        table.insert(self._items, to_insert)
        max_w = math.max(max_w, item_w)
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

    local to_show = {}
    for move in values(self._user:list_moves()) do
        table.insert(to_show, {move})
    end
    self._verbose_info:show(table.unpack(to_show))
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