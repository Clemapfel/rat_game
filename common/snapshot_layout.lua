--- @class rt.SnapshotLayout
--- @brief caches rendered child to a canvas, this can be used to apply color transforms or reduce load during rendering
rt.SnapshotLayout = meta.new_type("SnapshotLayout", rt.Widget, function()
    local out = meta.new(rt.SnapshotLayout, {
        _child = {},
        _canvas = rt.RenderTexture(1, 1, true),
        _shader = rt.Shader(rt.SnapshotLayout._shader_source),
        _rgb_offsets = {0, 0, 0},
        _hsv_offsets = {0, 0, 0},
        _rgb_factors = {1, 1, 1},
        _hsv_factors = {1, 1, 1},
        _alpha_offset = 0,
        _alpha_factor = 1,
        _position_x = 0,
        _position_y = 0,
        _x_offset = 0,
        _y_offset = 0,
        _scale_x = 1,
        _scale_y = 1,
        _origin_x = 0.5,
        _origin_y = 0.5,
        _invert = false,
        _mix_color = rt.RGBA(1, 1, 1, 1),
        _mix_weight = 0,
        _vertex_color = rt.RGBA(1, 1, 1, 1),
        _opacity = 1,
    })
    return out
end)

rt.SnapshotLayout._shader_source = love.filesystem.read("assets/shaders/snapshot_layout.glsl")

--- @brief update internally held render canvas
function rt.SnapshotLayout:snapshot(to_draw)
    if to_draw == nil then to_draw = self._child end
    self._canvas:bind_as_render_target()
    rt.graphics.clear(0, 0, 0, 0)
    if meta.is_drawable(to_draw) then
        love.graphics.push()
        local x, y = to_draw:get_position()
        rt.graphics.translate(-x, -y)
        if to_draw.snapshot ~= nil then to_draw:snapshot() else to_draw:draw() end
        love.graphics.pop()
    end
    self._canvas:unbind_as_render_target()
end

--- @overload rt.Drawable.draw
function rt.SnapshotLayout:draw()
    self._shader:bind()
    self._shader:send("_r_offset", self._rgb_offsets[1])
    self._shader:send("_g_offset", self._rgb_offsets[2])
    self._shader:send("_b_offset", self._rgb_offsets[3])
    self._shader:send("_h_offset", self._hsv_offsets[1])
    self._shader:send("_s_offset", self._hsv_offsets[2])
    self._shader:send("_v_offset", self._hsv_offsets[3])
    self._shader:send("_a_offset", self._alpha_offset)

    self._shader:send("_r_factor", self._rgb_factors[1])
    self._shader:send("_g_factor", self._rgb_factors[2])
    self._shader:send("_b_factor", self._rgb_factors[3])
    self._shader:send("_h_factor", self._hsv_factors[1])
    self._shader:send("_s_factor", self._hsv_factors[2])
    self._shader:send("_v_factor", self._hsv_factors[3])
    self._shader:send("_a_factor", self._alpha_factor)

    self._shader:send("_mix_color", {self._mix_color.r, self._mix_color.g, self._mix_color.b, self._mix_color.a})
    self._shader:send("_mix_weight", self._mix_weight)
    self._shader:send("_invert", self._invert)
    self._shader:send("_vertex_color", {self._vertex_color.r, self._vertex_color.g, self._vertex_color.b, self._vertex_color.a})
    self._shader:send("_opacity", self._opacity)

    local bounds = self:get_bounds()
    local x_offset, y_offset = bounds.x + self._origin_x * bounds.width, bounds.y + self._origin_y * bounds.height
    love.graphics.push()
    love.graphics.setCanvas(nil)
    rt.graphics.translate(x_offset, y_offset)
    rt.graphics.scale(self._scale_x, self._scale_y)
    rt.graphics.translate(-1 * x_offset, -1 * y_offset)

    love.graphics.draw(self._canvas._native, self._position_x + self._x_offset, self._position_y + self._y_offset)
    love.graphics.pop()
    self._shader:unbind()
end

--- @overload rt.Widget.size_allocate
function rt.SnapshotLayout:size_allocate(x, y, width, height)
    local canvas_w, canvas_h = self._canvas:get_size()
    self._position_x = x
    self._position_y = y
    self._bounds = rt.AABB(x, y, width, height)

    self._canvas = rt.RenderTexture(width, height, true)
    self:snapshot()
end

