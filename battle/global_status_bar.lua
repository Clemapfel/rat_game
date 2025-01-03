--- @class bt.GlobalStatusBar
bt.GlobalStatusBar = meta.new_type("GlobalStatusBar", rt.Widget, rt.Updatable, function()
    return meta.new(bt.GlobalStatusBar, {
        _ordered_box = bt.OrderedBox(),
        _global_status_to_sprite = {}, -- Table<bt.GlobalStatusConfig, rt.Sprite>
        _frame = rt.Frame(),
        _bounds = rt.AABB(0, 0, 1, 1),
        _frame_thickness = 0,
        _max_item_h = NEGATIVE_INFINITY,

        _motion = rt.SmoothedMotion1D(0),
    })
end)

--- @override
function bt.GlobalStatusBar:realize()
    if self:already_realized() then return end
    self._ordered_box:realize()
    self._frame:realize()
end

--- @override
function bt.GlobalStatusBar:size_allocate(x, y, width, height)
    self._frame_thickness = self._frame:get_thickness()
    -- resize on add
end

--- @override
function bt.GlobalStatusBar:update(delta)
    self._ordered_box:update(delta)
    self._motion:update(delta)
end

--- @brief
function bt.GlobalStatusBar:add_global_status(status, n_turns_left)
    meta.assert_isa(status, bt.GlobalStatusConfig)
    meta.assert_number(n_turns_left)

    if self._global_status_to_sprite[status] ~= nil then
        self:set_global_status_n_turns_left(status, n_turns_left)
        return
    end

    local sprite = rt.Sprite(status:get_sprite_id())
    if n_turns_left ~= POSITIVE_INFINITY then
        sprite:set_bottom_right_child("<o>" .. n_turns_left .. "</o>")
    end
    sprite:set_minimum_size(sprite:get_resolution())

    local sprite_w, sprite_h = sprite:measure()
    local m = rt.settings.margin_unit
    -- allocate on first item
    if sprite_h > self._max_item_h then
        self._max_item_h = sprite_h
        local x, y, w, h = rt.aabb_unpack(self._bounds)
        local screen_w = love.graphics.getWidth()
        local box_h = sprite_h + 2 * m + 2 * self._frame_thickness
        self._frame:fit_into(0, y + 0.5 * h - 0.5 * box_h, screen_w, box_h)
        self._ordered_box:fit_into(0 + m, y + 0.5 * h - 0.5 * sprite_h, screen_w, sprite_h)
        self._motion:set_value(screen_w + m)
        self:_update_frame_position()
    end

    self._global_status_to_sprite[status] = sprite
    self._ordered_box:add(sprite, true)

    self:_update_frame_position()
end

--- @override
function bt.GlobalStatusBar:draw()
    love.graphics.push()
    love.graphics.translate(self._motion:get_value(), 0)
    self._frame:draw()
    self._ordered_box:draw()
    love.graphics.pop()
end

--- @brief
function bt.GlobalStatusBar:_update_frame_position()
    local max_x = self._bounds.x
    local m = rt.settings.margin_unit

    local total_sprite_w = 0
    for sprite in values(self._global_status_to_sprite) do
        total_sprite_w = total_sprite_w + select(1, sprite:measure())
    end

    if total_sprite_w == 0 then
        self._motion:set_target_value(love.graphics.getWidth() + m)
    else
        self._motion:set_target_value(love.graphics.getWidth() - 2 * m - total_sprite_w)
    end
end

--- @brief
function bt.GlobalStatusBar:remove_global_status(status)
    meta.assert_isa(status, bt.GlobalStatusConfig)

    local sprite = self._global_status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt.GlobalStatsuBar:remove_global_status: global status `" .. status:get_id() .. "` is not present")
        return
    end

    self._global_status_to_sprite[status] = nil
    self._ordered_box:remove(sprite)

    self:_update_frame_position()
end

--- @brief
function bt.GlobalStatusBar:set_global_status_n_turns_left(status, n_turns_left)
    meta.assert_isa(status, bt.GlobalStatusConfig)
    meta.assert_number(n_turns_left)

    local sprite = self._global_status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt.GlobalStatusBar:set_global_status_n_turns_left: global status `" .. status:get_id() .. "` is not present")
        return
    end

    if n_turns_left == POSITIVE_INFINITY then
        sprite:set_bottom_right_child("")
    else
        sprite:set_bottom_right_child("<o>" .. n_turns_left .. "</o>")
    end
end

--- @brief
function bt.GlobalStatusBar:activate_global_status(status, on_done_notify)
    meta.assert_isa(status, bt.GlobalStatusConfig)

    local sprite = self._global_status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt.GlobalStatusBar:activate_global_status: status `" .. status:get_id() .. "` is not present")
        return
    end

    self._ordered_box:activate(sprite, on_done_notify)
end

--- @brief
function bt.GlobalStatusBar:clear()
    self._ordered_box:clear()
    self._global_status_to_sprite = {}
    self:_update_frame_position()
    self:reformat()
end

--- @brief
function bt.GlobalStatusBar:skip()
    self._ordered_box:skip()
    self._motion:skip()
end

--- @brief
function bt.GlobalStatusBar:get_selection_nodes()
    local nodes = {}
    local n = 0
    local offset_x = self._motion:get_target_value()
    for global_status, sprite in pairs(self._global_status_to_sprite) do
        local bounds = self._ordered_box:get_widget_bounds(sprite)
        bounds.x = bounds.x + offset_x
        bounds.y = bounds.y
        local node = rt.SelectionGraphNode(bounds)
        node.object = global_status
        table.insert(nodes, node)
        n = n + 1
    end

    table.sort(nodes, function(a, b)
        return a:get_bounds().x < b:get_bounds().x
    end)

    for i = 1, n do
        local node = nodes[i]
        if i > 1 then
            node:set_left(nodes[i - 1])
        end

        if i < n then
            node:set_right(nodes[i + 1])
        end
    end

    return nodes
end