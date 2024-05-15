rt.settings.battle.priority_queue = {
    outer_margin = 2 * rt.settings.margin_unit,
    element_size = 100,
    first_element_scale_factor = 1.3,
    first_element_scale_speed = 0.4, -- duration from 1.0 to 1.3, in seconds
    collider_mass = 50,
    collider_speed = 2000
}

--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, rt.Animation, function(scene)
    return meta.new(bt.PriorityQueue, {
        _world = rt.PhysicsWorld(0, 0),
        _current = {
            entries = {},       -- Table<Entity, bt.PriorityQueue.ElementEntry>
            order = {},         -- Table<Entity>
            render_order = {}   -- Table<{entity_key, multiplicity_index}>
        },
        _next = {
            entries = {},
            order = {},
            render_order = {}
        },
        _preview_visible = false,
        _reorder_done = false,
        _elapsed = 0
    })
end)

--- @brief
function bt.PriorityQueue:set_preview_visible(b)
    self._preview_visible = b
    self:reformat()
end

--- @brief
function bt.PriorityQueue:get_preview_visible()
    return self._preview_visible
end

--- @brief
function bt.PriorityQueue:set_selected(entities)
    local is_selected = {}
    for entity in values(entities) do
        is_selected[entity] = true
    end

    local unselected_alpha = 0.5
    for id, entry in pairs(self._current.entries) do
        local element_selected = is_selected[id] == true
        for element in values(entry.elements) do
            element:set_is_selected(element_selected)
            element:set_opacity(ternary(element_selected, 1, unselected_alpha))
        end
    end
end

--- @brief
function bt.PriorityQueue:set_is_stunned(entity, b)
    for element in values(self._current.entries[entity].elements) do
        element:set_is_stunned(b)
    end
end

--- @brief
function bt.PriorityQueue:set_state(entity, state)
    for element in values(self._current.entries[entity].elements) do
        element:set_state(state)
    end
end


--- @brief
--- @param order Table<bt.Entity>
function bt.PriorityQueue:reorder(order, next_order)

    next_order = which(next_order, {})
    if not self._is_realized then
        self._current.order = order
        return
    end

    self._current.order = {}
    self._next.order = {}

    local function handle(which, order)
        which.order = order

        -- generate or remove new elements if entity or entity multiplicity is seen for the first time
        local n_seen = {}
        for _, entity in pairs(order) do
            if n_seen[entity] == nil then n_seen[entity] = 0 end
            n_seen[entity] = n_seen[entity] + 1
            table.insert(which, entity)
        end

        for entity, n in pairs(n_seen) do
            if which.entries[entity] == nil then
                which.entries[entity] = {
                    id = entity,
                    elements = {},  -- Table<rt.PriorityQueueElement>
                    colliders = {}, -- Table<rt.Collider>
                    size = 0,
                    target_positions = {} -- Table<Table<X, Y>>
                }
            end

            local entry = which.entries[entity]
            local element_size = rt.settings.battle.priority_queue.element_size

            while #entry.colliders < n do
                local queue_element = bt.PriorityQueueElement(
                    self._scene,
                    entity
                )
                table.insert(entry.elements, queue_element)

                local bounds = self:get_bounds()
                if bounds.width + bounds.height == 0 then
                    bounds = rt.AABB(rt.graphics.get_width(), 0, 0, 0)
                    -- if called before first size_allocate
                end

                local collider_x = bounds.x + bounds.width + 2 * element_size
                local collider_y = bounds.y + bounds.height * mix(0.25, 0.75, rt.rand())
                local collider = rt.CircleCollider(
                    self._world, rt.ColliderType.DYNAMIC, collider_x, collider_y, element_size / 2
                )
                collider:set_collision_group(rt.ColliderCollisionGroup.NONE)
                collider:set_mass(rt.settings.battle.priority_queue.collider_mass)

                table.insert(entry.colliders, collider)
                table.insert(entry.target_positions, { 0, 0 })

                local element_size = rt.settings.battle.priority_queue.element_size
                if self._is_realized == true then
                    queue_element:realize()
                end
                queue_element:fit_into(0, 0, element_size, element_size)
            end

            while #entry.colliders > n do
                table.remove(entry.elements, 1) --#(entry.elements))
                table.remove(entry.colliders, 1) --#(entry.colliders))
                table.remove(entry.target_positions, 1)--#(entry.target_positions))
            end
        end
    end

    handle(self._current, order)
    handle(self._next, next_order)
    self._reorder_done = false

    self:reformat()
