rt.settings.overworld.map = {
    tile_layer_id = "tilelayer",
    object_layer_id = "objectgroup"
}

--- @class TileLayer
--- @field tiles Table<ow.Tile>
--- @field batches Table<love.SpriteBatch>
function ow.TileLayer(tiles, sprite_batches)
    return {
        tiles = tiles,
        batches = sprite_batches
    }
end

--- @class ow.Map
ow.Map = meta.new_type("Map", function(name, path_prefix)
    local out = meta.new(ow.Map, {
        _path_prefix = path_prefix,
        _name = name,
        _tilesets = {},     -- Table<ow.Tileset>
        _tile_layers = {},  -- Table<ow.TileLayer>
    }, rt.Drawable)
    out:_create()
    return out
end)

--- @brief [internal]
function ow.Map:_create()
    local config_path = self._path_prefix .. "/" .. self._name .. ".lua"
    local chunk, error_maybe = love.filesystem.load(config_path)
    if not meta.is_nil(error_maybe) then
        rt.error("In ow.Map:create_from: Error when loading file at `" .. config_path .. "`: " .. error_maybe)
    end

    local x = chunk()

    self._n_tiles_width = x.width
    self._n_tiles_height = x.height
    self._tile_width = x.tilewidth
    self._tile_height = x.tileheight

    for _, tileset in pairs(x.tilesets) do
        meta.assert(not meta.is_nil(tileset.name))
        local to_push = ow.Tileset(tileset.name, self._path_prefix)
        to_push:set_id_offset(tileset.firstgid)
        table.insert(self._tilesets, to_push)
    end

    for _, layer in pairs(x.layers) do
        if layer.type == rt.settings.overworld.map.tile_layer_id then
            self:_create_tile_layer(layer)
        elseif layer.type == rt.settings.overworld.map.object_layer_id then
            self:_create_object_layer()
        end
    end

    return self
end

--- @brief [internal]
function ow.Map:_create_tile_layer(layer)
    local start_x, start_y, offset_x, offset_y = layer.x, layer.y, layer.offsetx, layer.offsety

    local w, h = self._tile_width, self._tile_height
    local n_columns = layer.width
    local n_rows = layer.height

    local tiles = {}    -- Table<ow.Tile>
    local batch = {}    -- Table<love.SpriteBatch>

    for _, tileset in pairs(self._tilesets) do
        table.insert(batch, love.graphics.newSpriteBatch(tileset._texture._native))
    end

    local x, y = start_x, start_y
    for row_i = 1, n_rows do
        for col_i = 1, n_columns do
            local index = (row_i - 1) * n_rows + col_i
            local id = layer.data[index]
            local pushed = false
            for tileset_i, tileset in pairs(self._tilesets) do
                local tile = tileset:get_tile(id)
                if not meta.is_nil(tile) then -- else, try next tileset
                    table.insert(tiles, tile)
                    batch[tileset_i]:add(tile.quad, col_i * self._tile_width, row_i * self._tile_height)
                    pushed = true
                end
            end

            if not pushed then
                rt.error("In ow.Map:_create_tile_layer: No tileset with tile id `" .. id .. "`")
            end
        end
    end

    table.insert(self._tile_layers, ow.TileLayer(tiles, batch))
end

--- @brief [internal]
function ow.Map:_create_object_layer(layer)

end

--- @brief
function ow.Map:draw()
    love.graphics.push()
    love.graphics.reset()
    for _, layer in pairs(self._tile_layers) do
        for _, batch in pairs(layer.batches) do
            love.graphics.draw(batch)
        end
    end

    love.graphics.pop()
end



