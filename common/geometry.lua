--- @class rt.Direction
rt.Direction = meta.new_enum({
    UP = "up",
    RIGHT = "right",
    DOWN = "down",
    LEFT = "left",
    NONE = "none"
})

--- @class rt.AxisAlignedRectangle
function rt.AxisAlignedRectangle(top_left_x, top_left_y, width, height)
    if meta.is_nil(top_left_x) then
        top_left_x = 0
    end

    if meta.is_nil(top_left_y) then
        top_left_y = 0
    end

    if meta.is_nil(width) then
        width = 0
    end

    if meta.is_nil(height) then
        height = 0
    end

    return {
        x = top_left_x,
        y = top_left_y,
        width = width,
        height = height
    }
end

rt.AABB = rt.AxisAlignedRectangle

--- @brief
function meta.is_aabb(object)
    return sizeof(object) == 4 and meta.is_number(object.x) and meta.is_number(object.y) and meta.is_number(object.width) and meta.is_number(object.height)
end

--- @brief
function meta.assert_aabb(object)
    if not meta.is_aabb(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Expected `AxisAlignedRectangle`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @brief is point inside rectangles bounds
--- @param x Number
--- @param y Number
--- @return Boolean
function rt.aabb_contains(self, x, y)
    return x >= self.x and x <= (self.x + self.width) and y >= self.y and y <= (self.y + self.height)
end

--- @brief
--- @return x, y, w, h
function rt.aabb_unpack(self)
    return self.x, self.y, self.width, self.height
end

--- @brief
function rt.aabb_equals(a, b)
    return a.x == b.x and a.y == b.y and a.width == b.width and a.height == b.height
end

--- @brief
function rt.aabb_copy(a)
    return rt.AABB(a.x, a.y, a.width, a.height)
end

--- @brief translate point along vector with angle relative to x axis
function rt.translate_point_by_angle(point_x, point_y, distance, angle)
    return point_x + distance * math.cos(angle), point_y + distance * math.sin(angle)
end

--- @brief get angle of vector relative to x axis
function rt.angle(x, y)
    return math.atan2(y, x)
end

--- @brief
function rt.magnitude(x, y)
    return math.sqrt(x^2 + y^2)
end

--- @brief
function rt.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

--- @brief
function rt.distance_point_to_line(x, y, x1, y1, x2, y2)
    local a = x - x1
    local b = y - y1
    local c = x2 - x1
    local d = y2 - y1

    local dot = a * c + b * d
    local len_sq = c * c + d * d
    local param = -1
    if len_sq ~= 0 then
        param = dot / len_sq
    end

    local xx, yy
    if param < 0 then
        xx = x1
        yy = y1
    elseif param > 1 then
        xx = x2
        yy = y2
    else
        xx = x1 + param * c
        yy = y1 + param * d
    end

    local dx = x - xx
    local dy = y - yy
    return math.sqrt(dx * dx + dy * dy)
end

--- @brief
function rt.normalize(x, y)
    local magnitude = rt.magnitude(x, y)
    if magnitude == 0 then return 0, 0 end
    return x / magnitude, y / magnitude
end


function rt.intersection(l1p1x, l1p1y, l1p2x, l1p2y, l2p1x, l2p1y, l2p2x, l2p2y)
    local d = (l1p1x - l1p2x) * (l2p1y - l2p2y) - (l1p1y - l1p2y) * (l2p1x - l2p2x)
    local a = l1p1x * l1p2y - l1p1y * l1p2x
    local b = l2p1x * l2p2y - l2p1y * l2p2x
    local x = (a * (l2p1x - l2p2x) - (l1p1x - l1p2x) * b) / d
    local y = (a * (l2p1y - l2p2y) - (l1p1y - l1p2y) * b) / d

    return x, y
end

--- @brief
function rt.to_polar(x, y)
    return rt.magnitude(x, y), math.atan2(y, x)
end

--- @brief
function rt.from_polar(magnitude, angle)
    return rt.translate_point_by_angle(0, 0, magnitude, angle)
end

--- @brief convert radians to degrees
--- @param rads Number
--- @return Number
function rt.radians_to_degrees(rads)
    return rads * (180 / math.pi)
end

--- @brief convert degrees to radians
--- @param dgs Number
--- @return Number
function rt.degrees_to_radians(dgs)
    return dgs * (math.pi / 180)
end


--- @brief triangle with rounded corners, like a triangular sign
function rt.generate_rounded_triangle(center_x, center_y, radius, corner_radius, n_corner_vertices)
    if n_corner_vertices == nil then n_corner_vertices = 16 end

    local function translate_point_by_angle(point_x, point_y, distance, angle)
        return point_x + distance * math.cos(angle), point_y + distance * math.sin(angle)
    end

    local vertices = {}
    for _, angle in pairs({
        0/3 * (2 * math.pi) + (math.pi / 6),
        1/3 * (2 * math.pi) + (math.pi / 6),
        2/3 * (2 * math.pi) + (math.pi / 6)
    }) do
        local corner_x, corner_y = translate_point_by_angle(center_x, center_y, radius - corner_radius, angle)
        for i = 1, n_corner_vertices do
            local x, y = translate_point_by_angle(corner_x, corner_y, corner_radius, (i - 1) / (n_corner_vertices) * (2 * math.pi) / 3 - ((2 * math.pi) / 6) + angle)
            table.insert(vertices, x)
            table.insert(vertices, y)
        end
    end

    -- close loop
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])

    return vertices
