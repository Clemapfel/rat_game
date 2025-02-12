rt.settings.overworld.tileset_config = {
    config_path = "assets/tilesets",
    is_solid_property_name = "is_solid"
}

--[[
Expects "multiple images" Tiled tileset
located in "assets/tilesets"
with images of tileset "foo" in "assets/tilesets/foo" directory
]]--

--- @class ow.TilesetConfig
ow.TilesetConfig = meta.new_type("TilesetConfig", function(id)
    local out = ow.TilesetConfig._atlas[id]
    if out == nil then
        out = meta.new(ow.TilesetConfig, {
            _id = id
        })
        out:realize()
        ow.TilesetConfig._atlas[id] = out
    end
    return out
end)
ow.TilesetConfig._atlas = {}



--- @brief
function ow.TilesetConfig:realize()
    local config_path_prefix = rt.settings.overworld.tileset_config.config_path .. "/"
    local path = config_path_prefix .. self._id .. ".lua"

    local load_success, chunk_or_error, love_error = pcall(love.filesystem.load, path)
    if not load_success then
        rt.error("In ow.TilesetConfig.realize: error when parsing tileset at `" .. path .. "`: " .. chunk_or_error)
        return
    end

    if love_error ~= nil then
        rt.error("In ow.TilesetConfig.realize: error when loading tileset at `" .. path .. "`: " .. love_error)
        return
    end

    local chunk_success, config_or_error = pcall(chunk_or_error)
    if not chunk_success then
        rt.error("In ow.TilesetConfig.realize: error when running tileset at `" .. path .. "`: " .. config_or_error)
        return
    end

    local config = config_or_error

    local _get = function(t, name) -- safely exit on malformatted table
        local out = t[name]
        if out == nil then
            rt.error("In ow.TilesetConfig.realize: trying to access property `" .. name .. "` of tileset at `" .. path .. "`, but it does not exist")
        end
        return out
    end

    local widths = {}
    local n_tiles = 0
    local total_area = 0
    local tiles_sorted = {}
    local _min, _max = math.min, math.max

    self._n_tiles = _get(config, "tilecount")
    self._tile_width = _get(config, "tilewidth")
    self._tile_height = _get(config, "tileheight")
    self._first_tile_id = POSITIVE_INFINITY
    self._last_tile_id = NEGATIVE_INFINITY
    self._tile_ids = {}
    self._tiles = {}
    local tiles = _get(config, "tiles")
    for tile in values(tiles) do
        -- init tile data
        local id = _get(tile, "id")
        local tile_path = config_path_prefix .. _get(tile, "image")
        local to_push = {
            id = id,
            path = tile_path,
            width = _get(tile, "width"),
            height = _get(tile, "height"),

            texture = love.graphics.newImage(tile_path),
            texture_x = 0,
            texture_y = 0,
            texture_width = 0,
            texture_height = 0,

            objects = {},
            properties = {}
        }

        self._first_tile_id = _min(self._first_tile_id, id)
        self._last_tile_id = _max(self._last_tile_id, id)
        table.insert(self._tile_ids, id)

        if not (to_push.width == to_push.texture:getWidth()) or not (to_push.height == to_push.texture:getHeight()) then
            rt.error("In ow.TilesetConfig.realize: malformed tile texture of tile `" .. id .. "` of tileset at `" .. path .. "`: is this tile already in a texture altas?")
        end

        self._tiles[id] = to_push
        table.insert(tiles_sorted, id)
        table.insert(widths, to_push.width)
        n_tiles = n_tiles + 1
        total_area = total_area + to_push.width * to_push.height

        -- per-tile properties
        if tile.properties ~= nil then
            for key, value in pairs(_get(tile, "properties")) do
                to_push.properties[key] = value
            end
        end

        if tile.objectGroup ~= nil then
            to_push.objects = ow.parse_tiled_object_group(_get(tile, "objectGroup"))
        end
    end

    -- construct texture atlas positioning
    table.sort(tiles_sorted, function(a, b)
        return self._tiles[b].height < self._tiles[b].height
    end)

    table.sort(tiles_sorted, function(a, b)
        return self._tiles[a].width < self._tiles[b].width
    end)

    table.sort(widths, function(a, b)
        return a > b
    end)

    -- heuristic to determine optimal atlas size
    local atlas_width = widths[1]
    if n_tiles > 1 then
        atlas_width = atlas_width + widths[2]
    end
    atlas_width = math.max(atlas_width, math.ceil(math.sqrt(total_area)))

    local atlas_height = 0
    local max_row_width = NEGATIVE_INFINITY
    do
        local current_x, current_y = 0, 0
        local row_width = 0
        local shelf_height = 0

        for id in values(tiles_sorted) do
            local tile = self._tiles[id]
            if current_x + tile.width > atlas_width then
                current_y = current_y + shelf_height
                current_x = 0
                atlas_height = atlas_height + shelf_height
                shelf_height = 0
                max_row_width = math.max(max_row_width, row_width)
                row_width = 0
            end

            tile.texture_x = current_x
            tile.texture_y = current_y
            tile.texture_width = tile.width
            tile.texture_height = tile.height

            current_x = current_x + tile.width
            row_width = row_width + tile.width
            shelf_height = math.max(shelf_height, tile.height)
        end

        atlas_height = atlas_height + shelf_height
    end

    atlas_width = max_row_width -- trim if no row is full

    -- paste to canvas
    self._texture_atlas = rt.RenderTexture(atlas_width, atlas_height, 0)

    local space_usage = total_area / (atlas_width * atlas_height)
    if space_usage < 0.7 then
        rt.warning("In ow.TilesetConfig.realize: texture atlas of tileset `" .. self._id .. "` only uses `" .. math.floor(space_usage * 1000) / 1000 * 100 .. "%` of allocated space")
    end

    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(self._texture_atlas._native)
    love.graphics.setColor(1, 1, 1, 1)
    for tile in values(self._tiles) do
        love.graphics.draw(tile.texture, tile.texture_x, tile.texture_y)

        -- compute float texture coordinates
        tile.texture:release()
        tile.texture = nil
        tile.texture_x = tile.texture_x / atlas_width
        tile.texture_y = tile.texture_y / atlas_height
        tile.texture_width = tile.texture_width / atlas_width
        tile.texture_height = tile.texture_height / atlas_height
    end
    love.graphics.setCanvas(nil)
