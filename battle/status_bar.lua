rt.settings.battle.status_bar = {
    element_size = 50,
    add_animation_max_scale = 5,
    add_animation_duration = 1, -- seconds
    hide_animation_duration = 2, -- seconds
}

--- @class bt.StatusBar
bt.StatusBar = meta.new_type("StatusBar", rt.Widget, rt.Animation, function(entity)
    return meta.new(bt.StatusBar, {
        _elements = {}, -- Table<ID, cf. :add>
        _debug_shape = {} -- rt.Shape
    })
end)

--- @override
function bt.StatusBar:update(delta)
    if not self._is_realized then return end

    local to_remove = {}
    local add_duration = rt.settings.battle.status_bar.add_animation_duration
    local max_scale = rt.settings.battle.status_bar.add_animation_max_scale
    local hide_duration = rt.settings.battle.status_bar.hide_animation_duration

    for i, e in ipairs(self._elements) do
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
                if e.elapsed > hide_duration then
                    e.is_hiding = false
                    table.insert(to_remove, i)
                end
            end
        end
    end

    for i in values(to_remove) do
        table.remove(self._elements, i)
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
        local size = height--rt.settings.battle.status_bar.element_size
        local m = 2
        local total_size = #self._elements * size + (#self._elements - 1) * size
        local start_x = x + 0.5 * width - total_size * 0.5 + 0.5 * size
        local start_y = y + height * 0.5 - size * 0.5

        for i, t in ipairs(self._elements) do
            local element_x, element_y, w, h = start_x + (i - 1) * (size + m), start_y, size, size
            t.element:fit_into(element_x, element_y, w, h)
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

    if rt.current_scene:get_debug_draw_enabled() then
        self._debug_shape:draw()
        for e in values(self._elements) do
            e.debug_shape:draw()
        end
    end

    for e in values(self._elements) do
        e.element:draw()
    end
end

--- @brief
function bt.StatusBar:add(entity, status)
    local element = bt.StatusBarElement(entity, status)
    if self._is_realized then
        element:realize()
    end
    table.insert(self._elements, {
        element = element,
        elapsed = 0,
        is_revealing = true,
        is_hiding = false,
        debug_shape = {}
    })

    self:reformat()
end
