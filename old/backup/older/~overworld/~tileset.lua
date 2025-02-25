--- @class ow.Tileset
--- @param name String Tileset ID "debug_tileset
--- @param path_prefix String "assets/maps/debug"
ow.Tileset = meta.new_type("Tileset", rt.Drawable, function(name, path_prefix)
    local out = meta.new(ow.Tileset, {
        _path_prefix = path_prefix,
        _name = name,
        _id_offset = 0,
        _tile_width = -1,
        _tile_height = -1,
        _n_columns = -1,
        _n_tiles = -1,
        _tiles = {},    -- Table<Number, ow.Tile>
        _array_texture = {},
        _texture = {},  -- rt.Texture
        _batch = nil    -- love.SpriteBatch
    })
    out:_create()
    return out
end)

--- @class ow.Tile
--- @field id String
function ow.Tile(texture)
    return {
       quad = love.graphics.newQuad(0, 0, texture:getWidth(), texture:getHeight(), texture),
       id = id
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

    local image_path = self._path_prefix .. "/" .. x.name .. ".png"
    local image = rt.Image(self._path_prefix .. "/" .. x.name .. ".png")

    do -- generate array texture, unless already exported version is available as a folder of individual images
        local export_dir = "spritesheets/" .. x.name
        local info = love.filesystem.getInfo(export_dir)

        -- check whether the current input file is different from the one last used to generate the individual images
        local sha256_filename = "sha256.txt"
        local current_hash = rt.filesystem.hash(image_path, true)
        local old_hash = love.filesystem.read(export_dir .. "/" .. sha256_filename)

        if not meta.is_nil(info) and info.type == "directory" and old_hash == current_hash then
            local files = love.filesystem.getDirectoryItems(export_dir)
            local slices = {}
            for i = 1, #files do
                if files[i] ~= sha256_filename then
                    table.insert(slices, export_dir .. "/" .. files[i])
                end
            end
            self._array_texture = love.graphics.newArrayImage(slices)
        else
            local image = image._native
            local tile_w, tile_h = self._tile_width, self._tile_height
            local slices = {}
            for tile_x = 1, image:getWidth() / tile_w do
                for tile_y = 1, image:getHeight() / tile_h do
                    local data = love.image.newImageData(tile_w, tile_h, rt.Image.FORMAT) -- rgba16
                    for x_offset = 1, tile_w do
                        for y_offset = 1, tile_h do
                            local r, g, b, a = image:getPixel((tile_x - 1) * tile_w + x_offset - 1, (tile_y - 1) * tile_h + y_offset - 1)
                            data:setPixel(x_offset - 1, y_offset - 1, r, g, b, a)
                        end
                    end
                    table.insert(slices, data)
                end
            end

            -- export to .local/share/love/rat_game, so it can be loaded next time instead
            local spritesheet_prefix = "spritesheets/" .. x.name
            love.filesystem.createDirectory(spritesheet_prefix)
            for i, slice in ipairs(slices) do
                local data = slice:encode("png", spritesheet_prefix.. "/" .. x.name .. "_" .. ternary(i < 10, "0", "") .. i .. ".png")
            end

            love.filesystem.write(spritesheet_prefix .. "/" .. sha256_filename, current_hash)
            self._array_texture = love.graphics.newArrayImage(slices)
        end
    end
    self._texture = rt.Texture(image)

    for tile_i = 1, x.tilecount do
        local tile = ow.Tile(self._array_texture)
        tile.id = id
        tile.quad:setLayer(tile_i)

        local config_maybe = x.tiles[tile_i]
        local id = tile_i - 1
        if not meta.is_nil(config_maybe) then
            id = config_maybe.id
            if not meta.is_nil(config_maybe.properties) then
                for name, value in pairs(config_maybe.properties) do
                    assert(name ~= "id" and name ~= "quad")
                    tile[name] = value
                end
            end
        end

        self._tiles[id] = tile
    end

    return self
end

--- @brief
function ow.Tileset:draw()
    if meta.is_nil(self._batch) then
        self._batch = love.graphics.newSpriteBatch(self._texture._native, self._n_tiles)

        local max_n_sprites_per_row = 0
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
function ow.Tileset:get_tile(id)
    return self._tiles[id - self._id_offset]
end

--- @brief
function ow.Tileset:get_texture_rectangle(id)
    local w, h = self._texture:get_size()
    local tile_w = self._tile_width / w
    local tile_h = self._tile_height / h

    local col_i = id - self._id_offset
    return rt.AABB(
        col_i * tile_w, 0,
            tile_w, tile_h
    )
end

