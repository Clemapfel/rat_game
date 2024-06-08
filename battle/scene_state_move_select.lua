rt.settings.battle.scene.move_select = {
    show_hide_button = rt.InputButton.X,
}

bt.MoveSelectionItem = meta.new_type("MoveSelectionItem", rt.Widget, function(move, n_uses)
    return meta.new(bt.MoveSelectionItem, {
        _sprite = {},
        _label = {},
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _move = move,
        _n_uses = n_uses,
    })
end)

function bt.MoveSelectionItem:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._sprite = rt.LabeledSprite(self._move:get_sprite_id())
    self._label = rt.Label(self._move:get_name())

    for widget in range(self._sprite, self._label) do
        widget:realize()
    end
end

function bt.MoveSelectionItem:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    self._sprite:set_sprite_scale(2)
    local sprite_w, sprite_h = self._sprite:measure()
    self._sprite:fit_into(x, y, sprite_w, sprite_h)

    local label_w, label_h = self._label:measure()
    self._label:fit_into(x + sprite_w + m, y + 0.5 * sprite_w - 0.5 * label_h, POSITIVE_INFINITY, POSITIVE_INFINITY)
end

function bt.MoveSelectionItem:draw()
    if self._is_realized ~= true then return end
    self._sprite:draw()
    self._label:draw()
end

function bt.MoveSelectionItem:measure()

    if self._is_realized ~= true then self:realize() end

    local m = rt.settings.margin_unit
    local sprite_w, sprite_h = self._sprite:measure()
    local label_w, label_h = self._label:measure()

    return sprite_w + m + label_w, math.max(sprite_h, label_h)
end

function bt.MoveSelectionItem:set_selection_state(state)
    -- TODO
end

--- @class bt.SceneState.MOVE_SELECT
bt.SceneState.MOVE_SELECT = meta.new_type("MOVE_SELECT", function(scene)
    local out = meta.new(bt.SceneState.MOVE_SELECT, {
        _scene = scene,
        _control_indicator = {}, -- rt.ControlIndicator
        _area = rt.AABB(0, 0, 1, 1),
        _items = {}, -- Table<bt.MoveSelectionItem>
        _box = {},  -- rt.OrderedBox
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

    self._box = rt.OrderedBox()

    self._items = {}

    for move in values(moveset) do
        local item = bt.MoveSelectionItem(move, user:get_move_n_uses_left(move))
        self._box:add(move, item)
    end

    self._box:set_orientation(rt.Orientation.HORIZONTAL)

    self._box:realize()
    self._box:fit_into(self._area)
end

--- @brief [internal]
function bt.SceneState.MOVE_SELECT:_update_selection()
end

--- @brief [internal]
function bt.SceneState.MOVE_SELECT:_update_control_indicator()
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
    self._box:draw()
    self._box:draw_bounds()

    love.graphics.setColor(1, 0, 1, 0.6)
    love.graphics.rectangle("fill", self._area.x, self._area.y, self._area.width, self._area.height)
end