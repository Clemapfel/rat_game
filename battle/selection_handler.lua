--[[
Nodes:
+ Single Enemy
+ Single Ally
+ Ally Enemies
+ All Allies
+ Everyone
+ Field
]]--

bt.SelectionHandler = meta.new_type("BattleSelectionHandler", function(scene)
    return meta.new(bt.SelectionHandler, {
        _scene = scene,
        _nodes = {},
        _mapping = {}
    })
end)

bt.SelectionHandler.Direction = meta.new_enum({
    UP = "UP",
    RIGHT = "RIGHT",
    DOWN = "DOWN",
    LEFT = "LEFT"
})

--- @param entities Table<Table<bt.Entity>>
function bt.SelectionHandler:create_from(entities)
    self._nodes = {}
    self._mapping = {}

    local min_centroid_x, min_centroid_y, max_centroid_x, max_centroid_y = POSITIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for group in values(entities) do
        local sprites = {}
        local min_x, min_y, max_x, max_y = POSITIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
        for entity in values(group) do
            local sprite = self._scene._ui:get_sprite(entity)
            local bounds = sprite:get_bounds()
            min_x = math.min(min_x, bounds.x)
            max_x = math.max(max_x, bounds.x + bounds.width)
            min_y = math.min(min_y, bounds.y)
            max_y = math.max(max_y, bounds.y + bounds.height)
            table.insert(sprites, sprite)

        end

        local centroid_x = min_x + (max_x - min_x) * 0.5
        local centroid_y = min_y + (max_y - min_y) * 0.5

        table.insert(self._nodes, {
            entities = group,
            sprites = sprites,
            aabb = rt.AABB(min_x, min_y, max_x - min_x, max_y - min_y),
            centroid_x = centroid_x,
            centroid_y = centroid_y
        })

        min_centroid_x = math.min(min_centroid_x, centroid_x)
        min_centroid_y = math.min(min_centroid_y, centroid_y)
        max_centroid_x = math.max(max_centroid_x, centroid_x)
        max_centroid_y = math.max(max_centroid_y, centroid_y)
    end

    local Direction = bt.SelectionHandler.Direction

    function angle_to_direction(angle)
        angle = (angle + math.pi) / (2 * math.pi)
        local eights = 0.125
        local lookup = {
            [1] = Direction.UP,
            [2] = Direction.RIGHT,
            [3] = Direction.RIGHT,
            [4] = Direction.DOWN,
            [5] = Direction.DOWN,
            [6] = Direction.LEFT,
            [7] = Direction.LEFT,
            [8] = Direction.UP,
        }
        return lookup[math.ceil(angle / eights)]
    end

    for node in values(self._nodes) do
        -- find closest other node
        local min_distances = {
            [Direction.UP] = POSITIVE_INFINITY,
            [Direction.RIGHT] = POSITIVE_INFINITY,
            [Direction.DOWN] = POSITIVE_INFINITY,
            [Direction.LEFT] = POSITIVE_INFINITY,
        }

        local closest_node = {
            [Direction.UP] = nil,
            [Direction.RIGHT] = nil,
            [Direction.DOWN] = nil,
            [Direction.LEFT] = nil,
        }

        for other in values(self._nodes) do
            if node ~= other then
                local distance = rt.distance(node.centroid_x, node.centroid_y, other.centroid_x, other.centroid_y)
                local angle = rt.angle(other.centroid_x - node.centroid_x, other.centroid_y - node.centroid_y)
                local direction = angle_to_direction(angle)
                if distance < min_distances[direction] then
                    closest_node[direction] = other
                end
            end
        end

        self._mapping[node] = closest_node
    end
end

--- @brief [internal]
function bt.SelectionHandler:draw()
    love.graphics.setLineWidth(1)
    for node, neighbors in pairs(self._mapping) do
        local from_x, from_y = node.centroid_x, node.centroid_y
        love.graphics.setColor(rt.color_unpack(rt.Palette.BLACK))
        love.graphics.circle("fill", from_x, from_y, 7)
        love.graphics.setColor(rt.color_unpack(rt.Palette.WHITE))
        love.graphics.circle("fill", from_x, from_y, 6)
        for direction in range(
            bt.SelectionHandler.Direction.UP,
            bt.SelectionHandler.Direction.RIGHT,
            bt.SelectionHandler.Direction.DOWN,
            bt.SelectionHandler.Direction.LEFT
        ) do
            if neighbors[direction] ~= nil then
                local to_x, to_y = neighbors[direction].centroid_x, neighbors[direction].centroid_y
                love.graphics.line(from_x, from_y, to_x, to_y)
            end
        end
    end
end