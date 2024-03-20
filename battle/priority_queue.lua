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
        _world = rt.PhysicsWorld(0, 0),
        _elements = {}, -- Table<EntityID, bt.PriorityQueue.ElementEntry>
        _current_order = {}, -- Table<Entity>

        _floor = {}, --rt.LineCollider
        _rail = {}, -- rt.LogGradient
    })
end)

--- @brief
--- @param order Table<bt.Entity>
function bt.PriorityQueue:reorder(order)

    self._current_order = {}

    -- generate or remove new elements if entity or entity multiplicity is seen for the first time
    local n_seen = {}
    for _, entity in pairs(order) do
        if n_seen[entity] == nil then n_seen[entity] = 0 end
        n_seen[entity] = n_seen[entity] + 1
        table.insert(self._current_order,
    end

    for entity, n in pairs(n_seen) do
        if self._elements[entity] == nil then
            self._elements[entity] = {
                id = entity,
                elements = {},  -- Table<rt.PriorityQueue>
                colliders = {}, -- Table<rt.Collider>
                size = 0,
                target_positions = {} -- Table<Table<X, Y>>
            }
        end

        local entry = self._elements[entity]
        local element_size = rt.settings.battle.priority_queue.element_size

        while #entry.colliders < n do
            local queue_element = rt.PrioritQueueElement(
                self._scene,
                entity
            )
            table.insert(entry.elements, queue_element)
            table.insert(entry.colliders, rt.CircleCollider(
                self._world, rt.ColliderType.DYNAMIC, rt.graphics.get_width() + 1.5, 0, element_size / 2)
            )
            table.insert(entry.target_positions, {0, 0})

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

end