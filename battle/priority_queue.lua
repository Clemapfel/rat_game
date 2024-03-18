rt.settings.battle.priority_queue = {
    element_size = 75
}

--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, function(scene)
    return meta.new(bt.PriorityQueue, {
        _scene = scene,
        _elements = {}, -- Table<EntityID, bt.PriorityQueue.ElementEntry>
    })
end)

--- @brief [internal]
function bt.PriorityQueue.ElementEntry(scene, entity)
    -- instead of reformating, elements, store position as vector and translate during draw
    return {
        element = bt.PriorityQueueElement(scene, entity),
        positions = {{0, 0}}
    }
end

--- @override
function bt.PriorityQueue:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._elements = {}
    for _, entity in pairs(self._scene:get_entities()) do
        local entry = bt.PriorityQueue.ElementEntry(self._scene, entity)
        self._elements[entity:get_id()] = entry
        entry.element:realize()
        local size = rt.settings.battle.priority_queue.element_size
        entry.element:fit_into(0, 0, size, size)
    end
end

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    if self._is_realized then
        local h = 0
        local size = 75
        for _, entry in pairs(self._elements) do
            entry.positions = {{x, y + h}, {x + size * 2, y + h}}
            h = h + size + 10
        end
    end
end

--- @override
function bt.PriorityQueue:draw()
    if self._is_realized then
        rt.graphics.push()
        for id, entry in pairs(self._elements) do
            for _, position in pairs(entry.positions) do
                rt.graphics.translate(position[1], position[2])
                entry.element:draw()
                rt.graphics.translate(-1 * position[1], -1 * position[2])
            end
        end
        rt.graphics.pop()
    end
end