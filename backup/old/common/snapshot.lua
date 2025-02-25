rt.settings.snapshot = {
    shader_source = "assets/shaders/snapshot_layout.glsl"
}

--- @class rt.Snapshot
rt.Snapshot = meta.new_type("Snapshot", rt.Widget, function()
    return meta.new(rt.Snapshot, {
        _canvas = rt.RenderTexture(1, 1, true),
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
        _padding_horizontal = 0,
        _padding_vertical = 0,
        _invert = false,
        _mix_color = rt.RGBA(1, 1, 1, 1),
        _mix_weight = 0,
        _opacity = 1,
    })
end, {
    -- shared static members
    _shader = rt.Shader(rt.settings.snapshot.shader_source)
})

--- @brief
function rt.Snapshot:snapshot(to_draw)
    rt.graphics.push()
    self._canvas:bind()
    rt.graphics.clear(0, 0, 0, 0)
    local x, y = to_draw:get_position()
    rt.graphics.translate(-x, -y)
    rt.graphics.translate(self._padding_horizontal, self._padding_vertical)
    if to_draw.snapshot ~= nil then to_draw:snapshot() else to_draw:draw() end
    self._canvas:unbind()
    rt.graphics.pop()
end

--- @brief
function rt.Snapshot:draw()
    self._shader:bind()
    self._shader:send("r_offset", self._rgb_offsets[1])
    self._shader:send("g_offset", self._rgb_offsets[2])
    self._shader:send("b_offset", self._rgb_offsets[3])
    self._shader:send("h_offset", self._hsv_offsets[1])
    self._shader:send("s_offset", self._hsv_offsets[2])
    self._shader:send("v_offset", self._hsv_offsets[3])
    --self._shader:send("_a_offset", self._alpha_offset)

    self._shader:send("r_factor", self._rgb_factors[1])
    self._shader:send("g_factor", self._rgb_factors[2])
    self._shader:send("b_factor", self._rgb_factors[3])
    self._shader:send("h_factor", self._hsv_factors[1])
    self._shader:send("s_factor", self._hsv_factors[2])
    self._shader:send("v_factor", self._hsv_factors[3])
    --self._shader:send("_a_factor", self._alpha_factor)

    self._shader:send("mix_color", {self._mix_color.r, self._mix_color.g, self._mix_color.b, self._mix_color.a})
    self._shader:send("mix_weight", self._mix_weight)
    self._shader:send("invert", self._invert)
    self._shader:send("opacity", self._opacity)

    local black = rt.Palette.BLACK
    self._shader:send("black", {black.r, black.g, black.b, black.a})

    self:draw_canvas()
    self._shader:unbind()
end

--- @brief
function rt.Snapshot:size_allocate(x, y, width, height)
    if not self._is_realized then return end
    self._canvas = rt.RenderTexture(width + 2 * self._padding_horizontal, height + 2 * self._padding_vertical, true)
    self._position_x = x - self._padding_horizontal
    self._position_y = y - self._padding_vertical
end

--- @brief
function rt.Snapshot:set_opacity(alpha)
    self._opacity = alpha
end

--- @brief
function rt.Snapshot:set_rgb_offset(r, g, b)
    self._rgb_offsets[1] = which(r, 0)
    self._rgb_offsets[2] = which(g, 0)
    self._rgb_offsets[3] = which(b, 0)
end

--- @brief
function rt.Snapshot:set_hsv_offset(h, s, v)
    self._hsv_offsets[1] = which(h, 0)
    self._hsv_offsets[2] = which(s, 0)
    self._hsv_offsets[3] = which(v, 0)
end

--- @brief
function rt.Snapshot:set_opacity_offset(value)
    self._alpha_offset = which(value, 0)
end

--- @brief
function rt.Snapshot:set_color_offsets(r, g, b, h, s, v, a)
    self._rgb_offsets[1] = which(r, 0)
    self._rgb_offsets[2] = which(g, 0)
    self._rgb_offsets[3] = which(b, 0)
    self._hsv_offsets[1] = which(h, 0)
    self._hsv_offsets[2] = which(s, 0)
    self._hsv_offsets[3] = which(v, 0)
    self._alpha_offset = which(a, 0)
end

--- @brief
function rt.Snapshot:set_position_offset(x, y)
    self._x_offset = math.floor(which(x, 0))
    self._y_offset = math.floor(which(y, 0))
end

--- @brief
--- @param x Number in [0, 1]
--- @param y Number in [0, 1]
function rt.Snapshot:set_origin(x, y)
    self._origin_x = which(x, 0.5)
    self._origin_y = which(y, 0.5)
end

--- @brief
function rt.Snapshot:set_scale(x, y)
    self._scale_x = which(x, 1)
    self._scale_y = which(y, x)
end

--- @brief
function rt.Snapshot:reset()
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
    self._scale_x = 1
    self._scale_y = 1
    self._origin_x = 0.5
    self._origin_y = 0.5

    self._invert = false
    self._mix_color = rt.RGBA(1, 1, 1, 1)
    self._mix_weight = 0

    self._opacity = 1
end

--- @brief
function rt.Snapshot:get_rgb_offset()
    return self._rgb_offsets[1], self._rgb_offsets[2], self._rgb_offsets[3]
end

--- @brief
function rt.Snapshot:get_hsv_offset()
    return self._hsv_offsets[1], self._hsv_offsets[2], self._hsv_offsets[3]
end

--- @brief
function rt.Snapshot:get_alpha_offset()
    return self._alpha_offset
end

--- @brief
function rt.Snapshot:set_mix_color(color)
    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end
    self._mix_color = color
end

--- @brief
--- @param weight Number 0 for only original, 1 for only mix
function rt.Snapshot:set_mix_weight(weight)
    self._mix_weight = weight
end

--- @brief
function rt.Snapshot:set_invert(b)
    self._invert = b
end

--- @brief
function rt.Snapshot:get_invert()
    return self._invert
end

--- @brief
function rt.Snapshot:set_padding(horizontal, vertical)
    horizontal = which(horizontal, 0)
    vertical = which(vertical, 0)

    local reformat = self._padding_horizontal ~= horizontal or self._padding_vertical ~= vertical
    self._padding_horizontal = horizontal
    self._padding_vertical = vertical

    if reformat and self._is_realized then
        self:reformat()
    end
end

--- @brief
function rt.Snapshot:draw_canvas()
    local bounds = self:get_bounds()
    local x_offset, y_offset = bounds.x + self._origin_x * bounds.width, bounds.y + self._origin_y * bounds.height
    rt.graphics.push()
    rt.graphics.translate(x_offset, y_offset)
    rt.graphics.scale(self._scale_x, self._scale_y)
    rt.graphics.translate(-1 * x_offset, -1 * y_offset)

    love.graphics.draw(self._canvas._native, self._position_x + self._x_offset, self._position_y + self._y_offset)
    rt.graphics.pop()
end