end

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    local element_size = rt.settings.battle.priority_queue.element_size
    local off_screen_pos_x, off_screen_pos_y = x + width + 2 * element_size, 0
    if self._is_realized == true then
        local function handle(which, offset)
            for _, entry in pairs(which.entries) do
                for i, element in ipairs(entry.elements) do
                    entry.target_positions[i][1] = off_screen_pos_x
                end
            end

            local n_seen = {}
            local outer_margin = rt.settings.battle.priority_queue.outer_margin
            local factor = rt.settings.battle.priority_queue.first_element_scale_factor
            local size = rt.settings.battle.priority_queue.element_size

            local m = math.min(
                rt.settings.margin_unit,
                ((height - 2 * outer_margin) - ((#which.order) * element_size) - (element_size * factor)) / (#which.order + 1)
            )
            local center_x = x + width - outer_margin
            local element_x, element_y = center_x, y + outer_margin + 0.5 * element_size + 0.5 * element_size
            local x_offset = ternary(offset, -1 * size * factor + m, 0)
            -- first element is larger
            which.render_order = {}
            for _, entity in pairs(which.order) do
                if n_seen[entity] == nil then n_seen[entity] = 0 end
                n_seen[entity] = n_seen[entity] + 1

                local entry = which.entries[entity]
                local i = n_seen[entity]
                entry.target_positions[i] = {
                    element_x - element_size / 2 + x_offset,
                    element_y - element_size / 2
                }
                element_y = element_y + element_size + m

                -- store scale animation in collider userdata, scale is applied during draw
                local is_first = is_empty(which.render_order)
                local collider = entry.colliders[i]

                if collider:get_userdata("is_first") ~= is_first then
                    collider:add_userdata("scale", 1)
                    collider:add_userdata("is_first", is_first)
                end

                table.insert(which.render_order, 1, { entity, n_seen[entity] }) -- sic, reverse order
            end
        end

        handle(self._current, false)
        handle(self._next, false)
    end
end

--- @override
function bt.PriorityQueue:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._current.entries = {}
    self._next.entries = {}
    self:reorder(self._current.order, self._next.order)

    for _, entry in pairs(self._current.entries) do
        for _, element in pairs(entry.elements) do
            element:realize()
        end
    end

    for _, entry in pairs(self._next.entries) do
        for _, element in pairs(entry.elements) do
            element:realize()
        end
    end

    self:set_is_animated(true)
end

--- @override
function bt.PriorityQueue:update(delta)
    self._elapsed = self._elapsed + delta

    local function handle(which)
        for _, entry in pairs(which.entries) do
            for i, collider in ipairs(entry.colliders) do
                local current_x, current_y = collider:get_centroid()
                local target = entry.target_positions[i]
                local target_x, target_y = target[1], target[2]

                if rt.distance(current_x, current_y, target_x, target_y) > 1 then
                    self._reorder_done = false
                end

                local angle = rt.angle(target_x - current_x, target_y - current_y)
                local magnitude = rt.settings.battle.priority_queue.collider_speed
                local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
                collider:apply_linear_impulse(vx, vy)

                -- increase friction as object gets closer to target, to avoid overshooting
                local distance = rt.magnitude(target_x - current_x, target_y - current_y)
                local damping = magnitude / (4 * distance)
                collider:set_linear_damping(damping)

                if collider:get_userdata("is_first") == true then
                    local max_factor = rt.settings.battle.priority_queue.first_element_scale_factor
                    local step = delta / rt.settings.battle.priority_queue.first_element_scale_speed

                    if collider:contains_point(target_x, target_y) then
                        step = step * 2
                    end

                    collider:add_userdata("scale", clamp(collider:get_userdata("scale") + step, 1, max_factor))
                end
            end
        end
    end

    handle(self._current)
    handle(self._next)
    self._world:update(delta)
end

--- @override
function bt.PriorityQueue:draw()
    if self._is_realized == true then
        local function handle(which)
            -- draw current
            rt.graphics.push()
            local size = rt.settings.battle.priority_queue.element_size
            local max_scale = rt.settings.battle.priority_queue.first_element_scale_factor
            local scaled_offset = 0
            for i = 1, #which.render_order do
                local t = which.render_order[i]

                local entry = which.entries[t[1]]
                local element = entry.elements[t[2]]
                local collider = entry.colliders[t[2]]

                local pos_x, pos_y = collider:get_position()
                pos_x = math.floor(pos_x - 0.5 * size)
                pos_y = math.floor(pos_y - 0.5 * size)

                -- offset all elements except first scaled one
                local scale = collider:get_userdata("scale")
                scaled_offset = ternary(math.abs(scale - 1) < 0.001, (max_scale - 1) * size, 0)

                rt.graphics.translate(pos_x, pos_y + scaled_offset)

                rt.graphics.push()
                rt.graphics.translate((scale - 1) * -1 * size, 0)
                rt.graphics.scale(scale, scale)
                element:draw()
                rt.graphics.pop()
                rt.graphics.translate(-1 * pos_x, -1 * (pos_y + scaled_offset))
            end
            rt.graphics.pop()
        end

        handle(self._current)
        if self._preview_visible then
            handle(self._next)
        end
    end
end

--- @brief
function bt.PriorityQueue:skip()
    local function handle(which)
        for _, entry in pairs(which.entries) do
            for i, collider in ipairs(entry.colliders) do
                local target = entry.target_positions[i]
                local target_x, target_y = target[1], target[2]
                collider:set_position(target_x, target_y)
            end
        end
    end

    handle(self._current)
    handle(self._next)
end

--- @brief
function bt.PriorityQueue:get_is_reorder_done()
    return self._reorder_done
end