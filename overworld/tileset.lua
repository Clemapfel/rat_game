rt.settings.overworld.tileset = {
    export_prefix = "spritesheets/",
    sha256_filename = "sha256.txt"
}

--- @class ow.Tileset
--- @param name String Tileset ID "debug_tileset
--- @param path_prefix String "assets/maps/debug"
ow.Tileset = meta.new_type("Tileset", rt.Drawable, function(name, path_prefix)
    local out = meta.new(ow.Tileset, {
        _path_prefix = path_prefix,
        _name = name,
        _is_realized = false,
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

    out._config_path = out._path_prefix .. "/" .. out._name .. ".lua"
    return out
end)

--- @class ow.Tile
--- @field id String
function ow.Tile(texture)
    return {
        quad = love.graphics.newQuad(0, 0, texture:getWidth(), texture:getHeight(), texture),
        is_empty = false
    }
end

--- @brief [internal]
function ow.Tileset:_check_should_export(name)
    local export_dir = rt.settings.overworld.tileset.export_prefix .. name
    local info = love.filesystem.getInfo(export_dir)
    if info == nil then return true end
    
    local image_path = self._path_prefix .. "/" .. name .. ".png"
    local current_hash = rt.filesystem.hash(image_path, true)
    local old_hash = love.filesystem.read(export_dir .. "/" .. rt.settings.overworld.tileset.sha256_filename)
    return old_hash ~= current_hash
end

--- @brief
--- @return love.graphics.ArrayImage
function ow.Tileset:_load_from_export(name)
    local export_dir = rt.settings.overworld.tileset.export_prefix .. name
    local sha256_filename = rt.settings.overworld.tileset.sha256_filename
    local files = love.filesystem.getDirectoryItems(export_dir)
    local slices = {}
    for i = 1, #files do
        if files[i] ~= sha256_filename then
            table.insert(slices, export_dir .. "/" .. files[i])
        end
    end
    return love.graphics.newArrayImage(slices)
end

--- @brief
--- @return love.graphics.ArrayImage
function ow.Tileset:_export(name)
    local image_path = self._path_prefix .. "/" .. name .. ".png"
    local current_hash = rt.filesystem.hash(image_path, true)
    local sha256_filename = rt.settings.overworld.tileset.sha256_filename

    local image = love.image.newImageData(image_path)
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

    -- export to .local/share/love/rat_game, so it can be loaded next time instead of generating slices
    local spritesheet_prefix = "spritesheets/" .. name
    love.filesystem.createDirectory(spritesheet_prefix)
    for i, slice in ipairs(slices) do
        local data = slice:encode("png", spritesheet_prefix.. "/" .. name .. "_" .. ternary(i < 10, "0", "") .. i .. ".png")
    end

    love.filesystem.write(spritesheet_prefix .. "/" .. sha256_filename, current_hash)
    return love.graphics.newArrayImage(slices)
end

--- @brief
function ow.Tileset:realize()
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

    if self:_check_should_export(self._name) then
        self._array_texture = self:_export(self._name)
    else
        self._array_texture = self:_load_from_export(self._name)
    end

    self._tiles = {}
    local empty_tile = ow.Tile(self._array_texture)
    empty_tile.quad:setViewport(0, 0, 0, 0) -- default transparent tile
    empty_tile.is_empty = true
    self._tiles[0] = empty_tile

    for tile_i = 1, x.tilecount do
        local tile = ow.Tile(self._array_texture)
        tile.quad:setLayer(tile_i)
        self._tiles[tile_i] = tile
    end

    for _, properties in pairs(x.tiles) do
        local tile_i = properties.id
        local config_maybe = properties["properties"]
        if not meta.is_nil(config_maybe) then
            for name, value in pairs(config_maybe) do
                assert(name ~= "id" and name ~= "quad")
                self._tiles[tile_i][name] = value
            end
        end
    end

    self._texture =  rt.Texture(self._path_prefix .. "/" .. self._name .. ".png")

    self._array_texture:setWrap(rt.TextureWrapMode.ZERO, rt.TextureWrapMode.ZERO)
    self._texture:set_wrap_mode(rt.TextureWrapMode.ZERO)

    self._is_realized = true
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
    local out = self._tiles[id - self._id_offset + 1]
    return out
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
