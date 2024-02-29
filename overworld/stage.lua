rt.settings.overworld.stage = {
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
--- @brief non-template sprite
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

--- @class ow.Stage
ow.Stage = meta.new_type("Stage", ow.OverworldEntity, function(world, name, path_prefix)
    local out = meta.new(ow.Stage, {
        _path_prefix = path_prefix,
        _name = name,
        _world = world,
        _tilesets = {},     -- Table<ow.Tileset>
        _tile_layers = {},  -- Table<ow.TileLayer>
        _object_layers = {},    -- Table<ow.ObjectLayer>
        _debug_draw_enabled = true
    })
    return out
end)

--- @override
function ow.Stage:draw()
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

        if rt.current_scene:get_debug_draw_enabled() then
            for _, collider in pairs(layer.colliders) do
                collider:draw()
            end
        end
    end

    love.graphics.pop()
end

--- @override
function ow.Stage:update(delta)
end

--- @brief
function ow.Stage:realize()
    local config_path = self._path_prefix .. "/" .. self._name .. ".lua"
    local chunk, error_maybe = love.filesystem.load(config_path)
    if not meta.is_nil(error_maybe) then
        rt.error("In ow.Stage:create_from: Error when loading file at `" .. config_path .. "`: " .. error_maybe)
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
        to_push:realize()
        table.insert(self._tilesets, to_push)
    end

    for _, layer in pairs(x.layers) do
        if layer.type == rt.settings.overworld.stage.tile_layer_id then
            self:_create_tile_layer(layer)
        elseif layer.type == rt.settings.overworld.stage.object_layer_id then
            self:_create_object_layer(layer)
        end
    end
end

--- @brief [internal]
function ow.Stage._generate_tile_colliders(matrix)

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

--- @brief [internal]
function ow.Stage:_create_tile_layer(layer)
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
                if tile.is_empty then
                    pushed = true
                    break
                else
                    if not meta.is_nil(tile) then -- else, try next tileset
                        table.insert(tiles, tile)
                        batch[tileset_i]:add(tile.quad, (col_i - 1) * self._tile_width, (row_i - 1) * self._tile_height)
                        tile_hitbox:set(col_i, row_i, ternary(which(tile[rt.settings.overworld.stage.is_solid_id], false), 1, 0))
                        pushed = true
                        break
                    end
                end
            end

            if not pushed then
                rt.error("In ow.Stage:_create_tile_layer: No tileset with tile id `" .. id .. "` available")
            end
        end
    end

    -- generate hitboxes for solid tiles
    local bounds = ow.Stage._generate_tile_colliders(tile_hitbox)
    local colliders = {}
    for _, aabb in pairs(bounds) do
        table.insert(colliders, rt.RectangleCollider(self._world, rt.ColliderType.STATIC,
                (aabb.x - 1) * w, (aabb.y - 1) * h,
                aabb.width * w, aabb.height * h
        ))
    end

    table.insert(self._tile_layers, ow.TileLayer(tiles, batch))
    table.insert(self._object_layers, ow.ObjectLayer({}, colliders))
end

--- @brief [internal] parse tile object layer, objects without a `class` field will be parsed as basic sprites / colliders
function ow.Stage:_create_object_layer(layer)
    local colliders = {}
    local sprites = {}
    local entities = {}

    for _, object in pairs(layer.objects) do
        local class_id = object.type

        -- basic collider or sprite, not a custom class
        if class_id == nil or class_id == "" then
            local is_solid = which(object.properties[rt.settings.overworld.stage.is_solid_id], true)
            local is_sprite = meta.is_number(object.gid)
            local x, y, w, h = math.round(object.x), math.round(object.y), math.round(object.width), math.round(object.height)
            if is_sprite then y = y - h end -- TODO: why is this necessary?

            if is_solid then -- basic hitbox
                local to_push
                if object.shape == "rectangle" then
                    to_push = rt.RectangleCollider(self._world, rt.ColliderType.STATIC, x, y, w, h)
                elseif object.shape == "polygon" then
                    if #object.polygon > 16 then
                        rt.error("In ow.Stage:_create_object_layer: polygon shape with id `" .. object.id .. "` of object layer `" .. layer.id .. "`: has `" .. tostring(#object.polygon / 2) .. "` vertices, but only up to 8 vertices are allowed")
                    end

                    local vertices = {}
                    for _, xy in pairs(object.polygon) do
                        -- convert to global coordinates
                        table.insert(vertices, xy.x + x)
                        table.insert(vertices, xy.y + y)
                    end

                    if not love.math.isConvex(vertices) then
                        rt.warning("In ow.Stage:_create_object_layer: polygon shape with id `" .. object.id .. "` of object layer `" .. layer.id .. "` is non-convex, its outer hull will be used instead")
                    end

                    to_push = rt.PolygonCollider(self._world, rt.ColliderType.STATIC, splat(vertices))
                else
                    rt.warning("In ow.Stage._create_object_layer: basic collider with shape type `" .. object.shape .. "` is not supported, using AABB instead")
                    to_push = rt.RectangleCollider(self._world, rt.ColliderType.STATIC, x, y, w, h)
                end
                table.insert(colliders, to_push)
            end

            if is_sprite then
                local pushed = false
                for tileset_i, tileset in pairs(self._tilesets) do
                    local tile = tileset:get_tile(object.gid)
                    if not meta.is_nil(tile) then -- else, try next tileset
                        local to_push = ow.ObjectSprite(
                            tileset._texture,
                            tileset:get_texture_rectangle(object.gid),
                            x, y, w, h
                        )
                        to_push.id = object.id
                        table.insert(sprites, to_push)
                        pushed = true
                        break
                    end
                end

                if not pushed then
                    rt.error("In ow.Stage:_create_object_layer: No tileset with tile id `" .. id .. "` available")
                end
            end
        else
            rt.error("In ow.Stage._create_object_layer: unhandled type `" .. object.type .. "`")
        end
    end

    table.insert(self._object_layers, ow.ObjectLayer(sprites, colliders))
end
