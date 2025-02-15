rt.settings.overworld.stage_config = {
    config_path = "assets/stages",
    hitbox_class_name = "Hitbox"
}

--[[
expects Tiled stage
located at /assets/stages
stage size "infinite"
with non-injected tilesets
]]--

--- @class ow.StageConfig
ow.StageConfig = meta.new_type("StageConfig", function(id)
    local out = ow.StageConfig._atlas[id]
    if out == nil then
        out = meta.new(ow.StageConfig, {
            _id = id,
            _tilesets = {}, -- Table<rt.TilesetConfig>
            _gid_to_tileset_tile = {},
            _layer_i_to_layer = {},

        })
        out:realize()
        ow.StageConfig._atlas[id] = out
    end
    return out
end)
ow.StageConfig._atlas = {}

ow.LayerType = meta.new_enum("LayerType", {
    TILES = "tilelayer",
    OBJECTS = "objectlayer"
})

--- @brief
function ow.StageConfig:realize()
    local config_path_prefix = rt.settings.overworld.stage_config.config_path .. "/"
    local path = config_path_prefix .. self._id .. ".lua"

    local load_success, chunk_or_error, love_error = pcall(love.filesystem.load, path)
    if not load_success then
        rt.error("In rt.load_config: error when parsing stage at `" .. path .. "`: " .. chunk_or_error)
        return
    end

    if love_error ~= nil then
        rt.error("In rt.load_config: error when loading stage at `" .. path .. "`: " .. love_error)
        return
    end

    local chunk_success, config_or_error = pcall(chunk_or_error)
    if not chunk_success then
        rt.error("In rt.load_config: error when running stage at `" .. path .. "`: " .. config_or_error)
        return
    end

    local config = config_or_error
    local _get = function(t, name)
        local out = t[name]
        if out == nil then
            rt.error("In rt.load_config: trying to access property `" .. name .. "` of stage at `" .. path .. "`, but it does not exist")
        end
        return out
    end

    -- global properties
    self._tile_width = _get(config, "tilewidth")
    self._tile_height = _get(config, "tileheight")
    self._n_columns = _get(config, "width")
    self._n_rows = _get(config, "height")

    -- init tilesets
    self._tilesets = {}
    for tileset in values(_get(config, "tilesets")) do
        table.insert(self._tilesets, {
            id_offset = _get(tileset, "firstgid"),
            tileset = ow.TilesetConfig(_get(tileset, "name"))
        })
    end

    self._gid_to_tileset_tile = {}
    for entry in values(self._tilesets) do
        local offset = entry.id_offset
        for tile_id in values(entry.tileset:get_tile_ids()) do
            self._gid_to_tileset_tile[tile_id + offset] = {
                id = tile_id,
                tileset = entry.tileset
            }
        end
    end

    self._layer_i_to_layer = {}
    local is_solid_name = rt.settings.overworld.tileset_config.is_solid_property_name

    local layer_i = 1
    local n_layers = 0
    for layer in values(_get(config, "layers")) do
        local to_add = {
            properties = {},
            is_visible = _get(layer, "visible"),
            name = _get(layer, "name"),
            x_offset = _get(layer, "offsetx"),
            y_offset = _get(layer, "offsety"),
            parallax_factor_x = _get(layer, "parallaxx"),
            parallax_factor_y = _get(layer, "parallaxy"),
        }

        self._layer_i_to_layer[layer_i] = to_add
        layer_i = layer_i + 1
        n_layers = n_layers + 1

        local layer_type = _get(layer, "type")
        if layer_type == "tilelayer" then
            to_add.type = ow.LayerType.TILES
            to_add.gid_matrix = rt.Matrix()
            to_add.n_columns = _get(layer, "width")
            to_add.n_rows = _get(layer, "height")

            if layer.chunks == nil then
                rt.error("In ow.StageConfig.realize: layer `" .. layer_i .. "` does not have `chunks` field, is this an infinite map?")
            end

            local is_solid_matrix = rt.Matrix()

            -- construct gid matrix
            local chunks = _get(layer, "chunks")
            for chunk in values(chunks) do
                local x_offset = _get(chunk, "x")
                local y_offset = _get(chunk, "y")
                local width = _get(chunk, "width")
                local height = _get(chunk, "height")
                local data = _get(chunk, "data")
                for y = 1, height do
                    for x = 1, width do
                        local gid = data[(y - 1) * width + x]
                        if gid ~= 0 then -- empty tile
                            assert(to_add.gid_matrix:get(x + x_offset, y + y_offset) == nil)
                            to_add.gid_matrix:set(x + x_offset, y + y_offset, gid)

                            local tile = self._gid_to_tileset_tile[gid]
                            local is_solid = tile.tileset:get_tile_property(tile.id, is_solid_name) == true

                            if is_solid then
                                is_solid_matrix:set(x + x_offset, y + y_offset, true)
                            end
                        end
                    end
                end
            end

            -- per-layer properties
            if layer.properties ~= nil then
                for key, value in pairs(_get(layer, "properties")) do
                    to_add.properties[key] = value
                end
            end
        elseif layer_type == "objectgroup" then
            to_add.type = ow.LayerType.OBJECTS
            to_add.objects = ow.parse_tiled_object_group(layer)
        elseif layer_type == "imagelayer" then
            -- noop
            rt.warning("In ow.StageConfig.realizue: layer type `imagelayer` of stage `" .. self._id .. "` is not supported")
        else
            rt.error("In ow.StageConfig.realize: unhandled layer type `" .. layer_type .. "of stage `" .. self._id .. "` is not supported")
        end
    end

    self._n_layers = n_layers
