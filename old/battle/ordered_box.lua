rt.settings.battle.ordered_box = {
    max_scale = 2,
    scale_speed = 2.5,      -- fraction per second
    opacity_speed = 1.2,    -- fraction per second
    speed = 300, -- px per second
}

bt.OrderedBoxPositioning = meta.new_enum("OrderedBoxPositioning", {
    LEFT = true,
    RIGHT = false
})

--- @class bt.OrderedBox
bt.OrderedBox = meta.new_type("OrderedBox", rt.Widget, function()
    local out = meta.new(bt.OrderedBox, {
        _widget_to_item = {}, -- Table<rt.Widget, cf. add>
        _widget_order = {},
        _opacity = 1,
    })
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

        current_opacity = 0,
        target_opacity = 1,

        current_scale = 1,
        target_scale = 1,

        position_animation = nil, -- rt.SmoothedMotion2D
        current_position_x = nil,
        current_position_y = nil,

        on_scale_reached = {}, -- Table<Function>
        on_opacity_reached_0 = nil, -- Function
    }

    self._widget_to_item[widget] = to_add
    table.insert(self._widget_order, widget)

    if self._is_realized then
        widget:realize()
        self:reformat()
        self:update(0)
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

--- @override
function bt.OrderedBox:update(delta)
    for item in values(self._widget_to_item) do
        -- update position
        item.position_animation:update(delta)
        item.current_position_x, item.current_position_y = item.position_animation:get_position()
        item.current_position_x = math.floor(item.current_position_x)
        item.current_position_y = math.floor(item.current_position_y)

        -- update scale
        local scale_speed = rt.settings.battle.ordered_box.scale_speed

        if item.current_scale < item.target_scale then
            item.current_scale = item.current_scale + scale_speed * delta
            if item.current_scale > item.target_scale then
                item.current_scale = item.target_scale
            end

            if item.current_scale >= item.target_scale then
                item.target_scale = 1
                for f in values(item.on_scale_reached) do
                    f(item.widget)
                end
                item.on_scale_reached = {}
            end
        elseif item.current_scale > item.target_scale then
            item.current_scale = item.current_scale - scale_speed * delta
            if item.current_scale < item.target_scale then
                item.current_scale = item.target_scale
            end
        end

        -- update opacity
        local fade_speed = rt.settings.battle.ordered_box.scale_speed
        local before = item.current_opacity
        if item.current_opacity < item.target_opacity then
            item.current_opacity = clamp(item.current_opacity + fade_speed * delta, 0, item.target_opacity)
        elseif item.current_opacity > item.target_opacity then
            item.current_opacity = clamp(item.current_opacity - fade_speed * delta, 0)
            if item.current_opacity <= 0 and item.on_opacity_reached_0 ~= nil then
                item.on_opacity_reached_0(item.widget)
                item.on_opacity_reached_0 = nil
            end
        end

        if item.current_opacity ~= before then
            item.widget:set_opacity(item.current_opacity * self._opacity)
        end
    end
end

--- @override
function bt.OrderedBox:realize()
    if self:already_realized() then return end

    for item in values(self._widget_to_item) do
        item.widget:realize()
    end
end

--- @override
function bt.OrderedBox:draw()
    for widget in values(self._widget_order) do
        local item = self._widget_to_item[widget]
        if item.position_animation ~= nil then -- size_allocate called
            rt.graphics.push()
            local w, h = item.size_x, item.size_y
            local x_translate, y_translate = item.current_position_x - 0.5 * w, item.current_position_y - 0.5 * h
            rt.graphics.translate(x_translate, y_translate)
            rt.graphics.translate(0.5 * w, 0.5 * h)
            rt.graphics.scale(item.current_scale)
            rt.graphics.translate(-0.5 * w, -0.5 * h)

            item.widget:draw()
            rt.graphics.pop()
        end
    end
end

