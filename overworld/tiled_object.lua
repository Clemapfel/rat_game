--- @brief
function ow.parse_tile_object(tiled_object)
    local is_solid_name = rt.settings.overworld.tileset_config.is_solid_property_name

    local object_to_add = {
        name = _get(object, "name"),
        class = _get(object, "class"),
        is_visible = _get(object, "is_visible")
    }
    if object.gid ~= nil then -- sprite
        assert(object.shape == "rectangle", "malformed sprite object")
        local true_gid, flip_x, flip_y = _decode_gid(object.gid)

        local x, y = _get(object, "x"), _get(object, "y")
        local width, height = _get(object, "width"), _get(object, "height")
        table.insert(to_add.objects, {
            type =  ow.ObjectType.SPRITE,
            gid = true_gid,
            flip_horizontally = flip_x,
            flip_vertically = flip_y,
            x = x,
            y = y - height, -- tiled uses bottom left origin
            width = width,
            height = height,
            rotation = _get(object, "rotation"),
            origin_x = x,
            origin_y = y,
            is_visible = _get(object, "is_visible")
        })
    else

    end

    local shape_type = _get(object, "shape")
    local object_to_add = {
        name = _get(object, "name"),
        class = _get(object, "class"),
        is_visible = _get(object, "is_visible")
    }

    table.insert(to_push.objects, object_to_add)

    if shape_type == "rectangle" then
        local x = _get(object, "x")
        local y = _get(object, "y")
        local width = _get(object, "width")
        local height = _get(object, "height")

        if width * height >= tile.width * tile.height then -- if hitbox is larger than tile, tile is wall
            to_push.properties[is_solid_name] = true
        end

        object_to_add.type = ow.ObjectType.RECTANGLE
        object_to_add.x = x -- top left
        object_to_add.y = y
        object_to_add.width = width
        object_to_add.height = height
    elseif shape_type == "ellipse" then
        local x = _get(object, "x")
        local y = _get(object, "y")
        local width = _get(object, "width")
        local height = _get(object, "height")

        object_to_add.type = ow.ObjectType.ELLIPSE
        object_to_add.center_x = x + 0.5 * width
        object_to_add.center_y = y + 0.5 * height
        object_to_add.x_radius = 0.5 * width
        object_to_add.y_radius = 0.5 * height
    elseif shape_type == "polygon" then
        local vertices = {}
        local offset_x, offset_y = _get(object, "x"), _get(object, "y")
        for vertex in values(_get(object, "polygon")) do
            table.insert(vertices, _get(vertex, "x") + offset_x)
            table.insert(vertices, _get(vertex, "y") + offset_y)
        end

        object_to_add.type = ow.ObjectType.POLYGON
        object_to_add.vertices = vertices
        object_to_add.shapes = ow.TilesetConfig._decompose_polygon(vertices)
    elseif shape_type == "point" then
        object_to_add.type = ow.ObjectType.POINT
        object_to_add.x = _get(object, "x")
        object_to_add.y = _get(object, "y")
    else
        rt.error("In ow.TilesetConfig.realize: unrecognized shape type when handling tile `" .. id .. "` of tiles set at `" .. path .. "`")
    end

    if sizeof(_get(object, "properties")) > 0 then
        rt.error("In ow.TilesetConfig.realize: unhandled per-hitbox properties in object group of tile `" .. id .. "` of tiles set at `" .. path .. "`")
    end

end