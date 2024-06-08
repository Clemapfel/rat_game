rt.settings.battle.move_selection = {
    sprite_icon_size = 64
}

--[[
Information on Screen:
+ who is selecting entity
+ selecting entity hp, status
+ global status
+ priority queue
+ priority queue preview
+ already selected party member moves, + order
+ possible targets (cf. priority queue)
+ list of possible moves
+ sorting modes
+ keyboard binding: a = select, b = back, y = sort: <by>, x = inspect

+ turn count
]]--

bt.MoveSelection = meta.new_type("MoveSelection", rt.Widget, function()
    return meta.new(bt.MoveSelection, {
        _world = rt.PhysicsWorld(0, 0),
        _nodes = {},    -- cf. create_from
        _sortings = {},  -- Table<Number>
        _sort_mode = bt.MoveSelection.SortMode.DEFAULT,
        _user = {},     -- bt.Entity
        _position_x = 0,
        _position_y = 0,
    })
end)

bt.MoveSelection.SortMode = meta.new_enum({
    DEFAULT = 1,
    BY_NAME = 2,
    BY_N_USES_LEFT = 3
})

--- @brief
function bt.MoveSelection:_regenerate_sortings()
    local default = {}
    local by_name = {}
    local by_n_uses_left = {}

    for node_i, _ in ipairs(self._nodes) do
        for to_insert_into in range(default, by_name, by_n_uses_left) do
            table.insert(to_insert_into, node_i)
        end
    end

    table.sort(by_name, function(a_i, b_i)
        local a_node, b_node = self._nodes[a_i], self._nodes[b_i]
        return utf8.less_than(a_node.move:get_name(), b_node.move:get_name())
    end)

    table.sort(by_n_uses_left, function(a_i, b_i)
        local a_node, b_node = self._nodes[a_i], self._nodes[b_i]
        return self._user:get_move_n_uses_left(a_node.move) > self._user:get_move_n_uses_left(b_node.move)
    end)

    self._sortings = {}
    self._sortings[bt.MoveSelection.SortMode.DEFAULT] = default
    self._sortings[bt.MoveSelection.SortMode.BY_NAME] = by_name
    self._sortings[bt.MoveSelection.SortMode.BY_N_USES_LEFT] = by_n_uses_left
end

--- @brief
function bt.MoveSelection:set_sort_mode(mode)
    self._sort_mode = mode
    self:reformat()
end

--- @brief
function bt.MoveSelection:_format_n_uses_label(n)
    if n == POSITIVE_INFINITY then
        return ""
    else
        return "<o>" .. tostring(n) .. "</o>"
    end
end

--- @brief
function bt.MoveSelection:_format_move_name(name)
    return "<b>" .. name .. "</b>"
end

--- @brief
function bt.MoveSelection:create_from(user, moves)
    meta.assert_isa(user, bt.Entity)

    local w = rt.settings.battle.move_selection.sprite_icon_size
    local m = rt.settings.margin_unit
    local origin_x, origin_y = 0, 0
    self._user = user
    self._nodes = {}
    for move in values(moves) do
        local to_insert = {
            move = move,
            sprite = rt.LabeledSprite(move:get_sprite_id()),
            label = rt.Label(self:_format_move_name(move:get_name())),
            collider = rt.CircleCollider(
                self._world,
                rt.ColliderType.DYNAMIC,
                0, 0,
                rt.settings.ordered_box.collider_radius
            ),
            target_position_x = origin_x,
            target_position_y = origin_y
        }

        to_insert.collider:set_collision_group(rt.ColliderCollisionGroup.NONE)
        to_insert.collider:set_mass(rt.settings.ordered_box.collider_mass)

        local x, y = -0.5 * w, -0.5 * w

        to_insert.sprite:set_label(self:_format_n_uses_label(self._user:get_move_n_uses_left(to_insert.move)))
        to_insert.sprite:realize()
        to_insert.sprite:set_scale(2)
        to_insert.sprite:fit_into(x, y, w, w)

        to_insert.label:realize()
        local label_h = select(2, to_insert.label:measure())
        to_insert.label:fit_into(x + w + m, y + 0.5 * w - 0.5 * label_h, POSITIVE_INFINITY, w)

        table.insert(self._nodes, to_insert)
    end

    self:_regenerate_sortings()
end

--- @brief
function bt.MoveSelection:size_allocate(x, y, width, height)
    if self._is_realized == false then return end
    self._position_x, self._position_y = x, y

    local current_x, current_y = 0, 0
    local sorting = self._sortings[self._sort_mode]
    for node_i in values(sorting) do
        local node = self._nodes[node_i]
        node.target_position_x = current_x
        node.target_position_y = current_y

        local bounds = node.sprite:get_bounds()
        current_y = current_y + bounds.height
    end
end

--- @brief
function bt.MoveSelection:update(delta)
    self._world:update(delta)

    for node in values(self._nodes) do
        local current_x, current_y = node.collider:get_position()
        local target_x, target_y = node.target_position_x, node.target_position_y
        local distance = rt.distance(current_x, current_y, target_x, target_y)
        local angle = rt.angle(target_x - current_x, target_y - current_y)
        local magnitude = rt.settings.ordered_box.collider_speed
        local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
        node.collider:apply_linear_impulse(vx, vy)
        local damping = magnitude / (4 * distance)
        node.collider:set_linear_damping(damping)
    end
end

--- @brief
function bt.MoveSelection:draw()
    if self._is_realized == false then return end

    rt.graphics.push()
    rt.graphics.translate(self._position_x, self._position_y)
    for node in values(self._nodes) do
        local x, y = node.collider:get_position()
        rt.graphics.push()
        rt.graphics.translate(x, y)
        node.sprite:draw()
        node.label:draw()
        rt.graphics.pop()
    end
    rt.graphics.pop()

    self:draw_bounds()
end