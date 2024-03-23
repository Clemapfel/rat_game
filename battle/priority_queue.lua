rt.settings.battle.priority_queue = {
    element_size = 75,
    first_element_scale_factor = 1.3,
    first_element_scale_speed = 0.4, -- duration from 1.0 to 1.3, in seconds
    collider_mass = 50,
    collider_speed = 2000
}

--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, rt.Animation, function(scene)
    return meta.new(bt.PriorityQueue, {
        _scene = scene,
        _world = rt.PhysicsWorld(0, 0),
        _current = {
            entries = {},       -- Table<EntityID, bt.PriorityQueue.ElementEntry>
            order = {},         -- Table<Entity>
            render_order = {}   -- Table<{entity_key, multiplicity_index}>
        },
        _next = {
            entries = {},       -- Table<EntityID, bt.PriorityQueue.ElementEntry>
            order = {},         -- Table<Entity>
            render_order = {}   -- Table<{entity_key, multiplicity_index}>
        },
        _next_visible = false
    })
end)

--- @brief
--- @param order Table<bt.Entity>
function bt.PriorityQueue:reorder(order, next_order)

    next_order = which(next_order, {})
    if not self._is_realized then
        self._current.order = order
        return
    end

    self._current.order = {}

    -- generate or remove new elements if entity or entity multiplicity is seen for the first time
    local n_seen = {}
    for _, entity in pairs(order) do
        if n_seen[entity] == nil then n_seen[entity] = 0 end
        n_seen[entity] = n_seen[entity] + 1
        table.insert(self._current.order, entity)
    end

    for entity, n in pairs(n_seen) do
        if self._current.entries[entity] == nil then
            self._current.entries[entity] = {
                id = entity,
                elements = {},  -- Table<rt.PriorityQueue>
                colliders = {}, -- Table<rt.Collider>
                size = 0,
                target_positions = {} -- Table<Table<X, Y>>
            }
        end

        local entry = self._current.entries[entity]
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
            table.insert(entry.target_positions, {0, 0})

            local element_size = rt.settings.battle.priority_queue.element_size
            if self._is_realized then
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

    self:reformat()
end

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    local element_size = rt.settings.battle.priority_queue.element_size
    local off_screen_pos_x, off_screen_pos_y = x + width + 2 * element_size, 0
    if self._is_realized then
        for _, entry in pairs(self._current.entries) do
            for i, element in ipairs(entry.elements) do
                entry.target_positions[i][1] = off_screen_pos_x
            end
        end

        local n_seen = {}
        local outer_margin = 1.5 * rt.settings.margin_unit
        local factor = rt.settings.battle.priority_queue.first_element_scale_factor
        local m = math.min(
            rt.settings.margin_unit,
            ((height - 2 * outer_margin) - ((#self._current.order) * element_size) - (element_size * factor)) / (#self._current.order + 1)
        )
        local center_x = x + width - 2 * outer_margin
        local element_x, element_y = center_x, y + 2 * outer_margin + 0.5 * element_size + 0.5 * element_size

        -- first element is larger
        self._current.render_order = {}

        for _, entity in pairs(self._current.order) do
            if n_seen[entity] == nil then n_seen[entity] = 0 end
            n_seen[entity] = n_seen[entity] + 1

            local entry = self._current.entries[entity]
            local i = n_seen[entity]
            entry.target_positions[i] = {
                element_x - element_size / 2, element_y - element_size / 2
            }
            element_y = element_y + element_size + m

            -- store scale animation in collider userdata, scale is applied during draw
            local is_first = is_empty(self._current.render_order)
            local collider = entry.colliders[i]

            if collider:get_userdata("is_first") ~= is_first then
                collider:add_userdata("scale", 1)
                collider:add_userdata("is_first", is_first)
            end

            table.insert(self._current.render_order, 1, {entity, n_seen[entity]}) -- sic, reverse order
        end
    end
end

--- @override
function bt.PriorityQueue:realize()
    if self._is_realized then return end
    self._is_realized = true
    self._current.entries = {}
    self:reorder(self._current.order)

    for _, entry in pairs(self._current.entries) do
        for _, element in pairs(entry.elements) do
            element:realize()
        end
    end

    self:set_is_animated(true)
end

--- @override
function bt.PriorityQueue:update(delta)
    for _, entry in pairs(self._current.entries) do
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

    self._world:update(delta)
end

--- @override
function bt.PriorityQueue:draw()
    if self._is_realized then
        rt.graphics.push()

        local size = rt.settings.battle.priority_queue.element_size
        local max_scale = rt.settings.battle.priority_queue.first_element_scale_factor
        local scaled_offset = 0

        for i = 1, #self._current.render_order do
            local t = self._current.render_order[i]

            local entry = self._current.entries[t[1]]
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
end 