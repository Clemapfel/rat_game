rt.settings.battle.status_bar = {
    element_size = 50,
    element_velocity = 150, -- px per seconds
    add_animation_max_scale = 5,
    add_animation_duration = 1, -- seconds
    hide_animation_duration = 2, -- seconds
    element_alignment = rt.Alignment.END
}

--- @class bt.StatusBar
bt.StatusBar = meta.new_type("StatusBar", rt.Widget, rt.Animation, function(entity)
    return meta.new(bt.StatusBar, {
        _elements = {}, -- cf :add
        _debug_shape = {}, -- rt.Shape
        _world = rt.PhysicsWorld(),
    })
end)

--- @override
function bt.StatusBar:update(delta)
    if not self._is_realized then return end

    self._world:update(delta)

    local to_remove = {}
    local add_duration = rt.settings.battle.status_bar.add_animation_duration
    local max_scale = rt.settings.battle.status_bar.add_animation_max_scale
    local hide_duration = rt.settings.battle.status_bar.hide_animation_duration

    for i, e in ipairs(self._elements) do

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

        -- add / hide animation
        if e.is_revealing or e.is_hiding then
            e.elapsed = e.elapsed + delta
            if e.is_revealing then
                local value = e.elapsed / add_duration
                e.element:set_opacity(value)
                e.element:set_scale(max_scale - mix(1, max_scale, value) + 1)
                if e.elapsed > add_duration then
                    e.is_revealing = false
                    e.element:set_opacity(1)
                    e.element:set_scale(1)
                    e.element:set_hide_n_turns_left(false)
                end
            elseif e.is_hiding then
                local value = e.elapsed / hide_duration
                e.element:set_opacity(1 - value)
                if e.elapsed > hide_duration then
                    e.is_hiding = false
                    table.insert(to_remove, i)
                end
            end
        end
    end

    local removed = false
    for i in values(to_remove) do
        table.remove(self._elements, i)
        removed = true
    end

    if removed then
        self:reformat()
    end
end

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
function bt.StatusBar:size_allocate(x, y, width, height)
    if self._is_realized then
        local size = rt.settings.battle.status_bar.element_size
        local m = 2
        local n = sizeof(self._elements)
        local total_size = n * size + (n - 1) * m

        local alignment = rt.settings.battle.status_bar.element_alignment
        local start_x, start_y = nil, y + height * 0.5 - size * 0.5

        if alignment == rt.Alignment.CENTER then
            start_x = x + 0.5 * width - total_size * 0.5
        elseif alignment == rt.Alignment.START then
            start_x = x
        elseif alignment == rt.Alignment.END then
            start_x = x + width - total_size
        else
            rt.error("In bt.StatusBar:size_allocate: unreachable reached")
        end

        for i, t in ipairs(self._elements) do
            local element_x, element_y, w, h = start_x + (i - 1) * (size + m), start_y, size, size
            t.target_x = element_x
            t.target_y = element_y
            t.size = size
            t.element:fit_into(0, 0, w, h)
            t.debug_shape = rt.Rectangle(element_x, element_y, w, h)
            t.debug_shape:set_is_outline(true)
        end
    end

    self._debug_shape = rt.Rectangle(x, y, width, height)
    self._debug_shape:set_is_outline(true)
end

--- @override
function bt.StatusBar:draw()
    if not self._is_realized then return end

    local debug_draw = rt.current_scene:get_debug_draw_enabled()
    if debug_draw then
        self._debug_shape:draw()
    end

    for e in values(self._elements) do

        rt.graphics.push()
        rt.graphics.translate(e.current_x, e.current_y)
        e.element:draw()
        rt.graphics.pop()

        if debug_draw then
            e.debug_shape:draw()
        end
    end
end

--- @brief
function bt.StatusBar:add(entity, status)
    local element = bt.StatusBarElement(entity, status)
    element:set_hide_n_turns_left(true)
    element:set_scale(rt.settings.battle.status_bar.add_animation_max_scale)
    element:set_opacity(0)

    if self._is_realized then
        element:realize()
    end
    table.insert(self._elements, {
        element = element,
        elapsed = 0,
        is_revealing = true,
        is_hiding = false,
        initialized = false,
        current_x = 0,
        current_y = 0,
        target_x = 0,
        target_y = 0,
        debug_shape = {}
    })

    self:reformat()
end

--- @brief
function bt.StatusBar:remove(entity, status)
    local seen = false
    for e in values(self._elements) do
        if e.element._entity == entity and e.element._status == status then
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
        rt.warning("In bt.StatusBar:remove: status `" .. status:get_id() .. "` of entity `" .. entity:get_id() .. "` was not yet added to StatusBar")
    end
end
