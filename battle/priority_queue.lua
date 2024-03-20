rt.settings.battle.priority_queue = {
    element_size = 75,
    first_element_scale_factor = 1.3,

    collider_mass = 50,
    collider_speed = 2000
}

--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, rt.Animation, function(scene)
    return meta.new(bt.PriorityQueue, {
        _scene = scene,
        _world = rt.PhysicsWorld(0, 0),
        _entries = {}, -- Table<EntityID, bt.PriorityQueue.ElementEntry>
        _current_order = {}, -- Table<Entity>
        _render_order = {} -- Table<{bt.PriorityQueueElement, Collider}>
    })
end)

--- @brief
--- @param order Table<bt.Entity>
function bt.PriorityQueue:reorder(order)

    if not self._is_realized then
        self._current_order = order
        return
    end

    self._current_order = {}

    -- generate or remove new elements if entity or entity multiplicity is seen for the first time
    local n_seen = {}
    for _, entity in pairs(order) do
        if n_seen[entity] == nil then n_seen[entity] = 0 end
        n_seen[entity] = n_seen[entity] + 1
        table.insert(self._current_order, entity)
    end

    for entity, n in pairs(n_seen) do
        if self._entries[entity] == nil then
            self._entries[entity] = {
                id = entity,
                elements = {},  -- Table<rt.PriorityQueue>
                colliders = {}, -- Table<rt.Collider>
                size = 0,
                target_positions = {} -- Table<Table<X, Y>>
            }
        end

        local entry = self._entries[entity]
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

            local collider = rt.CircleCollider(
                self._world, rt.ColliderType.DYNAMIC,
                    bounds.x + bounds.width + 2 * element_size,
                    bounds.y + bounds.height * mix(0.25, 0.75, rt.rand()),
                    element_size / 2
            )
            collider:set_collision_group(rt.ColliderCollisionGroup.NONE)
            collider:set_mass(rt.settings.battle.priority_queue.collider_mass)

            table.insert(entry.colliders, collider)
            table.insert(entry.target_positions, {0, 0})

            local element_size = rt.settings.battle.priority_queue.element_size
            if self._is_realized then
                queue_element:realize()
            end
        end

        while #entry.colliders > n do
            table.remove(entry.elements, #(entry.elements))
            table.remove(entry.colliders, #(entry.colliders))
            table.remove(entry.target_positions, #(entry.target_positions))
        end
    end

    self:reformat()
end

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    local element_size = rt.settings.battle.priority_queue.element_size
    local off_screen_pos_x, off_screen_pos_y = x + width + 2 * element_size, 0
    if self._is_realized then
        for _, entry in pairs(self._entries) do
            for i, element in ipairs(entry.elements) do
                entry.target_positions[i][1] = off_screen_pos_x
            end
        end

        local n_seen = {}

        local outer_margin = 1.5 * rt.settings.margin_unit
        local m = math.min(
            rt.settings.margin_unit,
            ((height - 2 * outer_margin - element_size) - (#self._current_order * element_size)) / (#self._current_order + 1)
        )
        local center_x = x + width - 2 * outer_margin
        local element_x, element_y = center_x, y + 2 * outer_margin + 0.5 * element_size + 0.5 * element_size

        -- first element is larger
        local factor = rt.settings.battle.priority_queue.first_element_scale_factor
        local align_center = false
        local y_offset_factor = ternary(align_center, 2, 1)
        local offset = (element_size - element_size * factor) / y_offset_factor

        self._render_order = {}

        for _, entity in pairs(self._current_order) do
            if n_seen[entity] == nil then n_seen[entity] = 0 end
            n_seen[entity] = n_seen[entity] + 1

            local entry = self._entries[entity]
            local i = n_seen[entity]
            entry.target_positions[i] = {
                element_x - element_size / 2, element_y - element_size / 2
            }
            element_y = element_y + element_size + m

            -- scale first element, then offset all other elements by size difference
            -- all anchored at 0, 0, actual position is set during draw
            if #self._render_order == 0 then
                entry.elements[i]:fit_into(offset, 0, element_size * factor, element_size * factor)
            else
                entry.elements[i]:fit_into(0, -1 * y_offset_factor * offset, element_size, element_size)
            end

            table.insert(self._render_order, 1, {entry.elements[i], entry.colliders[i]})
        end
    end
end

--- @override
function bt.PriorityQueue:realize()
    if self._is_realized then return end
    self._is_realized = true
    self._entries = {}
    self:reorder(self._current_order)

    for _, entry in pairs(self._entries) do
        for _, element in pairs(entry.elements) do
            element:realize()
        end
    end

    self:set_is_animated(true)
end

--- @override
function bt.PriorityQueue:update(delta)
    for _, entry in pairs(self._entries) do
        for i, collider in ipairs(entry.colliders) do
            local current_x, current_y = collider:get_centroid()
            local target = entry.target_positions[i]
            local target_x, target_y = target[1], target[2]

            local angle = rt.angle( target_x- current_x, target_y - current_y)
            local magnitude = rt.settings.battle.priority_queue.collider_speed
            local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
            collider:apply_linear_impulse(vx, vy)

            -- increase friction as object gets closer to target, to avoid overshooting
            local distance = rt.magnitude(target_x - current_x, target_y - current_y)
            local damping = magnitude / (4 * distance)
            collider:set_linear_damping(damping)
        end
    end

    self._world:update(delta)
end

--- @override
function bt.PriorityQueue:draw()
    if self._is_realized then
        rt.graphics.push()

        local size = rt.settings.battle.priority_queue.element_size
        local first_scale = 1.2
        local first_offset_x, first_offset_y = 0, 0
        for i, t in ipairs(self._render_order) do
            local element = t[1]
            local collider = t[2]
            local pos_x, pos_y = collider:get_position()
            pos_x = math.floor(pos_x - 0.5 * size)
            pos_y = math.floor(pos_y - 0.5 * size)

            rt.graphics.translate(pos_x, pos_y)
            element:draw()
            rt.graphics.translate(-1 * pos_x, -1 * pos_y)
        end

        rt.graphics.pop()
    end
end 