end

--- @brief
function ow.TilesetConfig:get_tile_property(id, property_name)
    local tile = self._tiles[id]
    if tile == nil then
        rt.error("In ow.TilesetConfig.get_tile_property: no tile with id `" .. id .. "` in tileset `" .. self._id .. "`")
        return nil
    end
    return tile.properties[property_name]
end

--- @brief
function ow.TilesetConfig:get_n_tiles()
    return self._n_tiles
end

--- @brief
function ow.TilesetConfig:get_tile_ids()
    return self._tile_ids
end

--- @brief
function ow.TilesetConfig:get_id()
    return self._id
end

--- @brief
function ow.TilesetConfig:get_texture()
    return self._texture_atlas
end

--- @brief
function ow.TilesetConfig:get_tile_size(id)
    if id == nil then
        return self._tile_width, self._tile_height
    else
        local tile = self._tiles[id]
        if tile == nil then
            rt.error("In ow.TilesetConfig.get_tile_size: no tile with id `" .. id .. "`")
            return 0, 0
        end
        return tile.width, tile.height
    end
end

--- @brief
function ow.TilesetConfig:get_texture_bounds(id)
    local tile = self._tiles[id]
    if tile == nil then
        rt.error("In ow.TilesetConfig.get_bounds: no tile with id `" .. id .. "`")
        return 0, 0, 0, 0
    end

    return tile.texture_x, tile.texture_y, tile.texture_width, tile.texture_height
end

--- @brief debug drawing
function ow.TilesetConfig:_draw(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._texture_atlas._native, x, y)
    local atlas_w, atlas_h = self._texture_atlas._native:getDimensions()

    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.rectangle("line", x, y, atlas_w, atlas_h)

    love.graphics.setPointSize(4)
    love.graphics.setLineWidth(1)
    love.graphics.setLineJoin("miter")

    local r, g, b = 0, 1, 1
    local fill_a, line_a = 0.2, 0.8

    for tile in values(self._tiles) do
        local tx, ty, tw, th = tile.texture_x * atlas_w, tile.texture_y * atlas_h, tile.texture_width * atlas_w, tile.texture_height * atlas_h
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.rectangle("line", tx, ty, tw, th)

        love.graphics.push()
        love.graphics.translate(tx, ty)
        for shape in values(tile.objects) do
            if shape.type == ow.ObjectType.POINT then
                love.graphics.setColor(r, g, b, line_a)
                love.graphics.points(shape.x, shape.y)
            elseif shape.type == ow.ObjectType.RECTANGLE then
                love.graphics.setColor(r, g, b, fill_a)
                love.graphics.rectangle("fill", shape.x, shape.y, shape.width, shape.height)
                love.graphics.setColor(r, g, b, line_a)
                love.graphics.rectangle("line", shape.x, shape.y, shape.width, shape.height)
            elseif shape.type == ow.ObjectType.ELLIPSE then
                love.graphics.setColor(r, g, b, fill_a)
                love.graphics.circle("fill", shape.center_x, shape.center_y, shape.x_radius, shape.y_radius)
                love.graphics.setColor(r, g, b, line_a)
                love.graphics.circle("line", shape.center_x, shape.center_y, shape.x_radius, shape.y_radius)
            elseif shape.type == ow.ObjectType.POLYGON then
                for d in values(shape.shapes) do
                    love.graphics.setColor(r, g, b, fill_a)
                    love.graphics.polygon("fill", d)
                    love.graphics.setColor(r, g, b, line_a)
                    love.graphics.polygon("line", d)
                end
            else
                rt.error("In ow.TilesetConfig._debug_draw: unhandled shape type `" .. shape.type .. "` in tileset `" .. self._id .. "`")
            end
        end
        love.graphics.pop()
    end
end
