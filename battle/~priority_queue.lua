rt.settings.battle.priority_queue = {
    element_size = 75,

    collider_mass = 50,
    collider_speed = 2000,
    max_velocity = 500
}


--- @class rt.LogGradient
rt.LogGradient = meta.new_type("LogGradient", rt.Drawable, function(left_color, right_color)
    left_color = which(left_color, rt.RGBA(0, 0, 0, 0))
    right_color = which(right_color, rt.RGBA(0, 0, 0, 1))
    return meta.new(rt.LogGradient, {
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _shader = rt.Shader("assets/shaders/log_gradient.glsl"),
        _left_color = left_color,
        _right_color = right_color
    })
end)

--- @brief
function rt.LogGradient:resize(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @brief
function rt.LogGradient:draw()
    self._shader:bind()
    self._shader:send("_left_color", {self._left_color.r, self._left_color.g, self._left_color.b, self._left_color.a})
    self._shader:send("_right_color", {self._right_color.r, self._right_color.g, self._right_color.b, self._right_color.a})
    self._shape:draw()
    self._shader:unbind()
end

---################

--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, rt.Animation, function(scene)
    return meta.new(bt.PriorityQueue, {
        _scene = scene,
        _elements = {}, -- Table<EntityID, bt.PriorityQueue.ElementEntry>
        _current_order = {},  -- Table<bt.Entity>

        _world = rt.PhysicsWorld(0, 0),
        _floor = {}, --rt.LineCollider
        _rail = {}, -- rt.LogGradient
    })
end)

--- @brief [internal]
function bt.PriorityQueue.ElementEntry(scene, entity, world)
    -- element position is managed by body, for physics-based animations
    return {
        id = entity:get_id(),
        element = bt.PriorityQueueElement(scene, entity),
        collider = nil, -- rt.Collider
        preview_collider = nil, -- rt.Collider
        size = 0,
        target_position = {0, 0},
        preview_position = {0, 0},
        positions = {{0, 0}}
    }
end

--- @override
function bt.PriorityQueue:realize()
    if self._is_realized then return end
    self._is_realized = true
    self._elements = {}
    self:set_is_animated(true)

    local color = rt.Palette.BACKGROUND
    self._rail = rt.LogGradient(rt.RGBA(0, 0, 0, 0), rt.RGBA(0, 0, 0, 0.7))
end

--- @brief
function bt.PriorityQueue:add_entity(entity)
    local entry = bt.PriorityQueue.ElementEntry(self._scene, entity)
    self._elements[entity:get_id()] = entry
    entry.element:realize()
    local size = rt.settings.battle.priority_queue.element_size
    entry.element:fit_into(0, 0, size, size)
    entry.size = size
end

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    if self._is_realized then
        local m = rt.settings.margin_unit
        local element_size = rt.settings.battle.priority_queue.element_size
        local center_x = x + width - m - 0.5 * element_size
        local element_x, element_y = center_x, y + m + element_size + m

        for _, entry in pairs(self._elements) do
            entry.positions = {}
            if meta.is_nil(entry.collider) then
                entry.collider = rt.CircleCollider(self._world, rt.ColliderType.DYNAMIC, center_x, -0.5 * rt.graphics.get_height(), element_size / 2)
                entry.collider:set_collision_group(rt.ColliderCollisionGroup.NONE)
                entry.collider:set_mass(rt.settings.battle.priority_queue.collider_mass)
            end
        end

        for i, entity in pairs(self._current_order) do
            local id = entity:get_id()
            local entry = self._elements[id]
            table.insert(entry.positions, {
                element_x - element_size / 2, element_y - element_size / 2
            })
            entry.collider:set_disabled(false)
            entry.target_position = {element_x, element_y}
            element_y = element_y + element_size + m
        end

        local rail_overshoot = 0.5
        self._rail:resize(x - rail_overshoot * width, y, width * (1 + rail_overshoot), height)
    end
end

--- @override
function bt.PriorityQueue:update(delta)
    for _, entry in pairs(self._elements) do
        local collider = entry.collider
        local current_x, current_y = collider:get_centroid()
        local target_x, target_y = entry.target_position[1], entry.target_position[2]
        local angle = rt.angle( target_x- current_x, target_y - current_y)
        local magnitude = rt.settings.battle.priority_queue.collider_speed

        local distance = rt.magnitude(target_x - current_x, target_y - current_y)
        local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
        collider:apply_linear_impulse(vx, vy)

        -- increase friction as object gets closer to target, to avoid overshooting
        local damping = magnitude / (4 * distance)
        collider:set_linear_damping(damping)
    end

    self._world:update(delta)
end

--- @brief
function bt.PriorityQueue:reorder(order)

    for _, entity in pairs(order) do
        if self._elements[entity:get_id()] == nil then
            self:add_entity(entity)
        end
    end

    self._current_order = order
    self:reformat()
end

--- @override
function bt.PriorityQueue:draw()
    if self._is_realized then

        self._rail:draw()

        rt.graphics.push()
        for id, entry in pairs(self._elements) do
            local pos_x, pos_y = entry.collider:get_position()
            pos_x = math.floor(pos_x - 0.5 * entry.size)
            pos_y = math.floor(pos_y - 0.5 * entry.size)
            rt.graphics.translate(pos_x, pos_y)
            entry.element:draw()
            rt.graphics.translate(-1 * pos_x, -1 * pos_y)
        end
        rt.graphics.pop()
    end
end