end

--- @brief
--- @param thickness
--- @param angle Number lower angle of hat, > 180 for downwards pointing
function rt.generate_hat_arrow(centroid_x, centroid_y, width, thickness, angle)

    angle = which(angle, 90)
    angle = 180 - angle

    local center_x, center_y = centroid_x, centroid_y
    local right_x, right_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, rt.degrees_to_radians((angle / 2)))
    local left_x, left_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, -1 * rt.degrees_to_radians(180 + (angle / 2)))


    local top = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, -1 * rt.degrees_to_radians(90))
    end

    local bottom = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, rt.degrees_to_radians(90))
    end

    local center_top_x, center_top_y = top(center_x, center_y)
    local center_bottom_x, center_bottom_y = bottom(center_x, center_y)
    local right_top_x, right_top_y = top(right_x, right_y)
    local right_bottom_x, right_bottom_y = bottom(right_x, right_y)
    local left_top_x, left_top_y = top(left_x, left_y)
    local left_bottom_x, left_bottom_y = bottom(left_x, left_y)

    return {
        center_top_x, center_top_y,
        right_top_x, right_top_y,
        right_bottom_x, right_bottom_y,

        center_bottom_x, center_bottom_y,
        center_top_x, center_top_y,
        right_bottom_x, right_bottom_y,

        center_top_x, center_top_y,
        left_top_x, left_top_y,
        left_bottom_x, left_bottom_y,

        center_top_x, center_top_y,
        center_bottom_x, center_bottom_y,
        left_bottom_x, left_bottom_y
    }
end

function rt.generate_hat_arrow_outline(centroid_x, centroid_y, width, thickness, angle)

    angle = which(angle, 90)
    angle = 180 - angle

    local center_x, center_y = centroid_x, centroid_y
    local right_x, right_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, rt.degrees_to_radians((angle / 2)))
    local left_x, left_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, -1 * rt.degrees_to_radians(180 + (angle / 2)))


    local top = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, -1 * rt.degrees_to_radians(90))
    end

    local bottom = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, rt.degrees_to_radians(90))
    end

    local center_top_x, center_top_y = top(center_x, center_y)
    local center_bottom_x, center_bottom_y = bottom(center_x, center_y)
    local right_top_x, right_top_y = top(right_x, right_y)
    local right_bottom_x, right_bottom_y = bottom(right_x, right_y)
    local left_top_x, left_top_y = top(left_x, left_y)
    local left_bottom_x, left_bottom_y = bottom(left_x, left_y)

    return {
        center_top_x, center_top_y,
        right_top_x, right_top_y,
        right_bottom_x, right_bottom_y,
        center_bottom_x, center_bottom_y,
        left_bottom_x, left_bottom_y,
        left_top_x, left_top_y,
        center_top_x, center_top_y,
    }
end


