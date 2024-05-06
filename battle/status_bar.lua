bt.StatusBarAlignment = meta.new_enum({
    CENTER = "center",
    LEFT = "left",
    RIGHT = "right",
})

rt.settings.battle.status_bar = {
    element_size = 32,
    element_velocity = 150, -- px per seconds
    add_animation_max_scale = 5,
    add_animation_duration = 1, -- seconds
    hide_animation_duration = 2, -- seconds
    activate_animation_duration = 1,
    activate_scale_peak = 3,
    default_element_alignment = bt.StatusBarAlignment.CENTER
}

--- @class bt.StatusBar
bt.StatusBar = meta.new_type("StatusBar", rt.Widget, rt.Animation, function()
    return meta.new(bt.StatusBar, {
        _elements = {}, -- cf :add
        _debug_shape = {}, -- rt.Shape
        _alignment = rt.settings.battle.status_bar.default_element_alignment,
        _world = rt.PhysicsWorld(),
    })
end)

--- @override
function bt.StatusBar:realize()
    self._is_realized = true
    for t in values(self._elements) do
        t.element:realize()
    end
    self:reformat()
    self:set_is_animated(true)
end

--- @override
function bt.StatusBar:update(delta)
    if not self._is_realized then return end

    self._world:update(delta)
    local to_remove = {}
    local add_duration = rt.settings.battle.status_bar.add_animation_duration
    local max_scale = rt.settings.battle.status_bar.add_animation_max_scale
    local hide_duration = rt.settings.battle.status_bar.hide_animation_duration
    local activate_duration = rt.settings.battle.status_bar.activate_animation_duration

    for which, e in pairs(self._elements) do
        -- move towards correct place animation
        if e.initialized == false then
            e.current_x = e.target_x
            e.current_y = e.target_y
            e.initialized = true
        else
            local bounds = e.element:get_bounds()
            local current_x, current_y = e.current_x, e.current_y
            local target_x, target_y = e.target_x, e.target_y
            local direction_x, direction_y = target_x - current_x, target_y - current_y
            local magnitude = rt.magnitude(direction_x, direction_y)
            if magnitude > 1 then
                direction_x = direction_x / magnitude
                direction_y = direction_y / magnitude
                local step = delta * rt.settings.battle.status_bar.element_velocity
                e.current_x = e.current_x + direction_x * step
                e.current_y = e.current_y + direction_y * step

                e.current_x = math.round(e.current_x)
                e.current_y = math.round(e.current_y)
            end
        end

        if e.is_revealing or e.is_hiding then
            -- add / hide animation
            e.elapsed = e.elapsed + delta
            if e.is_revealing then
                local value = e.elapsed / add_duration
                e.element:set_opacity(value)
                e.element:set_scale(max_scale - mix(1, max_scale, value) + 1)
                if e.elapsed > add_duration then
                    e.is_revealing = false
                    e.element:set_opacity(1)
                    e.element:set_scale(1)
                end
            elseif e.is_hiding then
                local value = e.elapsed / hide_duration
                e.element:set_opacity(1 - value)
                if e.elapsed > hide_duration then
                    e.is_hiding = false
                    table.insert(to_remove, which)
                end
            end
        elseif e.is_activating then
            -- activate animation
            e.activating_elapsed = e.activating_elapsed + delta
            local scale = e.element:get_scale()
            local fraction = e.activating_elapsed / activate_duration
            e.element:set_scale(1 + rt.symmetrical_linear(fraction, rt.settings.battle.status_bar.activate_scale_peak - 1))
            if fraction > 1 then
                e.activating_elapsed = 0
                e.is_activating = false
                e.element:set_scale(1)
            end
        end
    end

    local removed = false
    for i in values(to_remove) do
        self._elements[i] = nil
        removed = true
    end

    if removed then
        self:reformat()
    end
end

