--- @class ow.Tileset
--- @param name String Tileset ID "debug_tileset
--- @param path_prefix String "assets/maps/debug"
ow.Tileset = meta.new_type("Tileset", function(name, path_prefix)
    local out = meta.new(ow.Tileset, {
        _path_prefix = path_prefix,
        _name = name,
        _id_offset = 0,
        _tiles = {},    -- Table<Number, ow.Tile>
        _texture = {},  -- rt.Texture
        _batch = nil    -- love.SpriteBatch
    }, rt.Drawable)

    out:_create()
    return out
end)

--- @class ow.Tile
--- @field id String
--- @field quad love.Quad
--- @param texture rt.Texture
--- @param column_index Number 0-based
--- @param row_index Number 0-based
function ow.Tile(texture, tile_w, tile_h, column_index, row_index)
    column_index = which(column_index, 1)
    row_index = which(row_index, 1)

    local x = (column_index) * tile_w
    local y =  (row_index) * tile_h

    if x < 0 or x > texture:get_width() or y < 0 or y > texture:get_height() then
        rt.error("In ow.Tile: texture position `" .. x .. ", " .. y .. "` is out of bounds for a texture of size " .. texture:get_width() .. "x" .. texture:get_height())
    end

    return {
       quad = love.graphics.newQuad(x, y, tile_w, tile_h, texture._native),
       id = -1
    }
end

--- @brief [internal]
function ow.Tileset:_create()
    local config_path = self._path_prefix .. "/" .. self._name .. ".lua"
    local chunk, error_maybe = love.filesystem.load(config_path)
    if not meta.is_nil(error_maybe) then
        rt.error("In ow.Map:create_from: Error when loading file at `" .. config_path .. "`: " .. error_maybe)
    end

    local x = chunk()

    self._tile_width = x.tilewidth
    self._tile_height = x.tileheight
    self._n_columns = x.columns
    self._n_tiles = x.tilecount

    self._tile_offset_x = x.tileoffset[1]
    self._tile_offset_y = x.tileoffset[2]

    self._texture = rt.Texture(self._path_prefix .. "/" .. x.name .. ".png")

    for _, config in pairs(x.tiles) do
        local i = config.id
        local tile = ow.Tile(
            self._texture,
            self._tile_width, self._tile_height,
            i, 0
        )
        tile.id = config.id

        if not meta.is_nil(config.properties) then
            for name, value in pairs(config.properties) do
                assert(name ~= "id" and name ~= "quad")
                tile[name] = value
            end
        end
        self._tiles[i] = tile
    end

    return self
end

--- @brief
function ow.Tileset:draw()
    if meta.is_nil(self._batch) then
        self._batch = love.graphics.newSpriteBatch(self._texture._native, self._n_tiles)

        local max_n_sprites_per_row = 5
        local start_x, start_y = 0, 0

        local x, y = start_x, start_y
        local row_width = 0
        for id, tile in pairs(self._tiles) do
            self._batch:add(tile.quad, x, y)
            x = x + self._tile_width

            row_width = row_width + 1
            if row_width > max_n_sprites_per_row then
                row_width = 0
                y = y + self._tile_height
                x = start_x
            end
        end
    end
    love.graphics.draw(self._batch)
end

--- @brief
function ow.Tileset:set_id_offset(offset)
    self._id_offset = offset
end

--- @brief
function ow.Tileset:get_id_offset()
    return self._id_offset
end

--- @brief
function ow.Tileset:has_id(id)
    return id <= self._id_offset + self._n_tiles
end

--- @brief
function ow.Tileset:get_tile(id)
    return self._tiles[id - self._id_offset]
end

