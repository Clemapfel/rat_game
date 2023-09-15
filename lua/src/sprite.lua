--- @class Image


--- @class Vertex
rt.Vertex = meta.new("Vertex", function()
    return meta.new(rt.Vertex, {})
end)

rt.Vertex._position_x_index = 1
rt.Vertex._position_y_index = 2
rt.Vertex._texture_coordinate_u_index = 3
rt.Vertex._texture_coordinate_v_index = 4
rt.Vertex._color_r_index = 5
rt.Vertex._color_g_index = 6
rt.Vertex._color_b_index = 7
rt.Vertex._color_b_index = 8

--- @brief
function rt.Vertex:set_position(x, y)
    meta.assert_isa(self, rt.Vertex)
    self[rt.Vertex._position_x_index] = x
    self[rt.Vertex._position_y_index] = y
end

--- @brief
function rt.Vertex:get_position()
    meta.assert_isa(self, rt.Vertex)
    return self[rt.Vertex._position_x_index], self[rt.Vertex._position_y_index]
end

--- @brief
function rt.Vertex:set_texture_coordinate(u, v)
    meta.assert_isa(self, rt.Vertex)
    self[rt.Vertex._texture_coordinate_u_index] = u
    self[rt.Vertex._texture_coordinate_v_index] = v
end

--- @brief
function rt.Vertex:get_texture_coordinate()
    meta.assert_isa(self, rt.Vertex)
    return self[rt.Vertex._texture_coordinate_u_index], self[rt.Vertex._texture_coordinate_v_index]
end

--- @brief
function rt.Vertex:set_color(color)
    meta.assert_isa(self, rt.Vertex)
    rt.assert_rgba(color)
    self[rt.Vertex._color_r_index] = color.r
    self[rt.Vertex._color_g_index] = color.g
    self[rt.Vertex._color_b_index] = color.b
    self[rt.Vertex._color_a_index] = color.a
end

--- @brief
function rt.Vertex:get_color()
    meta.assert_isa(self, rt.Vertex)
    return rt.RGBA(
        self[rt.Vertex._color_r_index],
        self[rt.Vertex._color_g_index],
        self[rt.Vertex._color_b_index],
        self[rt.Vertex._color_a_index]
    )
end

--- @class Sprite
rt.Sprite = meta.new("Sprite", function()
    local out = meta.new(rt.Sprite, {
        _mesh =
    }, rt.Drawable)
end)