--- @override
function bt.OrderedBox:size_allocate(x, y, width, height)
    local left_x, left_y = x, y
    local right_x, right_y = x + width, y
    local item_h = height
    local item_w = item_h

    local total_left_item_w = 0
    local total_right_item_w = 0
    local n_left_items = 0
    local n_right_items = 0
    local largest_w = 0
    for widget in values(self._widget_order) do
        local item = self._widget_to_item[widget]
        item.widget:fit_into(0, 0, item_w, item_h)
        item.size_x, item.size_y = item.widget:measure()
        item.size_x = math.max(item.size_x, item_w)
        item.size_y = math.max(item.size_y, item_h)

        if item.left_or_right == true then
            total_left_item_w = total_left_item_w + item.size_x
            n_left_items = n_left_items + 1
        else
            total_right_item_w = total_right_item_w + item.size_x
            n_right_items = n_right_items + 1
        end

        largest_w = math.max(largest_w, item.size_x)
    end

    local m = rt.settings.margin_unit
    local left_item_m = math.min((0.5 * width - total_left_item_w)  / (n_left_items - 1), 0)
    local right_item_m = math.min((0.5 * width - total_right_item_w) / (n_right_items - 1), 0)

    for widget in values(self._widget_order) do
        local item = self._widget_to_item[widget]
        local target_position_x, target_position_y
        if item.left_or_right == true then
            target_position_x, target_position_y = left_x + 0.5 * item_w, left_y + 0.5 * item_h
            left_x = left_x + item_w + left_item_m
        else
            target_position_x, target_position_y = right_x - 0.5 * item_w, right_y + 0.5 * item_h
            right_x = right_x - item_w - right_item_m
        end

        if item.current_position_x == nil then
            item.current_position_x = x + 0.5 * width
        end

        if item.current_position_y == nil then
            item.current_position_y = y + 0.5 * height
        end

        if item.position_animation == nil then
            item.position_animation = rt.SmoothedMotion2D(item.current_position_x, item.current_position_y, rt.settings.battle.ordered_box.speed)
        end
        item.position_animation:set_target_position(target_position_x, target_position_y)
    end

    self:update(0)
end

--- @brief
function bt.OrderedBox:activate(widget, on_activate_done)
    local item = self._widget_to_item[widget]
    if item == nil then
        rt.error("In bt.OrderedBox:activate: widget `" .. meta.typeof(widget) .. "` is not part of box")
        return
    end

    item.target_scale = rt.settings.battle.ordered_box.max_scale
    table.insert(item.on_scale_reached, on_activate_done)
end

--- @brief
function bt.OrderedBox:skip()
    if not self._is_realized then return end

    for item in values(self._widget_to_item) do
        item.current_scale = 1
        item.target_scale = 1
        for f in values(item.on_scale_reached) do
            f(item.widget)
        end
        item.on_scale_reached = {}

        if item.target_opacity == 0 then
            item.current_opacity = 0
            if item.on_opacity_reached_0 ~= nil then
                item.on_opacity_reached_0(item.widget)
                item.on_opacity_reached_0 = nil
            end
        else
            item.current_opacity = 1
            item.target_opacity = 1
        end
        item.widget:set_opacity(item.current_opacity)

        item.position_animation:skip()
    end
end

--- @brief
function bt.OrderedBox:set_opacity(alpha)
    self._opacity = alpha
    for item in values(self._widget_to_item) do
        item.widget:set_opacity(item.current_opacity * self._opacity)
    end
end

--- @brief
function bt.OrderedBox:clear()
    self._widget_to_item = {}
    self._widget_order = {}
end

--- @brief
function bt.OrderedBox:get_widget_bounds(widget)
    local item = self._widget_to_item[widget]
    if item == nil then
        rt.error("In bt.OrderedBox.get_widget_bounds: item `" .. meta.typeof(widget) .. "` is not present")
        return rt.AABB(0, 0, 1, 1)
    end

    local x, y = item.position_animation:get_target_position()
    x = x - 0.5 * item.size_x
    y = y - 0.5 * item.size_y
    return rt.AABB(x, y, item.size_x, item.size_y)
end