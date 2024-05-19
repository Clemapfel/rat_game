rt.settings.ordered_box = {
    max_scale = 2,
    collider_radius = 100,
    collider_mass = 50,
    collider_speed = 2000,        -- px per second

    scale_speed = 1.5,      -- fraction per second
    opacity_speed = 1.2,    -- fraction per second
}

--[[
get_is_animations_finished

set_order(order)
add(id, element)
remove(id)
activate(id, function on_peak end)
set_is_hidden

get(id)


]]--

rt.Orientation = meta.new_enum({
    HORIZONTAL = "HORIZONTAL",
    VERTICAL = "VERTICAL"
})

rt.Alignment = meta.new_enum({
    START = "START",
    CENTER = "CENTER",
    END = "END"
})

rt.OrderedBox = meta.new_type("OrderedBox", rt.Widget, rt.Animation, function()
    return meta.new(rt.OrderedBox, {
        _world = rt.PhysicsWorld(0, 0),
        _order = {},   -- Array<ID>
        _entries = {}, -- Table<ID, cf. add>
        _orientation = rt.Orientation.HORIZONTAL,
        _alignment = rt.Alignment.START,
        _alignment_x_offset = 0,
        _alignment_y_offset = 0,
        _true_width = 0,
        _true_height = 0
    })
end)

--- @brief
function rt.OrderedBox:add(id, element)
    meta.assert_isa(element, rt.Widget)

    local present = self._entries[id]

    local origin_x, origin_y = self._bounds.x + 0.5 * self._bounds.width, self._bounds.y + 0.5 * self._bounds.height
    local to_insert = {
        element = element,
        collider = rt.CircleCollider(self._world, rt.ColliderType.DYNAMIC, 0, 0, rt.settings.ordered_box.collider_radius),
        target_position_x = 0,
        target_position_y = 0,
        width = 0,
        height = 0,
        target_alpha = 1,
        current_alpha = 0,
        target_scale = 1,
        current_scale = 1,
        is_scaling = false,
        on_scaling_peak = nil, -- function
        on_removing_done = nil,
        is_removing = false
    }

    local w, h = element:measure()
    to_insert.width = w
    to_insert.height = h
    to_insert.collider:set_position(origin_x, origin_y)
    to_insert.collider:set_collision_group(rt.ColliderCollisionGroup.NONE)
    to_insert.collider:set_mass(rt.settings.ordered_box.collider_mass)

    if self._is_realized == true then
        to_insert.element:realize()
    end

    self._entries[id] = to_insert

    if not present then
        table.insert(self._order, id)
    end
    self:reformat()
end

--- @brief
function rt.OrderedBox:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    for entry in values(self._entries) do
        entry.element:realize()
        local w, h = entry.element:measure()
        entry.width = w
        entry.height = h

        local origin_x, origin_y = self._bounds.x + 0.5 * self._bounds.width, self._bounds.y + 0.5 * self._bounds.height
        entry.collider:set_position(origin_x, origin_y)
    end
    self:set_is_animated(true)
end

function rt.OrderedBox:update(delta)
    self._world:update(delta)

    local to_remove = {}

    for index, id in pairs(self._order) do
        local entry = self._entries[id]
        -- update position
        local current_x, current_y = entry.collider:get_position()
        local target_x, target_y = entry.target_position_x, entry.target_position_y
        local distance = rt.distance(current_x, current_y, target_x, target_y)
        local angle = rt.angle(target_x - current_x, target_y - current_y)
        local magnitude = rt.settings.ordered_box.collider_speed
        local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
        entry.collider:apply_linear_impulse(vx, vy)
        local damping = magnitude / (4 * distance)
        entry.collider:set_linear_damping(damping)

        -- update opacity
        do
            local current = entry.current_alpha
            local target = entry.target_alpha
            if current > target then
                current = current - delta * rt.settings.ordered_box.opacity_speed
                if current < 0 then current = 0 end
            else
                current = current + delta * rt.settings.ordered_box.opacity_speed
                if current > target then current = target end
            end

            if current ~= entry.current_alpha then
                entry.element:set_opacity(current)
            end
            entry.current_alpha = current

            if current == 0 and entry.is_removing then
                table.insert(to_remove, {index, id})
                entry.is_removing = false
            end
        end

        -- update scale
        do
            local current = entry.current_scale
            local target = entry.target_scale
            local max_scale = rt.settings.ordered_box.max_scale
            if current > target then
                current = current - delta * rt.settings.ordered_box.scale_speed * (1 + rt.exponential_acceleration((current - target) / target))
                if current < 0 then current = 0 end
            else
                current = current + delta * rt.settings.ordered_box.scale_speed * (1 + rt.exponential_acceleration((target - current) / target))
                if current > target then current = target end
            end

            entry.current_scale = current

            if current == target then
                entry.target_scale = 1
                entry.is_scaling = false
                if entry.on_scaling_peak ~= nil then
                    entry.on_scaling_peak(entry.element)
                end
            end
        end
    end

    local should_reformat = false
    table.sort(to_remove, function(a, b)
        return b < a
    end)

    for id in values(to_remove) do
        table.remove(self._order, id[1])
        local entry = self._entries[id[2]]
        if entry.on_removing_done ~= nil then
            entry.on_removing_done(entry.element)
        end
        self._entries[id[2]] = nil
        should_reformat = true
    end

    if should_reformat then
        self:reformat()
    end
end

