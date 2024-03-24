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
        _entries = {},        -- Table<Entity, cf. line 37>
        _current_order = {},  -- Table<Entity>
        _preview_order = {},  -- Table<Entity>
        _render_order = {},   -- Table<{entity_key, multiplicity_index}>
        _is_preview_active = false
    })
end)

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    -- generate new entries if needed
    local order = ternary(self._is_preview_active, self._preview_order, self._current_order)

    println(" ")
    for v in values(order) do
        println(v:get_id())
    end

    local n_seen = {}
    for _, entity in pairs(order) do
        if n_seen[entity] == nil then n_seen[entity] = 0 end
        n_seen[entity] = n_seen[entity] + 1
    end

    local element_size = rt.settings.battle.priority_queue.element_size

    for entity, n in pairs(n_seen) do
        if self._entries[entity] == nil then
            self._entries[entity] = {
                id = entity,
                elements = {},  -- Table<rt.PriorityQueue>
                colliders = {}, -- Table<rt.Collider>
                target_positions = {} -- Table<Table<X, Y>>
            }
        end

        local entry = self._entries[entity]

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

            queue_element:realize()
            queue_element:fit_into(0, 0, element_size, element_size)
        end

        while #entry.colliders > n do
            table.remove(entry.elements, 1)
            table.remove(entry.colliders, 1)
            table.remove(entry.target_positions, 1)
        end
    end

    -- update entry priority labels
    local current_first_occurence = {}
    for i, entity in ipairs(self._current_order) do
        if current_first_occurence[entity] == nil then
            current_first_occurence[entity] = {
                occurences = { i },
                offset = 1
            }
        else
            table.insert(current_first_occurence[entity].occurences, i)
        end
    end

    local preview_first_occurrence = {}
    for i, entity in ipairs(self._preview_order) do
        if preview_first_occurrence[entity] == nil then
            preview_first_occurrence[entity] = {
                occurences = { i },
                offset = 1
            }
        else
            table.insert(preview_first_occurrence[entity].occurences, i)
        end
    end

    for entity, entry in pairs(self._entries) do
        for _, element in pairs(entry.elements) do
            local before_entry = current_first_occurence[entity]
            local after_entry = preview_first_occurrence[entity]

            local before = nil
            local after = nil

            if before_entry ~= nil then
                before = before_entry.occurences[before_entry.offset]
            end

            if after_entry ~= nil then
                after = after_entry.occurences[after_entry.offset]
            end

            if before == nil and after == nil then
                -- noop
            elseif before == nil and after ~= nil then

            elseif before ~= nil and after == nil then

            elseif before < after then
                element:set_change_indicator(rt.Direction.DOWN)
            elseif before > after then
                element:set_change_indicator(rt.Direction.UP)
            else -- before == after
                element:set_change_indicator(rt.Direction.NONE)
            end

            element:set_change_indicator_visible(self._is_preview_active)

            if before_entry ~= nil then
                before_entry.offset = before_entry.offset + 1
            end

            if after_entry ~= nil then
                after_entry.offset = after_entry.offset + 1
            end
        end
    end

    -- set entry positions
    local off_screen_pos_x, off_screen_pos_y = x + width + 2 * element_size, 0
    for _, entry in pairs(self._entries) do
        for i, element in ipairs(entry.elements) do
            entry.target_positions[i][1] = off_screen_pos_x
        end
    end

    local outer_margin = 1.5 * rt.settings.margin_unit
    local factor = rt.settings.battle.priority_queue.first_element_scale_factor
    local size = rt.settings.battle.priority_queue.element_size
    local m = math.min(
        rt.settings.margin_unit,
        ((height - 2 * outer_margin) - ((#order) * element_size) - (element_size * factor)) / (#order + 1)
    )
    local center_x = x + width - 2 * outer_margin
    local element_x, element_y = center_x, y + 2 * outer_margin + 0.5 * element_size + 0.5 * element_size
    -- first element is larger
    local entity_index = {}
    self._render_order = {}
    for _, entity in pairs(order) do
        local entry = self._entries[entity]
        if entity_index[entity] == nil then entity_index[entity] = 0 end
        entity_index[entity] = entity_index[entity] + 1
        local i = entity_index[entity]
        entry.target_positions[i] = {
            element_x - element_size / 2,
            element_y - element_size / 2
        }
        element_y = element_y + element_size + m

        -- store scale animation in collider userdata, scale is applied during draw
        local is_first = is_empty(self._render_order)
        local collider = entry.colliders[i]

        if collider:get_userdata("is_first") ~= is_first then
            collider:add_userdata("scale", 1)
            collider:add_userdata("is_first", is_first)
        end

        table.insert(self._render_order, 1, { entity, entity_index[entity] }) -- sic, reverse order
    end
end

--- @brief
function bt.PriorityQueue:set_preview_order(order)
    self._preview_order = order
    if self._is_realized and self._is_preview_active then
        self:reformat()
    end
end 

--- @brief
function bt.PriorityQueue:set_order(order)
    self._current_order = order
    if self._is_realized then
        self:reformat()
    end
end

--- @brief
function bt.PriorityQueue:set_is_preview_active(b)
    if self._is_preview_active ~= b then
        self._is_preview_active = b
        if self._is_realized then
            self:reformat()
        end
    end
end 

--- @brief
function bt.PriorityQueue:get_is_preview_active(b)
    return self._is_preview_active
end 

--- @override
function bt.PriorityQueue:realize()
    if self._is_realized then return end
    self._is_realized = true
    self._entries = {}
    self:reformat()
    self:set_is_animated(true)
end

--- @override
function bt.PriorityQueue:update(delta)
    for _, entry in pairs(self._entries) do
        for i, collider in ipairs(entry.colliders) do
            local current_x, current_y = collider:get_centroid()
            local target = entry.target_positions[i]
            local target_x, target_y = target[1], target[2]

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
    
    self._world:update(delta)
end

--- @override
function bt.PriorityQueue:draw()
    if self._is_realized then
        rt.graphics.push()
        local size = rt.settings.battle.priority_queue.element_size
        local max_scale = rt.settings.battle.priority_queue.first_element_scale_factor
        local scaled_offset = 0
        for i = 1, #(self._render_order) do
            local t = self._render_order[i]

            local entry = self._entries[t[1]]
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