end

--- @brief
function ow.StageConfig:get_n_layers()
    return self._n_layers
end

--- @brief
function ow.StageConfig:get_layer_type(i)
    local layer = self._layer_i_to_layer[i]
    if layer == nil then
        rt.error("In ow.StageConfig.get_layer_type: layer index `" .. i .. "` is out of bounds for a stage with `" .. self._n_layers .. "` layers")
        return nil
    end
    return layer
end

--- @brief
function ow.StageConfig:_construct_spritebatches()
    self._layer_i_to_tileset_to_spritebatch = {}
    for layer_i, layer in pairs(self._layer_i_to_layer) do
        local tileset_to_spritebatch = {}
        self._layer_i_to_tileset_to_spritebatch[layer_i] = tileset_to_spritebatch

        if layer.type == ow.LayerType.TILES then
            local current_x, current_y = 0, 0
            for row_i = 1, self._n_rows do
                for col_i = 1, self._n_columns do
                    local gid = layer.gid_matrix:get(col_i, row_i)
                    if gid ~= nil then
                        local entry = self._gid_to_tileset_tile[gid]
                        local tileset = entry.tileset

                        local spritebatch = tileset_to_spritebatch[tileset]
                        if spritebatch == nil then
                            spritebatch = ow.SpriteBatch(tileset:get_texture())
                            tileset_to_spritebatch[tileset] = spritebatch
                        end

                        local local_id = entry.id
                        local texture_x, texture_y, texture_w, texture_h = tileset:get_texture_bounds(local_id)
                        local tile_w, tile_h = tileset:get_tile_size(local_id)
                        local _ = spritebatch:add(
                            current_x, current_y, tile_w, tile_h,
                            texture_x, texture_y, texture_w, texture_h,
                            false, false, 0
                        )
                    end
                    current_x = current_x + self._tile_width
                end
                current_y = current_y + self._tile_height
                current_x = 0
            end
        end
    end
end

--- @brief
function ow.StageConfig:_construct_object_sprites()
    self._layer_i_to_object_spritebatches = {}
    for layer_i, layer in pairs(self._layer_i_to_layer) do
        if layer.type == ow.LayerType.OBJECTS then
            local batches = {}
            local bounds = {}
            self._layer_i_to_object_spritebatches[layer_i] = {
                batches = batches,
                bounds = bounds
            }

            -- group subsequent sprites of same tileset to batches
            -- but 1:1 tileset to batches is not possible, it would violate render order
            local last_tileset = nil
            local current_batch = nil
            for object in values(layer.objects) do
                if object.type == ow.ObjectType.SPRITE then
                    local entry = self._gid_to_tileset_tile[object.gid]
                    local tileset = entry.tileset

                    if tileset ~= last_tileset then
                        last_tileset = tileset
                        current_batch = ow.SpriteBatch(tileset:get_texture())
                        table.insert(batches, current_batch)
                    end

                    local local_id = entry.id
                    local texture_x, texture_y, texture_w, texture_h = tileset:get_texture_bounds(local_id)
                    current_batch:add(
                        object.top_left_x, object.top_left_y, object.width, object.height,
                        texture_x, texture_y, texture_w, texture_h,
                        object.flip_horizontally, object.flip_vertically, object.rotation
                    )

                    table.insert(bounds, {
                        object.top_left_x, object.top_left_y, object.width, object.height
                    })
                end
            end
        end
    end
end

ow.PhysicsShapeType = meta.new_enum("PhysicsShapeType", {
    CIRCLE = "circle",
    POLYGON = "polygon"
})