--- @brief
function rt.OrderedBox:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end

    local total_w, total_h, n = 0, 0, 0
    for id in values(self._order) do
        local entry = self._entries[id]
        entry.element:realize()
        local w, h = entry.element:measure()
        entry.element:fit_into(0, 0, w, h)
        entry.width = w
        entry.height = h

        total_w = total_w + w
        total_h = total_h + h
        n = n + 1
    end

    self._true_width, self._true_height = total_w, total_h

    local m = (width - total_w) / (n - 1)

    local current_x, current_y = self._bounds.x, self._bounds.y
    local origin_x, origin_y = self._bounds.x + 0.5 * self._bounds.width, self._bounds.y

    origin_x = origin_x - self._alignment_x_offset
    origin_y = origin_y - self._alignment_y_offset

    for id in values(self._order) do
        local entry = self._entries[id]
        local w, h = entry.width, entry.height
        entry.target_position_x = current_x
        entry.target_position_y = current_y
        entry.collider:set_position(origin_x, origin_y)

        if self._orientation == rt.Orientation.HORIZONTAL then
            entry.target_position_y = current_y + 0.5 * self._bounds.height - 0.5 * h
        end

        if self._orientation == rt.Orientation.VERTICAL then
            entry.target_position_x = current_x + 0.5 * self._bounds.width - 0.5 * w
        end

        if self._orientation == rt.Orientation.HORIZONTAL then
            current_x = current_x + w + m
            current_y = current_y + 0
        else
            current_x = current_x + 0
            current_y = current_y + h + m
        end
    end

    if self._orientation == rt.Orientation.HORIZONTAL then
        if self._alignment == rt.Alignment.START then
            self._alignment_x_offset = 0
            self._alignment_y_offset = 0
        elseif self._alignment == rt.Alignment.CENTER then
            self._alignment_x_offset = clamp(0.5 * width - 0.5 * total_w, 0)
            self._alignment_y_offset = 0
        elseif self._alignment == rt.Alignment.END then
            self._alignment_x_offset = clamp(width - total_w, 0)
            self._alignment_y_offset = 0
        else
            rt.error("In rt.OrderedBox.size_allocate: unknown alignment `" .. self._orientation .. "`")
        end
    elseif self._orientation == rt.Orientation.VERTICAL then
        if self._alignment == rt.Alignment.START then
            self._alignment_x_offset = 0
            self._alignment_y_offset = 0
        elseif self._alignment == rt.Alignment.CENTER then
            self._alignment_x_offset = 0
            self._alignment_y_offset = clamp(0.5 * height - 0.5 * total_h, 0)
        elseif self._alignment == rt.Alignment.END then
            self._alignment_x_offset = 0
            self._alignment_y_offset = clamp(height - total_h, 0)
        else
            rt.error("In rt.OrderedBox.size_allocate: unknown alignment `" .. self._orientation .. "`")
        end
    else
        rt.error("In rt.OrderedBox.size_allocate: unknown orientation `" .. self._orientation .. "`")
    end
end

--- @brief
function rt.OrderedBox:draw()
    if self._is_realized ~= true then return end

    rt.graphics.push()
    rt.graphics.translate(self._alignment_x_offset, self._alignment_y_offset)
    local bounds = self._bounds
    for _, entry in pairs(self._entries) do
        rt.graphics.push()
        rt.graphics.translate(entry.collider:get_position())
        rt.graphics.translate(0.5 * entry.width, 0.5 * entry.height)
        rt.graphics.scale(entry.current_scale)
        rt.graphics.translate(-0.5 * entry.width, -0.5 * entry.height)
        entry.element:draw()
        rt.graphics.pop()
    end
    rt.graphics.pop()
end

--- @brief
function rt.OrderedBox:remove(id, on_remove)
    local element = self._entries[id]
    if element == nil then
        rt.warning("In rt.OrderedBox.remove: no element with id `" .. serialize(id) .. "`")
        return
    end

    element.is_removing = true
    element.target_alpha = 0
    element.on_removing_done = on_remove
end

--- @brief
--- @param on_peak Function invoked when activate peak is reached
function rt.OrderedBox:activate(id, on_peak)
    local element = self._entries[id]
    if element == nil then
        rt.warning("In rt.OrderedBox.activate: no element with id `" .. serialize(id) .. "`")
        return
    end

    element.is_scaling = true
    element.on_scaling_peak = on_peak
    element.target_scale = rt.settings.ordered_box.max_scale
end

--- @brief
--- @param Table<id>
function rt.OrderedBox:list_elements()
    local out = {}
    for id in values(self._order) do
        table.insert(out, id)
    end
    return out
end

--- @brief
function rt.OrderedBox:get_elements(id)
    return self._entries[id]
end

--- @brief
function rt.OrderedBox:set_order(order)
    for id in values(order) do
        if self._entries[id] == nil then
            rt.warning("In rt.OrderedBox.set_order: no element with id `" .. serialize(id) .. "`")
            return
        end
    end
    self._order = order
    self:reformat()
end

--- @brief
function rt.OrderedBox:set_orientation(orientation)
    self._orientation = orientation
    if self._is_realized == true then
        self:reformat()
    end
end

--- @brief
function rt.OrderedBox:set_alignment(alignment)
    self._alignment = alignment
    if self._is_realized == true then
        self:reformat()
    end
end

--- @brief
function rt.OrderedBox:clear()
    self._entries = {}
    self._order = {}
    self:reformat()
end

--- @brief
function rt.OrderedBox:measure()
    return self._true_width, self._true_height
end

--- @brief
function rt.OrderedBox:is_empty()
    return #self._order == 0
end