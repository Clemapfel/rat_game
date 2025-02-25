rt.settings.overworld.tiled = {
    is_solid_property_name = "is_solid"
}

ow.ObjectType = meta.new_enum("ObjectType", {
    RECTANGLE = "rectangle",
    ELLIPSE = "ellipse",
    POLYGON = "polygon",
    POINT = "point",
    SPRITE = "sprite"
})

-- tiled uses first 4 bits for flipping (3, 4 for non-square tilings)
local function _decode_gid(gid)
    local true_id = bit.band(gid, 0x0FFFFFFF) -- all but first 4 bit
    local flip_x = 0 ~= bit.band(gid, 0x80000000) -- first bit
    local flip_y = 0 ~= bit.band(gid, 0x40000000) -- second bit
    return true_id, flip_x, flip_y
end

local _get = function(t, name)
    local out = t[name]
    if out == nil then
        rt.error("In rt.parse_tiled_config: trying to access property `" .. name .. "`, but it does not exist")
    end
    return out
end

--- @brief parse tile object group, of tile or object layer
function ow.parse_tiled_object_group(object_group)
    local is_solid_name = rt.settings.overworld.tiled.is_solid_property_name
    
    local group_offset_x, group_offset_y = _get(object_group, "offsetx"), _get(object_group, "offsety")
    local group_visible = _get(object_group, "visible")

    local objects = {}
    for object in values(_get(object_group, "objects")) do
        local to_push = {
            tiled_id = _get(object, "id"),
            name = _get(object, "name"),
            class = _get(object, "type"), -- sic
            is_visible = _get(object, "visible") and group_visible,
            properties = {}
        }
        table.insert(objects, to_push)

        for key, value in values(_get(object, "properties")) do
            if meta.is_table(value) then -- object property
                to_push.properties[key] = { value.id }
            else
                to_push.properties[key] = value
            end
        end

        to_push.rotation = math.rad(_get(object, "rotation"))

        if object.gid ~= nil then -- sprite
            assert(object.shape == "rectangle", "In ow.parse_tiled_object: object has gid, but is not a rectangle")

            local true_gid, flip_horizontally, flip_vertically = _decode_gid(object.gid)
            local x, y = _get(object, "x"), _get(object, "y")
            local width, height = _get(object, "width"), _get(object, "height")

            to_push.type = ow.ObjectType.SPRITE
            to_push.gid = true_gid
            to_push.top_left_x = x + group_offset_x
            to_push.top_left_y = y - height + group_offset_y -- tiled uses bottom left
            to_push.width = width
            to_push.height = height
            to_push.flip_vertically = flip_vertically
            to_push.flip_horizontally = flip_horizontally
            to_push.origin_x = x -- bottom left
            to_push.origin_y = y
            to_push.flip_origin_x = 0.5 * width
            to_push.flip_origin_y = 0.5 * height
        else
            local shape_type = _get(object, "shape")
            if shape_type == "rectangle" then
                local x, y = _get(object, "x"), _get(object, "y")
                to_push.type = ow.ObjectType.RECTANGLE
                to_push.top_left_x = x + group_offset_y -- top left
                to_push.top_left_y = y + group_offset_y
                to_push.width = _get(object, "width")
                to_push.height = _get(object, "height")
                to_push.origin_x = x
                to_push.origin_y = y
            elseif shape_type == "ellipse" then
                local x = _get(object, "x") + group_offset_x
                local y = _get(object, "y") + group_offset_y
                local width = _get(object, "width")
                local height = _get(object, "height")

                to_push.type = ow.ObjectType.ELLIPSE
                to_push.center_x = x + 0.5 * width
                to_push.center_y = y + 0.5 * height
                to_push.x_radius = 0.5 * width
                to_push.y_radius = 0.5 * height
                to_push.origin_x = x
                to_push.origin_y = y
            elseif shape_type == "polygon" then
                local vertices = {}
                local offset_x, offset_y = _get(object, "x"), _get(object, "y")
                for vertex in values(_get(object, "polygon")) do
                    local x, y = _get(vertex, "x"), _get(vertex, "y")
                    table.insert(vertices, x + offset_x + group_offset_x)
                    table.insert(vertices, y + offset_y + group_offset_y)
                end

                to_push.type = ow.ObjectType.POLYGON
                to_push.vertices = vertices
                to_push.shapes = ow.decompose_polygon(vertices)
                to_push.origin_x = offset_x
                to_push.origin_y = offset_y
            elseif shape_type == "point" then
                local x, y = _get(object, "x"),  _get(object, "y")
                to_push.type = ow.ObjectType.POINT
                to_push.x = x + group_offset_x
                to_push.y = y + group_offset_y
                to_push.origin_x = x
                to_push.origin_y = y
                if object.rotation ~= nil then assert(object.rotation == 0) end
            end
        end
    end

    return objects
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

function ow.decompose_polygon(vertices)
    return _merge_triangles_into_trapezoids(_triangulate(vertices))
end