--- @override
function bt.StatusBar:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end

    local size = rt.settings.battle.status_bar.element_size
    local n = sizeof(self._elements)
    local total_size = n * size
    local m = math.min(2, (width - total_size) / (n - 1))

    local alignment = self._alignment
    local start_x, start_y = nil, y + height * 0.5 - size * 0.5

    if alignment == bt.StatusBarAlignment.CENTER then
        start_x = x + 0.5 * width - (total_size + (n - 1) * m) * 0.5
    elseif alignment == bt.StatusBarAlignment.LEFT then
        start_x = x
    elseif alignment == bt.StatusBarAlignment.RIGHT then
        start_x = x + width - total_size
    else
        rt.error("In bt.StatusBar:size_allocate: unhandled alignment `" .. alignment .. "`")
    end

    local element_x, element_y, w, h = start_x, start_y, size, size
    for status, t in pairs(self._elements) do
        t.target_x = element_x
        t.target_y = element_y
        t.size = size
        t.element:fit_into(0, 0, w, h)
        t.debug_shape = rt.Rectangle(element_x, element_y, w, h)
        t.debug_shape:set_is_outline(true)

        element_x = element_x + size + m
    end
end

--- @override
function bt.StatusBar:draw()
    if self._is_realized ~= true then return end

    -- draw labels separate in case of overlap
    for e in values(self._elements) do
        rt.graphics.push()
        rt.graphics.translate(e.current_x, e.current_y)
        e.element:_draw_sprite()
        rt.graphics.pop()
    end

    for e in values(self._elements) do
        rt.graphics.push()
        rt.graphics.translate(e.current_x, e.current_y)
        e.element:_draw_label()
        rt.graphics.pop()
    end
end

--- @brief
function bt.StatusBar:add(status, elapsed)
    local element = bt.StatusBarElement(status)
    element:set_elapsed(elapsed)
    element:set_scale(rt.settings.battle.status_bar.add_animation_max_scale)
    element:set_opacity(0)

    if self._is_realized == true then
        element:realize()
    end

    self._elements[status] = {
        element = element,
        elapsed = 0,
        activating_elapsed = 0,
        is_revealing = true,
        is_hiding = false,
        is_activating = false,
        initialized = false,
        current_x = 0,
        current_y = 0,
        target_x = 0,
        target_y = 0,
        debug_shape = {}
    }
    self:reformat()
end

--- @brief
function bt.StatusBar:remove(status)
    local seen = false
    for e in values(self._elements) do
        if e.element._status == status then
            e.is_revealing = false
            e.element:set_scale(1)
            e.element:set_opacity(1)
            e.element:set_hide_n_turns_left(true)
            e.is_hiding = true
            seen = true
            break
        end
    end

    if not seen then
        rt.warning("In bt.StatusBar:remove: status `" .. status:get_id() .. "` of entity `" .. self._entity:get_id() .. "` was not yet added to StatusBar")
    end
end

--- @brief
function bt.StatusBar:activate(status)
    for e in values(self._elements) do
        if e.element._status == status then
            e.is_activating = true
            e.activating_elapsed = 0
        end
    end
end

--- @brief
--- @param statuses Table<bt.Status, Number> status to elapsed
function bt.StatusBar:create_from(statuses)
    for status, elapsed in pairs(statuses) do
        meta.assert_isa(status, bt.Status)
        meta.assert_number(elapsed)
        if self._elements[status] == nil then
            self:add(status, elapsed)
        else
            self._elements[status].element:set_elapsed(elapsed)
        end
    end

    for status, element in pairs(self._elements) do
        if statuses[status] == nil then
            self:remove(status)
        end
    end
end

--- @brief
function bt.StatusBar:synchronize(entity)
    local statuses = entity:list_statuses()
    local to_create_from = {}
    for status in values(statuses) do
        to_create_from[status] = entity:get_status_n_turns_elapsed(status)
    end
    self:create_from(to_create_from)
end

--- @brief
function bt.StatusBar:set_alignment(alignment)
    if self._alignment ~= alignment then
        self._alignment = alignment
        self:reformat()
    end
end