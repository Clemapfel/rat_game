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
ow.Map = meta.new_type("Map", rt.Drawable, rt.Animation, function(name, path_prefix)
    local out = meta.new(ow.Map, {
        _path_prefix = path_prefix,
        _name = name,
        _world = rt.PhysicsWorld(0, 0),
        _tilesets = {},     -- Table<ow.Tileset>
        _tile_layers = {},  -- Table<ow.TileLayer>
        _object_layers = {},    -- Table<ow.ObjectLayer>
        _debug_draw_enabled = true
    })
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
        table.insert(batch, love.graphics.newSpriteBatch(tileset._array_texture))
    end

    local tile_hitbox = rt.Matrix(n_columns, n_rows)

    local x, y = start_x, start_y
    local i = 1
    for row_i = 1, n_rows do
        for col_i = 1, n_columns do
            local index = (row_i - 1) * n_columns + col_i
            local id = layer.data[index]
            assert(not meta.is_nil(id))
            local pushed = false
            for tileset_i, tileset in pairs(self._tilesets) do
                local tile = tileset:get_tile(id)
                if not meta.is_nil(tile) then -- else, try next tileset
                    table.insert(tiles, tile)
                    batch[tileset_i]:add(tile.quad, (col_i - 1) * self._tile_width, (row_i - 1) * self._tile_height)
                    tile_hitbox:set(col_i, row_i, ternary(which(tile[rt.settings.overworld.map.is_solid_id], false), 1, 0))
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

    -- generate hitboxes for solid tiles
    local bounds = ow.Map._generate_tile_colliders(tile_hitbox)
    --table.insert(bounds, rt.AABB(3, 5, 15, 13))

    local colliders = {}
    for _, aabb in pairs(bounds) do
        table.insert(colliders, rt.RectangleCollider(self._world, rt.ColliderType.STATIC,
                (aabb.x - 1) * w, (aabb.y - 1) * h,
                aabb.width * w, aabb.height * h
        ))
    end

    table.insert(self._object_layers, ow.ObjectLayer({}, colliders))
end

--- @brief [internal]
function ow.Map:_create_object_layer(layer)
    local colliders = {}
    local sprites = {}

    local id_to_collider = {} -- Number -> rt.Collider

    for _, object in pairs(layer.objects) do
        local solid = which(object.properties[rt.settings.overworld.map.is_solid_id], false)
        local x, y, w, h = math.round(object.x), math.round(object.y), math.round(object.width), math.round(object.height)
        local is_sprite = not meta.is_nil(object.gid)

        if is_sprite then y = y - h end -- TODO: why is this necessary?

        local to_push
        if object.shape == "rectangle" then
            to_push = rt.RectangleCollider(self._world, rt.ColliderType.STATIC, x, y, w, h)
        elseif object.shape == "circle" or object.shape == "ellipse" then
            local x_radius, y_radius = w / 2, h / 2
            local center_x, center_y = x + x_radius, y + y_radius
            to_push = rt.CircleCollider(self._world, rt.ColliderType.STATIC, center_x, center_y, mix(x_radius, y_radius, 0.5))
        elseif object.shape == "point" then
            to_push = rt.CircleCollider(self._world, rt.ColliderType.STATC, x, y, 1 / 6 * 32) --rt.settings.overworld.player.radius)
        elseif object.shape == "polygon" then
            if #object.polygon > 16 then
                rt.error("In ow.Map:_create_object_layer: polygon shape with id `" .. object.id .. "` of object layer `" .. layer.id .. "`: has `" .. tostring(#object.polygon / 2) .. "` vertices, but only up to 8 vertices are allowed")
            end

            local vertices = {}
            for _, xy in pairs(object.polygon) do
                -- convert to global coordinates
                table.insert(vertices, xy.x + x)
                table.insert(vertices, xy.y + y)
            end

            if not love.math.isConvex(vertices) then
                rt.warning("In ow.Map:_create_object_layer: polygon shape with id `" .. object.id .. "` of object layer `" .. layer.id .. "` is non-convex, its outer hull will be used instead")
            end

            to_push = rt.PolygonCollider(self._world, rt.ColliderType.STATIC, splat(vertices))
        end

        to_push:add_userdata("id", object.id)
        table.insert(colliders, to_push)

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

    love.graphics.setColor(1, 1, 1, 1)
    rt.graphics.set_blend_mode(rt.BlendMode.NORMAL)

    for _, layer in pairs(self._tile_layers) do
        for _, batch in pairs(layer.batches) do
            love.graphics.draw(batch)
        end
    end

    for _, layer in pairs(self._object_layers) do
        for _, sprite in pairs(layer.sprites) do
            sprite.shape:draw()
        end

        if self._debug_draw_enabled then
            for _, collider in pairs(layer.colliders) do
                collider:draw()
            end
        end
    end


    love.graphics.pop()
end

--- @brief [internal]
function ow.Map._generate_tile_colliders(matrix)


    local clock = rt.Clock()
    local out = {}

    local seen = rt.Matrix(matrix:get_dimension(1), matrix:get_dimension(2))
    seen:clear(false)

    local row_to_aabbs = {}
    local aabb = rt.AABB(1, 1, 0, 0)
    local active = false
    for row_i = 1, matrix:get_dimension(2) do
        table.insert(row_to_aabbs, {})
        for col_i = 1, matrix:get_dimension(1) do
            local solid = matrix:get(col_i, row_i) ~= 0

            if solid then
                -- open
                if not active then
                    aabb = rt.AABB(col_i, row_i, 0, 1)
                    aabb.merged = false
                    active = true
                end

                -- extend
                if active then
                    aabb.width = aabb.width + 1
                end
            else
                if active then
                    -- close
                    table.insert(row_to_aabbs[row_i], aabb)
                    active = false
                else
                    -- continue
                end
            end
            --seen:set(col_i, row_i, true)
        end

        if active then
            -- close at end of line
            table.insert(row_to_aabbs[row_i], aabb)
            active = false
        end
    end

    -- merge step
    local current_row = 1
    for _, row in pairs(row_to_aabbs) do
        for _, shape in pairs(row) do
            if not shape.merged and current_row < #row_to_aabbs then
                for row_i = current_row + 1, #row_to_aabbs do
                    local merge_successfull = false
                    for _, other_shape in pairs(row_to_aabbs[row_i]) do
                        if not other_shape.merged then
                            if shape.x == other_shape.x and shape.width == other_shape.width then
                                shape.height = shape.height + 1
                                other_shape.merged = true
                                merge_successfull = true
                            end
                        end
                    end
                    if not merge_successfull then break end
                end
            end
        end

        current_row = current_row + 1
    end


    local out = {}
    for _, row in pairs(row_to_aabbs) do
        for _, shape in pairs(row) do
            local already_merged = which(shape.merged, false)
            if not already_merged then
                table.insert(out, shape)
            end
        end
    end

    return out
end

--- @brief
function ow.Map:update(delta)
    self._world:update(delta)
end