--- @brief
function rt.SnapshotLayout:set_rgb_offset(r, g, b)
    self._rgb_offsets[1] = which(r, 0)
    self._rgb_offsets[2] = which(g, 0)
    self._rgb_offsets[3] = which(b, 0)
end

--- @brief
function rt.SnapshotLayout:set_hsv_offset(h, s, v)
    self._hsv_offsets[1] = which(h, 0)
    self._hsv_offsets[2] = which(s, 0)
    self._hsv_offsets[3] = which(v, 0)
end

--- @brief
function rt.SnapshotLayout:set_opacity_offset(value)
    self._alpha_offset = which(value, 0)
end

--- @brief
function rt.SnapshotLayout:set_color_offsets(r, g, b, h, s, v, a)
    self._rgb_offsets[1] = which(r, 0)
    self._rgb_offsets[2] = which(g, 0)
    self._rgb_offsets[3] = which(b, 0)
    self._hsv_offsets[1] = which(h, 0)
    self._hsv_offsets[2] = which(s, 0)
    self._hsv_offsets[3] = which(v, 0)
    self._alpha_offset = which(a, 0)
end

--- @brief sets vertex colors
function rt.SnapshotLayout:set_color(rgba)
    if meta.is_hsva(rgba) then rgba = rt.hsva_to_rgba(rgba) end
    self._vertex_color = rgba
end

--- @brief
function rt.SnapshotLayout:set_position_offset(x, y)
    self._x_offset = which(x, 0)
    self._y_offset = which(y, 0)
end

--- @brief
--- @param x Number in [0, 1]
--- @param y Number in [0, 1]
function rt.SnapshotLayout:set_origin(x, y)
    self._origin_x = which(x, 0.5)
    self._origin_y = which(y, 0.5)
end

--- @brief
function rt.SnapshotLayout:set_scale(x, y)
    self._scale_x = which(x, 1)
    self._scale_y = which(y, x)
end

--- @brief
function rt.SnapshotLayout:reset()
    self._rgb_offsets[1] = 0
    self._rgb_offsets[2] = 0
    self._rgb_offsets[3] = 0
    self._hsv_offsets[1] = 0
    self._hsv_offsets[2] = 0
    self._hsv_offsets[3] = 0
    self._alpha_offset = 0

    self._rgb_factors[1] = 1
    self._rgb_factors[2] = 1
    self._rgb_factors[3] = 1
    self._hsv_factors[1] = 1
    self._hsv_factors[2] = 1
    self._hsv_factors[3] = 1
    self._alpha_factor = 1

    self._x_offset = 0
    self._y_offset = 0
end

--- @brief
function rt.SnapshotLayout:get_rgb_offset()
    return self._rgb_offsets[1], self._rgb_offsets[2], self._rgb_offsets[3]
end

--- @brief
function rt.SnapshotLayout:get_hsv_offset()
    return self._hsv_offsets[1], self._hsv_offsets[2], self._hsv_offsets[3]
end

--- @brief
function rt.SnapshotLayout:get_alpha_offset()
    return self._alpha_offset
end

--- @brief
function rt.SnapshotLayout:set_mix_color(color)
    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end
    self._mix_color = color
end

--- @brief
--- @param weight Number 0 for only original, 1 for only mix
function rt.SnapshotLayout:set_mix_weight(weight)
    self._mix_weight = weight
end

--- @brief
function rt.SnapshotLayout:set_invert(b)
    self._invert = b
end

--- @brief
function rt.SnapshotLayout:get_invert()
    return self._invert
end

--- @brief set singular child
--- @param child rt.Widget
function rt.SnapshotLayout:set_child(child)
    if not meta.is_nil(self._child) and meta.is_widget(self._child) then
        self._child:set_parent(nil)
    end

    self._child = child
    child:set_parent(self)

    if self:get_is_realized() then
        self._child:realize()
        self:reformat()
    end

    self:snapshot()
end

--- @brief get singular child
--- @return rt.Widget
function rt.SnapshotLayout:get_child()
    return self._child
end

--- @brief remove child
function rt.SnapshotLayout:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end

    self:snapshot()
end

--- @overload rt.Widget.measure
function rt.SnapshotLayout:measure()
    if not meta.is_widget(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.SnapshotLayout:realize()
    if self:get_is_realized() then return end
    if meta.is_widget(self._child) then
        self._child:realize()
    end

    rt.Widget.realize(self)
    if meta.is_widget(self._child) then
        self:snapshot()
    end
end

--- @override
function rt.SnapshotLayout:set_opacity(alpha)
    self._opacity = alpha
end