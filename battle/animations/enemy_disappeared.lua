rt.settings.enemy_disappeared = {
    duration = 3,
    tile_size = 32
}

--- @class
--- @param targets Table<rt.Widget>
bt.EnemyDisappearedAnimation = meta.new_type("EnemyDisappearedAnimation", function(targets)
    local out = meta.new(bt.EnemyDisappearedAnimation, {
        _targets = targets,
        _n_targets = sizeof(targets),
        _snapshots = {}, -- Table<rt.SnapshotLayout>
        _tiles = {},     -- Table<Table<rt.VertexShape>>
        _elapsed = 0,
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local snapshot = rt.SnapshotLayout()
        table.insert(out._snapshots, snapshot)
    end
    return out
end)

-- @overload
function bt.EnemyDisappearedAnimation:start()
    self._paths = {}
    self._tiles = {}
    for i = 1, self._n_targets do
        local target = self._targets[i]
        local snapshot = self._snapshots[i]
        snapshot:realize()
        snapshot:fit_into(target:get_bounds())

        target:set_is_visible(true)
        snapshot:snapshot(target)
        target:set_is_visible(false)

        local bounds = target:get_bounds()
        local tiles = {}
        local tile_size = rt.settings.enemy_disappeared.tile_size
        local bounds = self._targets[i]:get_bounds()
        local n_columns = bounds.width / tile_size
        local n_rows = bounds.height / tile_size

        local row_overlap = bounds.width - n_rows
        local column_overlap = bounds.height - n_columns

        n_rows, n_columns = math.ceil(n_rows), math.ceil(n_columns)

        local x_start, y_start = bounds.x, bounds.y
        local x, y = x_start, y_start
        for y_i = 1, n_rows do
            for x_i = 1, n_columns do
                local to_insert = rt.VertexRectangle(x, y, tile_size, tile_size)
                to_insert:set_texture(snapshot._canvas)
                to_insert:set_texture_rectangle(rt.AABB(x_i / n_columns, y_i / n_rows, 1 / n_columns, 1 / n_rows))
                --to_insert:set_color(rt.HSVA(rt.random.number(0, 1), 1, 1, 1))
                table.insert(tiles, to_insert)
                x = x + tile_size
            end
            y = y + tile_size
            x = x_start
        end
        table.insert(self._tiles, tiles)
    end
end

--- @overload
function bt.EnemyDisappearedAnimation:update(delta)
    local duration = rt.settings.enemy_appeared.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do
    end
    return self._elapsed < duration
end

--- @overload
function bt.EnemyDisappearedAnimation:finish()
    for i = 1, self._n_targets do
        local target = self._targets[i]
        target:set_is_visible(true)
    end
end

--- @overload
function bt.EnemyDisappearedAnimation:draw()
    for i = 1, self._n_targets do
        --self._snapshots[i]:draw()

        local tiles = self._tiles[i]
        for j = 1, #tiles do
            tiles[j]:draw()
        end
    end
end