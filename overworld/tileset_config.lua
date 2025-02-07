rt.settings.overworld.tileset_config = {
    config_path = "assets/tilesets"
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

ow.TilesetObjectType = meta.new_enum("TilesetObjectType", {
    RECTANGLE = "rectangle",
    ELLIPSE = "ellipse"
})

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

    local min_width, min_height = POSITIVE_INFINITY, POSITIVE_INFINITY
    local max_width, max_height = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local total_width, total_height = 0, 0
    local tiles_sorted = {}
    local _min, _max = math.min, math.max

    self._n_tiles = _get(config, "tilecount")
    self._first_tile_id = POSITIVE_INFINITY
    self._last_tile_id = NEGATIVE_INFINITY
    self._tile_ids = {}
    self._tiles = {}
    local tiles = _get(config, "tiles")
    for tile in values(tiles) do
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

            shapes = {},
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

        min_width = _min(min_width, to_push.width)
        max_width = _max(max_width, to_push.width)
        min_height = _min(min_height, to_push.height)
        max_height = _max(max_height, to_push.height)
        total_width = total_width + to_push.width
        total_height = total_height + to_push.height

        -- parse physics shapes
        if tile.objectGroup ~= nil then
            local objects = _get(_get(tile, "objectGroup"), "objects")

            if objects.properties ~= nil then
                rt.error("In ow.TilesetConfig.realize: unhandled per-object group properties in object group of tile `" .. id .. "` of tiles set at `" .. path .. "`")
            end

            for object in values(objects) do
                local shape_type = _get(object, "shape")
                if shape_type == "rectangle" then
                    table.insert(to_push.shapes, {
                        type = ow.TilesetObjectType.RECTANGLE,
                        x = _get(object, "x"), -- top left
                        y = _get(object, "y"),
                        width = _get(object, "width"),
                        height = _get(object, "height")
                    })
                elseif shape_type == "ellipse" then
                    local x = _get(object, "x")
                    local y = _get(object, "y")
                    local width = _get(object, "width")
                    local height = _get(object, "height")
                    table.insert(to_push.shapes, {
                        type = ow.TilesetObjectType.ELLIPSE,
                        center_x = x + 0.5 * width,
                        center_y = y + 0.5 * height,
                        x_radius = 0.5 * width,
                        y_radius = 0.5 * height
                    })
                elseif shape_type == "polygon" then
                    local vertices = {}
                    for vertex in values(_get(object, "polygon")) do
                        table.insert(vertices, _get(vertex, "x"))
                        table.insert(vertices, _get(vertex, "y"))
                    end

                    table.insert(to_push.shapes, {
                        vertices = vertices
                    })
                elseif shape_type == "point" then
                    table.insert(to_push.shapes, {
                        x = _get(object, "x"),
                        y = _get(object, "y")
                    })
                else
                    rt.error("In ow.TilesetConfig.realize: unrecognized shape type when handling tile `" .. id .. "` of tiles set at `" .. path .. "`")
                end

                if sizeof(_get(object, "properties")) > 0 then
                    rt.error("In ow.TilesetConfig.realize: unhandled per-hitbox properties in object group of tile `" .. id .. "` of tiles set at `" .. path .. "`")
                end
            end
        end

        -- per-tile properties
        if tile.properties ~= nil then
            for key, value in pairs(_get(tile, "properties")) do
                to_push.properties[key] = value
            end
        end
    end

    -- construct texture atlas
    table.sort(tiles_sorted, function(a, b)
        return self._tiles[a].width < self._tiles[b].width
    end)

    table.sort(tiles_sorted, function(a, b)
        return self._tiles[b].height < self._tiles[b].height
    end)

    self._texture = love.graphics.newCanvas(max_width, total_height, {
        msaa = 0
    })

    -- TODO: use actual packing algorithm
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(self._texture)
    love.graphics.setColor(1, 1, 1, 1)
    local current_x, current_y = 0, 0
    for id in values(tiles_sorted) do
        local tile = self._tiles[id]
        tile.texture_x = current_x
        tile.texture_y = current_y
        tile.texture_width = tile.width
        tile.texture_height = tile.height
        love.graphics.draw(tile.texture, current_x, current_y)
        current_y = current_y + tile.height
    end
    love.graphics.setCanvas(nil)
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