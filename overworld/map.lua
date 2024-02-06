rt.settings.overworld.map = {
    tile_layer_id = "tilelayer",
    object_layer_id = "objectgroup",
    is_solid_id = "is_solid",
}

--- @class ow.TileLayer
--- @field tiles Table<ow.Tile>
--- @field batches Table<love.SpriteBatch>
function ow.TileLayer(tiles, sprite_batches)
    return {
        tiles = tiles,
        batches = sprite_batches
    }
end

--- @class ow.ObjectSprite
--- @param texture rt.Texture
function ow.ObjectSprite(texture, texture_rectangle, x, y, width, height)
    local out = {
        shape = rt.VertexRectangle(x, y, width, height),
        id = -1,
    }
    out.shape:set_texture(texture)
    out.shape:set_texture_rectangle(texture_rectangle)
    return out
end

--- @class ow.ObjectLayer
function ow.ObjectLayer(sprites, colliders)
    return {
        sprites = sprites,          -- Table<ow.ObjectSprites>
        colliders = colliders       -- Table<rt.Collider>
    }
end

--- @class ow.Map
ow.Map = meta.new_type("Map", function(name, path_prefix)
    local out = meta.new(ow.Map, {
        _path_prefix = path_prefix,
        _name = name,
        _world = rt.PhysicsWorld(0, 0),
        _tilesets = {},     -- Table<ow.Tileset>
        _tile_layers = {},  -- Table<ow.TileLayer>
        _object_layers = {},    -- Table<ow.ObjectLayer>
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
            self:_create_object_layer(layer)
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

    local hitbox_map = rt.Matrix(n_columns, n_rows)

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
                    batch[tileset_i]:add(tile.quad, (col_i - 1) * self._tile_width, (row_i - 1) * self._tile_height)

                    hitbox_map:set(col_i, row_i, ternary(which(tile[rt.settings.overworld.map.is_solid_id], false), 1, 0))
                    pushed = true
                    break
                end
            end

            if not pushed then
                rt.error("In ow.Map:_create_tile_layer: No tileset with tile id `" .. id .. "` available")
            end
        end
    end

    table.insert(self._tile_layers, ow.TileLayer(tiles, batch))
end

--- @brief [internal]
function ow.Map:_create_object_layer(layer)
    local colliders = {}
    local sprites = {}

    local id_to_collider = {} -- Number -> rt.Collider

    for _, object in pairs(layer.objects) do
        local solid = which(object.properties[rt.settings.overworld.map.is_solid_id], false)
        local x, y, w, h = math.round(object.x), math.round(object.y), math.round(object.width), math.round(object.height)
        if object.shape == "rectangle" then
            local to_push = rt.RectangleCollider(self._world, rt.ColliderType.STATIC, x, y, w, h)
            to_push:add_userdata("id", object.id)
            --to_push:set_is_sensor(not solid)
            table.insert(colliders, to_push)
        elseif object.shape == "point" then
            local to_push = rt.CircleCollider(self._world, rt.ColliderType.STATC, x, y, rt.settings.overworld.player.radius)
            --to_push:set_is_sensor(not solid)
            table.insert(colliders, to_push)
        end

        local id = object.gid
        if not meta.is_nil(object.gid) then
            local pushed = false
            for tileset_i, tileset in pairs(self._tilesets) do
                local tile = tileset:get_tile(id)
                if not meta.is_nil(tile) then -- else, try next tileset
                    local to_push = ow.ObjectSprite(
                        tileset._texture,
                        tileset:get_texture_rectangle(id),
                        x, y, w, h
                    )
                    to_push.id = object.id
                    table.insert(sprites, to_push)
                end
                pushed = true
            end

            if not pushed then
                rt.error("In ow.Map:_create_object_layer: No tileset with tile id `" .. id .. "` available")
            end
        end
    end

    table.insert(self._object_layers, ow.ObjectLayer(sprites, colliders))
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

    for _, layer in pairs(self._object_layers) do
        for _, sprite in pairs(layer.sprites) do
            sprite.shape:draw()
        end

        for _, collider in pairs(layer.colliders) do
            collider:draw()
        end
    end

    love.graphics.pop()
end



