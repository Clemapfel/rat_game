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
        _area = rt.AABB(0, 0, 1, 1),

        _user = scene._state:list_party()[1],
        _move_selection = bt.MoveSelection()
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
    local control_w, control_h = 0, 50 --self._control_indicator:measure()
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

    self._move_selection:create_from(self._user, moveset)
    self._move_selection:realize()
    self._move_selection:fit_into(self._area)
end

--- @brief [internal]
function bt.SceneState.MOVE_SELECT:_update_selection()
end

--- @override
function bt.SceneState.MOVE_SELECT:handle_button_pressed(button)
    local scene = self._scene

    if button == rt.InputButton.UP then
        self._move_selection:move_up()
    elseif button == rt.InputButton.RIGHT then
        self._move_selection:move_right()
    elseif button == rt.InputButton.DOWN then
        self._move_selection:move_down()
    elseif button == rt.InputButton.LEFT then
        self._move_selection:move_left()
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

    self:_create()
end

--- @override
function bt.SceneState.MOVE_SELECT:exit()
end

--- @override
function bt.SceneState.MOVE_SELECT:update(delta)
    local scene = self._scene
end

--- @override
function bt.SceneState.MOVE_SELECT:draw()
    local scene = self._scene

    self._move_selection:draw()
end