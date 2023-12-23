rt.settings.swipe_layout = {
    indicator_radius = 100,
    scroll_speed_base = 1000, -- px per second
    scroll_speed_acceleration_factor = 10,
}

--- @class rt.SwipeLayout
rt.SwipeLayout = meta.new_type("SwipeLayout", function(orientation)
    orientation = which(orientation, rt.Orientation.HORIZONTAL)
    local out = meta.new(rt.SwipeLayout, {
        _children = rt.List(),
        _left_indicator = rt.DirectionIndicator(rt.Direction.LEFT),
        _right_indicator = rt.DirectionIndicator(rt.Direction.RIGHT),
        _up_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _down_indicator = rt.DirectionIndicator(rt.Direction.DOWN),
        _orientation = orientation,
        _current_element = 0,
        _offset = 0,
        _offset_target = 0,    -- x-offset / y -offset
        _slot_positions = {}, -- Table<rt.Vector2>
        _area = rt.AABB(0, 0, 1, 1),
        _elapsed = 0,
        _show_selection = true,
        _modifies_focus = true,
        _allow_wrap = true,
        _input = {}
    }, rt.Drawable, rt.Widget, rt.Animation)

    local mu = rt.settings.margin_unit
    out._left_indicator:set_margin_left(mu)
    out._right_indicator:set_margin_right(mu)
    out._up_indicator:set_margin_top(mu)
    out._down_indicator:set_margin_bottom(mu)
    for _, indicator in pairs({out._left_indicator, out._up_indicator, out._right_indicator, out._down_indicator}) do
        indicator:set_margin(rt.settings.margin_unit)
    end

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", rt.SwipeLayout._on_button_pressed, out)
    return out
end)

--- @brief [internal]
function rt.SwipeLayout:_on_button_pressed(which, self)

    local element_offset = 0
    if self._orientation == rt.Orientation.HORIZONTAL then
        if which == rt.InputButton.LEFT then
            element_offset = -1
        elseif which == rt.InputButton.RIGHT then
            element_offset = 1
        end
    elseif self._orientation == rt.Orientation.VERTICAL then
        if which == rt.InputButton.UP then
            element_offset = -1
        elseif which == rt.InputButton.DOWN then
            element_offset = 1
        end
    end

    if element_offset ~= 0 then
        self:jump_to(self._current_element + element_offset)
    end
end

--- @brief
function rt.SwipeLayout:jump_to(index)

    if sizeof(self._slot_positions) == 0 then return end

    local n = self._children:size()
    if self._allow_wrap then
        if index < 1 then
            index = n
        elseif index > n then
            index = 1
        end
    else
        index = clamp(index, 1, n)
    end

    if self._modifies_focus then
        self._children:at(self._current_element):set_has_focus(false)
        self._children:at(index):set_has_focus(true)
    end

    self._offset_target = ternary(self._orientation == rt.Orientation.HORIZONTAL, self._slot_positions[index].x, self._slot_positions[index].y)
    self._current_element = index
end

--- @overload rt.Animation.update
function rt.SwipeLayout:update(delta)
    self._elapsed = self._elapsed + delta

    while self._elapsed > 1 / 60 do
        local current = self._offset
        local target = self._offset_target

        local acceleration = 1;
        if self._orientation == rt.Orientation.HORIZONTAL then
            acceleration = acceleration + rt.settings.swipe_layout.scroll_speed_acceleration_factor *  math.abs(target - current) / math.abs(self._slot_positions[1].x - self._slot_positions[self._children:size()].x)
        else
            acceleration = acceleration + rt.settings.swipe_layout.scroll_speed_acceleration_factor *  math.abs(target - current) / math.abs(self._slot_positions[1].y - self._slot_positions[self._children:size()].y)
        end

        local delta = (rt.settings.swipe_layout.scroll_speed_base / 60) * (1 + acceleration)

        if math.abs(current - target) > 1 then
            if current < target then
                self._offset = self._offset + math.min(delta, target - current)
            elseif current > target then
                self._offset = self._offset - math.min(delta, target + current)
            end
        end

        self._elapsed = self._elapsed - 1 / 60
    end
