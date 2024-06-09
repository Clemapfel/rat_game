rt.settings.battle.scene.move_select = {
    show_hide_button = rt.InputButton.X,
}

bt.MoveSelectionItem = meta.new_type("MoveSelectionItem", rt.Widget, function(move, n_uses)
    return meta.new(bt.MoveSelectionItem, {
        _sprite = {},
        _name_label = {},
        _description_label = {},
        _move = move,
        _n_uses = n_uses,
        _final_width = 0,
        _final_height = 0
    })
end)

function bt.MoveSelectionItem:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._sprite = rt.LabeledSprite(self._move:get_sprite_id())
    self._sprite:set_sprite_scale(3)
    self._sprite:set_label("<mono><o>" .. self._n_uses .. "</o></mono>")

    self._name_label = rt.Label("<b><o>" .. self._move:get_name() .. "</o></b>")
    self._description_label = rt.Label("<o>" .. self._move:get_description() .. "</o>", rt.settings.font.default_small, rt.settings.font.default_small)

    for widget in range(self._sprite, self._name_label, self._description_label) do
        widget:realize()
    end

    self._name_label:set_justify_mode(rt.JustifyMode.LEFT)
    self._description_label:set_justify_mode(rt.JustifyMode.LEFT)
end

function bt.MoveSelectionItem:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    self._sprite:set_sprite_scale(2)

    local current_x, current_y = x, y
    local sprite_w, sprite_h = self._sprite:measure()
    self._sprite:fit_into(current_x, current_y, sprite_w, sprite_h)

    current_y = current_y + sprite_w
    self._name_label:fit_into(current_x, current_y, width, height)
    local name_label_w, name_label_h = self._name_label:measure()

    current_y = current_y + name_label_h

    self._description_label:fit_into(current_x, current_y, name_label_w, height)
    current_y = current_y + select(2, self._description_label:measure())

    self._final_width = math.max(name_label_w, sprite_w)
    self._final_height = current_y - y
end

function bt.MoveSelectionItem:draw()
    if self._is_realized ~= true then return end
    self._sprite:draw()
    self._name_label:draw()
    self._description_label:draw()
end

function bt.MoveSelectionItem:measure()
    return self._final_width, self._final_height
end


--- @class bt.SceneState.MOVE_SELECT
bt.SceneState.MOVE_SELECT = meta.new_type("MOVE_SELECT", function(scene)
    local out = meta.new(bt.SceneState.MOVE_SELECT, {
        _scene = scene,
        _control_indicator = {}, -- rt.ControlIndicator
        _area = rt.AABB(0, 0, 1, 1),

        _items = {}, -- Table<bt.MoveSelectionItem>
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

    -- TODO
    local user = scene._state:list_party()[1]
    local moveset = user:list_moves()
    -- TODO

    self._items = {}
    for move in values({bt.Move("DEBUG_MOVE")}) do
        local to_insert = bt.MoveSelectionItem(move, user:get_move_n_uses_left(move))
        to_insert:realize()
        to_insert:fit_into(self._area)
        table.insert(self._items, to_insert)
    end
end

--- @override
function bt.SceneState.MOVE_SELECT:handle_button_pressed(button)
    local scene = self._scene
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
    })
    self._control_indicator:fit_into(scene:get_bounds())

    self:_create()
end

--- @override
function bt.SceneState.MOVE_SELECT:exit()
end

--- @override
function bt.SceneState.MOVE_SELECT:update(delta)
    local scene = self._scene

    scene._global_status_bar:update(delta)
    scene._priority_queue:update(delta)
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

    for item in values(self._items) do
        item:draw()
    end
end