--- @brief
function ow.StageConfig:_construct_hitboxes()
    local hitbox_class = rt.settings.overworld.stage_config.hitbox_class_name

    local function _process_polygon(vertices, angle, origin_x, origin_y, offset_x, offset_y)
        local cos_angle = math.cos(angle)
        local sin_angle = math.sin(angle)

        local out = {}
        for i = 1, #vertices, 2 do
            local x, y = vertices[i], vertices[i + 1]

            x = x - origin_x
            y = y - origin_y

            local new_x = x * cos_angle - y * sin_angle
            local new_y = x * sin_angle + y * cos_angle

            new_x = new_x + origin_x
            new_y = new_y + origin_y

            table.insert(out, new_x + offset_x)
            table.insert(out, new_y + offset_y)
        end

        return out
    end
    
    self._layer_i_to_physics_shapes = {}
    for layer_i, layer in pairs(self._layer_i_to_layer) do
        local objects = {}

        -- collect hitbox objects
        if layer.type == ow.LayerType.TILES then
            local current_x, current_y = 0, 0
            for row_i = 1, self._n_rows do
                for col_i = 1, self._n_columns do
                    local gid = layer.gid_matrix:get(col_i, row_i)
                    if gid ~= nil then
                        local entry = self._gid_to_tileset_tile[gid]
                        local tile_objects = entry.tileset:get_tile_objects(entry.id)
                        for object in values(tile_objects) do
                            if object.class == hitbox_class then
                                table.insert(objects, {
                                    object = object,
                                    offset_x = current_x,
                                    offset_y = current_y
                                })
                            end
                        end
                    end
                    current_x = current_x + self._tile_width
                end
                current_y = current_y + self._tile_height
                current_x = 0
            end
        elseif layer.type == ow.LayerType.OBJECTS then
            for object in values(layer.objects) do
                if object.class == hitbox_class then
                    table.insert(objects, {
                        object = object,
                        offset_x = 0,
                        offset_y = 0
                    })
                end

                --[[
                if object.type == ow.ObjectType.SPRITE then
                    local gid = object.gid
                    local entry = self._gid_to_tileset_tile[gid]
                    local tile_objects = entry.tileset:get_tile_objects(entry.id)
                    for tile_object in values(tile_objects) do
                        if tile_object.class == hitbox_class then
                            table.insert(objects, {
                                object = tile_object,
                                offset_x = object.top_left_x,
                                offset_y = object.top_left_y,
                                flip_horizontally = object.flip_horizontally,
                                flip_vertically = object.flip_vertically
                            })
                        end
                    end
                end
                ]]--
            end
        end

        -- convert to physics shapes
        local shapes = {}
        for entry in values(objects) do
            local object = entry.object
            local offset_x, offset_y = entry.offset_x, entry.offset_y
            if object.type == ow.ObjectType.RECTANGLE then
                local x, y = object.top_left_x, object.top_left_y
                local w, h = object.width, object.height

                table.insert(shapes, {
                    type = ow.PhysicsShapeType.POLYGON,
                    vertices = _process_polygon({
                            x, y,
                            x + w, y,
                            x + w, y + h,
                            x, y + h
                        },
                        object.rotation, object.origin_x, object.origin_y,
                        offset_x, offset_y
                    );
                })
            elseif object.type == ow.ObjectType.ELLIPSE then
                local xy = _process_polygon(
                    {
                        object.center_x,
                        object.center_y
                    },
                    object.rotation, object.origin_x, object.origin_x,
                    offset_x, offset_y
                )
                table.insert(shapes, {
                    type = ow.PhysicsShapeType.CIRCLE,
                    x = xy[1],
                    y = xy[2],
                    radius = math.max(object.x_radius, object.y_radius)
                })

                if object.x_radius ~= object.y_radius then
                    rt.warning("In ow.StageConfig._construct_physics_shape: layer `" .. layer_i .. "` has object with elliptical shape, which is not support in box2d, use a circle instead")
                end
            elseif object.type == ow.ObjectType.POLYGON then
                for vertices in values(object.shapes) do
                    table.insert(shapes, {
                        type = ow.PhysicsShapeType.POLYGON,
                        vertices = _process_polygon(
                            vertices,
                            object.rotation,
                            object.origin_x,
                            object.origin_y,
                            offset_x,
                            offset_y
                        )
                    })
                end
            elseif object.type == ow.ObjectType.POINT then
                rt.warning("In ow.StageConfig._construct_physics_shape: layer `" .. layer_i .. "` has point object with hitbox, it will be ignored")
            end
        end

        if sizeof(shapes) > 0 then
            self._layer_i_to_physics_shapes[layer_i] = {
                shapes = shapes
            }
        end
    end
end

--- @override
function ow.StageConfig:draw()
    for i = 1, self._n_layers do
        local entry = self._layer_i_to_tileset_to_spritebatch[i]
        if entry ~= nil then
            for _, batch in pairs(entry) do
                batch:draw()
            end
        end

        entry = self._layer_i_to_object_spritebatches[i]
        if entry ~= nil then
            for batch in values(entry.batches) do
                batch:draw()
            end
        end
    end

    -- debug draw:
    for i = 1, self._n_layers do
        local entry = self._layer_i_to_object_spritebatches[i]
        if entry ~= nil then
            for aabb in values(entry.bounds) do
                love.graphics.rectangle("line", table.unpack(aabb))
            end
        end

        entry = self._layer_i_to_physics_shapes[i]
        if entry ~= nil then
            for shape in values(entry.shapes) do
                if shape.type == ow.PhysicsShapeType.CIRCLE then
                    love.graphics.circle("line", shape.x, shape.y, shape.radius, shape.radius)
                elseif shape.type == ow.PhysicsShapeType.POLYGON then
                    love.graphics.polygon("line", shape.vertices)
                end
            end
        end
    end
end