end

--- @overload rt.Drawable.draw
function rt.SwipeLayout:draw()

    if not self:get_is_visible() then return end

    love.graphics.push()
    if self._orientation == rt.Orientation.HORIZONTAL then
        love.graphics.translate(-self._offset, 0)
    else
        love.graphics.translate(0, -self._offset)
    end

    local i = 1
    for _, child in pairs(self._children) do
        child:draw()
        if self._show_selection and i == self._current_element then
            child:draw_selection_indicator()
        end
        i = i + 1
    end

    love.graphics.pop()
    if self._orientation == rt.Orientation.HORIZONTAL then
        if self._allow_wrap or  self._current_element ~= 1 then
            self._left_indicator:draw()
        end
        if self._allow_wrap or self._current_element < self._children:size() then
            self._right_indicator:draw()
        end
    elseif self._orientation == rt.Orientation.VERTICAL then
        if self._allow_wrap or  self._current_element ~= 1 then
            self._up_indicator:draw()
        end
        if self._allow_wrap or self._current_element < self._children:size() then
            self._down_indicator:draw()
        end
    end
end

--- @overload rt.Widget.realize
function rt.SwipeLayout:realize()
    for _, child in pairs(self._children) do
        child:realize()
    end

    for _, indicator in pairs({self._left_indicator, self._up_indicator, self._right_indicator, self._down_indicator}) do
        indicator:realize()
    end

    rt.Widget.realize(self)
    self:set_is_animated(true)
end

--- @overload rt.Widget.size_allocate
function rt.SwipeLayout:size_allocate(x, y, width, height)

    self._area = rt.AABB(x, y, width, height)
    local radius = rt.settings.swipe_layout.indicator_radius
    self._slot_positions = {}
    local child_area = rt.AABB(x + radius, y + radius, width - 2 * radius, height - 2 * radius)

    if self._orientation == rt.Orientation.HORIZONTAL then
        self._left_indicator:fit_into(x, y + 0.5 * height - 0.5 * radius, radius, radius)
        self._right_indicator:fit_into(x + width - radius, y + 0.5 * height - 0.5 * radius, radius, radius)

        for _, child in pairs(self._children) do
            child:fit_into(child_area)
            table.insert(self._slot_positions, rt.Vector2(child_area.x - (x + radius), child_area.y))
            child_area.x = child_area.x + child_area.width
        end
    elseif self._orientation == rt.Orientation.VERTICAL then
        self._up_indicator:fit_into(x + 0.5 * width - 0.5 * radius, y, radius, radius)
        self._down_indicator:fit_into(x + 0.5 * width - 0.5 * radius, y + height - radius, radius, radius)

        for _, child in pairs(self._children) do
            child:fit_into(child_area)
            table.insert(self._slot_positions, rt.Vector2(child_area.x, child_area.y - (y + radius)))
            child_area.y = child_area.y + child_area.height
        end
    end

    self:jump_to(self._current_element)
end

--- @brief append child
--- @param child rt.Widget
function rt.SwipeLayout:push_back(child)
    child:set_parent(self)
    self._children:push_back(child)

    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end

    if self._modifies_focus and self._children:size() ~= self._current_element then
        child:set_has_focus(false)
    end
end

--- @brief
function rt.SwipeLayout:set_show_selection(b)
    self._show_selection = b
end

--- @brief
function rt.SwipeLayout:get_show_selection()
    return self._show_selection
end

--- @brief
function rt.SwipeLayout:set_modifies_focus(b)
    if b ~= self._modifies_focus then
        self._modifies_focus = b
        if self._modifies_focus == true then
            local i = 1
            for _, child in pairs(self._children) do
                child:set_has_focus(i == self._current_element)
            end
        end
    end
end

--- @brief
function rt.SwipeLayout:set_allow_wrap(b)
    self._allow_wrap = b
end

--- @brief
function rt.SwipeLayout:get_allow_wrap()
    return self._allow_wrap
end