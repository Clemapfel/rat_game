--- @class bt.GlobalStatusBar
bt.GlobalStatusBar = meta.new_type("GlobalStatusBar", rt.Widget, rt.Animation, function()
    return meta.new(bt.GlobalStatusBar, {
        _elements = {}, -- Table<cf. add>
        _box = rt.OrderedBox(),
        _frame = bt.GradientFrame(),
        _opacity = 1,
        _sprite_scale = 2,
        _target_width = 0,
        _frame_aabb = rt.AABB(0, 0, 1, 1), -- current width
        _elapsed = 0
    })
end)

--- @brief [internal]
function bt.GlobalStatusBar:_format_elapsed(status, elapsed)
    local max = status:get_max_duration()
    if max == POSITIVE_INFINITY then
        return ""
    else
        return "<o>" .. tostring(max - elapsed) .. "</o>"
    end
end

--- @brief
function bt.GlobalStatusBar:add(status, elapsed)
    meta.assert_number(elapsed)

    if self._elements[status] ~= nil then
        self:set_n_turns_elapsed(status, elapsed)
        return
    end

    local to_insert = {
        element = rt.LabeledSprite(status:get_sprite_id()),
        elapsed = elapsed
    }

    to_insert.element:set_label(self:_format_elapsed(status, elapsed))
    to_insert.element:set_sprite_scale(self._sprite_scale)
    self._elements[status] = to_insert

    if self._is_realized == true then
        to_insert.element:realize()
        self._box:add(status, to_insert.element)
    end
    self:reformat()
end

--- @brief
function bt.GlobalStatusBar:remove(status)
    local entry = self._elements[status]
    if entry == nil then
        rt.warning("In bt.GlobalStatusBar.remove: trying to remove status `" .. status:get_id() .. "`, but status is not present in status bar")
        return
    end

    if self._is_realized == true then
        self._box:remove(status, function(element)
            self:reformat()
        end)
    end
    self._elements[status] = nil
    self:reformat()
end

--- @brief
function bt.GlobalStatusBar:activate(status)
    local entry = self._elements[status]
    if entry == nil then
        rt.warning("In bt.GlobalStatusBar.activate: trying to activate status `" .. status:get_id() .. "`, but status is not present in status bar")
        return
    end

    if self._is_realized == true then
        self._box:activate(status)
    end
end

--- @brief
function bt.GlobalStatusBar:synchronize(entity)
    local actually_present = {}
    for status in values(entity:list_statuses()) do
        actually_present[status] = true
    end

    local currently_present = {}
    for status in values(self._box:list_elements()) do
        currently_present[status] = true
    end

    -- remove
    for status in keys(currently_present) do
        if actually_present[status] ~= true then
            self:remove(status)
        end
    end

    -- add & update time
    for status in keys(actually_present) do
        local n_elapsed = entity:get_status_n_turns_elapsed(status)
        if currently_present[status] ~= true then
            self:add(status, n_elapsed)
        else
            self:set_n_turns_elapsed(status, n_elapsed)
        end
    end
end

--- @brief
function bt.GlobalStatusBar:skip()
    self:update(60) -- finish all animations
end

--- @brief
function bt.GlobalStatusBar:set_n_turns_elapsed(status, elapsed)
    local current = self._elements[status]
    if current == nil then
        self:add(status, elapsed)
    end

    if current.elapsed ~= elapsed then
        self._box:activate(status, function(sprite)
            sprite:set_label(self:_format_elapsed(status, elapsed))
        end)
    end
end

--- @override
function bt.GlobalStatusBar:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._box:realize()

    for status, entry in pairs(self._elements) do
        entry.element:realize()
        self._box:add(status, entry.element)
    end

    self._frame:realize()
end

--- @override
function bt.GlobalStatusBar:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta

    self._box:update(delta)

    local should_reformat = false
    local current, target = self._frame_aabb.width, self._target_width
    if current ~= target then
        local offset = rt.settings.textbox.backdrop_expand_speed * delta
        if current < target then
            self._frame_aabb.width = clamp(current + offset, 0, target)
            should_reformat = true
        elseif current > target then
            self._frame_aabb.width = clamp(current - offset, target)
            should_reformat = true
        end
    end

    if should_reformat then
        self._frame:fit_into(self._frame_aabb)
    end
end

--- @override
function bt.GlobalStatusBar:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end

    local thickness = self._frame:get_frame_thickness()
    local m = rt.settings.margin_unit
    local sprite_height = 32 * self._sprite_scale

    local box_aabb = rt.AABB(x, y + 0.5 * height - 0.5 * sprite_height, width - 2 * m, sprite_height)
    self._box:fit_into(box_aabb)

    local box_w, box_h = self._box:measure()
    self._frame_aabb = rt.AABB(
        box_aabb.x - thickness - m,
        box_aabb.y - 0.5 * m,
        self._frame_aabb.width,
        box_h + m
    )
    self._target_width = ternary(self._box:is_empty(), 0, box_w + 2 * m + thickness)
    self._frame:fit_into(self._frame_aabb)
end

--- @override
function bt.GlobalStatusBar:draw()
    if self._is_realized ~= true then return end
    if self._target_width > 1 then
        self._frame:draw()
        self._box:draw()
    end
end

--- @brief
function bt.GlobalStatusBar:set_alignment(alignment)
    self._box:set_alignment(alignment)
end

--- @override
function bt.GlobalStatusBar:measure()
    local w, h = self._box:measure()
    if self._box:is_empty() then h = self._sprite_scale * 32 end
    h = h + 2 * self._frame:get_frame_thickness()
    w = w + 2 * self._frame:get_frame_thickness() * 2 * rt.settings.margin_unit
    return w, h
end

--- @brief
function bt.GlobalStatusBar:set_opacity(alpha)
    self._opacity = alpha
    if self._is_realized then
        self._box:set_opacity(alpha)
        self._frame:set_opacity(alpha)
    end
end
