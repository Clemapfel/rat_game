rt.settings.ordered_box = {
    max_scale = 2,
    collider_radius = 100,
    collider_mass = 50,
    collider_speed = 4000,        -- px per second

    scale_speed = 2.5,      -- fraction per second
    opacity_speed = 1.2,    -- fraction per second
}

--- @brief
bt.OrderedBox = meta.new_type("OrderedBox", rt.Widget, function()
    local out = meta.new(bt.OrderedBox, {
        _widget_to_item = {}, -- Table<rt.Widget, cf. add>
        _widget_order = {},
        _world = b2.World(0, 0),
        _opacity = 1
    })
    --meta.make_weak(out._widget_order, true, true)
    return out
end)

--- @brief
function bt.OrderedBox:add(widget, left_or_right)
    meta.assert_isa(widget, rt.Widget)
    if left_or_right == nil then left_or_right = true end

    local to_add = {
        widget = widget,
        left_or_right = left_or_right,
        size_x = 0,
        size_y = 0,
        current_position_x = self._bounds.x + 0.5 * self._bounds.width,
        current_position_y = self._bounds.y + 0.5 * self._bounds.height,
        target_position_x = 0,
        target_position_y = 0,
        current_opacity = 0,
        target_opacity = 1,
        current_scale = 2,
        target_scale = 1,

        body = nil, -- set on first size allocate
        shape = nil,

        on_scale_reached = nil, -- function
        on_opacity_reached_0 = nil, -- function
    }

    self._widget_to_item[widget] = to_add
    table.insert(self._widget_order, widget)

    if self._is_realized then
        widget:realize()
        self:reformat()
    end
end

--- @override
function bt.OrderedBox:update(delta)
    local item_speed = 1000
    for item in values(self._widget_to_item) do
        local current_x, current_y = item.body:get_centroid()
        local target_x, target_y = item.target_position_x, item.target_position_y
        local distance = rt.distance(current_x, current_y, target_x, target_y)
        local angle = rt.angle(target_x - current_x, target_y - current_y)
        local magnitude = item_speed

        local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
        item.body:apply_linear_impulse(vx, vy)
        local damping = magnitude / (4 * distance)
        item.body:set_linear_damping(damping)

        item.current_position_x, item.current_position_y = item.body:get_centroid()
    end

    self._world:step(delta)
end

--- @override
function bt.OrderedBox:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for item in values(self._widget_to_item) do
        item.widget:realize()
    end
end

--- @override
function bt.OrderedBox:size_allocate(x, y, width, height)
    local left_x, left_y = x, y
    local right_x, right_y = x + width, y
    local item_h = height
    local item_w = item_h

    local total_item_w = 0
    local n_items = 0
    for item in values(self._widget_to_item) do
        item.widget:fit_into(0, 0, item_w, item_h)
        item.size_x, item.size_y = item.widget:measure()
        item.size_x = math.max(item.size_x, item_w)
        item.size_y = math.max(item.size_y, item_h)

        n_items = n_items + 1
        total_item_w = total_item_w + item.size_x
    end

    local item_m = math.min((width - total_item_w) / (n_items + 1), rt.settings.margin_unit)
    for item in values(self._widget_to_item) do
        if item.left_or_right == true then
            item.target_position_x, item.target_position_y = left_x + 0.5 * item_w, left_y + 0.5 * item_h
            left_x = left_x + item_w + item_m
        else
            item.target_position_x, item.target_position_y = right_x - 0.5 * item_w, right_y + 0.5 * item_h
            right_x = right_x - item_w - item_m
        end

        item.current_position_x, item.current_position_y = x + 0.5 * width, y + 0.5 * height

        if item.body ~= nil then
            item.body:destroy()
        end

        item.shape = nil
        item.body = b2.Body(self._world, b2.BodyType.DYNAMIC, item.current_position_x, item.current_position_y)
        item.shape = b2.CircleShape(item.body, b2.Circle(item_h / 2))
        item.shape:set_collision_group(b2.CollisionGroup.NONE)
    end

    self:update(0)
end

--- @override
function bt.OrderedBox:draw()
    for item in values(self._widget_to_item) do
        local w, h = item.size_x, item.size_y
        local x_translate, y_translate = item.current_position_x - 0.5 * w, item.current_position_y - 0.5 * h
        rt.graphics.translate(x_translate, y_translate)
        item.widget:draw()
        rt.graphics.translate(-x_translate, -y_translate)
    end
end

--- @brief
function bt.OrderedBox:remove(widget, on_remove_done)
    local item = self._widget_to_item[widget]
    if item == nil then
        rt.error("In bt.OrderedBox:remove: widget `" .. meta.typeof(widget) .. "` is not part of box")
        return
    end

    item.target_opacity = 0
    item.on_opacity_reached_0 = function(widget)
        self._widget_to_item[widget] = nil
        for i, x in ipairs(self._widget_order) do
            if x == widget then
                table.remove(self._widget_order, i)
                break
            end
        end

        if on_remove_done ~= nil then
            on_remove_done(widget)
        end
        self:reformat()
    end
end

--- @brief
function bt.OrderedBox:activate(widget, on_activate_done)
    local item = self._widget_to_item[widget]
    if item == nil then
        rt.error("In bt.OrderedBox:activate: widget `" .. meta.typeof(widget) .. "` is not part of box")
        return
    end

    item.target_scale = 2
    item.on_scale_reached = function(widget)
        if on_activate_done ~= nil then
            on_activate_done(widget)
        end
    end
end

--- @brief
function bt.OrderedBox:skip()
    self:update(60)
end

--- @brief
function bt.OrderedBox:set_opacity(alpha)
    self._opacity = alpha
    for item in values(self._widget_to_item) do
        item.widget:set_opacity(item.current_opacity * self._opacity)
    end
end
