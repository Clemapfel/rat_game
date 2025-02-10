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
    ELLIPSE = "ellipse",
    POLYGON = "polygon",
    POINT = "point"
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
    local total_area = 0
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
        total_area = total_area + to_push.width * to_push.height

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
                    local offset_x, offset_y = _get(object, "x"), _get(object, "y")
                    for vertex in values(_get(object, "polygon")) do
                        table.insert(vertices, _get(vertex, "x") + offset_x)
                        table.insert(vertices, _get(vertex, "y") + offset_y)
                    end

                    -- decompose polygon into 8-gons
                    for d in values(ow.TilesetConfig._decompose_polygon(vertices)) do
                        table.insert(to_push.shapes, {
                            type = ow.TilesetObjectType.POLYGON,
                            vertices = d,
                        })
                    end
                elseif shape_type == "point" then
                    table.insert(to_push.shapes, {
                        type = ow.TilesetObjectType.POINT,
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
        return self._tiles[b].height < self._tiles[b].height
    end)

    table.sort(tiles_sorted, function(a, b)
        return self._tiles[a].width < self._tiles[b].width
    end)

    local atlas_width, atlas_height = math.max(max_width, math.ceil(math.sqrt(total_area))), 0
    do
        local current_x, current_y = 0, 0
        local shelf_height = 0

        for id in values(tiles_sorted) do
            local tile = self._tiles[id]
            if current_x + tile.width > atlas_width then
                current_y = current_y + shelf_height
                current_x = 0
                atlas_height = atlas_height + shelf_height
                shelf_height = 0
            end

            tile.texture_x = current_x
            tile.texture_y = current_y
            tile.texture_width = tile.width
            tile.texture_height = tile.height

            current_x = current_x + tile.width
            shelf_height = math.max(shelf_height, tile.height)
        end

        atlas_height = atlas_height + shelf_height
    end

    self._texture_atlas = love.graphics.newCanvas(atlas_width, atlas_height, {
        msaa = 0
    })
    dbg(self._id, total_area / (atlas_width * atlas_height))

    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(self._texture_atlas)
    love.graphics.setColor(1, 1, 1, 1)
    for tile in values(self._tiles) do
        love.graphics.rectangle("fill", tile.texture_x, tile.texture_y, tile.texture_width, tile.texture_height)
        love.graphics.draw(tile.texture, tile.texture_x, tile.texture_y)
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

--- @brief debug drawing
function ow.TilesetConfig:_draw(tile_id, x, y)
    local tile = self._tiles[tile_id]
    if tile == nil then
        rt.erorr("In ow.TilesetConfig._debug_draw: no tile with id `" .. tile_id .. "` in tileset `" .. self._id .. "`")
    end

    love.graphics.push()
    love.graphics.translate(x, y)

    love.graphics.draw(tile.texture)
    love.graphics.setPointSize(4)
    love.graphics.setLineWidth(1)
    love.graphics.setLineJoin("miter")

    local hue, hue_step = 0, 1 / sizeof(tile.shapes)
    for shape in values(tile.shapes) do
        local r, g, b, _ = rt.color_unpack(rt.lcha_to_rgba(rt.LCHA(0.8, 1, hue, 1)))
        hue = hue + hue_step
        if shape.type == ow.TilesetObjectType.POINT then
            love.graphics.setColor(r, g, b, 1)
            love.graphics.points(shape.x, shape.y)
        elseif shape.type == ow.TilesetObjectType.RECTANGLE then
            love.graphics.setColor(r, g, b, 0.5)
            love.graphics.rectangle("fill", shape.x, shape.y, shape.width, shape.height)
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("line", shape.x, shape.y, shape.width, shape.height)
        elseif shape.type == ow.TilesetObjectType.ELLIPSE then
            love.graphics.setColor(r, g, b, 0.5)
            love.graphics.circle("fill", shape.center_x, shape.center_y, shape.x_radius, shape.y_radius)
            love.graphics.setColor(r, g, b, 1)
            love.graphics.circle("line", shape.center_x, shape.center_y, shape.x_radius, shape.y_radius)
        elseif shape.type == ow.TilesetObjectType.POLYGON then
            love.graphics.setColor(r, g, b, 0.5)
            love.graphics.polygon("fill", shape.vertices)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.polygon("line", shape.vertices)
        else
            rt.error("In ow.TilesetConfig._debug_draw: unhandled shape type `" .. shape.type .. "` in tileset `" .. self._id .. "`")
        end
    end

    love.graphics.pop()
end

-- ear clipping triangulation
local function _triangulate(vertices)
    local triangles = {}
    local n = #vertices / 2
    local indices = {}
    for i = 1, n do
        indices[i] = i
    end

    local function get_point(index)
        return vertices[2 * index - 1], vertices[2 * index]
    end

    local function sign(px1, py1, px2, py2, px3, py3)
        return (px1 - px3) * (py2 - py3) - (px2 - px3) * (py1 - py3)
    end

    while #indices > 3 do
        local ear_found = false
        for i = 1, #indices do
            local i1 = indices[i]
            local i2 = indices[(i % #indices) + 1]
            local i3 = indices[(i + 1) % #indices + 1]

            local x1, y1 = get_point(i1)
            local x2, y2 = get_point(i2)
            local x3, y3 = get_point(i3)

            local cross_product = (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1)
            if cross_product < 0 then
                local is_ear = true
                for j = 1, #indices do
                    if j ~= i and j ~= (i % #indices) + 1 and j ~= (i + 1) % #indices + 1 then
                        local px, py = get_point(indices[j])

                        local d1 = sign(px, py, x1, y1, x2, y2)
                        local d2 = sign(px, py, x2, y2, x3, y3)
                        local d3 = sign(px, py, x3, y3, x1, y1)

                        local has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
                        local has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

                        local is_point_in_triangle = not (has_neg and has_pos)

                        if is_point_in_triangle then
                            is_ear = false
                            break
                        end
                    end
                end

                if is_ear then
                    table.insert(triangles, {x1, y1, x2, y2, x3, y3})
                    table.remove(indices, (i % #indices) + 1)
                    ear_found = true
                    break
                end
            end
        end

        if not ear_found then
            rt.error("In ow.TilesetConfig._decompose_polygon: unable to triangulate polygon")
        end
    end

    local x1, y1 = get_point(indices[1])
    local x2, y2 = get_point(indices[2])
    local x3, y3 = get_point(indices[3])
    table.insert(triangles, {x1, y1, x2, y2, x3, y3})
    return triangles
end

-- merge triangles with shared base
local function _merge_triangles_into_trapezoids(triangles)
    local trapezoids = {}
    local used = {}

    for i = 1, #triangles do
        if not used[i] then
            local merged = false
            for j = i + 1, #triangles do
                if not used[j] then
                    local shared_vertices = 0
                    for m = 1, 6, 2 do
                        for n = 1, 6, 2 do
                            if triangles[i][m] == triangles[j][n] and triangles[i][m + 1] == triangles[j][n + 1] then
                                shared_vertices = shared_vertices + 1
                            end
                        end
                    end

                    if shared_vertices == 2 then
                        local trapezoid = {}
                        for m = 1, 6, 2 do
                            table.insert(trapezoid, triangles[i][m])
                            table.insert(trapezoid, triangles[i][m + 1])
                        end
                        for m = 1, 6, 2 do
                            local is_shared = false
                            for n = 1, #trapezoid, 2 do
                                if triangles[j][m] == trapezoid[n] and triangles[j][m + 1] == trapezoid[n + 1] then
                                    is_shared = true
                                    break
                                end
                            end
                            if not is_shared then
                                table.insert(trapezoid, triangles[j][m])
                                table.insert(trapezoid, triangles[j][m + 1])
                            end
                        end

                        assert(#trapezoid <= 8) -- box2d max vertex count
                        table.insert(trapezoids, trapezoid)
                        used[i] = true
                        used[j] = true
                        merged = true
                        break
                    end
                end
            end
            if not merged then
                table.insert(trapezoids, triangles[i])
            end
        end
    end

    return trapezoids
end

function ow.TilesetConfig._decompose_polygon(vertices)
    return _merge_triangles_into_trapezoids(_triangulate(vertices))
end